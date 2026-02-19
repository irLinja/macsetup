#!/usr/bin/env bash
# audit-gui-apps.sh -- Scan all GUI apps on this Mac, cross-reference with
# NixCasks API / Homebrew cask / Mac App Store, and generate APP-REVIEW.md
#
# Outputs a categorized review file with channel assignments following:
#   App Store > NixCasks (version-current) > Homebrew cask
#
# Safe to re-run (idempotent). Overwrites the review file each time.
# Requires: curl, jq, brew

set -euo pipefail

###############################################################################
# Configuration
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_OUTPUT="$REPO_ROOT/.planning/phases/06-gui-applications/APP-REVIEW.md"
HOSTNAME_SHORT="$(hostname -s 2>/dev/null || hostname)"
DATE="$(date '+%Y-%m-%d %H:%M')"

# Rate limiting for NixCasks API
API_DELAY=0.5

# Parse --output flag
OUTPUT_FILE="$DEFAULT_OUTPUT"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --output=*)
      OUTPUT_FILE="${1#*=}"
      shift
      ;;
    -h|--help)
      echo "Usage: audit-gui-apps.sh [--output PATH]"
      echo "  --output PATH  Output file (default: $DEFAULT_OUTPUT)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

mkdir -p "$(dirname "$OUTPUT_FILE")"

###############################################################################
# Apple system apps to skip (apps that live in /Applications but are from Apple)
###############################################################################

declare -A APPLE_SYSTEM_APPS=(
  ["Safari"]=1
  ["Mail"]=1
  ["FaceTime"]=1
  ["Photo Booth"]=1
  ["Siri"]=1
  ["News"]=1
  ["Stocks"]=1
  ["Home"]=1
  ["Freeform"]=1
  ["Passwords"]=1
  ["iPhone Mirroring"]=1
  ["Books"]=1
  ["Calendar"]=1
  ["Contacts"]=1
  ["Maps"]=1
  ["Messages"]=1
  ["Music"]=1
  ["Notes"]=1
  ["Photos"]=1
  ["Podcasts"]=1
  ["Reminders"]=1
  ["TV"]=1
  ["Weather"]=1
  ["Clock"]=1
  ["Calculator"]=1
  ["Preview"]=1
  ["QuickTime Player"]=1
  ["TextEdit"]=1
  ["Voice Memos"]=1
  ["Automator"]=1
  ["Font Book"]=1
  ["Keychain Access"]=1
  ["Migration Assistant"]=1
  ["Terminal"]=1
  ["Activity Monitor"]=1
  ["Console"]=1
  ["Disk Utility"]=1
  ["System Information"]=1
  ["System Preferences"]=1
  ["System Settings"]=1
  ["App Store"]=1
  ["Time Machine"]=1
  ["Finder"]=1
  ["Launchpad"]=1
  ["Mission Control"]=1
  ["Screenshot"]=1
  ["Feedback Assistant"]=1
  ["Bluetooth File Exchange"]=1
  ["Boot Camp Assistant"]=1
  ["Grapher"]=1
  ["Instruments"]=1
  ["FileMerge"]=1
  ["Accessibility Inspector"]=1
)

###############################################################################
# App name to pname mapping (for NixCasks API lookups)
# Format: ["App Display Name"]="nixcasks-pname"
###############################################################################

