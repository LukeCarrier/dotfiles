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

The working copy is always a change. `jj new` starts a fresh change on top; re-running `jj describe -m` amends the current one.

### Rebase
```bash
jj rebase -d main -r <change-id>   # a specific change
jj rebase -d main                   # the working copy
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

## Caveats

- **`jj git push` won't force-push by default.** It errors if the remote diverged. Use with care.
- **Bookmarks don't auto-track.** Push explicitly with `--bookmark`; after a rebase the local and remote bookmark diverge until you push.
- **Undo is cheap.** A wrong mutation is recoverable via `jj undo` / `jj op restore` — prefer fixing forward over aborting.
