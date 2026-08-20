---
name: jj-stack
description: Build, reorder, and bookmark a stacked diff series in jj. Load when the user wants to organise commits into reviewable branches, reorder a patch series, or set bookmarks at branch boundaries.
---

## The goal

A stack is a linear sequence of commits where each bookmark tip can be reviewed and merged independently. The stack bottom is `main`; each bookmark marks a logical boundary that can be submitted as a PR.

## Plan before touching anything

1. List the full chain: `jj log -r 'main::<tip>' --no-graph`
2. For each commit, note its stat: `jj diff -r <rev> --stat`
3. Draw the dependency graph — a commit depends on another if it modifies the same file, or if its tests/fixtures assume the other commit's output exists
4. Identify branch boundaries: where does a logical concern end and another begin?
5. **Propose the ordering and bookmarks to the user. Get sign-off before any writes.**

## Dependency rules

A commit B depends on A if:
- B modifies a file A also modifies (file-level conflict risk)
- B's tests assert output that A's code produces (semantic dependency)
- B imports a symbol that A introduces
- B uses generated artifacts (files in `apps/`) that A's generator creates

Commits with no overlapping files can be freely reordered — verify with `jj diff -r <A> --stat` vs `jj diff -r <B> --stat`.

## Reordering a single commit

To move commit X to sit after Y (no descendants of X need moving):

```bash
jj rebase -r <X> -d <Y>
```

If X has descendants that should stay where they are (not follow X), this is safe — jj rebases only X, leaving its former descendants on their original parent.

If X's descendants must follow it, rebase the whole subtree:

```bash
jj rebase -s <X> -d <Y>
```

After any rebase, check for conflicts:
```bash
jj log -r 'all()' --no-graph | grep conflict
```

## Setting bookmarks

```bash
jj bookmark create <name> -r <rev>   # new bookmark
jj bookmark set <name> -r <rev>      # move existing bookmark
```

Name bookmarks after the logical concern, not the ticket (tickets are in commit messages). Good names: `default-regions`, `image-naming`, `infra-generator`, `test-apps`.

## Verifying the stack

After reordering, run `nx sync` and tests at every bookmark tip — not just the head:

```bash
for rev in <tip1> <tip2> <tip3>; do
  jj edit $rev
  pnpm nx sync 2>&1 | grep -E "out of sync|up to date"
  pnpm nx run-many -t test 2>&1 | grep -E "NX   Successfully|Failed tasks:"
done
```

## Parallel branches

When a commit belongs on a different concern from the main chain (e.g. a plugin fix that doesn't touch the same files as a generator change), it can sit as a parallel branch off the common ancestor:

```
main
└── base-fix    [bookmark: base-fix]
    ├── plugin-fix   [bookmark: plugin-fix]  ← parallel, no file overlap
    └── generator-change → ... → [bookmark: generator]
                                   └── test-apps  [bookmark: test-apps]
```

The parallel branch and the main chain can be developed and reviewed independently, but both must be merged before anything that depends on both (e.g. `test-apps` here depends on `generator` which implicitly pulls in `base-fix`).

## Planning stacks early

Stacking should be decided at design time, not after the fact. When starting a piece of work:

1. Identify the independent concerns (plugin fix, generator scaffold, template content, test app generation, operational config)
2. Map their dependencies — which concerns must land before others?
3. Name the branches and create empty bookmarks as placeholders:
   ```bash
   jj new main -m "placeholder: plugin-fix"
   jj bookmark create plugin-fix -r @
   ```
4. Work on each concern in its own branch, committing directly to the right bookmark

This avoids the split-change problem entirely — rather than splitting one large commit after the fact, each concern is committed atomically from the start.

## Common pitfalls

- **`jj restore` is all-or-nothing per file** — use editor tools for hunk-level splits; see `jj-split-change` skill
- **Callers of changed APIs must all be updated in the same commit** — audit every call site before squashing an interface change; a partial update breaks commits between the change and the fix
- **Generated artifacts must be regenerated** — if a commit changes a generator, the next commit that runs that generator must produce correct output; run `nx sync` at every commit that introduces or changes a generator
- **Test fixtures in plugin tests are independent of generator templates** — updating a template does not update the hardcoded fixture strings in plugin tests; both must be updated in the same commit