declare -A APP_TO_PNAME=(
  ["1Password"]="1password"
  ["1Password for Safari"]="1password-for-safari"
  ["AnyConnect"]="cisco-anyconnect"
  ["Arc"]="arc"
  ["Audacity"]="audacity"
  ["BetterDisplay"]="betterdisplay"
  ["ChatGPT"]="chatgpt"
  ["Claude"]="claude"
  ["Consent-O-Matic"]="consent-o-matic"
  ["Cursor"]="cursor"
  ["DBeaver"]="dbeaver-community"
  ["DisplayLink Manager"]="displaylink"
  ["Enchanted"]="enchanted"
  ["Epic Games Launcher"]="epic-games"
  ["Figma"]="figma"
  ["Ghostty"]="ghostty"
  ["GitHub Desktop"]="github"
  ["Google Chrome"]="google-chrome"
  ["Grammarly Desktop"]="grammarly-desktop"
  ["Headlamp"]="headlamp"
  ["IINA"]="iina"
  ["JetBrains Toolbox"]="jetbrains-toolbox"
  ["Kyocera Cloud Print and Scan"]="kyocera-cloud-print-and-scan"
  ["League of Legends"]="league-of-legends"
  ["Ledger Live"]="ledger-live"
  ["LM Studio"]="lm-studio"
  ["Local AI"]="local-ai"
  ["Logi Tune"]="logi-tune"
  ["Microsoft Excel"]="microsoft-excel"
  ["Microsoft OneNote"]="microsoft-onenote"
  ["Microsoft Outlook"]="microsoft-outlook"
  ["Microsoft PowerPoint"]="microsoft-powerpoint"
  ["Microsoft Teams"]="microsoft-teams"
  ["Microsoft Word"]="microsoft-word"
  ["Miro"]="miro"
  ["MongoDB Compass"]="mongodb-compass"
  ["MonitorControl"]="monitorcontrol"
  ["Multipass"]="multipass"
  ["Notion"]="notion"
  ["OneDrive"]="onedrive"
  ["Opsgenie"]="opsgenie"
  ["Prime Video"]="prime-video"
  ["PrusaSlicer"]="prusaslicer"
  ["Rancher Desktop"]="rancher"
  ["Raycast"]="raycast"
  ["Routine"]="routine"
  ["ShadowsocksX-NG"]="shadowsocksx-ng"
  ["Slack"]="slack"
  ["Spotify"]="spotify"
  ["Steam"]="steam"
  ["Stremio"]="stremio"
  ["Sunsama"]="sunsama"
  ["Surfshark"]="surfshark"
  ["Tailscale"]="tailscale"
  ["Telegram"]="telegram"
  ["The Unarchiver"]="the-unarchiver"
  ["Transmission"]="transmission"
  ["Visual Studio Code"]="visual-studio-code"
  ["Void"]="void"
  ["WhatsApp"]="whatsapp"
  ["WireGuard"]="wireguard-tools"
  ["YubiKey Manager"]="yubico-yubikey-manager"
  ["Zen"]="zen"
  ["Antigravity"]="antigravity"
  ["OpenVPN Connect"]="openvpn-connect"
)

###############################################################################
# Known App Store apps (by display name -> mas ID)
# These are apps commonly available on the App Store.
# The script also checks `mas list` if mas is installed.
###############################################################################

declare -A KNOWN_MAS_APPS=(
  ["Amphetamine"]="937984704"
  ["The Unarchiver"]="425424353"
  ["1Password for Safari"]="1569813296"
  ["WhatsApp"]="310633997"
  ["Telegram"]="747648890"
  ["Microsoft Excel"]="462058435"
  ["Microsoft Word"]="462054276"
  ["Microsoft PowerPoint"]="462062816"
  ["Microsoft Outlook"]="985367838"
  ["Microsoft OneNote"]="784801555"
  ["OneDrive"]="823766827"
  ["Microsoft Teams"]="1113153706"
  ["Slack"]="803453959"
  ["WireGuard"]="1451685025"
  ["Prime Video"]="545519333"
  ["Tailscale"]="1475387142"
  ["Surfshark"]="1437809329"
  ["Notion"]="1559269364"
  ["Miro"]="1180074770"
)

# Apps available as BOTH App Store and direct download (dual-available)
declare -A DUAL_AVAILABLE=(
  ["WhatsApp"]="1"
  ["Telegram"]="1"
  ["Slack"]="1"
  ["Microsoft Excel"]="1"
  ["Microsoft Word"]="1"
  ["Microsoft PowerPoint"]="1"
  ["Microsoft Outlook"]="1"
  ["Microsoft OneNote"]="1"
  ["OneDrive"]="1"
  ["Microsoft Teams"]="1"
  ["Notion"]="1"
  ["1Password for Safari"]="1"
  ["Miro"]="1"
  ["Tailscale"]="1"
  ["Surfshark"]="1"
  ["Prime Video"]="1"
  ["WireGuard"]="1"
)

