---
phase: "09"
plan: "04"
status: complete
started: 2026-02-28
completed: 2026-02-28
---

## Summary

Rewrote bootstrap.sh as an interactive wizard that generates user.nix from user.nix.example, updated the macsetup CLI with auto-staging of user.nix and hostname-based config detection, added host-config generation to capture.sh, updated CLAUDE.md with full architecture documentation, and updated flake.nix description.

User chose to keep the project name as "macsetup" — no rename needed.

## Key Changes

### bootstrap.sh
- Replaced sed-based username replacement with user.nix generation wizard
- Prompts for name, email, 1Password preference, git signing key
- Generates user.nix from user.nix.example via sed substitution
- Stages with `git add -f` and applies skip-worktree
- Supports env vars for non-interactive use (MACSETUP_USERNAME, etc.)

### macsetup CLI
- Added `stage_user_nix()` — auto-stages user.nix before every rebuild
- Added `config_name()` — detects hostname-based host file, falls back to "macsetup"
- capture subcommand now forwards arguments (--gen-host works)

### capture.sh
- Added `config_name()` for dynamic config detection
- Added `generate_host_config()` — creates hosts/<hostname>.nix from example.nix
- Added `--gen-host` flag for standalone host config generation
- All user-facing messages use `macsetup` CLI commands

### CLAUDE.md
- Documented user.nix, profiles, auto-discovery, userConfig threading
- All instructions reference macsetup CLI (not raw scripts)

### flake.nix
- Updated description to reflect open-source framework purpose

## Commits

- `ca1ecc9` feat(09-04): rewrite bootstrap.sh wizard and update CLI with auto-stage
- `07d310c` feat(09-04): update capture.sh and CLAUDE.md for new architecture
- `d2f7703` feat(09-04): update flake.nix description (name stays macsetup)
- `6cd124c` fix(09-04): add custom taps to generated FunLand-Pro host config
- `0ca2c06` fix(09-04): pass arguments through to capture.sh from CLI
- `c8df0b0` fix(09-04): use macsetup CLI in all user-facing messages

## Deviations

- **Project name kept as "macsetup"** — user decided no rename needed, so Task 3 only updated flake.nix description
- **FunLand-Pro.nix tap fix** — generated host file needed custom taps (peonping, tfversion) uncommented to match modules/darwin/homebrew.nix requirements
- **Argument forwarding fix** — macsetup capture wasn't passing --gen-host to capture.sh
- **User-facing message cleanup** — all raw script references replaced with macsetup CLI commands

## Self-Check: PASSED

- [x] bootstrap.sh generates user.nix via wizard
- [x] macsetup CLI auto-stages user.nix and uses hostname detection
- [x] capture.sh has generate_host_config() and --gen-host flag
- [x] CLAUDE.md documents new architecture
- [x] flake.nix description updated
- [x] Human verified darwin-rebuild switch works end-to-end
- [x] All user-facing messages use macsetup CLI commands
