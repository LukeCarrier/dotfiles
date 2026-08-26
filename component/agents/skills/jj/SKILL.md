---
name: jj
description: Working with jj (Jujutsu) version control. Load when the user mentions jj, or asks to commit, rebase, push, or inspect history in a jj repo.
---

## When to use me

Whenever version control runs through jj: committing, rebasing, pushing, fetching, or inspecting history.

## Orient first

jj setup varies per repo — discover it, never assume:

```bash
jj git remote list   # remote names and URLs
jj bookmark list     # local bookmarks
```

Use the discovered remote name (usually `origin`, but confirm) in `jj git push`/`fetch`.

## Co-located repos

A repo with both `.jj/` and `.git/` metadata is **co-located**. jj imports Git state on each command and exports its own state back, so `git` operations do not corrupt jj — jj reconciles them on its next invocation.

**Prefer jj commands regardless, especially for writes.** Reach for `git` only for reads jj has no equivalent for. Let jj own history mutation so its operation log stays authoritative and undoable (`jj op log`, `jj undo`).

## Common operations

### Status and history
```bash
jj status
jj log --limit 10
jj log -r 'main..@'   # commits ahead of main
```

### Bookmarks (jj's name for branches)
```bash
jj bookmark list
jj bookmark list --all   # includes remote-tracking bookmarks
```

### Describe the working copy
```bash
jj describe -m "feat: my feature description"
```

jj has no Git-style staging area. Most jj commands snapshot the working copy before operating, unless explicitly told not to. `@` names the current revision, while the working copy is the checkout that jj snapshots. `jj new` starts a fresh change on top; re-running `jj describe -m` amends the current one. Treat a request to split the latest change as a request to split `@` when that is the latest revision.

### `describe` is not `commit`

`jj describe` sets a message on `@` and **leaves `@` open**. It is not the end of a unit of work. Every edit made afterwards is snapshotted into that same described change, silently mixing the next piece of work into a commit that already reads as finished.

When building a stack of commits, close each one before starting the next:

```bash
jj commit -m "<msg>"   # describe @ AND start a fresh empty change
# or
jj describe -m "<msg>" && jj new
```

`jj commit` is `describe` + `new` in one step, so prefer it when writing a series. Reach for bare `jj describe` only when amending the message of a change you intend to keep working in.

Symptom of getting this wrong: `jj diff --stat` on a change you thought was finished lists files belonging to the following commit. Recover with `jj split` rather than starting over — see the `jj-split-change` skill.

### Rebase
```bash
jj rebase -d main -r <change-id>   # a specific change
jj rebase -d main                   # the current revision
```

### Push and fetch
```bash
jj git push --bookmark <bookmark-name>
jj git fetch
```

Local and remote bookmarks are distinct and do not auto-track. Always name the bookmark explicitly on push.

### Diff
```bash
jj diff -r <change-id> --stat   # summary
jj diff -r <change-id>          # full diff
```

### Bisect

```bash
jj bisect run --range '<good>::<bad>' -- <command>
```

Walks the range bisecting on exit code: 0 = good, non-0 = bad. Prints the first bad revision when done. To discard any commits created during the search, run the `jj op restore` command it prints at the end.

## Caveats

- **`jj git push` won't force-push by default.** It errors if the remote diverged. Use with care.
- **Bookmarks don't auto-track.** Push explicitly with `--bookmark`; after a rebase the local and remote bookmark diverge until you push.
- **Undo is cheap.** A wrong mutation is recoverable via `jj undo` / `jj op restore` — prefer fixing forward over aborting.
- **`jj squash` opens an editor by default.** Pass `--message` to avoid it: `jj squash --into <rev> --message "<msg>"`.
- **Anything that writes a description may open an editor.** `jj split`, `jj squash` and `jj describe` all do. Pass `-m/--message` where the command accepts it. Where it does not, set `EDITOR=true` — a bare command name resolved on `PATH`, *not* `/bin/true`, which does not exist on every system. Without a TTY the editor panics (`reader source not set`) and jj rolls the whole operation back, so the command appears to do nothing.