###############################################################################
# Category assignments for known apps
###############################################################################

declare -A APP_CATEGORY=(
  # Development
  ["Cursor"]="Development"
  ["Visual Studio Code"]="Development"
  ["Ghostty"]="Development"
  ["JetBrains Toolbox"]="Development"
  ["GitHub Desktop"]="Development"
  ["DBeaver"]="Development"
  ["MongoDB Compass"]="Development"
  ["Headlamp"]="Development"
  ["Rancher Desktop"]="Development"
  ["LM Studio"]="Development"
  ["Void"]="Development"

  # Productivity
  ["Notion"]="Productivity"
  ["Raycast"]="Productivity"
  ["Amphetamine"]="Productivity"
  ["Sunsama"]="Productivity"
  ["Routine"]="Productivity"
  ["Miro"]="Productivity"
  ["Grammarly Desktop"]="Productivity"
  ["Figma"]="Productivity"

  # Communication
  ["Slack"]="Communication"
  ["Telegram"]="Communication"
  ["WhatsApp"]="Communication"
  ["Microsoft Teams"]="Communication"
  ["Opsgenie"]="Communication"

  # Media
  ["IINA"]="Media"
  ["Spotify"]="Media"
  ["Audacity"]="Media"
  ["Prime Video"]="Media"
  ["Stremio"]="Media"

  # Security
  ["1Password"]="Security"
  ["1Password for Safari"]="Security"
  ["Surfshark"]="Security"
  ["YubiKey Manager"]="Security"

  # Utilities
  ["The Unarchiver"]="Utilities"
  ["MonitorControl"]="Utilities"
  ["BetterDisplay"]="Utilities"
  ["DisplayLink Manager"]="Utilities"
  ["Logi Tune"]="Utilities"
  ["Multipass"]="Utilities"
  ["Transmission"]="Utilities"
  ["Consent-O-Matic"]="Utilities"
  ["Tailscale"]="Utilities"

  # Internet
  ["Google Chrome"]="Internet"
  ["Arc"]="Internet"
  ["Zen"]="Internet"

  # Gaming
  ["Steam"]="Gaming"
  ["Epic Games Launcher"]="Gaming"
  ["League of Legends"]="Gaming"

  # Creative
  ["PrusaSlicer"]="Creative"
  ["Enchanted"]="Creative"
  ["ChatGPT"]="Creative"
  ["Claude"]="Creative"
  ["Local AI"]="Creative"

  # Office
  ["Microsoft Excel"]="Productivity"
  ["Microsoft Word"]="Productivity"
  ["Microsoft PowerPoint"]="Productivity"
  ["Microsoft Outlook"]="Productivity"
  ["Microsoft OneNote"]="Productivity"
  ["OneDrive"]="Productivity"

  # Networking / VPN
  ["AnyConnect"]="Security"
  ["OpenVPN Connect"]="Security"
  ["ShadowsocksX-NG"]="Security"
  ["WireGuard"]="Security"
  ["Antigravity"]="Security"

  # Finance
  ["Ledger Live"]="Utilities"

  # Printing
  ["Kyocera Cloud Print and Scan"]="Utilities"
)

###############################################################################
# Helper functions
###############################################################################

# Derive pname from app display name (lowercase, spaces to hyphens)
derive_pname() {
  local app_name="$1"

  # Check explicit mapping first
  if [[ -v "APP_TO_PNAME[$app_name]" ]]; then
    echo "${APP_TO_PNAME[$app_name]}"
    return
  fi

  # Auto-derive: lowercase, spaces to hyphens, remove special chars
  echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-'
}

# Get category for an app
get_app_category() {
  local app_name="$1"
  if [[ -v "APP_CATEGORY[$app_name]" ]]; then
    echo "${APP_CATEGORY[$app_name]}"
  else
    echo "Utilities"
  fi
}

# Check NixCasks API for a package
# Returns: JSON response if found, empty if not
check_nixcasks() {
  local pname="$1"
  local response
  local http_code

  http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://nix-casks.yorganci.dev/api/package/${pname}" 2>/dev/null || echo "000")

  if [[ "$http_code" == "200" ]]; then
    response=$(curl -s "https://nix-casks.yorganci.dev/api/package/${pname}" 2>/dev/null || echo "")
    echo "$response"
  fi
}

