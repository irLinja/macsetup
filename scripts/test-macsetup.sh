#!/usr/bin/env bash
# Tests for ./macsetup: pure helpers directly, orchestration against stubbed
# sudo/nix/brew/mas. No real sudo, no network, no nix evaluation -- safe to
# run anywhere:
#   scripts/test-macsetup.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../macsetup
# shellcheck disable=SC1091  # checked separately; only dispatches when executed
source "$here/../macsetup"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fails=0
pass() { echo "  ok   $1"; }
fail() { echo "  FAIL $1"; echo "       expected: $2"; echo "       actual:   $3"; fails=$((fails + 1)); }
assert_eq() { if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "$2" "$3"; fi; }
assert_contains() { if [[ "$3" == *"$2"* ]]; then pass "$1"; else fail "$1" "...$2..." "$3"; fi; }
assert_true()  { if "$@"; then pass "$*"; else fail "$*" "exit 0" "non-zero"; fi; }
assert_false() { if "$@"; then fail "$*" "non-zero" "exit 0"; else pass "$*"; fi; }

# ---------------------------------------------------------------------------
echo "lock_diff"
# ---------------------------------------------------------------------------
cat > "$tmp/old.lock" <<'JSON'
{"nodes":{"nixpkgs":{"locked":{"rev":"35e212742ceab4ae1dcfbfd9039a39215c816e8e"}},
          "home-manager":{"locked":{"rev":"a3dfb887d40d134af29fa8e924ba85a3e3a99194"}},
          "nix-darwin":{"locked":{"rev":"4cff07de74b50e64bdd68cd4e722ab5b6b35ee48"}},
          "root":{"inputs":{"nixpkgs":"nixpkgs"}}}}
JSON
cat > "$tmp/new.lock" <<'JSON'
{"nodes":{"nixpkgs":{"locked":{"rev":"b6c8664de9b6cc07fe5666a29f91884ba81197c4"}},
          "home-manager":{"locked":{"rev":"cf22324a27249bf67d4eb0a38d8b6fd426efd5c2"}},
          "nix-darwin":{"locked":{"rev":"4cff07de74b50e64bdd68cd4e722ab5b6b35ee48"}},
          "root":{"inputs":{"nixpkgs":"nixpkgs"}}}}
JSON
assert_eq "lists only changed inputs, sorted, short revs" \
  $'home-manager: a3dfb88 -> cf22324\nnixpkgs: 35e2127 -> b6c8664' \
  "$(lock_diff "$tmp/old.lock" "$tmp/new.lock")"
assert_eq "identical locks print nothing" "" "$(lock_diff "$tmp/old.lock" "$tmp/old.lock")"

# ---------------------------------------------------------------------------
echo "dry_run_local_builds"
# ---------------------------------------------------------------------------
cat > "$tmp/dryrun1.txt" <<'TXT'
warning: Git tree '/Users/arash/Documents/Workspace/macsetup' has uncommitted changes
these 83 derivations will be built:
  /nix/store/09021br9iqmhnczgcb58cm27fnbfspdf-hm_Usersarash.localstate.keep.drv
  /nix/store/0g762hh8bh1fbcz8by417f91mam6q0li-brew.drv
  /nix/store/1aa185pnxcnqv8a3dr97ldm8wj5hkg3k-darwin-option.drv
  /nix/store/61nx1wmw356i1lws2hx9625w017ajk23-direnv-2.37.1.drv
  /nix/store/gi8zqa7cj42civ4ll8nqxn7l9ir1xb1x-pre-commit-4.6.2.drv
  /nix/store/hx6p5vp9wdiiqic59gnc27dzx2g762dh-etc-zshrc.drv
  /nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-brew-7.0.4-patched.drv
  /nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-org.nixos.activate-system.plist.drv
  /nix/store/cccccccccccccccccccccccccccccccc-darwin-system-26.11.drv
these 457 paths will be fetched (1.3 GiB download, 4.9 GiB unpacked):
  /nix/store/dddddddddddddddddddddddddddddddd-clang-21.1.8
  /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-boost-1.89.0
TXT
assert_eq "keeps versioned packages, drops glue, brew patch and fetched paths" \
  $'direnv-2.37.1\npre-commit-4.6.2' \
  "$(dry_run_local_builds "$tmp/dryrun1.txt")"

cat > "$tmp/dryrun2.txt" <<'TXT'
this derivation will be built:
  /nix/store/ffffffffffffffffffffffffffffffff-dotnet-stage0-vmr-8.0.31.drv
this path will be fetched (0.1 MiB download, 0.3 MiB unpacked):
  /nix/store/gggggggggggggggggggggggggggggggg-hello-2.12.1
TXT
assert_eq "singular wording is parsed too" "dotnet-stage0-vmr-8.0.31" "$(dry_run_local_builds "$tmp/dryrun2.txt")"

