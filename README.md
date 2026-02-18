# macsetup

Declarative macOS setup using Nix. Takes a fresh Mac from bare macOS to a fully configured development environment with a single command.

## Stack

- **nix-darwin** — system-level macOS configuration
- **Home Manager** — user-level dotfiles and programs
- **nixpkgs-unstable** — packages pinned via `flake.lock`
- **Homebrew** (via nix-darwin) — declaratively managed for fast-moving CLI tools

## Usage

```bash
./macsetup bootstrap   # First-time setup (install Nix + nix-darwin)
./macsetup switch      # Apply current configuration
./macsetup update      # Update flake inputs then apply
./macsetup build       # Build without applying (dry run)
./macsetup check       # Validate flake
```

## Structure

```
flake.nix              # Entry point — inputs and darwinConfigurations
hosts/shared.nix       # Per-machine config (imports all modules)
modules/
  darwin/              # System-level (packages, defaults, security, homebrew)
    homebrew.nix       # Declarative Homebrew formulae (cloud, k8s, security tools)
  home/                # User-level (shell, git, programs, dotfiles)
    packages.nix       # Nix packages (stable CLI tools, GNU utils, dev tools)
scripts/
  audit-packages.sh    # Scan current Mac and map tools to nixpkgs
  bootstrap.sh         # Bare Mac → first successful build
macsetup               # CLI helper (wraps darwin-rebuild)
```

## Package Strategy

**Hybrid approach** — stable tools via Nix (reproducible, pinned), fast-moving tools via Homebrew (always latest):

| Category | Manager | Why |
|----------|---------|-----|
| CLI utilities, dev tools, GNU core | Nix (`home.packages`) | Version stability, reproducibility |
| Cloud CLIs, Kubernetes, security scanners | Homebrew (`homebrew.brews`) | API compat, fast release cycles |

Both are managed declaratively — `darwin-rebuild switch` handles everything.

## License

MIT
