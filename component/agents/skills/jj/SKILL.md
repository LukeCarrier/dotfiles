---
name: jj
description: Working with jj (Jujutsu) version control. Load when the user mentions jj, or asks to commit, rebase, push, inspect history, or reclaim disk space in a jj repo.
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

### Reclaiming space

Deleting a bookmark does not free its objects. jj protects every commit its **operation log** references with a `refs/jj/keep/<oid>` ref, and `git` counts those as reachable. `jj util gc` alone will not drop them, even with `--expire=now`; its `--help` names the missing step — abandon the operations that reference them first.

```bash
# 1. What still holds them?
git for-each-ref --contains <commit> --format='%(refname)'

# 2. Drop the operation history that references them.
#    Bookmarks and commits are unchanged; undo history before @ is not.
jj op abandon '..@-'

# 3. Collect: jj removes the keep refs, then runs git gc itself.
jj util gc --expire=now

# 4. Verify
git for-each-ref refs/jj/keep                      # the object is gone
git rev-list --objects --all | grep -c '<path>/'   # 0
du -sh .git
```

`..@-` abandons every operation before the current one. To keep recent history, abandon up to the operation that introduced the objects instead: `jj op abandon '..<op-id>'`.

**Order matters in a co-located repo.** Run `git gc --prune=now` first and it deletes the objects while the operation log still references them. jj then recreates the keep ref during its next `jj util gc` and fails:

```
refs/jj/keep/<oid> does not point to a valid object!
```

Repair by deleting the dangling ref, then abandoning the operations that reference it:

```bash
git update-ref -d refs/jj/keep/<oid>
jj op abandon '..@-'      # add --ignore-working-copy if the working-copy snapshot re-reads the ref
jj util gc --expire=now
```

Delete only the dangling keep ref. Removing other `refs/jj/keep/*` entries drops commits jj still needs.

Done when `git for-each-ref refs/jj/keep` no longer lists the object, `jj log -r @` works, and `.git` has dropped the paths.

## Caveats

- **`jj git push` won't force-push by default.** It errors if the remote diverged. Use with care.
- **Bookmarks don't auto-track.** Push explicitly with `--bookmark`; after a rebase the local and remote bookmark diverge until you push.
- **Undo is cheap.** A wrong mutation is recoverable via `jj undo` / `jj op restore` — prefer fixing forward over aborting.
- **`jj op abandon` is not undoable.** It discards operation history, so `jj undo` and `jj op restore` cannot reach anything from before the abandoned point. Bookmarks and the current view are untouched.
- **`jj squash` opens an editor by default.** Pass `--message` to avoid it: `jj squash --into <rev> --message "<msg>"`.
- **Anything that writes a description may open an editor.** `jj split`, `jj squash` and `jj describe` all do. Pass `-m/--message` where the command accepts it. Where it does not, set `EDITOR=true` — a bare command name resolved on `PATH`, *not* `/bin/true`, which does not exist on every system. Without a TTY the editor panics (`reader source not set`) and jj rolls the whole operation back, so the command appears to do nothing.