# Get Homebrew cask version
get_brew_cask_version() {
  local cask_name="$1"
  brew info --cask "$cask_name" --json=v2 2>/dev/null | jq -r '.casks[0].version // empty' 2>/dev/null || echo ""
}

###############################################################################
# Main audit
###############################################################################

echo "=== macsetup GUI App Audit ==="
echo "Scanning /Applications on $(hostname)..."
echo ""

# ---- Step 1: Scan /Applications for .app bundles ----
echo "[1/4] Scanning /Applications for third-party apps..."

THIRD_PARTY_APPS=()

# Scan direct .app bundles in /Applications
while IFS= read -r app_path; do
  app_basename="$(basename "$app_path")"
  app_name="${app_basename%.app}"

  # Skip Apple system apps
  if [[ -v "APPLE_SYSTEM_APPS[$app_name]" ]]; then
    continue
  fi

  THIRD_PARTY_APPS+=("$app_name")
done < <(ls -1d /Applications/*.app 2>/dev/null | sort)

# Also scan .localized directories (e.g., WhatsApp.localized/WhatsApp.app)
while IFS= read -r app_path; do
  app_basename="$(basename "$app_path")"
  app_name="${app_basename%.app}"

  # Skip Apple system apps
  if [[ -v "APPLE_SYSTEM_APPS[$app_name]" ]]; then
    continue
  fi

  # Skip uninstallers and utility launchers bundled with other apps
  case "$app_name" in
    Uninstall*|uninstall*) continue ;;
    "USB File Manager") continue ;;  # Bundled with Send to Kindle
  esac

  # Skip if already found (avoid duplicates)
  already_found=false
  for existing in "${THIRD_PARTY_APPS[@]}"; do
    if [[ "$existing" == "$app_name" ]]; then
      already_found=true
      break
    fi
  done

  if [[ "$already_found" == false ]]; then
    THIRD_PARTY_APPS+=("$app_name")
  fi
done < <(ls -1d /Applications/*.localized/*.app /Applications/*/*.app 2>/dev/null | sort)

# Sort the final list
IFS=$'\n' THIRD_PARTY_APPS=($(printf '%s\n' "${THIRD_PARTY_APPS[@]}" | sort)); unset IFS

echo "  Found ${#THIRD_PARTY_APPS[@]} third-party apps"

# ---- Step 2: Scan Homebrew casks ----
echo "[2/4] Scanning Homebrew casks..."

declare -A BREW_CASKS
if command -v brew &>/dev/null; then
  while IFS= read -r cask; do
    [[ -z "$cask" ]] && continue
    BREW_CASKS["$cask"]=1
  done < <(brew list --cask 2>/dev/null)
  echo "  Found ${#BREW_CASKS[@]} installed casks"
else
  echo "  Homebrew not found -- skipping"
fi

# ---- Step 3: Scan Mac App Store ----
echo "[3/4] Scanning Mac App Store..."

declare -A MAS_APPS  # name -> ID
declare -A MAS_VERSIONS  # name -> version

if command -v mas &>/dev/null; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # Format: "497799835 Xcode (16.2)"
    mas_id="${line%% *}"
    rest="${line#* }"
    mas_name="${rest% (*}"
    mas_ver="${rest##*(}"
    mas_ver="${mas_ver%)}"
    MAS_APPS["$mas_name"]="$mas_id"
    MAS_VERSIONS["$mas_name"]="$mas_ver"
  done < <(mas list 2>/dev/null)
  echo "  Found ${#MAS_APPS[@]} App Store apps"
else
  echo "  mas CLI not installed -- using known App Store app list"
  echo "  (Install mas via 'brew install mas' for live App Store scanning)"
fi

# ---- Step 4: Check NixCasks availability ----
echo "[4/4] Checking NixCasks availability for each app..."
echo "  (Rate-limited: ${API_DELAY}s between requests)"
echo ""