cat > "$tmp/dryrun3.txt" <<'TXT'
these 2 paths will be fetched (0.1 MiB download, 0.3 MiB unpacked):
  /nix/store/gggggggggggggggggggggggggggggggg-hello-2.12.1
  /nix/store/hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh-cowsay-3.8.4
TXT
assert_eq "nothing to build prints nothing" "" "$(dry_run_local_builds "$tmp/dryrun3.txt")"
assert_eq "empty output prints nothing" "" "$(dry_run_local_builds /dev/null)"

# ---------------------------------------------------------------------------
echo "heavy_builds"
# ---------------------------------------------------------------------------
assert_eq "flags known multi-hour toolchain builds" \
  $'dotnet-stage0-vmr-8.0.31\nllvm-20.1.8\nclang-21.1.8\nnodejs-22.20.0\ncargo-1.90.0\nopenjdk-21.0.4' \
  "$(printf '%s\n' direnv-2.37.1 dotnet-stage0-vmr-8.0.31 llvm-20.1.8 clang-21.1.8 nodejs-22.20.0 cargo-edit-0.13.0 cargo-1.90.0 openjdk-21.0.4 pre-commit-4.6.2 | heavy_builds)"
assert_eq "no heavy builds prints nothing" "" "$(printf '%s\n' direnv-2.37.1 pre-commit-4.6.2 | heavy_builds)"

# ---------------------------------------------------------------------------
echo "is_transient_nix_error"
# ---------------------------------------------------------------------------
printf 'error:\n       … while calling derivationStrict\n       error: polling file descriptor: Invalid argument\n' > "$tmp/log1.txt"
printf 'error: builder for /nix/store/x-foo.drv failed with exit code 1\n' > "$tmp/log2.txt"
assert_true  is_transient_nix_error "$tmp/log1.txt"
assert_false is_transient_nix_error "$tmp/log2.txt"
assert_false is_transient_nix_error /dev/null

# ---------------------------------------------------------------------------
echo "version_lt"
# ---------------------------------------------------------------------------
assert_true  version_lt 3.16.0 3.22.0
assert_true  version_lt 3.9.9 3.22.0
assert_false version_lt 3.22.5 3.22.0
assert_false version_lt 3.22.0 3.22.0
assert_true  version_lt 2.99.0 3.0.0

# ---------------------------------------------------------------------------
echo "parse_determinate_versions"
# ---------------------------------------------------------------------------
cat > "$tmp/dn1.txt" <<'TXT'
Determinate Nixd daemon version: 3.16.0
Determinate Nixd client version: 3.16.0
Latest version: 3.22.5

A new version of Determinate Nix is available. Please update Determinate Nix using the command line:

    sudo determinate-nixd upgrade
TXT
assert_eq "outdated: prints daemon and latest" "3.16.0 3.22.5" "$(parse_determinate_versions "$tmp/dn1.txt")"
printf 'Determinate Nixd daemon version: 3.22.5\nDeterminate Nixd client version: 3.22.5\n' > "$tmp/dn2.txt"
assert_eq "current: latest falls back to daemon version" "3.22.5 3.22.5" "$(parse_determinate_versions "$tmp/dn2.txt")"

# ---------------------------------------------------------------------------
echo "brew_tail_matches"
# ---------------------------------------------------------------------------
# Cut down from Homebrew's bin/brew (7.0.x) and nix-homebrew's brew.tail.sh.
cat > "$tmp/bin-brew-7" <<'TXT'
#!/bin/bash
HOMEBREW_PREFIX="$(cd "$(dirname "$0")/.." && pwd)"
HOMEBREW_LIBRARY="${HOMEBREW_REPOSITORY}/Library"

PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export_homebrew_env_file "/etc/homebrew/brew.env"
exec "${HOMEBREW_LIBRARY}/Homebrew/brew.sh" "$@"
TXT
# 6.0.x still exported HOMEBREW_ORIGINAL_BREW_FILE, which 7.0 dropped.
cat > "$tmp/bin-brew-6" <<'TXT'
#!/bin/bash
HOMEBREW_LIBRARY="${HOMEBREW_REPOSITORY}/Library"

PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export HOMEBREW_ORIGINAL_BREW_FILE="$0"
export_homebrew_env_file "/etc/homebrew/brew.env"
exec "${HOMEBREW_LIBRARY}/Homebrew/brew.sh" "$@"
TXT
cat > "$tmp/brew.tail.sh" <<'TXT'
# -----
# The following is copied from upstream bin/brew
# Copyright (c) 2009-present, Homebrew contributors
# -----

# nix-homebrew:
# Run scripts/update-brew-tail.sh to update this

