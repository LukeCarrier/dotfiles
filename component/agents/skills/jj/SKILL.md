---
name: jj
description: Working with jj (Jujutsu) version control in this repo. Load when the user mentions jj, commits, branches, rebasing, or pushing.
---

## When to use me

Use when you need to interact with jj for version control operations: committing, rebasing, pushing, pulling, or inspecting history. This repo uses jj as its primary VCS interface, backed by a Git remote.

## How jj is set up here

- **Remote**: `origin` → `https://github.com/throwparty/agentkit` (HTTPS, not SSH)
- **No custom config**: No `.jjconfig.toml`, no `~/.jj/` config. All settings are jj defaults.
- **Underlying Git**: jj stores data in `.jj/repo/` but there is also a `.git/` directory. Use `jj` commands, not `git` commands. Using `git` will corrupt jj's state.

## Common operations

### Check status
```bash
jj status
```

### View log
```bash
jj log --limit 10
jj log -r 'main..@'  # commits ahead of main
jj log -r 'remote_bookmarks()..@ | (remote_bookmarks()..@)-'  # default revset
```

### List bookmarks (branches)
```bash
jj bookmark list
jj bookmark list --all  # includes remote-tracking bookmarks
```

### Create a new change
```bash
jj describe -m "feat: my feature description"
```

Changes are automatically created on `jj new` (like `jj checkout -b` in Git). The working copy is always a change.

### Amend changes
```bash
# After making edits:
jj describe -m "better message"
```

### Rebase onto main
```bash
jj rebase -d main -r <change-id>
# or to rebase the current working copy:
jj rebase -d main
```

### Push to remote
```bash
jj git push --bookmark <bookmark-name>
```

Since remote bookmarks don't automatically track local ones, always specify `--bookmark` explicitly.

### Fetch from remote
```bash
jj git fetch
```

### See diff
```bash
jj diff -r <change-id> --stat  # summary
jj diff -r <change-id>         # full diff
```

## Important caveats

- **Never use `git` commands** directly on this repo. jj manages the Git repo internally and `git` operations will corrupt jj's state.
- **No tracking relationship** is set up between local and remote bookmarks. Always push explicitly with `--bookmark`.
- **The working copy is a jj change**, not a Git branch. Use `jj describe -m ""` for empty/clean working copies.
- **`jj git push` will not force-push** by default. It errors if the remote has diverged. Use with care.

## Bookmarks vs branches

jj calls branches "bookmarks". The local `main` bookmark and `origin/main` remote bookmark are distinct — they don't automatically have a tracking relationship. After rebasing, you may need to force-push (though this is rarely needed day-to-day).