# Data structures for results
declare -A CHANNEL_ASSIGNMENT  # app_name -> channel (AppStore|NixCasks|Homebrew|Skip|Unknown)
declare -A NIXCASKS_VERSION    # app_name -> version from NixCasks
declare -A NIXCASKS_PNAME      # app_name -> pname used for NixCasks
declare -A BREW_CASK_VERSION   # app_name -> version from Homebrew cask
declare -A BREW_CASK_NAME      # app_name -> cask name
declare -A MAS_ID_ASSIGNMENT   # app_name -> mas ID
declare -A IS_DUAL             # app_name -> 1 if dual-available
declare -A CHANNEL_NOTE        # app_name -> extra note

total=${#THIRD_PARTY_APPS[@]}
count=0

for app_name in "${THIRD_PARTY_APPS[@]}"; do
  count=$((count + 1))
  printf "\r  [%d/%d] Checking: %-40s" "$count" "$total" "$app_name"

  pname=$(derive_pname "$app_name")
  NIXCASKS_PNAME["$app_name"]="$pname"

  # Check if app is in App Store (either via mas or known list)
  is_in_mas=false
  mas_id=""
  if [[ -v "MAS_APPS[$app_name]" ]]; then
    is_in_mas=true
    mas_id="${MAS_APPS[$app_name]}"
  elif [[ -v "KNOWN_MAS_APPS[$app_name]" ]]; then
    is_in_mas=true
    mas_id="${KNOWN_MAS_APPS[$app_name]}"
  fi

  # Check NixCasks availability
  nixcasks_json=$(check_nixcasks "$pname")
  nixcasks_ver=""
  if [[ -n "$nixcasks_json" ]]; then
    nixcasks_ver=$(echo "$nixcasks_json" | jq -r '.version // empty' 2>/dev/null || echo "")
    NIXCASKS_VERSION["$app_name"]="$nixcasks_ver"
  fi

  # Check Homebrew cask version (use pname as cask name)
  brew_cask_ver=""
  brew_cask_name="$pname"

  # Try to get brew cask version
  brew_cask_ver=$(get_brew_cask_version "$brew_cask_name")
  if [[ -n "$brew_cask_ver" ]]; then
    BREW_CASK_VERSION["$app_name"]="$brew_cask_ver"
    BREW_CASK_NAME["$app_name"]="$brew_cask_name"
  fi

  # Check if dual-available
  if [[ -v "DUAL_AVAILABLE[$app_name]" ]]; then
    IS_DUAL["$app_name"]=1
  fi

  # Apply channel priority logic
  if [[ "$is_in_mas" == true ]]; then
    # Priority 1: App Store
    CHANNEL_ASSIGNMENT["$app_name"]="AppStore"
    MAS_ID_ASSIGNMENT["$app_name"]="$mas_id"

    if [[ -v "DUAL_AVAILABLE[$app_name]" ]]; then
      IS_DUAL["$app_name"]=1
    fi
  elif [[ -n "$nixcasks_ver" ]]; then
    # Priority 2: NixCasks (check version freshness)
    if [[ -n "$brew_cask_ver" && "$brew_cask_ver" != "latest" ]]; then
      # Compare versions -- simple string comparison
      # NixCasks version is considered current if it matches brew cask version
      if [[ "$nixcasks_ver" == "$brew_cask_ver" ]]; then
        CHANNEL_ASSIGNMENT["$app_name"]="NixCasks"
      else
        # Check if NixCasks version is "close enough" (could be newer or just different format)
        # Use Homebrew cask as fallback if NixCasks version seems stale
        # Simple heuristic: if first two version components match, consider current
        nix_major=$(echo "$nixcasks_ver" | cut -d. -f1-2)
        brew_major=$(echo "$brew_cask_ver" | cut -d. -f1-2)
        if [[ "$nix_major" == "$brew_major" ]]; then
          CHANNEL_ASSIGNMENT["$app_name"]="NixCasks"
          CHANNEL_NOTE["$app_name"]="minor version diff: NixCasks=$nixcasks_ver brew=$brew_cask_ver"
        else
          CHANNEL_ASSIGNMENT["$app_name"]="Homebrew"
          CHANNEL_NOTE["$app_name"]="NixCasks version stale: NixCasks=$nixcasks_ver brew=$brew_cask_ver"
        fi
      fi
    else
      # No brew version to compare or brew version is "latest" -- trust NixCasks
      CHANNEL_ASSIGNMENT["$app_name"]="NixCasks"
    fi
  elif [[ -n "$brew_cask_ver" ]]; then
    # Priority 3: Homebrew cask
    CHANNEL_ASSIGNMENT["$app_name"]="Homebrew"
  else
    # Not found anywhere -- mark as Unknown
    CHANNEL_ASSIGNMENT["$app_name"]="Unknown"
  fi

  # Rate limit
  sleep "$API_DELAY"
done

printf "\r  Done checking %d apps.                                        \n" "$total"

###############################################################################
# Count apps per channel
###############################################################################

app_store_count=0
nixcasks_count=0
homebrew_count=0
dual_count=0
unknown_count=0

for app_name in "${THIRD_PARTY_APPS[@]}"; do
  channel="${CHANNEL_ASSIGNMENT[$app_name]:-Unknown}"
  case "$channel" in
    AppStore)  app_store_count=$((app_store_count + 1)) ;;
    NixCasks)  nixcasks_count=$((nixcasks_count + 1)) ;;
    Homebrew)  homebrew_count=$((homebrew_count + 1)) ;;
    Unknown)   unknown_count=$((unknown_count + 1)) ;;
  esac
  if [[ -v "IS_DUAL[$app_name]" ]]; then
    dual_count=$((dual_count + 1))
  fi
