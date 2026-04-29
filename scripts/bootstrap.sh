#!/bin/bash
# bootstrap.sh - Take a bare Mac to a fully configured nix-darwin + Home Manager system
#
# Usage: macsetup bootstrap [--force]
#        MACSETUP_USERNAME=myuser MACSETUP_FULLNAME="..." MACSETUP_EMAIL="..." macsetup bootstrap
#
# Safe to re-run: detects existing Nix/nix-darwin installs and skips completed steps.
# On failure: stops immediately with instructions to re-run.

set -euo pipefail

trap 'echo ""; echo "Bootstrap failed at step above."; echo "Fix the issue, then re-run: macsetup bootstrap"; echo ""' ERR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

FORCE=false
if [ "${1:-}" = "--force" ] || [ "${1:-}" = "-f" ]; then
  FORCE=true
fi

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

info() {
  echo "==> $*"
}

error() {
  echo ""
  echo "ERROR: $*"
  echo "Fix the issue above, then re-run: macsetup bootstrap"
  echo ""
  exit 1
}

success() {
  echo ""
  echo "==> $*"
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
  local files=("/etc/nix/nix.conf" "/etc/bashrc" "/etc/zshrc" "/etc/zshenv")
  for f in "${files[@]}"; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then
      info "Moving $f to ${f}.before-nix-darwin"
      sudo mv "$f" "${f}.before-nix-darwin"
    fi
  done
}

# ---------------------------------------------------------------------------
# Step 1: Generate user.nix (interactive wizard)
# ---------------------------------------------------------------------------

generate_user_config() {
  local template="$REPO_DIR/user.nix.example"

  if [ ! -f "$template" ]; then
    error "user.nix.example not found at $template"
  fi

  echo ""
  echo "macsetup -- User Configuration Wizard"
  echo "======================================"
  echo ""
  echo "This wizard creates your personal user.nix configuration."
  echo ""

  # Auto-detect username
  local username="${MACSETUP_USERNAME:-$(whoami)}"
  echo "  Username: $username (auto-detected)"
  echo ""

  # Prompt for full name
  local fullname="${MACSETUP_FULLNAME:-}"
  if [ -z "$fullname" ]; then
    read -p "  Full name (for git commits): " fullname
    if [ -z "$fullname" ]; then
      error "Full name is required."
    fi
  else
    echo "  Full name: $fullname (from MACSETUP_FULLNAME)"
  fi

  # Prompt for email
  local email="${MACSETUP_EMAIL:-}"
  if [ -z "$email" ]; then
    read -p "  Email (for git commits): " email
    if [ -z "$email" ]; then
      error "Email is required."
    fi
  else
    echo "  Email: $email (from MACSETUP_EMAIL)"
  fi

  echo ""

  # Ask about 1Password integration
  local onepass="false"
  local signer="null"
  read -p "  Enable 1Password SSH agent + git signing? [y/N] " -n 1 -r op_reply
  echo ""
  if [[ "$op_reply" =~ ^[Yy]$ ]]; then
    onepass="true"
    signer='"\/Applications\/1Password.app\/Contents\/MacOS\/op-ssh-sign"'
  fi

  # Ask about git signing key
  local signing_key="null"
  local sign_by_default="false"
  local allowed_signers="null"
  echo ""
  read -p "  Paste your SSH signing public key (or press Enter to skip): " signing_key_input
  if [ -n "$signing_key_input" ]; then
    signing_key="\"$signing_key_input\""
    sign_by_default="true"
    allowed_signers="\"$email $signing_key_input\""
    # If 1Password was enabled, set the signer path (unescaped for sed)
    if [ "$onepass" = "true" ]; then
      signer='"\/Applications\/1Password.app\/Contents\/MacOS\/op-ssh-sign"'
    fi
  fi

  echo ""
  info "Generating user.nix..."

  # Generate user.nix from template via sed substitution
  sed \
    -e "s/username = \"CHANGEME\"/username = \"$username\"/" \
    -e "s/fullName = \"CHANGEME\"/fullName = \"$fullname\"/" \
    -e "s/email = \"CHANGEME@example.com\"/email = \"$email\"/" \
    -e "s/key = null;.*# Your SSH public key/key = $signing_key;           # Your SSH public key/" \
    -e "s/signByDefault = false/signByDefault = $sign_by_default/" \
    -e "s/signer = null;.*# Path to signing tool/signer = $signer;               # Path to signing tool/" \
    -e "s/allowedSigners = null;.*# \"email ssh-type/allowedSigners = $allowed_signers;         # \"email ssh-type/" \
    -e "s/\"1password\" = false/\"1password\" = $onepass/" \
    "$template" > "$REPO_DIR/user.nix"

  # Stage user.nix so the Nix flake can see it (flakes ignore unstaged files)
  git -C "$REPO_DIR" add -f user.nix
  git -C "$REPO_DIR" update-index --skip-worktree user.nix 2>/dev/null || true

  success "Created user.nix for $fullname <$email>"
}

