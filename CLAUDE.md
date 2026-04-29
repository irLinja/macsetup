# CLAUDE.md

## Project Overview

macsetup is a declarative macOS setup automation tool using Nix. It takes a fresh Mac from bare macOS to a fully configured development environment with a single command. Uses nix-darwin + Home Manager for reproducible, idempotent configuration across multiple machines and identities.

Users clone the repo, run the bootstrap wizard, answer a few questions, and get a configured Mac. Personal data lives in a gitignored `user.nix` file -- never in shared config files. Adding a new machine is as simple as adding a `.nix` file to `hosts/`.

## Stack

- **Nix 2.33.x** via Determinate Systems installer (flakes enabled by default)
- **nix-darwin** (master branch, tracks nixpkgs-unstable) -- system-level macOS config
- **Home Manager** (master branch) -- user-level config, integrated as nix-darwin module
- **nixpkgs-unstable** -- package repository, pinned via flake.lock
- **nix-homebrew** -- declarative Homebrew for GUI apps (casks) and fast-moving CLI tools
- **mas** -- Mac App Store CLI (from nixpkgs, not Homebrew)

## Key Commands

```bash
# Apply configuration (auto-detects hostname-based config or falls back to .#macsetup)
macsetup rebuild

# Or directly:
sudo darwin-rebuild switch --flake .#macsetup

# Update all dependencies
macsetup update

# Validate without applying
nix flake check

# First-time setup on a new Mac
macsetup bootstrap

# Audit current Mac and import unmanaged items
macsetup capture
```

## Architecture

- `flake.nix` -- entry point, inputs, darwinConfigurations with auto-discovery
- `user.nix` -- personal configuration (gitignored, staged with `git add -f`)
- `user.nix.example` -- template for new users (committed to repo)
- `hosts/` -- per-machine configs (auto-discovered by flake.nix)
- `hosts/shared.nix` -- legacy shared config (used by `.#macsetup` entry)
- `hosts/example.nix` -- reference host template for new machines
- `profiles/personal/` -- personal profile (base layer with default packages)
- `profiles/work/` -- work profile (base layer with work-oriented packages)
- `modules/darwin/` -- nix-darwin system modules (defaults, packages, security, services)
- `modules/home/` -- Home Manager user modules (shell, git, programs, dotfiles)
- `modules/optional/` -- opt-in feature modules (1password)
- `scripts/bootstrap.sh` -- interactive wizard: bare macOS -> first successful build
- `scripts/capture.sh` -- audit tool with host config generation
- `macsetup` -- CLI wrapper for rebuild, update, rollback, capture

### Responsibility Boundary

