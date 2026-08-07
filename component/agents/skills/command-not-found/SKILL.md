---
name: command-not-found
description: Resolve a failed command when a binary cannot be found (ENOENT, command not found, etc.) by retrying it via direnv exec or nix develop
license: MIT
compatibility: opencode
---

## What I do

- Retry a failed command inside the environment that provides the missing binary.
- Grant access to tools.
- Grant access to environment variables.

## When to use me

When running a shell command and you are unable to locate a binary which you assume should be installed, or receive authentication/authorisation errors due to a lack of configuration.

If a command execution fails because the binary is not found — for example the error mentions "command not found", ENOENT, or a missing executable — invoke this skill before concluding the binary is unavailable.

## Retry the failed command

If `.envrc` exists in the working directory, run the command inside the direnv environment:

`direnv exec $PWD $COMMAND [$ARG1[ $ARG2[...]]]`

Otherwise, if `flake.nix` or `nix/flake.nix` exists in the working directory, run the command inside the flake's devShell:

`nix develop $PWD -c $COMMAND [$ARG1[ $ARG2[...]]]`