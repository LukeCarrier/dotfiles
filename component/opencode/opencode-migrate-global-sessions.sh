#!/usr/bin/env bash
# https://gist.github.com/benoitheinrich/bb8d76edc6e2bfc0326a511e95e1d4b8
set -euo pipefail

DB="${DB:-$HOME/.local/share/opencode/opencode.db}"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "ERROR: sqlite3 not found on PATH" >&2
  exit 1
fi

if [[ ! -f "$DB" ]]; then
  echo "ERROR: DB file not found: $DB" >&2
  exit 1
fi

echo "DB: $DB"
echo "NOTE: Stop opencode before running this." >&2
echo

RESULTS="$(sqlite3 "$DB" <<'SQL'
.headers off
.mode list
SELECT
  s.directory || '|' || p.id || '|' || COUNT(*)
FROM session s
JOIN project p
  ON p.worktree = s.directory
WHERE s.project_id = 'global'
  AND p.id <> 'global'
GROUP BY s.directory, p.id
ORDER BY COUNT(*) DESC;
SQL
)"

if [[ -z "${RESULTS// }" ]]; then
  echo "No affected directories found. Nothing to do."
  exit 0
fi

echo "Found affected directories (directory | target_project_id | global_sessions):"
echo "$RESULTS" | sed 's/|/ | /g'
echo

read -r -p "Type YES to continue (a DB backup will be created): " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP="${DB}.bak.${STAMP}"
cp -a "$DB" "$BACKUP"
echo "Backup written: $BACKUP"

for ext in -wal -shm; do
  if [[ -f "${DB}${ext}" ]]; then
    cp -a "${DB}${ext}" "${BACKUP}${ext}"
    echo "Backup written: ${BACKUP}${ext}"
  fi
done

echo
echo "Applying migration..."
sqlite3 "$DB" <<'SQL'
.bail on
.headers on
.mode column

BEGIN;

SELECT
  s.directory,
  COUNT(*) AS global_sessions,
  SUM(CASE WHEN s.parent_id IS NULL THEN 1 ELSE 0 END) AS global_roots,
  p.id AS target_project_id,
  p.vcs
FROM session s
JOIN project p
  ON p.worktree = s.directory
WHERE s.project_id = 'global'
  AND p.id <> 'global'
GROUP BY s.directory, p.id, p.vcs
ORDER BY global_sessions DESC;

UPDATE session
SET project_id = (
  SELECT p.id
  FROM project p
  WHERE p.worktree = session.directory
    AND p.id <> 'global'
  ORDER BY p.time_updated DESC
  LIMIT 1
)
WHERE project_id = 'global'
  AND EXISTS (
    SELECT 1
    FROM project p
    WHERE p.worktree = session.directory
      AND p.id <> 'global'
  );

SELECT 'UPDATED_ROWS' AS phase, changes() AS updated_rows;

COMMIT;
SQL

echo
echo "Done. If something went wrong, restore the backup:"
echo "  cp -a \"$BACKUP\" \"$DB\""
echo "  # and also restore $BACKUP-wal / $BACKUP-shm if they exist"

