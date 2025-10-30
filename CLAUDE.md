# dotfiles Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-30

## Active Technologies

- Nix 2.x (for devShell definitions), Bash/POSIX shell (for shellHook scripts) + Nix flakes, mkShell, existing devShells in `shell/default.nix` (001-devshell-tool-versions)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Nix 2.x (for devShell definitions), Bash/POSIX shell (for shellHook scripts)

## Code Style

Nix 2.x (for devShell definitions), Bash/POSIX shell (for shellHook scripts): Follow standard conventions

## Recent Changes

- 001-devshell-tool-versions: Added Nix 2.x (for devShell definitions), Bash/POSIX shell (for shellHook scripts) + Nix flakes, mkShell, existing devShells in `shell/default.nix`

<!-- MANUAL ADDITIONS START -->
ALWAYS use ONLY Environments for ANY and ALL file, code, or shell operations—NO EXCEPTIONS—even for simple or generic requests.

DO NOT install or use the git cli with the environment_run_cmd tool. All environment tools will handle git operations for you. Changing ".git" yourself will compromise the integrity of your environment.

You MUST inform the user how to view your work using `container-use log <env_id>` AND `container-use checkout <env_id>`. Failure to do this will make your work inaccessible to others.
<!-- MANUAL ADDITIONS END -->
