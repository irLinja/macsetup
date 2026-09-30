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
echo
if [[ $fails -eq 0 ]]; then echo "all tests passed"; else echo "$fails test(s) FAILED"; exit 1; fi