# ---------------------------------------------------------------------------
# Step 2: Determine config name (hostname-based or macsetup fallback)
# ---------------------------------------------------------------------------

determine_config_name() {
  local hostname
  hostname="$(hostname -s)"

  if [ -f "$REPO_DIR/hosts/${hostname}.nix" ]; then
    CONFIG_NAME="$hostname"
  elif [ -f "$REPO_DIR/hosts/shared.nix" ]; then
    CONFIG_NAME="macsetup"
  else
    error "No host config found. Expected hosts/${hostname}.nix or hosts/shared.nix"
  fi

  info "Using configuration: .#$CONFIG_NAME"
}

# ---------------------------------------------------------------------------
# Main flow
# ---------------------------------------------------------------------------

echo ""
echo "macsetup bootstrap"
echo "=================="
echo ""

# Step 1: Generate user.nix if it doesn't exist (or --force skips)
if [ -f "$REPO_DIR/user.nix" ]; then
  if [ "$FORCE" = true ]; then
    info "user.nix already exists (--force specified, skipping wizard)"
  else
    info "user.nix already exists, skipping wizard"
  fi
else
  generate_user_config
fi

echo ""

# Step 2: Determine config name
CONFIG_NAME=""
determine_config_name

echo ""
read -p "Proceed with build? [Y/n] " -n 1 -r REPLY
echo ""
if [[ "$REPLY" =~ ^[Nn]$ ]]; then
  echo "Aborted. Run 'macsetup bootstrap' again when ready."
  exit 0
fi

echo ""

# ---------------------------------------------------------------------------
# Step 3: Install Nix
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
# Step 4: Bootstrap or rebuild nix-darwin
# ---------------------------------------------------------------------------

cd "$REPO_DIR"

if ! check_darwin_installed; then
  # First time: handle /etc conflicts before initial nix-darwin activation
  handle_etc_conflicts

  info "Bootstrapping nix-darwin (first time)..."
  sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ".#$CONFIG_NAME"
else
  info "Rebuilding with nix-darwin..."
  sudo darwin-rebuild switch --flake ".#$CONFIG_NAME"
fi

# After first bootstrap, darwin-rebuild is installed but not yet on PATH in this shell
export PATH="/run/current-system/sw/bin:$PATH"

# ---------------------------------------------------------------------------
# Step 5: Verify idempotency (second rebuild)
# ---------------------------------------------------------------------------

info "Verifying idempotency (second rebuild)..."
sudo darwin-rebuild switch --flake ".#$CONFIG_NAME"
info "Idempotency verified -- second rebuild completed without errors"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo "Bootstrap complete!"
echo ""
echo "Your Mac is now managed by nix-darwin + Home Manager."
echo "To apply future changes:  macsetup rebuild"
echo "To audit your Mac:       macsetup capture"
echo ""
