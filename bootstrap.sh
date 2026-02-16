#!/bin/bash
# bootstrap.sh - Take a bare Mac to a fully configured nix-darwin + Home Manager system
#
# Usage: ./bootstrap.sh
#
# Safe to re-run: detects existing Nix/nix-darwin installs and skips completed steps.
# On failure: stops immediately with instructions to re-run.

set -euo pipefail

trap 'echo ""; echo "Bootstrap failed at step above."; echo "Fix the issue, then re-run: ./bootstrap.sh"; echo ""' ERR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

info() {
  echo "==> $*"
}

error() {
  echo ""
  echo "ERROR: $*"
  echo "Fix the issue above, then re-run: ./bootstrap.sh"
  echo ""
  exit 1
}

check_nix_installed() {
  # Check both /nix/store existence and nix command availability
  # PATH might not be set yet after a fresh install
  if [ -d "/nix/store" ] && (command -v nix &>/dev/null || [ -x "/nix/var/nix/profiles/default/bin/nix" ]); then
    return 0
  fi
  return 1
}

check_darwin_installed() {
  command -v darwin-rebuild &>/dev/null
}

source_nix_profile() {
  # Source the Nix daemon profile so nix is on PATH in this shell session
  if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    # shellcheck disable=SC1091
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  fi
}

handle_etc_conflicts() {
  # Move regular files (not symlinks) that conflict with nix-darwin management
  local files=("/etc/nix/nix.conf" "/etc/bashrc" "/etc/zshrc")
  for f in "${files[@]}"; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then
      info "Moving $f to ${f}.before-nix-darwin"
      sudo mv "$f" "${f}.before-nix-darwin"
    fi
  done
}

# ---------------------------------------------------------------------------
# Step 1: Confirm identity
# ---------------------------------------------------------------------------

echo ""
echo "macsetup bootstrap"
echo "=================="
echo ""

HOSTNAME=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
USERNAME=$(whoami)

echo "  Hostname: $HOSTNAME"
echo "  Username: $USERNAME"
echo ""

if [ "$USERNAME" != "arash" ]; then
  echo "  WARNING: Nix config is hardcoded for username 'arash'."
  echo "  You will need to edit hosts/shared.nix and flake.nix to match your username."
  echo ""
fi

read -p "Proceed with these settings? [Y/n] " -n 1 -r REPLY
echo ""
if [[ "$REPLY" =~ ^[Nn]$ ]]; then
  echo "Aborted. Edit the Nix configuration files to match your setup, then re-run."
  exit 0
fi

echo ""

# ---------------------------------------------------------------------------
# Step 2: Install Nix
# ---------------------------------------------------------------------------

if check_nix_installed; then
  info "Nix already installed, skipping"
else
  info "Installing Nix via Determinate Systems installer..."
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi

source_nix_profile

# Verify nix is available
if ! command -v nix &>/dev/null; then
  error "Nix command not found after installation. Try opening a new terminal and re-running."
fi

info "Nix is available: $(nix --version)"

# ---------------------------------------------------------------------------
# Step 3: Bootstrap or rebuild nix-darwin
# ---------------------------------------------------------------------------

cd "$SCRIPT_DIR"

if ! check_darwin_installed; then
  # First time: handle /etc conflicts before initial nix-darwin activation
  handle_etc_conflicts

  info "Bootstrapping nix-darwin (first time)..."
  sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#macsetup
else
  info "Rebuilding with nix-darwin..."
  sudo darwin-rebuild switch --flake .#macsetup
fi

# ---------------------------------------------------------------------------
# Step 4: Verify idempotency (second rebuild)
# ---------------------------------------------------------------------------

info "Verifying idempotency (second rebuild)..."
sudo darwin-rebuild switch --flake .#macsetup
info "Idempotency verified -- second rebuild completed without errors"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo "Bootstrap complete!"
echo ""
echo "Your Mac is now managed by nix-darwin + Home Manager."
echo "To apply future changes: sudo darwin-rebuild switch --flake .#macsetup"
echo ""
