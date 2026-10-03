import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def run(*args, **kwargs):
    return subprocess.run(args, check=True, text=True, **kwargs)


def atomic_write(path, contents, mode=0o600, uid=0, gid=0):
    path = Path(path)
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}-")
    try:
        with os.fdopen(fd, "w") as stream:
            os.fchmod(stream.fileno(), mode)
            os.fchown(stream.fileno(), uid, gid)
            stream.write(contents)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def import_ids(config):
    for kind, names in (("uid", config["systemUsers"]), ("gid", config["systemGroups"])):
        legacy = Path(f"/var/lib/nixos/{kind}-map")
        if not legacy.exists():
            continue
        ids = json.loads(legacy.read_text())
        directory = Path(f"/var/lib/nixos/{kind}")
        directory.mkdir(mode=0o755, parents=True, exist_ok=True)
        for name in names:
            if name not in ids:
                continue
            marker = directory / name
            if marker.exists():
                metadata = marker.stat()
                if (metadata.st_uid if kind == "uid" else metadata.st_gid) != ids[name]:
                    raise RuntimeError(f"Legacy {kind.upper()} conflicts with marker ownership for {name}")
                continue
            atomic_write(marker, "", mode=0o644,
                         uid=ids[name] if kind == "uid" else 0,
                         gid=ids[name] if kind == "gid" else 0)


def shadow_record(name, paths):
    for path in paths:
        if not path.exists():
            continue
        for line in path.read_text().splitlines():
            fields = line.split(":")
            if fields[0] == name:
                password = fields[1]
                if not password.lstrip("!") or password.lstrip("!") in ("*", "x"):
                    raise RuntimeError(f"Unsupported password state for {name}; refusing to reset it")
                record = {"privileged": {"hashedPassword": [password]}}
                day = 86_400_000_000
                for index, key in ((3, "passwordChangeMinUSec"), (4, "passwordChangeMaxUSec"),
                                   (5, "passwordChangeWarnUSec"), (6, "passwordChangeInactiveUSec")):
                    if fields[index] and int(fields[index]) >= 0:
                        record[key] = int(fields[index]) * day
                if fields[2] and int(fields[2]) >= 0:
                    record["passwordChangeNow"] = int(fields[2]) == 0
                    if int(fields[2]) > 0:
                        record["lastPasswordChangeUSec"] = int(fields[2]) * day
                if fields[7] and int(fields[7]) >= 0:
                    if int(fields[7]) <= 1:
                        record["locked"] = True
                    else:
                        record["notAfterUSec"] = int(fields[7]) * day
                if any(isinstance(value, int) and value >= 2**64 - 1 for value in record.values()):
                    raise RuntimeError(f"Password aging value out of range for {name}")
                if fields[8] not in ("", "0"):
                    raise RuntimeError(f"Unsupported shadow flags for {name}")
                return record
    raise RuntimeError(f"No existing password hash found for {name}; refusing to reset it")


def assert_logged_out(uid):
    for status in Path("/proc").glob("[0-9]*/status"):
        try:
            for line in status.read_text().splitlines():
                if line.startswith("Uid:") and uid in map(int, line.split()[1:]):
                    raise RuntimeError(f"UID {uid} still has running processes; log out and reboot to migrate")
        except (FileNotFoundError, ProcessLookupError):
            continue


def remove_classic_account(name, backup):
    for filename in ("passwd", "shadow", "group", "gshadow"):
        path = Path("/etc") / filename
        if not path.exists():
            continue
        contents = path.read_text()
        saved = backup / filename
        if not saved.exists():
            atomic_write(saved, contents)
        lines = []
        for line in contents.splitlines():
            fields = line.split(":")
            if fields[0] == name:
                continue
            if filename in ("group", "gshadow"):
                for index in ([3] if filename == "group" else [2, 3]):
                    fields[index] = ",".join(member for member in fields[index].split(",") if member != name)
            lines.append(":".join(fields))
        updated = "\n".join(lines) + "\n"
        if updated != contents:
            metadata = path.stat()
            atomic_write(path, updated, metadata.st_mode & 0o777, metadata.st_uid, metadata.st_gid)
    for database in ("passwd", "group"):
        subprocess.run(["nscd", "--invalidate", database], check=False)


