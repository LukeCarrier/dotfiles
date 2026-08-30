---
status: draft
created: 2026-01-21
updated: 2026-01-21
author: Luke Carrier
---

# `adr.housekeeping`

Perform ADR housekeeping tasks. Run periodically or on demand.

## Usage

```
/adr.housekeeping
```

## Process

1. List all directories in `adrs/`.
2. For each directory, check for `spec.toon` and decode it to read `status`, `created`, and `title`.
3. Run any pending build scripts: `bash ${FIXTURES_DIR}/adr.build.sh adrs/<dir>` for each ADR with stale `.md` files.
4. Update `adrs/README.md` with the current list of ADRs and their statuses.
5. Remove any ADR directories whose status is `rejected`.
