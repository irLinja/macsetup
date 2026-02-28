# Roadmap: macsetup

## Overview

This roadmap takes a bare macOS machine to a fully declarative, reproducible development environment managed entirely through Nix. The journey starts with bootstrapping Nix itself, then layers on packages, shell configuration, developer tools, system defaults, GUI applications, and finally operations tooling. Each phase delivers a complete, verifiable capability that builds on the previous ones. The architecture follows the Nix dependency chain: you cannot configure programs without packages, and you cannot install packages without Nix.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Bootstrap Nix ecosystem and establish the flake-based declarative configuration skeleton (completed 2026-02-18)
- [x] **Phase 2: CLI Packages** - Declare and install CLI developer tools via nixpkgs with version pinning (completed 2026-02-18)
- [x] **Phase 3: Shell Environment** - Configure zsh, Starship prompt, and shell behavior across all terminal contexts (completed 2026-02-18)
- [x] **Phase 4: Developer Tools** - Set up git, dotfiles, fonts, and Touch ID for sudo via Home Manager (completed 2026-02-18)
- [x] **Phase 5: macOS Defaults** - Automate Dock, Finder, keyboard, security, and display system preferences (completed 2026-02-18)
- [x] **Phase 6: GUI Applications** - Install desktop apps via NixCasks/Homebrew casks and App Store apps via mas (completed 2026-02-19)
- [x] **Phase 7: Operations** - Build capture tool for current Mac audit and document rollback/generation management (completed 2026-02-19)

## Phase Details

### Phase 1: Foundation
**Goal**: User can bootstrap a bare Mac into a working nix-darwin + Home Manager system with a single command, with a modular flake structure ready for all subsequent configuration
**Depends on**: Nothing (first phase)
**Requirements**: BOOT-01, BOOT-02, BOOT-03, BOOT-04
**Success Criteria** (what must be TRUE):
  1. User can run the bootstrap script on a Mac with nothing but internet and end up with Nix, nix-darwin, and Home Manager installed and functional
  2. Running `darwin-rebuild switch` succeeds with no errors on the skeleton configuration
  3. The flake uses flake.lock to pin all inputs (nixpkgs, nix-darwin, home-manager) to specific revisions
  4. Configuration is split into modular .nix files organized by domain (not a single monolithic file)
  5. Running `darwin-rebuild switch` a second time produces no errors and no state changes (idempotent)
**Plans**: 2 plans

Plans:
- [x] 01-01-PLAN.md -- Create Nix flake configuration skeleton with modular darwin and home-manager modules
- [x] 01-02-PLAN.md -- Create bootstrap script and verify on actual Mac

### Phase 2: CLI Packages
**Goal**: User's core CLI developer tools are declaratively managed and installed from nixpkgs, with all packages version-pinned via flake.lock
**Depends on**: Phase 1
**Requirements**: PKG-01, PKG-06
**Success Criteria** (what must be TRUE):
  1. CLI tools declared in the Nix configuration are available on PATH after `darwin-rebuild switch`
  2. Adding a new CLI tool to the configuration and rebuilding installs it; removing one and rebuilding uninstalls it
  3. The flake.lock pins nixpkgs so the same versions install on any machine using this configuration
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md -- Audit current Mac CLI tools and generate categorized review file with nixpkgs mappings
- [x] 02-02-PLAN.md -- User reviews package list, then populate packages.nix and verify with darwin-rebuild

### Phase 3: Shell Environment
**Goal**: User has a fully configured zsh shell with plugins, aliases, PATH, and Starship prompt that works identically in every terminal context
**Depends on**: Phase 2
**Requirements**: SHEL-01, SHEL-02, SHEL-03
**Success Criteria** (what must be TRUE):
  1. Opening a new terminal shows the Starship prompt with the configured theme
  2. Zsh plugins (syntax highlighting, autosuggestions, etc.), aliases, and PATH additions declared in Nix are active
  3. Shell environment works correctly in a new Terminal.app window, VS Code integrated terminal, tmux session, and SSH session
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md -- Configure zsh declaratively with plugins, aliases, completions, PATH, and program integrations
- [x] 03-02-PLAN.md -- Create Starship prompt configuration with two-line layout and cloud/dev modules

### Phase 4: Developer Tools
**Goal**: User's development environment configuration (git, dotfiles, fonts, sudo) is fully managed by Home Manager
**Depends on**: Phase 2
**Requirements**: DEV-01, DEV-02, DEV-03, DEV-04
**Success Criteria** (what must be TRUE):
  1. Git is configured with the correct user identity, aliases, default branch, editor, and global gitignore without manual setup
  2. Arbitrary config files declared via home.file appear at their correct locations after rebuild
  3. Touch ID authenticates sudo commands and this setting persists across macOS updates
  4. Programming fonts (Nerd Fonts, JetBrains Mono) are installed and available to applications
**Plans**: 2 plans

Plans:
- [ ] 04-01-PLAN.md -- Git configuration, oh-my-zsh git plugin, and dotfile absorption via Home Manager
- [ ] 04-02-PLAN.md -- Touch ID/Apple Watch sudo and Nerd Font installation via nix-darwin

