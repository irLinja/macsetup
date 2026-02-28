# Requirements: macsetup

**Defined:** 2026-02-16
**Core Value:** One command on a fresh Mac with nothing but internet -- come back to a fully configured, ready-to-use machine.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Bootstrap

- [ ] **BOOT-01**: User can run a single bootstrap script on bare macOS (only internet required) that installs Nix, nix-darwin, and Home Manager
- [ ] **BOOT-02**: Configuration uses Nix flakes with flake.lock for reproducible version pinning across machines
- [ ] **BOOT-03**: Configuration is organized into modular .nix files per domain (shell, git, packages, defaults, etc.)
- [ ] **BOOT-04**: User can re-run `darwin-rebuild switch` safely at any time to sync/update -- no errors, no duplicate state

### Packages

- [x] **PKG-01**: CLI tools are declared in Nix configuration and installed from nixpkgs
- [x] **PKG-02**: GUI applications (.app bundles) are installed via NixCasks without Homebrew where supported
- [x] **PKG-03**: GUI applications not supported by NixCasks are installed via Homebrew casks managed declaratively by nix-darwin
- [x] **PKG-04**: Homebrew itself is installed and managed declaratively via nix-homebrew (user never runs brew directly)
- [x] **PKG-05**: Mac App Store apps are declared in configuration and installed via mas CLI
- [x] **PKG-06**: All packages across all sources are version-pinned via flake.lock for reproducibility

### Shell

- [x] **SHEL-01**: Zsh is configured declaratively with plugins, aliases, and PATH via Home Manager
- [x] **SHEL-02**: Starship prompt is configured declaratively via Home Manager
- [x] **SHEL-03**: Shell environment works correctly in all contexts: new terminal, tmux, VS Code integrated terminal, SSH

### macOS Defaults

- [x] **DFLT-01**: Dock preferences are configured (autohide, icon size, show-recents, position)
- [x] **DFLT-02**: Finder preferences are left at macOS defaults (user decision — no non-default Finder settings to declare)
- [x] **DFLT-03**: Keyboard and input settings are configured (key repeat rate, trackpad settings)
- [x] **DFLT-04**: Security and privacy settings are configured (firewall, FileVault, Gatekeeper)
- [x] **DFLT-05**: Display and desktop settings are configured (dark mode, Night Shift)
- [x] **DFLT-06**: All configured defaults apply immediately after rebuild (via activateSettings and killall where needed)

### Developer Tools

- [x] **DEV-01**: Git is configured declaratively (user identity, aliases, default branch, editor, global gitignore)
- [x] **DEV-02**: Arbitrary dotfiles and config files are placed in correct locations via Home Manager home.file
- [x] **DEV-03**: Touch ID for sudo is enabled and persists across macOS updates
- [x] **DEV-04**: Programming fonts (Nerd Fonts, JetBrains Mono, etc.) are installed declaratively

### Operations

- [x] **OPS-01**: A capture tool audits the current Mac's installed apps, shell config, and macOS defaults, then generates a starter Nix configuration
- [x] **OPS-02**: Rollback and generation management is documented with working examples

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Extended Configuration

- **EXT-01**: Terminal emulator configuration (Kitty/Alacritty/WezTerm/Ghostty) managed declaratively
- **EXT-02**: Editor configuration (Neovim/VS Code) with plugins managed declaratively
- **EXT-03**: Window manager integration (yabai + skhd or Aerospace)
- **EXT-04**: Per-project dev environments via direnv + nix-direnv
- **EXT-05**: Declarative launchd user agents and daemons
- **EXT-06**: Secrets management scaffolding (sops-nix or agenix hooks)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Personal data/file sync | Handled by iCloud/Time Machine -- not a config management concern |
| Credentials and secrets | Managed separately via 1Password or similar -- security boundary |
| Browser profiles | Synced by browser's own sync -- fragile to manage externally |
| Per-machine divergent configs | All Macs get identical config per PROJECT.md -- add later if needed |
| GUI configuration app | Undermines declarative philosophy -- use well-commented configs instead |
| Auto-update / scheduled rebuilds | Users should choose when to update -- Nix's strength is pinned reproducibility |
| Interactive setup wizard | Defeats the "one command, walk away" goal -- use sensible defaults |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BOOT-01 | Phase 1 | Pending |
| BOOT-02 | Phase 1 | Pending |
| BOOT-03 | Phase 1 | Pending |
| BOOT-04 | Phase 1 | Pending |
| PKG-01 | Phase 2 | Complete |
| PKG-02 | Phase 6 | Complete |
| PKG-03 | Phase 6 | Complete |
| PKG-04 | Phase 6 | Complete |
| PKG-05 | Phase 6 | Complete |
| PKG-06 | Phase 2 | Complete |
| SHEL-01 | Phase 3 | Complete |
| SHEL-02 | Phase 3 | Complete |
| SHEL-03 | Phase 3 | Complete |
| DFLT-01 | Phase 5 | Complete |
| DFLT-02 | Phase 5 | Complete |
| DFLT-03 | Phase 5 | Complete |
| DFLT-04 | Phase 5 | Complete |
| DFLT-05 | Phase 5 | Complete |
| DFLT-06 | Phase 5 | Complete |
| DEV-01 | Phase 4 | Complete |
| DEV-02 | Phase 4 | Complete |
| DEV-03 | Phase 4 | Complete |
| DEV-04 | Phase 4 | Complete |
| OPS-01 | Phase 7 | Complete |
| OPS-02 | Phase 7 | Complete |

**Coverage:**
- v1 requirements: 25 total
- Mapped to phases: 25
- Unmapped: 0

---
*Requirements defined: 2026-02-16*
*Last updated: 2026-02-16 after roadmap creation*