- **nix-darwin**: system packages, macOS defaults, launchd services, security, fonts, Nix daemon
- **Home Manager**: dotfiles, shell config, user packages, program configs, git, XDG dirs
- **user.nix**: all personal data (username, email, git signing, feature toggles)
- **profiles**: base-layer package sets and module selections
- **hosts/**: per-machine overrides on top of profiles

Always set `home-manager.useGlobalPkgs = true` and `home-manager.useUserPackages = true`.

### userConfig Threading

Personal data flows from `user.nix` through the entire module tree:

1. `flake.nix` imports `user.nix` as `userConfig`
2. `specialArgs = { inherit inputs userConfig; }` passes it to all darwin modules
3. `home-manager.extraSpecialArgs = { inherit inputs userConfig; }` passes it to all Home Manager modules
4. Every module receives `{ userConfig, ... }` and uses `userConfig.username`, `userConfig.email`, etc.
5. Optional features use `lib.mkIf userConfig.features."1password"` guards

## User Configuration

### user.nix

The `user.nix` file holds all personal values. It is gitignored to keep personal data out of the shared repo but staged with `git add -f` so the Nix flake can see it.

The `macsetup rebuild` command automatically stages `user.nix` before each build.

**Structure:**
```nix
{
  username = "yourname";
  fullName = "Your Name";
  email = "you@example.com";

  git = {
    signing = {
      key = null;            # SSH public key or null
      signByDefault = false;
      format = "ssh";
      signer = null;         # 1Password path or null
    };
    allowedSigners = null;   # "email ssh-type key..." or null
  };

  features = {
    "1password" = false;     # Enable 1Password SSH agent + git signing
  };
}
```

### Workflow

1. New user runs `macsetup bootstrap`
2. Wizard prompts for name, email, 1Password preference, signing key
3. Generates `user.nix` from `user.nix.example`
4. Stages with `git add -f user.nix` and applies `skip-worktree`
5. Builds with `macsetup rebuild`

After editing `user.nix`, run `macsetup rebuild` (which auto-stages) or manually `git add -f user.nix` before `darwin-rebuild switch`.

## Multi-Machine Setup

### Host Auto-Discovery

`flake.nix` auto-discovers host files in `hosts/`:
- Each `.nix` file (excluding `default.nix`, `example.nix`, `shared.nix`) becomes a `darwinConfiguration`
- The config name matches the filename (without `.nix`)
- A legacy `macsetup` entry points to `hosts/shared.nix` for backward compatibility

### Adding a New Machine

1. Run `macsetup capture --gen-host` to create `hosts/$(hostname -s).nix` from `example.nix`
2. Edit the file: choose a profile (`../profiles/personal` or `../profiles/work`), add host-specific packages
3. `git add hosts/yourhostname.nix`
4. `macsetup rebuild`

The `macsetup` CLI and `bootstrap.sh` automatically detect hostname-based config files.

### Profile System

Profiles are base-layer configurations that define default packages and module imports:

- `profiles/personal/` -- personal development setup with curated packages
- `profiles/work/` -- work-oriented setup (can add work-specific taps and tools)

Host configs import a profile and can override any setting with `lib.mkForce` or add packages on top.

## Critical nix-darwin Requirements

- `system.primaryUser` must be set to the username running darwin-rebuild
- `system.stateVersion = 6` for new installations
- All activation runs as root (`sudo darwin-rebuild switch`)
- `nix.enable = false` when using Determinate Systems installer
- `programs.zsh.enable = true` in BOTH nix-darwin and Home Manager

## Homebrew Enforcement

- `cleanup = "zap"` in `modules/darwin/homebrew.nix` -- any Homebrew formulae, casks, or mas apps NOT declared in config are **removed** on every `darwin-rebuild switch`
- `mutableTaps = false` in `hosts/shared.nix` -- undeclared taps are also removed
- Always add new Homebrew packages to the config **before** running rebuild, or they will be uninstalled

### nix-homebrew Tap Rules

- All taps require flake inputs in `flake.nix` with `flake = false` (homebrew-core, homebrew-cask, plus custom taps)
- Tap keys in `nix-homebrew.taps` use GitHub repo name format: `"peonping/homebrew-tap"` (not short `"peonping/tap"`)
- **Custom taps** (peonping, tfversion) must NOT appear in `homebrew.taps` -- Homebrew will try to `git clone` over nix-managed symlinks
- **Standard taps** (`homebrew/homebrew-core`, `homebrew/homebrew-cask`) MUST be in `homebrew.taps` -- otherwise `cleanup = "zap"` tries to untap them

## 1Password

- Must be installed via **Homebrew cask** (not NixCasks) -- requires `/Applications/` for SSH agent and browser integration
- Git SSH signing path: `/Applications/1Password.app/Contents/MacOS/op-ssh-sign` (configured via `userConfig.git.signing.signer`)
- Enabled via `userConfig.features."1password" = true` in `user.nix`
- Integration module: `modules/optional/1password.nix`

## Pitfalls

- Flakes silently ignore files not tracked by git -- always `git add` new .nix files before rebuild
- `user.nix` must be staged with `git add -f user.nix` for flake visibility (the CLI does this automatically)
- After editing `user.nix`, run `macsetup rebuild` (auto-stages) or `git add -f user.nix` manually
- Existing dotfiles block Home Manager activation -- back up before first run
- macOS defaults need `activateSettings -u` + `killall Dock/Finder` in post-activation script
- mas requires user to be signed into App Store (not fully unattended)
- Old `~/.gitconfig` overrides Home Manager's `~/.config/git/config` -- remove it if Home Manager manages git
- `darwin-rebuild switch --flake .` uses hostname as config name -- use `--flake .#macsetup` explicitly or let the CLI auto-detect

## Repository

- Remote: `git@github.com:irLinja/macsetup.git`
- Branch: `master`
