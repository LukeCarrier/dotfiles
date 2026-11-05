#!/usr/bin/env python3
"""Render a saved Terraform plan or stdin text/show -json output as HTML."""

import argparse
import difflib
import html
import json
from pathlib import Path
import re
import subprocess
import sys


TIMESTAMP = re.compile(
    r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}"
    r"(?:\.[0-9]+)?Z ", re.MULTILINE
)
ESCAPE = re.compile(
    r"\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)"
    r"|\x1b\[[0-?]*[ -/]*[@-~]|\x1b[ -/]*[@-Z\\-_]"
)
HEADER = re.compile(
    r"^\s*# (?P<address>\S.*) (?P<action>will be .+|must be .+|has .+)$"
)
DECLARATION = re.compile(r'\b(?:resource|data) "[^"]+" "[^"]+" \{\s*$')


def action_class(action):
    if "replaced" in action:
        return "replace"
    if "created" in action:
        return "add"
    if "destroyed" in action:
        return "remove"
    if "updated" in action:
        return "change"
    return "read"


def render_lines(lines):
    rendered = []
    for line in lines:
        marker = line.lstrip()
        kind = ""
        if marker.startswith(("-/+", "+/-")):
            kind = "replace"
        elif marker.startswith("+"):
            kind = "add"
        elif marker.startswith("-"):
            kind = "remove"
        elif marker.startswith("~"):
            kind = "change"
        elif marker.startswith("<="):
            kind = "read"
        rendered.append(f'<span class="{kind}">{html.escape(line)}</span>')
    return "<pre>" + "\n".join(rendered) + "</pre>"


def render_plan(text):
    parts = []
    lines = []
    resource = None
    closing = None

    def flush():
        if resource is None:
            if lines:
                parts.append(render_lines(lines))
        else:
            address, action = resource
            parts.append(
                f'<details class="resource {action_class(action)}">'
                f'<summary><code>{html.escape(address)}</code> '
                f'<span class="action">{html.escape(action)}</span></summary>'
                + render_lines(lines) + "</details>"
            )

    for line in text.splitlines():
        header = HEADER.match(line)
        if header:
            flush()
            lines = []
            resource = (header["address"], header["action"])
            closing = None
            continue
        lines.append(line)
        if resource is not None:
            declaration = DECLARATION.search(line)
            if declaration:
                closing = " " * declaration.start() + "}"
            elif closing is not None and line.rstrip() == closing:
                flush()
                lines = []
                resource = None
                closing = None
    flush()
    return "\n".join(parts)


def merge_sensitive(left, right):
    if left is True or right is True:
        return True
    if (isinstance(left, list) and isinstance(right, dict)) or (
        isinstance(left, dict) and isinstance(right, list)
    ):
        return True
    if isinstance(left, dict) or isinstance(right, dict):
        left = left if isinstance(left, dict) else {}
        right = right if isinstance(right, dict) else {}
        return {key: merge_sensitive(left.get(key), right.get(key))
                for key in left.keys() | right.keys()}
    if isinstance(left, list) or isinstance(right, list):
        left = left if isinstance(left, list) else []
        right = right if isinstance(right, list) else []
        return [merge_sensitive(left[i] if i < len(left) else None,
                                right[i] if i < len(right) else None)
                for i in range(max(len(left), len(right)))]
    return False


def display_value(value, sensitive=False, unknown=False):
    if sensitive is True:
        return "(sensitive value)"
    if unknown is True:
        return "(known after apply)"
    if isinstance(value, dict) or isinstance(unknown, dict):
        value = value if isinstance(value, dict) else {}
        sensitive = sensitive if isinstance(sensitive, dict) else {}
        unknown = unknown if isinstance(unknown, dict) else {}
        return {key: display_value(value.get(key), sensitive.get(key), unknown.get(key))
                for key in value.keys() | unknown.keys()}
    if isinstance(value, list) or isinstance(unknown, list):
        value = value if isinstance(value, list) else []
        sensitive = sensitive if isinstance(sensitive, list) else []
        unknown = unknown if isinstance(unknown, list) else []
        return [display_value(value[i] if i < len(value) else None,
                              sensitive[i] if i < len(sensitive) else False,
                              unknown[i] if i < len(unknown) else False)
                for i in range(max(len(value), len(unknown)))]
    return value


def render_change(change):
    sensitive = merge_sensitive(change.get("before_sensitive"), change.get("after_sensitive"))
    before = display_value(change.get("before"), sensitive)
    after = display_value(change.get("after"), sensitive, change.get("after_unknown"))
    before_lines = json.dumps(before, indent=2, ensure_ascii=False, sort_keys=True).splitlines()
    after_lines = json.dumps(after, indent=2, ensure_ascii=False, sort_keys=True).splitlines()
    if change["actions"] == ["create"]:
        lines = ["+ " + line for line in after_lines]
    elif change["actions"] == ["delete"]:
        lines = ["- " + line for line in before_lines]
    elif before == after:
        lines = after_lines
    else:
        lines = list(difflib.unified_diff(before_lines, after_lines,
                                          fromfile="before", tofile="after", lineterm=""))
    return render_lines(lines)