PATH="@runtimePath@:/usr/bin:/bin:/usr/sbin:/sbin"
export_homebrew_env_file "/etc/homebrew/brew.env"
exec "${HOMEBREW_LIBRARY}/Homebrew/brew.sh" "$@"
TXT
assert_true  brew_tail_matches "$tmp/bin-brew-7" "$tmp/brew.tail.sh"
assert_false brew_tail_matches "$tmp/bin-brew-6" "$tmp/brew.tail.sh"
assert_false brew_tail_matches "$tmp/no-such-bin-brew" "$tmp/brew.tail.sh"
sed 's|^# The following is copied.*|# Copied from bin/brew|' "$tmp/brew.tail.sh" > "$tmp/brew.tail-new-header.sh"
assert_true  brew_tail_matches "$tmp/bin-brew-7" "$tmp/brew.tail-new-header.sh"

# ---------------------------------------------------------------------------
echo "outdated_names / name_list / brew_dsl_errors"
# ---------------------------------------------------------------------------
cat > "$tmp/outdated.json" <<'JSON'
{"formulae":[{"name":"jq","installed_versions":["1.8.0"],"current_version":"1.8.1","pinned":false,"pinned_version":null},
             {"name":"harfbuzz","installed_versions":["14.5.1"],"current_version":"14.6.0","pinned":false,"pinned_version":null},
             {"name":"terraform","installed_versions":["1.5.7"],"current_version":"1.14.0","pinned":true,"pinned_version":"1.5.7"}],
 "casks":[{"name":"slack","installed_versions":["4.52.171"],"current_version":"4.52.182","pinned":false,"pinned_version":null}]}
JSON
assert_eq "the formulae brew upgrade acts on, sorted; pinned ones left out" \
  $'harfbuzz\njq' "$(outdated_names "$tmp/outdated.json" formulae)"
assert_eq "the casks" "slack" "$(outdated_names "$tmp/outdated.json" casks)"
assert_eq "not JSON: nothing" "" "$(echo 'Error: oops' > "$tmp/not.json"; outdated_names "$tmp/not.json" casks)"

assert_eq "short list in full" "a, b, c" "$(printf 'a\nb\nc\n' | name_list 8)"
assert_eq "long list capped" "a, b and 3 more" "$(printf 'a\nb\nc\nd\ne\n' | name_list 2)"
assert_eq "one package" "1 package" "$(packages 1)"
assert_eq "more packages" "61 packages" "$(packages 61)"

cat > "$tmp/brew-upgrade.log" <<'TXT'
==> Upgrading 2 outdated packages:
Error: homebrew/core/zlib-ng-compat: undefined method 'new' for an instance of Symbol
Error: Download failed on Cask 'microsoft-outlook' with message: Download failed: https://go.microsoft.com/fwlink/?linkid=525137
Error: Cask 'gcloud-cli' is unreadable: unknown keyword: :network_access
Error: homebrew/core/zlib-ng-compat: undefined method 'new' for an instance of Symbol
TXT
assert_eq "Ruby rejecting newer DSL (2026-10-21, 2026-08-13) is told apart from a failed download" \
  "Error: homebrew/core/zlib-ng-compat: undefined method 'new' for an instance of Symbol"$'\n'"Error: Cask 'gcloud-cli' is unreadable: unknown keyword: :network_access" \
  "$(brew_dsl_errors "$tmp/brew-upgrade.log")"
assert_eq "a log with only a failed download: none" "" \
  "$(grep 'Download failed' "$tmp/brew-upgrade.log" > "$tmp/download.log"; brew_dsl_errors "$tmp/download.log")"

# ---------------------------------------------------------------------------
# Stubs for the external commands the orchestration helpers drive. Each stub
# appends what it was asked to do to $CALLS, so a test can check exactly which
# commands ran, in what order, and whether they went through sudo. The point
# of most of these tests: one approval per run. Every sudo call must happen
# directly in macsetup's own terminal session (inside `script` or under
# activation it runs in a new session and asks again), and nothing that needs
# that approval may run after `brew` starts (brew revokes it).
# ---------------------------------------------------------------------------
stubs="$tmp/stubs"
mkdir -p "$stubs"
export CALLS="$tmp/calls.log"

cat > "$stubs/sudo" <<'STUB'
#!/bin/bash
echo "sudo $*" >> "$CALLS"
case "$1" in -v|-k|-n) exit 0 ;; esac
exec "$@"
STUB

cat > "$stubs/script" <<'STUB'
#!/bin/bash
# script -q -t 0 LOG CMD...
echo "script $*" >> "$CALLS"
shift 3
log="$1"
shift
"$@" > "$log" 2>&1
STUB

# Like the real one, `upgrade` returns before launchd restarts the daemon: the
# new version only shows up DN_RESTART_POLLS `version` calls later.
cat > "$stubs/determinate-nixd" <<'STUB'
#!/bin/bash
case "$1" in
  version)
    if [ -f "$DN_VERSION_FILE.pending" ]; then
      left="$(cat "$DN_VERSION_FILE.countdown")"
      if [ "$left" -le 0 ]; then
        mv "$DN_VERSION_FILE.pending" "$DN_VERSION_FILE"
        rm -f "$DN_VERSION_FILE.countdown"
        echo "daemon restarted" >> "$CALLS"
      else
        echo $((left - 1)) > "$DN_VERSION_FILE.countdown"
      fi
    fi
    cat "$DN_VERSION_FILE"
    ;;
  upgrade)
    echo "determinate-nixd upgrade" >> "$CALLS"
    [ -z "${DN_UPGRADE_FAIL:-}" ] || exit 1
    printf 'Determinate Nixd daemon version: %s\nDeterminate Nixd client version: %s\n' \
      "$DN_LATEST" "$DN_LATEST" > "$DN_VERSION_FILE.pending"
    echo "${DN_RESTART_POLLS:-0}" > "$DN_VERSION_FILE.countdown"
    ;;