def inspect(name):
    result = subprocess.run(["homectl", "inspect", "--json=short", name], check=False, text=True, capture_output=True)
    if result.returncode == 0:
        return json.loads(result.stdout)
    if not Path(f"/var/lib/systemd/home/{name}.identity").exists():
        return None
    raise RuntimeError(f"Unable to inspect existing homed account {name}: {result.stderr.strip()}")


def provision(config):
    state = Path("/var/lib/systemd/home-migration")
    state.mkdir(mode=0o700, parents=True, exist_ok=True)
    for name, user in config["users"].items():
        record = user["record"]
        home = Path(record["homeDirectory"])
        image = Path(record["imagePath"])
        pending = state / f"{name}.json"
        current = inspect(name)

        if current is None:
            if home.exists() or image.exists() or pending.exists():
                assert_logged_out(record["uid"])
                if home.is_symlink() or image.is_symlink():
                    raise RuntimeError(f"Refusing to migrate symlinked home for {name}")
                if not pending.exists():
                    migration = record | shadow_record(name, [Path("/etc/shadow"), Path(config["legacyShadow"])])
                    migration["privileged"]["sshAuthorizedKeys"] = record["privileged"]["sshAuthorizedKeys"]
                    # Persist the original credentials before moving the home or removing classic records.
                    atomic_write(pending, json.dumps(migration))
                if home.exists() and image.exists():
                    raise RuntimeError(f"Both {home} and {image} exist; resolve this before migrating")
                if home.exists():
                    home.rename(image)
                if not image.is_dir():
                    raise RuntimeError(f"Missing backing directory {image}")
                backup = state / name
                backup.mkdir(mode=0o700, exist_ok=True)
                remove_classic_account(name, backup)
                run("homectl", "register", str(pending))
            else:
                password_hash = run("mkpasswd", "--method=yescrypt", "--stdin", input=user["initialPassword"], capture_output=True).stdout.strip()
                creation = record | {
                    "secret": {"password": [user["initialPassword"]]},
                    "privileged": record["privileged"] | {"hashedPassword": [password_hash]},
                    "enforcePasswordPolicy": False,
                }
                run("homectl", "create", "--no-ask-password", "--identity=-", input=json.dumps(creation))
                run("homectl", "update", "--offline", name, "--enforce-password-policy=yes")

        if pending.exists():
            # Registration is authoritative; finish the embedded identity before clearing the checkpoint.
            embedded = run("homectl", "inspect", "-E", name, capture_output=True).stdout
            atomic_write(image / ".identity", embedded, uid=record["uid"], gid=record["uid"])
            pending.unlink()

        current = inspect(name)
        managed = ("realName", "shell", "memberOf")
        keys = record["privileged"]["sshAuthorizedKeys"]
        if (any(current.get(field, [] if isinstance(record[field], list) else "") != record[field] for field in managed)
                or current.get("privileged", {}).get("sshAuthorizedKeys", []) != keys):
            updated = {key: value for key, value in current.items()
                       if key not in ("signature", "status", "secret", "binding", "blobManifest", "lastChangeUSec", "sshAuthorizedKeys")}
            updated.update({field: record[field] for field in managed})
            updated["privileged"] = current.get("privileged", {}) | {"sshAuthorizedKeys": keys}
            run("homectl", "update", "--offline", "--identity=-", name, input=json.dumps(updated))


if __name__ == "__main__":
    with open(sys.argv[1]) as stream:
        config = json.load(stream)
    try:
        {"import-ids": import_ids, "provision": provision}[sys.argv[2]](config)
    except (RuntimeError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