def render_json_plan(plan):
    if not isinstance(plan, dict) or "format_version" not in plan or not any(
        key in plan for key in ("resource_changes", "planned_values", "output_changes", "errored")
    ):
        raise ValueError("Expected a plan from terraform/tofu show -json, not state or a remote-plan reference")
    changes = plan.get("resource_changes", [])
    outputs = plan.get("output_changes", {})
    if not isinstance(changes, list) or not isinstance(outputs, dict):
        raise ValueError("Invalid resource_changes or output_changes in JSON plan")
    labels = {
        ("create",): "will be created", ("delete",): "will be destroyed",
        ("update",): "will be updated in-place", ("read",): "will be read during apply",
        ("delete", "create"): "must be replaced (destroy then create)",
        ("create", "delete"): "must be replaced (create then destroy)",
        ("no-op",): "no changes", ("forget",): "will be removed from state (not destroyed)",
    }
    parts = []
    if plan.get("errored"):
        parts.append("<p>Planning failed; this plan may be incomplete.</p>")
    parts.append(f"<p>{len(changes)} resource entries. Values marked sensitive are redacted.</p>")
    for resource in changes:
        if not isinstance(resource, dict) or not isinstance(resource.get("address"), str):
            raise ValueError("Invalid resource address in JSON plan")
        change = resource.get("change")
        if not isinstance(change, dict):
            raise ValueError("Missing resource change in JSON plan")
        actions = change.get("actions")
        if not isinstance(actions, list) or not actions or not all(isinstance(a, str) for a in actions):
            raise ValueError("Invalid change actions in JSON plan")
        action = labels.get(tuple(actions), " / ".join(actions))
        address = resource["address"]
        parts.append(
            f'<details class="resource {action_class(action)}">'
            f'<summary><code>{html.escape(address)}</code> '
            f'<span class="action">{html.escape(action)}</span></summary>'
            + render_change(change) + "</details>"
        )
    if outputs:
        parts.append("<h2>Output changes</h2>")
        for name, change in outputs.items():
            if not isinstance(change, dict) or not isinstance(change.get("actions"), list):
                raise ValueError("Invalid output change in JSON plan")
            parts.append(f"<h3>{html.escape(name)}</h3>" + render_change(change))
    return "\n".join(parts)


DOCUMENT = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Terraform plan</title>
<style>
:root { color-scheme: light dark; font-family: system-ui, sans-serif; }
body { max-width: 100rem; margin: 2rem auto; padding: 0 1rem; }
h1 { font-size: 1.5rem; }
nav { display: flex; gap: .5rem; margin-bottom: 1rem; }
button { padding: .5rem .8rem; cursor: pointer; }
details { border: 1px solid #8886; border-left: 4px solid currentColor;
          border-radius: .3rem; margin: .6rem 0; }
summary { cursor: pointer; padding: .8rem; overflow-wrap: anywhere; }
.action { font-size: .85rem; margin-left: .8rem; }
pre { color: CanvasText; background: Canvas; overflow-x: auto;
      padding: 1rem; margin: 0; font-size: .85rem; line-height: 1.5; }
code, pre { font-family: ui-monospace, monospace; }
.add { color: light-dark(#187534, #7ee787); }
.remove { color: light-dark(#b42318, #ff9b95); }
.change { color: light-dark(#865d00, #f2cc60); }
.replace { color: light-dark(#8045a6, #d2a8ff); }
.read { color: light-dark(#096a9e, #79c0ff); }
@media print { nav { display: none; } pre { white-space: pre-wrap; } }
</style>
</head>
<body>
<h1>Terraform plan</h1>
<nav aria-label="Resource controls">
<button type="button" onclick="setExpanded(true)">Expand all</button>
<button type="button" onclick="setExpanded(false)">Collapse all</button>
<button type="button" onclick="copyAddresses()">Copy all resource addresses</button>
</nav>
<p id="copy-status" role="status" aria-live="polite"></p>
<main>
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "plan", nargs="?",
        help="saved plan file to read using show -json; omit for text or show -json on stdin",
    )
    parser.add_argument("--engine", choices=("terraform", "tofu"), default="terraform",
                        help="CLI used to read a saved plan (default: terraform)")
    args = parser.parse_args()
    if args.plan is None:
        data = sys.stdin.buffer.read()
    else:
        try:
            result = subprocess.run(
                [args.engine, "show", "-json", str(Path(args.plan).resolve())],
                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, check=True,
            )
        except OSError as error:
            parser.exit(1, f"Unable to run {args.engine} show -json: {error}\n")
        except subprocess.CalledProcessError as error:
            parser.exit(error.returncode if error.returncode > 0 else 1)
        data = result.stdout
    text = data.decode("utf-8", errors="replace")
    text = ESCAPE.sub("", TIMESTAMP.sub("", text))
    try:
        body = render_json_plan(json.loads(text)) if text.lstrip().startswith("{") else render_plan(text)
    except (ValueError, TypeError) as error:
        parser.exit(1, f"Unable to render JSON plan: {error}\n")
    document = DOCUMENT + body + """
</main>
<script>
function setExpanded(open) {
  document.querySelectorAll('details.resource').forEach(resource => {
    resource.open = open;
  });
}
async function copyAddresses() {
  const addresses = [...document.querySelectorAll('details.resource > summary > code')]
    .map(address => address.textContent);
  const status = document.getElementById('copy-status');
  if (!addresses.length) {
    status.textContent = 'No resource addresses to copy.';
    return;
  }
  const text = addresses.join('\\n');
  try {
    await navigator.clipboard.writeText(text);
  } catch {
    const field = document.createElement('textarea');
    field.value = text;
    field.setAttribute('aria-label', 'Resource addresses');
    document.body.append(field);
    field.select();
    let copied = false;
    try {
      copied = document.execCommand('copy');
    } catch {}
    if (!copied) {
      status.textContent = 'Automatic copy failed. Copy the selected addresses below.';
      return;
    }
    field.remove();
  }
  status.textContent = `Copied ${addresses.length} resource addresses.`;
}
</script>
</body>
</html>
"""
    sys.stdout.buffer.write(document.encode("utf-8"))


if __name__ == "__main__":
    main()
