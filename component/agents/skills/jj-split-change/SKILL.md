---
name: jj-split-change
description: Split a jj change into multiple commits by hunk. Load when the user asks to break up, split, or decompose a single jj change into separate commits.
---

## When to use me

When a single jj change contains multiple logical concerns and needs to be decomposed into a clean sequence of commits.

## Analyse before acting

In jj, there is no staging area. Most jj commands snapshot the working copy
before operating unless explicitly told not to. Do not describe checkout
contents as "unstaged" or "pending in a staging area". Inspect `@` and its
parent directly; if the user says to split the latest changeset and `@` is the
latest revision, `@` is the revision to split.

Read the full diff before proposing anything:

```bash
jj diff -r <change-id> --stat   # file-level overview
jj diff -r <change-id>           # full hunk-level diff
```

Group hunks by logical concern. **Do not group by file** — a single file often contains hunks belonging to different commits. Present the proposed split to the user and get sign-off before writing any jj commands.

## Sourcing file content

`jj restore --from <rev> --to @` takes the **full file content** from `<rev>`. It cannot restore a single hunk. For files that are being split across commits:

- If the file is **new in `<change-id>`**: source the pre-fix version from the change's parent using `jj file show -r <parent> <old-path>` and write it with the editor tool. Apply the fix in a later commit with the editor tool.
- If the file is **modified in `<change-id>`**: restore it from `<change-id>` then revert the hunks that belong in later commits using the editor tool.
- Only use `jj restore --from <change-id>` directly for files where the entire content belongs in this commit.

## The split loop

For each new commit:

1. `jj new <parent> -m "<message>"` — creates an empty change on top of the previous commit.
2. Restore or write the files for this commit only (see sourcing rules above).
3. Verify: `jj diff -r @ --stat` — confirm only the intended files/hunks are present.
4. Rebase the downstream tail: `jj rebase -s <first-descendant-of-original> -d @`
5. Pause for user review before proceeding to the next commit.

Do **not** batch steps 4 across multiple commits — rebase after every commit so conflicts surface immediately while the change is still small.

## Keeping the tail connected

After `jj new <parent>`, `@` is a new revision on top of `<parent>`. The original change's descendants still point at the original. Until you rebase them, history is forked. Run `jj rebase -s <first-descendant> -d @` after each commit to keep one linear chain.

Identify the first descendant of the original change before starting:

```bash
jj log -r 'children(<change-id>)' --no-graph
```

Use that change-id as `<first-descendant>` throughout.

## Abandoning the original

Once all commits are in place and the tail has been rebased, abandon the original:

```bash
jj abandon <original-change-id>
```

This also deletes any bookmark that pointed at it.

## Verifying the result

```bash
jj log -r '<parent>::<last-descendant>' --no-graph
```

The original change-id should not appear. The chain should be linear with the new commits followed by the original tail.

## Non-interactive only

Never use `jj split` or any other interactive command. All mutations go through `jj new`, `jj restore`, `jj rebase`, `jj abandon`, and editor-tool file writes.
