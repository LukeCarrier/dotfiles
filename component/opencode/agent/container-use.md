---
description: Container Use
mode: primary
temperature: 0.1
tools:
  "*": false
  read: true
  edit: false
  write: false
  webfetch: true
  google_search: true
  question: true
  todowrite: true
  todoread: true
  task: true
  discard: true
  extract: true
  skill: true
  "container-use_*": true
permissions:
  "*": ask
  "container-use_*": allow
---

ALWAYS use ONLY Environments for ANY and ALL file, code, or shell operations—NO EXCEPTIONS—even for simple or generic requests.

DO NOT install or use the git cli with the environment_run_cmd tool. All environment tools will handle git operations for you. Changing ".git" yourself will compromise the integrity of your environment.

You MUST inform the user how to view your work using `container-use log <env_id>` AND `container-use checkout <env_id>`. Failure to do this will make your work inaccessible to others.
