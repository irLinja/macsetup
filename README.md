# macsetup

Declarative macOS setup with Nix. One command to go from bare Mac to fully configured development environment.

## Quick Start

**Fresh Mac (bootstrap):**

```bash
git clone git@github.com:irLinja/macsetup.git ~/macsetup
cd ~/macsetup
bash scripts/bootstrap.sh
```

**Existing Mac (capture current setup):**

```bash
./scripts/macsetup capture
```

## Daily Usage

| Command | Description |
|---------|-------------|
| `macsetup rebuild` | Apply configuration changes |
| `macsetup update` | Update all Nix inputs and rebuild |
| `macsetup list` | Show generation history |
| `macsetup rollback` | Revert to previous generation |
| `macsetup switch N` | Switch to generation N |
| `macsetup capture` | Audit Mac and import unmanaged items |
| `macsetup --help` | Show usage summary |

Generation cleanup is automatic -- the last 3 generations are kept after every mutating operation.

## Architecture

```
flake.nix                  Entry point, inputs, darwinConfigurations
hosts/
  shared.nix               Per-machine config (imports all modules)
modules/
  darwin/                   System-level: packages, defaults, services, security, fonts, homebrew
  home/                     User-level: shell, git, programs, dotfiles
scripts/
  bootstrap.sh             Bare Mac -> first successful build
  macsetup                 CLI wrapper (this tool)
```

**Responsibility boundary:**

- **nix-darwin** -- system packages, macOS defaults, launchd services, security, fonts, Nix daemon
- **Home Manager** -- dotfiles, shell config, user packages, program configs, git, XDG dirs

## Adding Packages

**CLI tools (stable):** Add to `modules/home/packages.nix` under `home.packages`

**CLI tools (fast-moving):** Add to `modules/darwin/homebrew.nix` under `brews`

**GUI apps (NixCasks):** Add to `modules/home/packages.nix` under NixCasks section

**GUI apps (Homebrew cask):** Add to `modules/darwin/homebrew.nix` under `casks`

**App Store apps:** Add to `modules/darwin/homebrew.nix` under `masApps` as `"Name" = ID;`

**Fonts:** Add to `modules/darwin/fonts.nix`

Then run `macsetup rebuild` to apply.

## Rollback & Generations

```bash
macsetup list                    # Show all generations
macsetup rollback                # Revert to previous generation
macsetup switch 12               # Jump to generation 12
```

**Compare generations:**

```bash
nix store diff-closures \
  /nix/var/nix/profiles/system-{N-1}-link \
  /nix/var/nix/profiles/system-{N}-link
```

GC is automatic after rebuild, update, rollback, and switch (keeps last 3).

## Manual Commands

For users who prefer direct commands without the wrapper:

```bash
sudo darwin-rebuild switch --flake .#macsetup    # Apply config
nix flake update                                 # Update inputs
sudo darwin-rebuild --list-generations           # List generations
sudo darwin-rebuild --rollback                   # Rollback
sudo darwin-rebuild --switch-generation N        # Switch generation
```

## Requirements

- macOS (Apple Silicon)
- Internet connection
- Nix is installed automatically by `bootstrap.sh`

## License

MIT
