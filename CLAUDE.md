# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macsetup is a declarative macOS setup automation tool using Nix. It takes a fresh Mac from bare macOS to a fully configured development environment with a single command. Uses nix-darwin + Home Manager for reproducible, idempotent configuration across multiple machines.

## Stack

- **Nix 2.33.x** via Determinate Systems installer (flakes enabled by default)
- **nix-darwin** (master branch, tracks nixpkgs-unstable) -- system-level macOS config
- **Home Manager** (master branch) -- user-level config, integrated as nix-darwin module
- **nixpkgs-unstable** -- package repository, pinned via flake.lock
- **NixCasks** -- GUI .app bundles without Homebrew (primary)
- **nix-homebrew** -- declarative Homebrew as fallback for GUI apps NixCasks can't handle
- **mas** -- Mac App Store CLI (from nixpkgs, not Homebrew)

## Key Commands

```bash
# Apply configuration
sudo darwin-rebuild switch --flake .

# Update all dependencies
nix flake update

# Validate without applying
nix flake check
```

## Architecture

- `flake.nix` -- entry point, inputs, darwinConfigurations
- `hosts/` -- per-machine configs (currently single shared config)
- `modules/darwin/` -- nix-darwin system modules (defaults, packages, security, services)
- `modules/home/` -- Home Manager user modules (shell, git, programs, dotfiles)
- `bootstrap.sh` -- bare macOS -> first successful build

### Responsibility Boundary

- **nix-darwin**: system packages, macOS defaults, launchd services, security, fonts, Nix daemon
- **Home Manager**: dotfiles, shell config, user packages, program configs, git, XDG dirs

Always set `home-manager.useGlobalPkgs = true` and `home-manager.useUserPackages = true`.

## Critical nix-darwin Requirements (2025+)

- `system.primaryUser` must be set to the username running darwin-rebuild
- `system.stateVersion = 6` for new installations
- All activation runs as root (`sudo darwin-rebuild switch`)
- `nix.enable = false` when using Determinate Systems installer
- `programs.zsh.enable = true` in BOTH nix-darwin and Home Manager

## Homebrew Enforcement

- `cleanup = "zap"` in `modules/darwin/homebrew.nix` — any Homebrew formulae, casks, or mas apps NOT declared in config are **removed** on every `darwin-rebuild switch`
- `mutableTaps = false` in `hosts/shared.nix` — undeclared taps are also removed
- Always add new Homebrew packages to the config **before** running rebuild, or they will be uninstalled

### nix-homebrew Tap Rules

- All taps require flake inputs in `flake.nix` with `flake = false` (homebrew-core, homebrew-cask, plus custom taps)
- Tap keys in `nix-homebrew.taps` use GitHub repo name format: `"peonping/homebrew-tap"` (not short `"peonping/tap"`)
- **Custom taps** (peonping, tfversion) must NOT appear in `homebrew.taps` — Homebrew will try to `git clone` over nix-managed symlinks
- **Standard taps** (`homebrew/homebrew-core`, `homebrew/homebrew-cask`) MUST be in `homebrew.taps` — otherwise `cleanup = "zap"` tries to untap them

## 1Password

- Must be installed via **Homebrew cask** (not NixCasks) — requires `/Applications/` for SSH agent and browser integration
- Git SSH signing path: `/Applications/1Password.app/Contents/MacOS/op-ssh-sign` (in `modules/home/git.nix`)
- NixCasks installs to `~/Applications/Home Manager Apps/` which 1Password rejects

## Pitfalls

- Flakes silently ignore files not tracked by git -- always `git add` new .nix files before rebuild
- Existing dotfiles block Home Manager activation -- back up before first run
- macOS defaults need `activateSettings -u` + `killall Dock/Finder` in post-activation script
- NixCasks only supports .dmg/.zip (not .pkg installers)
- mas requires user to be signed into App Store (not fully unattended)
- Old `~/.gitconfig` overrides Home Manager's `~/.config/git/config` -- remove it if Home Manager manages git
- `darwin-rebuild switch --flake .` uses hostname as config name -- use `--flake .#macsetup` explicitly

## Repository

- Remote: `git@github.com:irLinja/macsetup.git`
- Branch: `master`
- Planning docs: `.planning/` (local only, gitignored)