esac
STUB

# `nix flake prefetch --json github:OWNER/REPO/REV` answers with the store path
# $PREFETCH_ROOT/REPO when PREFETCH_ROOT is set.
cat > "$stubs/nix" <<'STUB'
#!/bin/bash
echo "nix $*" >> "$CALLS"
if [ "${1:-} ${2:-} ${3:-}" = "flake prefetch --json" ] && [ -n "${PREFETCH_ROOT:-}" ]; then
  repo="${4#github:*/}"
  printf '{"storePath":"%s"}\n' "$PREFETCH_ROOT/${repo%%/*}"
fi
STUB

cat > "$stubs/nix-env" <<'STUB'
#!/bin/bash
echo "nix-env $*" >> "$CALLS"
STUB

cat > "$stubs/nix-collect-garbage" <<'STUB'
#!/bin/bash
echo "nix-collect-garbage $*" >> "$CALLS"
STUB

# mas outdated prints $MAS_OUTDATED; everything else is logged.
cat > "$stubs/mas" <<'STUB'
#!/bin/bash
case "$1" in
  outdated) [ -z "${MAS_OUTDATED:-}" ] || echo "$MAS_OUTDATED" ;;
  *) echo "mas $*" >> "$CALLS" ;;
esac
STUB

cat > "$stubs/darwin-rebuild" <<'STUB'
#!/bin/bash
echo "darwin-rebuild $*" >> "$CALLS"
if [ -n "${DR_FAIL_FIRST:-}" ] && [ ! -e "$DR_FAIL_FIRST" ]; then
  : > "$DR_FAIL_FIRST"
  printf 'error:\n       … while calling the '"'"'derivationStrict'"'"' builtin\n       error: polling file descriptor: Invalid argument\n'
  exit 1
fi
STUB

# `brew outdated --json=v2` prints $BREW_STATE: what is outdated right now.
# `brew upgrade --formulae` / `--casks` upgrades every unpinned package of
# that kind in it, unless BREW_FAIL names the kind. Failing formulae fail the
# way 2026-10-21 did (brew older than the taps: it dies before upgrading
# anything); failing casks the way a broken download does (only that cask is
# left behind).
cat > "$stubs/brew" <<'STUB'
#!/bin/bash
echo "brew $*" >> "$CALLS"
case "$1" in
  outdated)
    if [ -n "${BREW_OUTDATED_FAIL:-}" ]; then
      echo "config.rb:36:in 'fetch': key not found: \"HOMEBREW_ORIGINAL_BREW_FILE\" (KeyError)" >&2
      exit 1
    fi
    cat "$BREW_STATE"
    ;;
  upgrade)
    [ "${HOMEBREW_NO_ASK:-}" = 1 ] || echo "brew stops at: Do you want to proceed with the upgrade? [y/n]" >> "$CALLS"
    kind="${2#--}"
    case " ${BREW_FAIL:-} " in
      *" $kind "*)
        if [ "$kind" = formulae ]; then
          echo "Error: homebrew/core/zlib-ng-compat: undefined method 'new' for an instance of Symbol" >&2
        else
          echo "==> Upgrading microsoft-outlook"
          echo "Error: Download failed on Cask 'microsoft-outlook' with message: Download failed: https://go.microsoft.com/fwlink/?linkid=525137" >&2
          jq '.casks |= map(select(.name == "microsoft-outlook"))' "$BREW_STATE" > "$BREW_STATE.new"
          mv "$BREW_STATE.new" "$BREW_STATE"
        fi
        exit 1
        ;;
    esac
    jq --arg kind "$kind" '.[$kind] |= map(select(.pinned))' "$BREW_STATE" > "$BREW_STATE.new"
    mv "$BREW_STATE.new" "$BREW_STATE"
    ;;
esac
STUB

