#!/usr/bin/env bash
# Unit tests for the pure helper functions in ./macsetup.
# No sudo, no network, no nix evaluation -- safe to run anywhere:
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
# Stubs for the external commands the orchestration helpers drive. Each stub
# appends what it was asked to do to $CALLS, so a test can check exactly which
# commands ran, in what order, and whether they went through sudo. The point
# of most of these tests: every sudo call must happen directly in macsetup's
# own terminal session -- inside `script` or under activation it runs in a
# new session, and sudo asks for approval all over again.
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

cat > "$stubs/determinate-nixd" <<'STUB'
#!/bin/bash
case "$1" in
  version) cat "$DN_VERSION_FILE" ;;
  upgrade)
    echo "determinate-nixd upgrade" >> "$CALLS"
    [ -z "${DN_UPGRADE_FAIL:-}" ] || exit 1
    printf 'Determinate Nixd daemon version: %s\nDeterminate Nixd client version: %s\n' \
      "$DN_LATEST" "$DN_LATEST" > "$DN_VERSION_FILE"
    ;;
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

cat > "$stubs/brew" <<'STUB'
#!/bin/bash
echo "brew $* (PATH starts ${PATH%%:*})" >> "$CALLS"
if [ -n "${BREW_FAIL:-}" ]; then
  echo "==> Upgrading microsoft-outlook"
  echo "Error: Download failed on Cask 'microsoft-outlook' with message: Download failed: https://go.microsoft.com/fwlink/?linkid=525137" >&2
  echo "Installing microsoft-outlook has failed!"
  exit 1
fi
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
dn_version 3.16.0 3.23.0
rc="$(in_stubs upgrade_determinate_nix)"
assert_eq "behind: upgrades exactly once, through sudo" \
  $'sudo determinate-nixd upgrade\ndeterminate-nixd upgrade' "$(cat "$CALLS")"
assert_eq "behind: succeeds" 0 "$rc"

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

# ---------------------------------------------------------------------------
echo "homebrew_upgrade"
# ---------------------------------------------------------------------------
mkdir -p "$tmp/system"
cat > "$tmp/system/activate" <<'TXT'
# Homebrew Bundle
echo >&2 "Homebrew bundle..."
if [ -f "/opt/homebrew/bin/brew" ]; then
  PATH="/opt/homebrew/bin:/nix/store/l7c8zj12kzc4fv3rkz2nzw0czkvlxksz-mas-7.0.0/bin:$PATH" sudo --preserve-env=PATH --user=arash --set-home env brew bundle --file='/nix/store/lmrcdn5f747096fwcmq25lk44fk7cgp6-Brewfile' --no-upgrade --zap --force-cleanup
else
  echo -e "\e[1;31merror: Homebrew is not installed, skipping...\e[0m" >&2
fi
TXT
# shellcheck disable=SC2034  # read by homebrew_upgrade, sourced from ./macsetup
CURRENT_SYSTEM="$tmp/system"
# shellcheck disable=SC2034
HOMEBREW_BIN="$stubs/brew"

rc="$(in_stubs homebrew_upgrade)"
assert_eq "runs brew directly in this session, never through sudo" "brew" "$(cut -d' ' -f1 "$CALLS" | sort -u)"
assert_contains "installs/upgrades from the Brewfile activation used" \
  "bundle --file=/nix/store/lmrcdn5f747096fwcmq25lk44fk7cgp6-Brewfile" "$(cat "$CALLS")"
assert_contains "puts activation's mas first on PATH (mas is not on the user's PATH)" \
  "(PATH starts /nix/store/l7c8zj12kzc4fv3rkz2nzw0czkvlxksz-mas-7.0.0/bin)" "$(cat "$CALLS")"
assert_eq "succeeds" 0 "$rc"

export BREW_FAIL=1
rc="$(in_stubs homebrew_upgrade)"
unset BREW_FAIL
assert_eq "a failed cask upgrade does not fail the run (the system is already switched)" 0 "$rc"
assert_contains "the closing warning names the failed cask" "microsoft-outlook" "$(cat "$tmp/err")"

printf '#!/bin/sh\n# configuration without Homebrew\n' > "$tmp/system/activate"
rc="$(in_stubs homebrew_upgrade)"
assert_eq "no Brewfile in the activated system: brew is not run" "" "$(cat "$CALLS")"
assert_eq "no Brewfile: succeeds" 0 "$rc"

# ---------------------------------------------------------------------------
echo
if [[ $fails -eq 0 ]]; then echo "all tests passed"; else echo "$fails test(s) FAILED"; exit 1; fi