### Phase 5: macOS Defaults
**Goal**: User's macOS system preferences are configured declaratively so every Mac looks and behaves identically without manual System Settings changes
**Depends on**: Phase 1
**Requirements**: DFLT-01, DFLT-02, DFLT-03, DFLT-04, DFLT-05, DFLT-06
**Success Criteria** (what must be TRUE):
  1. Dock is configured (autohide, icon size, show-recents, position) and visually reflects settings after rebuild
  2. Finder preferences are left at macOS defaults (user decision — no non-default Finder settings to declare)
  3. Keyboard repeat rate, trackpad tap-to-click, and other input settings match declared values
  4. Security settings (firewall, FileVault awareness, Gatekeeper) are configured as declared
  5. Dark mode and display preferences are applied after rebuild without requiring logout
**Plans**: 1 plan

Plans:
- [ ] 05-01-PLAN.md -- Configure Dock, input, appearance, and firewall defaults with post-activation verification

### Phase 6: GUI Applications
**Goal**: User's desktop applications and App Store apps are installed declaratively without manual downloads or App Store clicks
**Depends on**: Phase 2
**Requirements**: PKG-02, PKG-03, PKG-04, PKG-05
**Success Criteria** (what must be TRUE):
  1. GUI applications supported by NixCasks appear in /Applications after rebuild
  2. GUI applications not supported by NixCasks are installed via Homebrew casks managed declaratively through nix-darwin (user never runs brew manually)
  3. Homebrew itself is installed and managed by nix-homebrew as a declarative dependency
  4. Mac App Store apps declared in configuration are installed via mas after rebuild (user must be signed into App Store)
**Plans**: 2 plans

Plans:
- [x] 06-01-PLAN.md -- Audit current Mac GUI apps and generate categorized APP-REVIEW.md with channel assignments
- [x] 06-02-PLAN.md -- Add flake inputs (NixCasks, nix-homebrew, mac-app-util) and populate all three GUI app channels

### Phase 7: Operations
**Goal**: User can audit their current Mac's setup to generate starter configuration, and has documented workflows for rollback and generation management
**Depends on**: Phase 6
**Requirements**: OPS-01, OPS-02
**Success Criteria** (what must be TRUE):
  1. Running the capture tool on a configured Mac produces a report of installed apps, shell config, and macOS defaults that can seed a starter Nix configuration
  2. User can list Nix generations, roll back to a previous generation, and switch forward again using documented commands
  3. Rollback and generation management examples work as documented
**Plans**: 2 plans

Plans:
- [ ] 07-01-PLAN.md -- macsetup CLI wrapper and project README documentation
- [ ] 07-02-PLAN.md -- Interactive capture/onboarding tool for Mac state audit and .nix import

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7

Note: Phases 3, 4, 5, and 6 all depend on Phase 2 (or Phase 1) and could theoretically run in parallel, but sequential execution is recommended for cleaner testing and debugging.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete    | 2026-02-18 |
| 2. CLI Packages | 2/2 | Complete    | 2026-02-18 |
| 3. Shell Environment | 2/2 | Complete    | 2026-02-18 |
| 4. Developer Tools | 0/? | Complete    | 2026-02-18 |
| 5. macOS Defaults | 0/? | Complete    | 2026-02-18 |
| 6. GUI Applications | 2/2 | Complete    | 2026-02-19 |
| 7. Operations | 0/? | Complete    | 2026-02-19 |

### Phase 8: Drop NixCasks, use Homebrew cask for all GUI apps

**Goal:** All GUI apps installed via Homebrew cask with NixCasks and mac-app-util infrastructure removed, leaving a simpler flake and clean responsibility boundary (nixpkgs = CLI, Homebrew = GUI)
**Depends on:** Phase 7
**Plans:** 2 plans

Plans:
- [ ] 08-01-PLAN.md -- Migrate GUI apps to Homebrew cask and remove NixCasks/mac-app-util from flake
- [ ] 08-02-PLAN.md -- Clean up tooling (capture.sh), delete audit scripts, and regenerate flake.lock

### Phase 9: making the project opensource and usable for anyone with any number of machines and identities

**Goal:** Transform the single-user, single-machine macsetup into a configurable open-source framework where users clone the repo, provide their identity via a gitignored user.nix file, pick a profile and host config, and get a fully working Mac setup. Supports multiple machines and identities per user. Personal data never enters the shared repo.
**Requirements**: TBD
**Depends on:** Phase 8
**Success Criteria** (what must be TRUE):
  1. A new user can clone the repo, run bootstrap, answer a few questions, and get a fully configured Mac
  2. Personal data (username, email, SSH keys) is stored in gitignored user.nix -- never in shared config files
  3. Adding a new machine is as simple as adding a .nix file to hosts/
  4. Two profiles (personal, work) ship as opinionated starter sets with anonymized packages
  5. 1Password integration is opt-in via a feature flag
  6. The capture tool generates host config files for the new structure
  7. All existing functionality continues to work after the restructuring
**Plans:** 4 plans

Plans:
- [x] 09-01-PLAN.md -- Safe foundation (additive only): Create user.nix, user.nix.example, profiles, optional modules, example host, .gitignore update -- NO existing files touched
- [ ] 09-02-PLAN.md -- Wire userConfig (backward-compatible): Update flake.nix with userConfig threading + auto-discovery, update hosts/shared.nix to accept userConfig -- legacy macsetup entry preserved
- [ ] 09-03-PLAN.md -- Refactor modules (now safe): Replace hardcoded personal data in hosts/shared.nix, git.nix, dotfiles.nix with userConfig.* -- build output identical
- [ ] 09-04-PLAN.md -- Bootstrap, CLI, capture, docs, cutover: Rewrite bootstrap.sh as wizard, update macsetup CLI + capture.sh, update CLAUDE.md, human checkpoint