chmod +x "$stubs"/*

# in_stubs CMD... -- run CMD in a subshell with the stubs first on PATH (or
# $STUB_PATH instead), an empty call log and errexit on, as in macsetup itself.
# stdout -> $tmp/out, stderr -> $tmp/err; prints CMD's exit status.
in_stubs() {
  : > "$CALLS"
  set +e
  ( set -e; PATH="${STUB_PATH:-$stubs:$PATH}"; "$@" ) >"$tmp/out" 2>"$tmp/err"
  local rc=$?
  set -e
  echo "$rc"
}

# dn_version DAEMON [LATEST] -- write a `determinate-nixd version` fixture.
export DN_VERSION_FILE="$tmp/dn-version.txt" DN_LATEST=3.23.0
dn_version() {
  {
    printf 'Determinate Nixd daemon version: %s\nDeterminate Nixd client version: %s\n' "$1" "$1"
    if [ -n "${2:-}" ]; then
      printf 'Latest version: %s\n\nA new version of Determinate Nix is available. Please update Determinate Nix using the command line:\n\n    sudo determinate-nixd upgrade\n' "$2"
    fi
    printf '\nThe following features are enabled:\n\n * lazy-trees\n'
  } > "$DN_VERSION_FILE"
}

# ---------------------------------------------------------------------------
echo "upgrade_determinate_nix"
# ---------------------------------------------------------------------------
# shellcheck disable=SC2034  # read by wait_for_determinate_nix, sourced from ./macsetup
NIX_DAEMON_POLL_SECONDS=0

dn_version 3.16.0 3.23.0
rc="$(in_stubs upgrade_determinate_nix)"
assert_eq "behind: upgrades once through sudo, then waits for the new daemon to answer" \
  $'sudo determinate-nixd upgrade\ndeterminate-nixd upgrade\ndaemon restarted\nnix store info' "$(cat "$CALLS")"
assert_eq "behind: succeeds" 0 "$rc"

# 2026-10-05: the daemon came back 21 s after `upgrade` returned, and the
# `nix flake update` that had already started died with it.
dn_version 3.16.0 3.23.0
export DN_RESTART_POLLS=3
rc="$(in_stubs upgrade_determinate_nix)"
unset DN_RESTART_POLLS
assert_eq "slow daemon restart: keeps polling, only talks to the store once the new daemon is up" \
  $'sudo determinate-nixd upgrade\ndeterminate-nixd upgrade\ndaemon restarted\nnix store info' "$(cat "$CALLS")"
assert_eq "slow daemon restart: succeeds" 0 "$rc"

dn_version 3.16.0 3.23.0
export DN_RESTART_POLLS=1000
# shellcheck disable=SC2034
NIX_DAEMON_WAIT_TRIES=3
rc="$(in_stubs upgrade_determinate_nix)"
# shellcheck disable=SC2034
NIX_DAEMON_WAIT_TRIES=90
unset DN_RESTART_POLLS
rm -f "$DN_VERSION_FILE.pending" "$DN_VERSION_FILE.countdown"
assert_eq "daemon never comes back: gives up instead of hanging, and does not fail the update" 0 "$rc"
assert_contains "daemon never comes back: says so" "WARNING" "$(cat "$tmp/err")"

dn_version 3.23.0
rc="$(in_stubs upgrade_determinate_nix)"
assert_eq "current: no upgrade and no sudo" "" "$(cat "$CALLS")"
assert_eq "current: succeeds" 0 "$rc"

dn_version 3.16.0 3.23.0
export DN_UPGRADE_FAIL=1
rc="$(in_stubs upgrade_determinate_nix)"
unset DN_UPGRADE_FAIL
assert_eq "failed upgrade (offline, server trouble) does not stop the update" 0 "$rc"
assert_contains "failed upgrade is reported" "WARNING" "$(cat "$tmp/err")"

mkdir -p "$tmp/stubs-no-dn"
cp "$stubs/sudo" "$tmp/stubs-no-dn/"
STUB_PATH="$tmp/stubs-no-dn:/usr/bin:/bin:/usr/sbin:/sbin"
rc="$(in_stubs upgrade_determinate_nix)"
unset STUB_PATH
assert_eq "no determinate-nixd (plain Nix install): nothing to do" "" "$(cat "$CALLS")"
assert_eq "no determinate-nixd: succeeds" 0 "$rc"

# ---------------------------------------------------------------------------
echo "sudo_start / sudo_stop"
# ---------------------------------------------------------------------------
sudo_cycle() {
  sudo_start
  local pid="$SUDO_KEEPALIVE_PID"
  sudo_stop
  if kill -0 "$pid" 2>/dev/null; then echo "keep-alive running"; else echo "keep-alive stopped"; fi
}
rc="$(in_stubs sudo_cycle)"
assert_eq "asks once up front, revokes the approval on stop" $'sudo -v\nsudo -k' "$(cat "$CALLS")"
assert_eq "keep-alive loop is gone after stop" "keep-alive stopped" "$(tail -n1 "$tmp/out")"
assert_eq "cycle succeeds" 0 "$rc"

# Homebrew may ask for its own approval after macsetup's is revoked; the
# EXIT trap runs sudo_stop again and must revoke that one too.
sudo_stop_twice() { sudo_start; sudo_stop; sudo_stop; }
rc="$(in_stubs sudo_stop_twice)"
assert_eq "a later stop (the EXIT trap) revokes again" $'sudo -v\nsudo -k\nsudo -k' "$(cat "$CALLS")"

rc="$(in_stubs sudo_stop)"
assert_eq "never started (doctor, list, ...): leaves the user's own approval alone" "" "$(cat "$CALLS")"

# ---------------------------------------------------------------------------
echo "run_logged sudo-tty"
# ---------------------------------------------------------------------------
rc="$(in_stubs run_logged sudo-tty "$tmp/switch.log" darwin-rebuild switch --flake ".#test")"
assert_eq "sudo is outermost, so it runs in this session and reuses the approval" \
  "sudo script -q -t 0 $tmp/switch.log darwin-rebuild switch --flake .#test" "$(head -n1 "$CALLS")"
assert_eq "command runs and succeeds" $'darwin-rebuild switch --flake .#test\n0' \
  "$(grep '^darwin-rebuild' "$CALLS")"$'\n'"$rc"

export DR_FAIL_FIRST="$tmp/dr-failed-once"
rc="$(in_stubs run_logged sudo-tty "$tmp/switch.log" darwin-rebuild switch --flake ".#test")"
unset DR_FAIL_FIRST
assert_eq "retries the transient daemon-socket error" 2 "$(grep -c '^darwin-rebuild' "$CALLS")"
assert_eq "succeeds on the retry" 0 "$rc"

# Activated-system fixture: the `brew bundle` line nix-darwin writes (copied
# from a real activate script), pointing at a fixture Brewfile and a mas dir.
masdir="$tmp/store/l7c8zj12kzc4fv3rkz2nzw0czkvlxksz-mas-7.0.0/bin"
mkdir -p "$tmp/system" "$masdir"
# Only activation's mas exists, as on the real machine (it is not on PATH).
mv "$stubs/mas" "$masdir/mas"
cat > "$tmp/Brewfile" <<'TXT'
# Taps
tap "homebrew/homebrew-core"
# Formulae
brew "jq"
# Casks
cask "ledger-wallet", trusted: true
cask "microsoft-outlook", trusted: true
# Mac App Store
mas "1Password for Safari", id: 1569813296
mas "Amphetamine", id: 937984704
TXT
write_activate() {
  cat > "$tmp/system/activate" <<TXT
# Homebrew Bundle
echo >&2 "Homebrew bundle..."
if [ -f "/opt/homebrew/bin/brew" ]; then
  PATH="/opt/homebrew/bin:$masdir:\$PATH" sudo --preserve-env=PATH --user=arash --set-home env brew bundle --file='$tmp/Brewfile' --no-upgrade --zap --force-cleanup
else
  echo -e "\e[1;31merror: Homebrew is not installed, skipping...\e[0m" >&2
fi
TXT
}
write_activate
# shellcheck disable=SC2034  # read by the sourced ./macsetup functions
CURRENT_SYSTEM="$tmp/system"
# shellcheck disable=SC2034
HOMEBREW_BIN="$stubs/brew"

# ---------------------------------------------------------------------------
echo "homebrew_upgrade"
# ---------------------------------------------------------------------------
# Two outdated formulae, two outdated casks, and a pinned formula that
# `brew upgrade` leaves alone.
export BREW_STATE="$tmp/brew-state.json"
outdated_state() { jq '.casks += [{"name":"microsoft-outlook","installed_versions":["16.101"],"current_version":"16.102","pinned":false,"pinned_version":null}]' "$tmp/outdated.json" > "$BREW_STATE"; }
upgrade_and_shortfall() { homebrew_upgrade; echo "shortfall: ${HOMEBREW_SHORTFALL:-none}"; }
# The kept logs land in the real per-user temp dir (macOS mktemp -t ignores TMPDIR).
remove_kept_logs() { rm -rf "$(sed -n 's/^WARNING: Homebrew logs: //p' "$tmp/err")"; }
# The brew-src pin the advice names, as in today's flake.lock.
mkdir -p "$tmp/brewrepo"
echo '{"nodes":{"brew-src":{"original":{"type":"github","owner":"Homebrew","repo":"brew","ref":"7.0.4"}}}}' \
  > "$tmp/brewrepo/flake.lock"
# shellcheck disable=SC2034  # read by the sourced ./macsetup functions
REPO_ROOT="$tmp/brewrepo"

outdated_state
rc="$(in_stubs upgrade_and_shortfall)"
assert_eq "formulae, then casks, one brew process each, counted before and after" \
  $'brew outdated --json=v2\nbrew upgrade --formulae\nbrew upgrade --casks\nbrew outdated --json=v2' "$(cat "$CALLS")"
assert_eq "never stops at brew's 'Do you want to proceed?' (nobody is there to answer)" \
  "" "$(grep 'stops at' "$CALLS" || true)"
assert_contains "says up front how much each process has to do, and which one may ask for sudo" \
  $'==> Upgrading Homebrew formulae (2 outdated)...\n==> Upgrading Homebrew casks (2 outdated; Homebrew asks for sudo itself if one needs root)...' \
  "$(grep '^==> Upgrading' "$tmp/out")"
assert_contains "says everything was upgraded (the pinned formula does not count)" \
  "Homebrew: upgraded 4 packages, nothing left outdated." "$(cat "$tmp/out")"
assert_eq "nothing left for the closing line" "shortfall: none" "$(tail -n1 "$tmp/out")"
assert_eq "succeeds" 0 "$rc"

# 2026-10-21: brew 7.0.4 could not load zlib-ng-compat from the new
# homebrew-core and died before upgrading anything -- apps included.
outdated_state
export BREW_FAIL=formulae
rc="$(in_stubs upgrade_and_shortfall)"
unset BREW_FAIL
assert_contains "the casks (apps) still upgrade after the formulae's brew dies" \
  $'brew upgrade --formulae\nbrew upgrade --casks' "$(cat "$CALLS")"
assert_contains "says plainly what was not upgraded" \
  "Homebrew upgraded 2 of 4 outdated packages. Not upgraded: harfbuzz, jq." "$(cat "$tmp/err")"
assert_contains "names the cause" \
  "Cause: Homebrew/brew/7.0.4 (brew-src in flake.nix) is older than the taps it reads:" "$(cat "$tmp/err")"
assert_contains "quotes brew's error" \
  "    Error: homebrew/core/zlib-ng-compat: undefined method 'new' for an instance of Symbol" "$(cat "$tmp/err")"
assert_contains "names the fix" \
  "Fix: pin brew-src to the latest Homebrew/brew release, then run: macsetup rebuild" "$(cat "$tmp/err")"
assert_eq "the closing line hears about it" \
  "shortfall: 2 of 4 outdated packages not upgraded" "$(tail -n1 "$tmp/out")"
assert_eq "does not fail the run (the system is already switched)" 0 "$rc"
remove_kept_logs

outdated_state
export BREW_FAIL=casks
rc="$(in_stubs upgrade_and_shortfall)"
unset BREW_FAIL
assert_contains "a failed download leaves only that cask behind" \
  "Homebrew upgraded 3 of 4 outdated packages. Not upgraded: microsoft-outlook." "$(cat "$tmp/err")"
assert_contains "and suggests a plain retry" "Retry with: brew upgrade" "$(cat "$tmp/err")"
assert_eq "no brew-src advice for a failed download" "" "$(grep 'brew-src' "$tmp/err" || true)"
assert_eq "does not fail the run" 0 "$rc"
remove_kept_logs

outdated_state
jq '.casks = []' "$BREW_STATE" > "$BREW_STATE.new" && mv "$BREW_STATE.new" "$BREW_STATE"
export BREW_FAIL=formulae
rc="$(in_stubs upgrade_and_shortfall)"
unset BREW_FAIL
assert_contains "nothing upgraded is said in so many words" \
  "Homebrew upgraded nothing: 2 packages still outdated." "$(cat "$tmp/err")"
assert_eq "no casks outdated: no casks process" "" "$(grep -e '--casks' "$CALLS" || true)"
assert_eq "the closing line hears about it" "shortfall: nothing was upgraded" "$(tail -n1 "$tmp/out")"
remove_kept_logs

echo '{"formulae":[],"casks":[]}' > "$BREW_STATE"
rc="$(in_stubs upgrade_and_shortfall)"
assert_eq "nothing outdated: brew upgrade is not run" "brew outdated --json=v2" "$(cat "$CALLS")"
assert_contains "and it says so" "Homebrew packages are all up to date." "$(cat "$tmp/out")"
assert_eq "nothing outdated: succeeds" 0 "$rc"

outdated_state
export BREW_OUTDATED_FAIL=1
rc="$(in_stubs upgrade_and_shortfall)"
unset BREW_OUTDATED_FAIL
assert_eq "brew outdated fails: upgrades both kinds anyway" \
  $'brew outdated --json=v2\nbrew upgrade --formulae\nbrew upgrade --casks' "$(cat "$CALLS")"
assert_contains "and says it could not count" "cannot tell what gets upgraded" "$(cat "$tmp/err")"
assert_eq "brew outdated fails: succeeds" 0 "$rc"

printf '#!/bin/sh\n# configuration without Homebrew\n' > "$tmp/system/activate"
rc="$(in_stubs homebrew_upgrade)"
write_activate
assert_eq "activation does not manage Homebrew: brew is not run" "" "$(cat "$CALLS")"
assert_eq "activation does not manage Homebrew: succeeds" 0 "$rc"

# ---------------------------------------------------------------------------
echo "closing line"
# ---------------------------------------------------------------------------
rc="$(in_stubs finished Update)"
assert_eq "clean run" "==> Update complete." "$(cat "$tmp/out")"
# shellcheck disable=SC2034  # read by the sourced ./macsetup functions
HOMEBREW_SHORTFALL="2 of 4 outdated packages not upgraded"
rc="$(in_stubs finished Update)"
HOMEBREW_SHORTFALL=""
assert_eq "a partial Homebrew upgrade does not read as a clean one" \
  "WARNING: Update complete, except Homebrew: 2 of 4 outdated packages not upgraded (details above)." \
  "$(cat "$tmp/err")"

# ---------------------------------------------------------------------------
echo "appstore_upgrade"
# ---------------------------------------------------------------------------
export MAS_OUTDATED="937984704  Amphetamine  (5.3.2 -> 5.3.3)"
rc="$(in_stubs appstore_upgrade)"
assert_eq "updates the Brewfile's App Store apps with activation's mas, directly (mas reuses the approval)" \
  "mas update 1569813296 937984704" "$(cat "$CALLS")"
assert_eq "succeeds" 0 "$rc"
unset MAS_OUTDATED

rc="$(in_stubs appstore_upgrade)"
assert_eq "nothing outdated: mas update is not run" "" "$(cat "$CALLS")"
assert_eq "nothing outdated: succeeds" 0 "$rc"

# ---------------------------------------------------------------------------
echo "check_brew_src_pin"
# ---------------------------------------------------------------------------
# flake.nix pins brew 7.0.10 while nix-homebrew's own lock still says 7.0.4.
export PREFETCH_ROOT="$tmp/prefetch"
mkdir -p "$tmp/pinrepo" "$PREFETCH_ROOT/brew/bin" "$PREFETCH_ROOT/nix-homebrew/modules"
cat > "$tmp/pinrepo/flake.lock" <<'JSON'
{"nodes":{"brew-src":{"locked":{"type":"github","owner":"Homebrew","repo":"brew","rev":"8f10429b56be28a25032b87463fffc95e556b5bc"},
                      "original":{"type":"github","owner":"Homebrew","repo":"brew","ref":"7.0.10"}},
          "nix-homebrew":{"locked":{"type":"github","owner":"zhaofengli","repo":"nix-homebrew","rev":"c11cccfdd36dd69b5323d70d354b2853379c2426"}}}}
JSON
cat > "$PREFETCH_ROOT/nix-homebrew/flake.lock" <<'JSON'
{"nodes":{"brew-src":{"original":{"type":"github","owner":"Homebrew","repo":"brew","ref":"7.0.4"}}}}
JSON
cp "$tmp/brew.tail.sh" "$PREFETCH_ROOT/nix-homebrew/modules/brew.tail.sh"
# shellcheck disable=SC2034  # read by the sourced ./macsetup functions
REPO_ROOT="$tmp/pinrepo"

cp "$tmp/bin-brew-7" "$PREFETCH_ROOT/brew/bin/brew"
rc="$(in_stubs check_brew_src_pin)"
assert_eq "newer tag than nix-homebrew's pin, same bin/brew tail: passes" 0 "$rc"
assert_contains "names both releases" \
  "brew-src Homebrew/brew/7.0.10 matches the bin/brew tail nix-homebrew vendors (from Homebrew/brew/7.0.4)" \
  "$(cat "$tmp/out")"

cp "$tmp/bin-brew-6" "$PREFETCH_ROOT/brew/bin/brew"
rc="$(in_stubs check_brew_src_pin)"
assert_eq "different bin/brew tail (the 2026-09-22 KeyError): fails" 1 "$rc"
assert_contains "names the release to pin instead" "pin brew-src to Homebrew/brew/7.0.4" "$(cat "$tmp/err")"

rm -rf "$PREFETCH_ROOT/brew"
rc="$(in_stubs check_brew_src_pin)"
assert_eq "brew-src cannot be fetched (offline): skips instead of blocking" 0 "$rc"
unset PREFETCH_ROOT

# ---------------------------------------------------------------------------
echo "rebuild: order of everything after activation"
# ---------------------------------------------------------------------------
mkdir -p "$tmp/repo"
dn_version 3.23.0
export MAS_OUTDATED="937984704  Amphetamine  (5.3.2 -> 5.3.3)"
# shellcheck disable=SC2034
REPO_ROOT="$tmp/repo"
outdated_state
rc="$(in_stubs cmd_rebuild)"
unset MAS_OUTDATED
assert_eq "one approval up front; App Store + gc use it; it is revoked; Homebrew (which revokes it too) goes last" \
  $'sudo -v\nsudo script\nmas update\nsudo nix-env\nsudo nix-collect-garbage\nsudo -k\nbrew outdated\nbrew upgrade\nbrew upgrade\nbrew outdated' \
  "$(grep -E '^(sudo|mas|brew) ' "$CALLS" | cut -d' ' -f1-2)"
assert_eq "rebuild succeeds" 0 "$rc"
assert_eq "and says so last" "==> Rebuild complete." "$(tail -n1 "$tmp/out")"

# ---------------------------------------------------------------------------
echo
if [[ $fails -eq 0 ]]; then echo "all tests passed"; else echo "$fails test(s) FAILED"; exit 1; fi
