---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: unknown
last_updated: "2026-02-28T15:26:43.472Z"
progress:
  total_phases: 9
  completed_phases: 9
  total_plans: 19
  completed_plans: 19
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-16)

**Core value:** One command on a fresh Mac with nothing but internet -- come back to a fully configured, ready-to-use machine.
**Current focus:** Phase 9: Making the project opensource and usable for anyone

## Current Position

Phase: 9 of 9 (Open Source Framework)
Plan: 3 of 4 in current phase -- COMPLETE
Status: Executing Phase 9
Last activity: 2026-02-28 -- Completed 09-03 Replace hardcoded data with userConfig

Progress: [█████████░] 90%

## Performance Metrics

**Velocity:**
- Total plans completed: 18
- Average duration: 6 min
- Total execution time: 1.4 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2 | 17 min | 9 min |
| 02-cli-packages | 2 | 16 min | 8 min |
| 03-shell-environment | 2 | 4 min | 2 min |
| 04-developer-tools | 2 | 8 min | 4 min |
| 05-macos-defaults | 1 | 3 min | 3 min |
| 06-gui-applications | 2 | 24 min | 12 min |
| 07-operations | 2 | 5 min | 3 min |
| 08-drop-nixcasks | 2 | 5 min | 3 min |
| 09-opensource | 3 | 8 min | 3 min |

**Recent Trend:**
- Last 5 plans: 08-02 (2 min), 09-01 (3 min), 09-02 (3 min), 09-03 (2 min)
- Trend: Stable

