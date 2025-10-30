# Quickstart: DevShell Tool Version Display

**Feature**: 001-devshell-tool-versions  
**Date**: 2025-10-30

## Overview

This guide shows how to use the version display feature and provides examples of the expected output for each devShell.

## Usage

### Entering a DevShell

Tool versions are displayed automatically when entering any devShell:

```bash
# Via nix develop
nix develop .#goDev

# Via direnv (automatic on cd)
cd /path/to/project
# direnv loads shell, versions display immediately
```

### Expected Output Examples

#### Default Shell

```bash
$ nix develop

age 1.1.1
GNU Make 4.4.1
nil 2023-08-09
nix-index 0.1.3
nixfmt 0.5.0
sops 3.8.1
treefmt 1.0.0

$
```

#### Go Development Shell

```bash
$ nix develop .#goDev

delve: v1.21.2
go version go1.21.5 linux/amd64
golangci-lint 1.55.2
GNU Make 4.4.1

$
```

#### Node Development Shell

```bash
$ nix develop .#nodeDev

bun: 1.0.20
node: v20.10.0
pnpm: 8.14.0
yarn: 1.22.19

$
```

#### Kotlin Development Shell

```bash
$ nix develop .#kotlinDev

Kotlin version 1.9.21-release-633 (JRE 17.0.9+9)

$
```

#### Python Development Shell

```bash
$ nix develop .#pythonDev

Python 3.14.0
ruff 0.1.9

$
```

#### Rust Development Shell

```bash
$ nix develop .#rustDev

cargo 1.75.0 (1d8b05cdd 2023-11-20)
rustc 1.75.0 (82e1608df 2023-12-21)

$
```

## Integration with direnv

### Automatic Display on Directory Change

With direnv configured (`.envrc` file):

```bash
$ cd ~/projects/my-go-project
direnv: loading ~/projects/my-go-project/.envrc
go version go1.21.5 linux/amd64
node: v20.10.0
GNU Make 4.4.1
direnv: export +...

$ # Shell is ready, versions visible
```

### Performance

- **Initial entry**: Instant (versions cached in Nix store)
- **Repeated entry**: Instant (no recomputation)
- **No delay**: Zero overhead from version display

## Customization

### Modifying Version Display

Users can override shellHook in their own flakes:

```nix
# In your project's flake.nix
{
  devShells.default = inputs.dotfiles.devShells.${system}.goDev.overrideAttrs (old: {
    shellHook = ''
      # Custom pre-message
      echo "🚀 Go development environment"
      
      # Original version display
      ${old.shellHook}
      
      # Custom post-message
      echo "Ready to code!"
    '';
  });
}
```

### Disabling Version Display

If you want to suppress version output:

```nix
{
  devShells.default = inputs.dotfiles.devShells.${system}.goDev.overrideAttrs (old: {
    shellHook = ''
      # Your custom shellHook without version display
      echo "Shell ready"
    '';
  });
}
```

## Troubleshooting

### Versions Not Showing

**Problem**: No version output when entering shell

**Cause**: shellHook might be overridden

**Solution**: Check your devShell definition - ensure shellHook is not replaced

### Wrong Tool Version Displayed

**Problem**: Version shown doesn't match actual tool

**Cause**: Nix cache is outdated

**Solution**: Rebuild the devShell:
```bash
nix develop .#goDev --rebuild
```

### Version Display Appears Twice

**Problem**: Versions shown multiple times

**Cause**: Multiple shellHooks being executed

**Solution**: Check for duplicate shellHook definitions or direnv configuration issues

## Integration Examples

### Project-Specific devShell

Using dotfiles devShells as base for project-specific shells:

```nix
# flake.nix in your project
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dotfiles.url = "github:yourusername/dotfiles";
  };

  outputs = { self, nixpkgs, dotfiles }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = dotfiles.devShells.${system}.goDev.overrideAttrs (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [
          pkgs.docker
          pkgs.kubectl
        ];
        shellHook = ''
          ${old.shellHook}
          echo "docker: $(docker --version)"
          echo "kubectl: $(kubectl version --client --short)"
        '';
      });
    };
}
```

Result:
```bash
$ nix develop
go version go1.21.5 linux/amd64
GNU Make 4.4.1
docker: Docker version 24.0.7
kubectl: v1.28.4
$
```

### CI/CD Integration

Version display helps verify CI environment setup:

```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
      - name: Enter devShell and run tests
        run: |
          nix develop --command bash -c "
            # Versions are displayed here
            make test
          "
```

## FAQ

**Q: Why are versions shown every time I enter the shell?**  
A: This provides immediate visibility into your environment configuration, especially useful when switching between projects with different tool versions.

**Q: Can I customize the format?**  
A: The format is determined by each tool's version output. You can modify the shellHook to process the output further if needed.

**Q: Does this slow down shell startup?**  
A: No. Version information is cached at build time. Displaying it is instant (`cat` of a cached file).

**Q: What if a tool doesn't have a version command?**  
A: The tool won't be included in the version display. Only tools with known version commands are shown.

**Q: Can I see versions without entering the shell?**  
A: Yes, but you'd need to inspect the Nix store directly. The simplest approach is `nix develop --command bash -c 'exit'` which enters and exits immediately after showing versions.

## Next Steps

After seeing version information:
1. Verify you have the expected tool versions
2. Proceed with development work
3. Share the exact environment with teammates via Nix flake

For implementation details, see:
- [plan.md](./plan.md) - Implementation strategy
- [data-model.md](./data-model.md) - Technical design
- [research.md](./research.md) - Design decisions