done

###############################################################################
# Generate APP-REVIEW.md
###############################################################################

echo ""
echo "=== Generating APP-REVIEW.md ==="

{
cat <<HEADER
# GUI App Review - macsetup

**Generated:** ${DATE}
**Source Mac:** ${HOSTNAME_SHORT}
**Third-party apps scanned:** ${#THIRD_PARTY_APPS[@]}
**Homebrew casks installed:** ${#BREW_CASKS[@]}

## Channel Summary

| Channel | Count | Description |
|---------|-------|-------------|
| App Store | ${app_store_count} | Installed via \`homebrew.masApps\` (mas CLI) |
| NixCasks | ${nixcasks_count} | Installed via NixCasks flake input (\`home.packages\`) |
| Homebrew Cask | ${homebrew_count} | Installed via \`homebrew.casks\` (fallback) |
| Dual Available | ${dual_count} | Available in both App Store and direct download (review required) |
| Unknown / Skipped | ${unknown_count} | Could not resolve -- manual review needed |

## Instructions

Review each section below. For each app:
- **Keep it** to include in your Nix configuration
- **Delete the line** if you do not want it
- **Move between sections** to change the channel assignment
- Apps marked **DUAL_AVAILABLE** appear in both App Store and direct download sections -- choose one

Channel priority (locked decision): App Store > NixCasks (version-current) > Homebrew cask

> **Note:** The existing \`homebrew.nix\` already declares \`"1password"\` as a cask.
> Apps already declared in the configuration are marked with \`[ALREADY_DECLARED]\`.

---

HEADER

# ---- App Store section ----
cat <<'SECTION_HEADER'
## App Store Apps

Apps assigned to the App Store channel. Declared via `homebrew.masApps` in `modules/darwin/homebrew.nix`.
Format: `"App Name" = masID;`

SECTION_HEADER

# Group by category
declare -a MAS_CATEGORIES=("Development" "Productivity" "Communication" "Media" "Security" "Utilities" "Internet" "Gaming" "Creative")

for category in "${MAS_CATEGORIES[@]}"; do
  entries=""
  for app_name in "${THIRD_PARTY_APPS[@]}"; do
    channel="${CHANNEL_ASSIGNMENT[$app_name]:-}"
    [[ "$channel" != "AppStore" ]] && continue
    app_cat=$(get_app_category "$app_name")
    [[ "$app_cat" != "$category" ]] && continue

    mas_id="${MAS_ID_ASSIGNMENT[$app_name]:-unknown}"
    dual_flag=""
    if [[ -v "IS_DUAL[$app_name]" ]]; then
      dual_flag=" [DUAL_AVAILABLE]"
    fi
    entries+="- \`\"${app_name}\" = ${mas_id};\`${dual_flag}"$'\n'
  done

  if [[ -n "$entries" ]]; then
    echo "### ${category}"
    echo ""
    echo "$entries"
  fi
done

echo ""
echo "---"
echo ""

# ---- NixCasks section ----
cat <<'SECTION_HEADER'
## NixCasks Apps

Apps assigned to the NixCasks channel. Declared via `inputs.nix-casks.packages.${pkgs.system}` in `home.packages`.
Format: `pname  # version`

SECTION_HEADER

for category in "${MAS_CATEGORIES[@]}"; do
  entries=""
  for app_name in "${THIRD_PARTY_APPS[@]}"; do
    channel="${CHANNEL_ASSIGNMENT[$app_name]:-}"
    [[ "$channel" != "NixCasks" ]] && continue
    app_cat=$(get_app_category "$app_name")
    [[ "$app_cat" != "$category" ]] && continue

    pname="${NIXCASKS_PNAME[$app_name]:-unknown}"
    ver="${NIXCASKS_VERSION[$app_name]:-unknown}"
    note="${CHANNEL_NOTE[$app_name]:-}"
    note_str=""
    if [[ -n "$note" ]]; then
      note_str=" ($note)"
    fi
    entries+="- \`${pname}\`  # ${app_name} v${ver}${note_str}"$'\n'
  done

  if [[ -n "$entries" ]]; then
    echo "### ${category}"
    echo ""
    echo "$entries"
  fi
done

echo ""
echo "---"
echo ""

# ---- Homebrew Cask section ----
cat <<'SECTION_HEADER'
## Homebrew Cask Apps

Apps assigned to the Homebrew cask channel (fallback). Declared via `homebrew.casks` in `modules/darwin/homebrew.nix`.
These are apps NOT available in NixCasks or with stale NixCasks versions.
Format: `"cask-name"  # App Name`

SECTION_HEADER

for category in "${MAS_CATEGORIES[@]}"; do
  entries=""
  for app_name in "${THIRD_PARTY_APPS[@]}"; do
    channel="${CHANNEL_ASSIGNMENT[$app_name]:-}"
    [[ "$channel" != "Homebrew" ]] && continue
    app_cat=$(get_app_category "$app_name")
    [[ "$app_cat" != "$category" ]] && continue

    pname="${NIXCASKS_PNAME[$app_name]:-}"
    cask_name="${BREW_CASK_NAME[$app_name]:-$pname}"
    ver="${BREW_CASK_VERSION[$app_name]:-unknown}"
    note="${CHANNEL_NOTE[$app_name]:-}"
    note_str=""
    if [[ -n "$note" ]]; then
      note_str=" ($note)"
    fi
    already=""
    if [[ "$cask_name" == "1password" ]]; then
      already=" [ALREADY_DECLARED]"
    fi
    entries+="- \`\"${cask_name}\"\`  # ${app_name} v${ver}${note_str}${already}"$'\n'
  done

  if [[ -n "$entries" ]]; then
    echo "### ${category}"
    echo ""
    echo "$entries"
  fi
done

echo ""
echo "---"
echo ""

# ---- Dual Available section ----
cat <<'SECTION_HEADER'
## Dual Available (User Review Required)

These apps are available in BOTH the Mac App Store AND as direct downloads.
App Store versions may have sandboxing limitations; direct downloads may have more features.

**Action required:** For each app, decide which channel to use. The default assignment above
follows the priority rule (App Store preferred), but you may want to override for specific apps.

SECTION_HEADER

for app_name in "${THIRD_PARTY_APPS[@]}"; do
  [[ ! -v "IS_DUAL[$app_name]" ]] && continue

  channel="${CHANNEL_ASSIGNMENT[$app_name]:-}"
  mas_id="${MAS_ID_ASSIGNMENT[$app_name]:-${KNOWN_MAS_APPS[$app_name]:-unknown}}"
  pname="${NIXCASKS_PNAME[$app_name]:-}"
  nixcasks_ver="${NIXCASKS_VERSION[$app_name]:-N/A}"

  echo "### ${app_name}"
  echo ""
  echo "- **Current assignment:** ${channel}"
  echo "- **App Store:** mas ID \`${mas_id}\`"
  if [[ "$nixcasks_ver" != "N/A" && -n "$nixcasks_ver" ]]; then
    echo "- **NixCasks:** \`${pname}\` v${nixcasks_ver}"
  fi
  brew_ver="${BREW_CASK_VERSION[$app_name]:-}"
  if [[ -n "$brew_ver" ]]; then
    echo "- **Homebrew cask:** \`${pname}\` v${brew_ver}"
  fi
  echo ""
done

echo "---"
echo ""

# ---- Unknown / Skipped section ----
cat <<'SECTION_HEADER'
## Unknown / Skipped

Apps that could not be resolved to any channel. These may need manual investigation
or may be apps that do not need declarative management.

SECTION_HEADER

has_unknown=false
for app_name in "${THIRD_PARTY_APPS[@]}"; do
  channel="${CHANNEL_ASSIGNMENT[$app_name]:-}"
  [[ "$channel" != "Unknown" ]] && continue
  has_unknown=true

  pname="${NIXCASKS_PNAME[$app_name]:-}"
  app_cat=$(get_app_category "$app_name")
  echo "- **${app_name}** (pname: \`${pname}\`, category: ${app_cat}) -- not found in NixCasks or Homebrew cask"
done

if [[ "$has_unknown" == false ]]; then
  echo "All apps were resolved to a channel."
fi

echo ""
echo "---"
echo ""

# ---- Full inventory table ----
cat <<'SECTION_HEADER'
## Full Inventory

Complete list of all scanned apps with their channel assignments.

| App | Channel | Identifier | Version | Category | Notes |
|-----|---------|------------|---------|----------|-------|
SECTION_HEADER

for app_name in "${THIRD_PARTY_APPS[@]}"; do
  channel="${CHANNEL_ASSIGNMENT[$app_name]:-Unknown}"
  app_cat=$(get_app_category "$app_name")
  note="${CHANNEL_NOTE[$app_name]:-}"

  case "$channel" in
    AppStore)
      identifier="${MAS_ID_ASSIGNMENT[$app_name]:-?}"
      version="${MAS_VERSIONS[$app_name]:-N/A}"
      ;;
    NixCasks)
      identifier="${NIXCASKS_PNAME[$app_name]:-?}"
      version="${NIXCASKS_VERSION[$app_name]:-N/A}"
      ;;
    Homebrew)
      identifier="${BREW_CASK_NAME[$app_name]:-${NIXCASKS_PNAME[$app_name]:-?}}"
      version="${BREW_CASK_VERSION[$app_name]:-N/A}"
      ;;
    *)
      identifier="${NIXCASKS_PNAME[$app_name]:-?}"
      version="N/A"
      ;;
  esac

  dual_flag=""
  if [[ -v "IS_DUAL[$app_name]" ]]; then
    dual_flag="DUAL_AVAILABLE"
    if [[ -n "$note" ]]; then
      note="${note}, ${dual_flag}"
    else
      note="$dual_flag"
    fi
  fi

  echo "| ${app_name} | ${channel} | \`${identifier}\` | ${version} | ${app_cat} | ${note} |"
done

echo ""
echo "---"
echo "*Generated by scripts/audit-gui-apps.sh on ${DATE}*"

} > "$OUTPUT_FILE"

echo ""
echo "=== Audit Complete ==="
echo "Review file: $OUTPUT_FILE"
echo ""
echo "Channel Summary:"
echo "  App Store:       ${app_store_count}"
echo "  NixCasks:        ${nixcasks_count}"
echo "  Homebrew Cask:   ${homebrew_count}"
echo "  Dual Available:  ${dual_count} (subset of above, flagged for review)"
echo "  Unknown/Skipped: ${unknown_count}"
echo ""
echo "Next steps:"
echo "  1. Open $OUTPUT_FILE"
echo "  2. Review each section -- delete apps you don't want"
echo "  3. For DUAL_AVAILABLE apps, choose App Store or direct download"
echo "  4. Move apps between sections if you prefer a different channel"
echo "  5. When done, resume the plan with 'approved'"