*Updated after each plan completion*
| Phase 03 P02 | 2 | 1 task | 2 files |
| Phase 04 P01 | 3 | 2 tasks | 4 files |
| Phase 04 P02 | 5 | 2 tasks | 3 files |
| Phase 05 P01 | 3 | 3 tasks | 2 files |
| Phase 06 P01 | 8 | 2 tasks | 2 files |
| Phase 06 P02 | 16 | 2 tasks | 6 files |
| Phase 07 P01 | 2 | 2 tasks | 2 files |
| Phase 07 P02 | 3 | 1 task | 1 file |
| Phase 08 P01 | 3 | 2 tasks | 4 files |
| Phase 08 P02 | 2 | 2 tasks | 1 file |
| Phase 09 P01 | 3 | 2 tasks | 11 files |
| Phase 09 P02 | 3 | 2 tasks | 2 files |
| Phase 09 P03 | 2 | 2 tasks | 3 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: NixCasks as primary GUI app strategy, managed Homebrew as fallback (per research recommendation)
- [Roadmap]: Phases 3/4/5/6 depend on Phase 2 but execute sequentially for cleaner testing
- [Roadmap]: PKG-06 (version pinning) mapped to Phase 2 since flake.lock is established in Phase 1 but package pinning is verified when packages exist
- [01-01]: Fixed config name "macsetup" (not hostname) for portability across machines
- [01-01]: Hardcoded username "arash" per user decision rather than templating
- [01-01]: Import aggregator pattern: default.nix files aggregate sibling imports
- [01-02]: Determinate Systems installer with --no-confirm for unattended Nix installation
- [01-02]: /etc conflicts moved to .before-nix-darwin suffix (preserves originals)
- [01-02]: /etc/zshenv must be in conflict handler (blocks darwin-rebuild on stock macOS)
- [01-02]: PATH export for /run/current-system/sw/bin needed after first bootstrap in same shell
- [01-02]: Env var overrides (MACSETUP_HOSTNAME, MACSETUP_USERNAME) for automation flexibility
- [02-01]: nix eval nixpkgs#attr.version for reliable version checking (not nix search)
- [02-01]: 82/87 brew leaves found in nixpkgs; 5 NOT_FOUND flagged for user decision
- [02-01]: Go binaries (gopls, staticcheck, go-critic) recommended for Nix migration
- [02-01]: npm/pipx niche tools kept in their ecosystems (aicommits, autocannon, extended-memory-mcp)
- [02-01]: Notable version gaps: kubernetes-helm (4.x vs 3.x), yq (4.x vs 3.x), kubescape (4.x vs 3.x)
- [02-02]: Hybrid strategy: 15 stable tools in nixpkgs home.packages, 21 fast-moving tools in nix-darwin homebrew.brews
- [02-02]: No runtimes in home.packages (user removed nodejs/python3/go, keeps pnpm+uv only)
- [02-02]: No GNU core replacements (user cleared entire section)
- [02-02]: homebrew.onActivation.cleanup = "zap" for fully declarative Homebrew management
- [02-02]: Shelved packages as commented-out lines in config files for quick re-enable
- [Phase 02]: Hybrid strategy: 15 stable tools in nixpkgs, 21 fast-moving tools in nix-darwin homebrew.brews
- [03-01]: zsh-syntax-highlighting over fast-syntax-highlighting (Nix store read-only breaks fast-theme)
- [03-01]: initContent with lib.mkOrder (not deprecated initExtra) for all custom shell snippets
- [03-01]: Homebrew fpath at priority 550 before compinit (570) for kubectl/helm/terraform completions
- [03-01]: Dedicated programs.* modules for fzf/zoxide/direnv (no manual eval calls)
- [03-01]: ~/.tfversion/bin included in PATH; ~/.rd/bin and ~/.antigravity/bin commented out
- [03-01]: Terraform completion via complete -C (Homebrew site-functions lacks _terraform)
- [03-02]: Starship TOML config as Nix attrset via programs.starship.settings
- [03-02]: kubernetes and azure modules explicitly enabled (disabled by default in Starship)
- [03-02]: gcloud module disabled per user's existing starship.toml preference
- [03-02]: Language modules kept with file-detection defaults made explicit in config
- [04-01]: Use settings.user.name/email instead of deprecated userName/userEmail in programs.git
- [04-01]: Absorb only stable non-secret dotfiles into Nix: .vimrc, .ssh/allowed_signers, .npmrc
- [04-01]: oh-my-zsh git plugin with no theme (Starship owns the prompt)
- [04-01]: macOS-only gitignore patterns (no IDE/language patterns per user decision)
- [04-01]: Dotfile absorption via home.file.text for small stable configs
- [04-02]: All three PAM options enabled (touchIdAuth, watchIdAuth, reattach) for maximum sudo convenience
- [04-02]: Four Nerd Font packages at system level: JetBrains Mono, Meslo LG, Fira Code, symbols-only
- [04-02]: System-level fonts via fonts.packages (not home.packages) for GUI app compatibility
- [05-01]: Used postActivation instead of removed postUserActivation (nix-darwin API change)
- [05-01]: Only 7 non-default macOS settings declared (minimal configuration surface per user decision)
- [05-01]: Finder settings intentionally omitted per user decision (DFLT-02)
- [05-01]: FileVault documented as comment-only awareness (no assertions that would break fresh Macs)
- [05-01]: networking.applicationFirewall for firewall (not deprecated system.defaults.alf)
- [06-01]: Channel priority locked: App Store > NixCasks (version-current) > Homebrew cask
- [06-01]: 18 active NixCasks apps, 3 shelved (betterdisplay, monitorcontrol, zen), 8 Homebrew cask, 4 App Store
- [06-01]: Dual-available apps resolved: Slack/Telegram/WhatsApp/Notion/Surfshark to NixCasks; Miro/Tailscale to Homebrew cask
- [06-01]: Removed Microsoft Excel/OneNote/PowerPoint/Word/OneDrive/Prime Video during user curation
- [06-01]: 7 unknown apps excluded from Nix config but kept for reference in APP-REVIEW.md
- [06-02]: 1password accessed via direct attribute path (digit-prefixed, not valid in Nix 'with' blocks)
- [06-02]: homebrew.onActivation.cleanup left as 'none' until user verifies all desired apps are declared
- [06-02]: nix-homebrew mutableTaps=false with declarative homebrew-core and homebrew-cask tap inputs
- [06-02]: mac-app-util integrated at both nix-darwin and Home Manager levels for Spotlight discoverability
- [06-02]: List concatenation pattern for mixed package sources: (with pkgs; [...]) ++ [...] ++ (with nix-casks; [...])
- [07-01]: capture subcommand delegates to scripts/capture.sh via exec (not yet created, handled gracefully)
- [07-02]: Reused extraction patterns from audit-packages.sh and audit-gui-apps.sh for capture tool
- [07-02]: npm/pipx globals listed as informational only (not offered for Add) since they belong in their ecosystems
- [07-02]: macOS defaults drift is read-only reporting (Nix config is source of truth)
- [07-02]: Font matching uses file name pattern to nerd-fonts attribute mapping with deduplication
- [08-01]: All GUI apps consolidated to Homebrew cask channel; NixCasks and mac-app-util archived (commented out)
- [08-01]: packages.nix simplified to CLI-only with { pkgs, ... } signature (no inputs parameter)
- [08-01]: Category organization for casks matches existing brews section style in homebrew.nix
- [08-02]: Simplified derive_cask_name to lowercase+hyphenate only (removed 46-entry APP_TO_PNAME lookup table)
- [08-02]: Replaced jq/NixCasks API availability check with brew info --cask lookup in capture.sh
- [09-01]: user.nix uses git add -f + skip-worktree to remain gitignored but visible to Nix flakes
- [09-01]: Profile packages use home-manager.sharedModules with lib.mkDefault for host-level overridability
- [09-01]: 1Password module accepts userConfig parameter and uses 'or false' fallback for safe evaluation
- [09-02]: Legacy macsetup entry kept as explicit (not auto-discovered) for backward compatibility
- [09-02]: Host auto-discovery excludes example.nix, shared.nix, default.nix by convention
- [09-02]: userConfig propagation: specialArgs for darwin modules, extraSpecialArgs for Home Manager
- [09-03]: lib.mkIf guards on signing/tag/allowedSigners so users without keys get clean config
- [09-03]: allowed_signers file conditionally created only when userConfig.git.allowedSigners is non-null

### Roadmap Evolution

- Phase 8 added: Drop NixCasks, use Homebrew cask for all GUI apps
- Phase 9 added: making the project opensource and usable for anyone with any number of machines and identities

### Pending Todos

None yet.

### Blockers/Concerns

- [Research]: NixCasks coverage for specific GUI apps untested -- RESOLVED: 18 of 33 curated apps available via NixCasks in 06-01
- [Research]: mas activation script without Homebrew Bundle is non-standard -- needs validation in Phase 6 Plan 02
- [Research]: Bootstrap on truly fresh Mac untested -- RESOLVED: Verified on real Mac in 01-02

## Session Continuity

Last session: 2026-02-28
Stopped at: Completed 09-03-PLAN.md (Replace hardcoded data with userConfig references)
Resume file: .planning/phases/09-making-the-project-opensource-and-usable-for-anyone-with-any-number-of-machines-and-identities/09-04-PLAN.md
