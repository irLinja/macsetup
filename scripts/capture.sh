#!/usr/bin/env bash
# capture.sh -- Interactive onboarding/capture tool for macsetup
#
# Audits six domains on the current Mac:
#   1. CLI tools (Homebrew leaves, npm globals, pipx)
#   2. GUI applications (/Applications)
#   3. Mac App Store apps
#   4. Shell configuration (aliases, PATH entries)
#   5. macOS defaults (drift detection against Nix config)
#   6. Fonts
#
# For each unmanaged item, the user chooses:
#   [A]dd   -- insert the correct entry into the correct .nix file
#   [I]gnore -- persist to ~/.macsetup/ignore.list (never ask again)
#   [S]kip   -- do nothing (item appears again on next run)
#
# Usage: ./capture.sh
# Requires: Nix-provided Bash 5.x (for mapfile), brew (optional), mas (optional)

set -euo pipefail

###############################################################################
# Preamble
###############################################################################

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

info()   { printf "  ${GREEN}>>>${RESET} %s\n" "$*"; }
warn()   { printf "  ${YELLOW}!!${RESET}  %s\n" "$*"; }
error()  { printf "  ${RED}***${RESET} %s\n" "$*"; }
header() { printf "\n${BOLD}=== %s ===${RESET}\n" "$*"; }

# Repo root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

if [[ ! -f "$REPO_ROOT/flake.nix" ]]; then
  error "Cannot find flake.nix at $REPO_ROOT -- run this script from the macsetup repository."
  exit 1
fi

# Counters
ADDED=0
IGNORED=0
SKIPPED=0

###############################################################################
# Ignore list management
###############################################################################

MACSETUP_DIR="$HOME/.macsetup"
IGNORE_FILE="$MACSETUP_DIR/ignore.list"

init_ignore_list() {
  mkdir -p "$MACSETUP_DIR"
  touch "$IGNORE_FILE"
}

is_ignored() {
  grep -qxF "$1" "$IGNORE_FILE" 2>/dev/null
}

add_to_ignore() {
  echo "$1" >> "$IGNORE_FILE"
  sort -u -o "$IGNORE_FILE" "$IGNORE_FILE"
}

###############################################################################
# Insertion helper
###############################################################################

# Insert text before a given line number in a file (BSD sed compatible)
insert_before_line() {
  local file="$1" line_num="$2" text="$3"
  sed -i '' "${line_num}i\\
${text}
" "$file"
}

###############################################################################
# Triage function (reusable for all domains)
###############################################################################

triage() {
  local item="$1"
  local display_name="$2"
  local add_callback="$3"
  shift 3
  local callback_args=("$@")

  if is_ignored "$item"; then
    return
  fi

  printf "\n  ${BOLD}%s${RESET}\n" "$display_name"
  printf "  [${GREEN}A${RESET}]dd to Nix config  [${YELLOW}I${RESET}]gnore (never ask again)  [${BLUE}S${RESET}]kip\n"
  read -p "  Choice: " -n 1 -r choice
  echo ""

  case "$choice" in
    [Aa])
      "$add_callback" "${callback_args[@]}"
      ADDED=$((ADDED + 1))
      info "Added to Nix config."
      ;;
    [Ii])
      add_to_ignore "$item"
      IGNORED=$((IGNORED + 1))
      info "Added to ignore list."
      ;;
    *)
      SKIPPED=$((SKIPPED + 1))
      ;;
  esac
}

###############################################################################
# .nix file editing functions
###############################################################################

# Add a nixpkgs package to modules/home/packages.nix
add_nixpkg() {
  local pkg_name="$1"
  local comment="${2:-}"
  local target="$REPO_ROOT/modules/home/packages.nix"

  local comment_suffix=""
  if [[ -n "$comment" ]]; then
    comment_suffix="            # $comment"
  fi

  # Find "# -- Shelved" inside the `with pkgs; [` block
  local block_start block_end shelved_line insert_at
  block_start=$(grep -n 'with pkgs;' "$target" | head -1 | cut -d: -f1)

  if [[ -z "$block_start" ]]; then
    warn "Could not find 'with pkgs;' block in $target"
    return
  fi

  # Find closing ]) after block start
  block_end=$(tail -n +"$block_start" "$target" | grep -n '^\s*\])' | head -1 | cut -d: -f1)
  block_end=$((block_start + block_end - 1))

  # Look for Shelved comment within the block
  shelved_line=$(sed -n "${block_start},${block_end}p" "$target" | grep -n '# -- Shelved' | head -1 | cut -d: -f1)

  if [[ -n "$shelved_line" ]]; then
    insert_at=$((block_start + shelved_line - 1))
  else
    insert_at=$block_end
  fi

  insert_before_line "$target" "$insert_at" "    ${pkg_name}${comment_suffix}"
}

# Add a Homebrew brew to modules/darwin/homebrew.nix
add_homebrew_brew() {
  local brew_name="$1"
  local comment="${2:-}"
  local target="$REPO_ROOT/modules/darwin/homebrew.nix"

  local comment_suffix=""
  if [[ -n "$comment" ]]; then
    comment_suffix="                   # $comment"
  fi

  local block_start block_end shelved_line insert_at
  block_start=$(grep -n 'brews = \[' "$target" | head -1 | cut -d: -f1)

  if [[ -z "$block_start" ]]; then
    warn "Could not find 'brews = [' in $target"
    return
  fi

  block_end=$(tail -n +"$block_start" "$target" | grep -n '^\s*\];' | head -1 | cut -d: -f1)
  block_end=$((block_start + block_end - 1))

  shelved_line=$(sed -n "${block_start},${block_end}p" "$target" | grep -n '# -- Shelved' | head -1 | cut -d: -f1)

  if [[ -n "$shelved_line" ]]; then
    insert_at=$((block_start + shelved_line - 1))
  else
    insert_at=$block_end
  fi

  insert_before_line "$target" "$insert_at" "      \"${brew_name}\"${comment_suffix}"
}

# Add a Homebrew cask to modules/darwin/homebrew.nix
add_homebrew_cask() {
  local cask_name="$1"
  local comment="${2:-}"
  local target="$REPO_ROOT/modules/darwin/homebrew.nix"

  local comment_suffix=""
  if [[ -n "$comment" ]]; then
    comment_suffix="                   # $comment"
  fi

  local block_start block_end insert_at
  block_start=$(grep -n 'casks = \[' "$target" | head -1 | cut -d: -f1)

  if [[ -z "$block_start" ]]; then
    warn "Could not find 'casks = [' in $target"
    return
  fi

  block_end=$(tail -n +"$block_start" "$target" | grep -n '^\s*\];' | head -1 | cut -d: -f1)
  insert_at=$((block_start + block_end - 1))

  insert_before_line "$target" "$insert_at" "      \"${cask_name}\"${comment_suffix}"
}

# Add a masApp to modules/darwin/homebrew.nix
add_masapp() {
  local app_name="$1"
  local app_id="$2"
  local target="$REPO_ROOT/modules/darwin/homebrew.nix"

  local block_start block_end insert_at
  block_start=$(grep -n 'masApps = {' "$target" | head -1 | cut -d: -f1)

  if [[ -z "$block_start" ]]; then
    warn "Could not find 'masApps = {' in $target"
    return
  fi

  block_end=$(tail -n +"$block_start" "$target" | grep -n '^\s*};' | head -1 | cut -d: -f1)
  insert_at=$((block_start + block_end - 1))

  insert_before_line "$target" "$insert_at" "      \"${app_name}\" = ${app_id};"
}

# Add a shell alias to modules/home/shell.nix
add_shell_alias() {
  local alias_name="$1"
  local alias_value="$2"
  local target="$REPO_ROOT/modules/home/shell.nix"

  local block_start block_end insert_at
  block_start=$(grep -n 'shellAliases = {' "$target" | head -1 | cut -d: -f1)

  if [[ -z "$block_start" ]]; then
    warn "Could not find 'shellAliases = {' in $target"
    return
  fi

  block_end=$(tail -n +"$block_start" "$target" | grep -n '^\s*};' | head -1 | cut -d: -f1)
  insert_at=$((block_start + block_end - 1))

  # Escape double quotes in value for Nix string
  local escaped_value="${alias_value//\"/\\\"}"
  insert_before_line "$target" "$insert_at" "      ${alias_name} = \"${escaped_value}\";"
}

# Add a PATH entry to modules/home/shell.nix
add_session_path() {
  local path_entry="$1"
  local target="$REPO_ROOT/modules/home/shell.nix"

  local block_start block_end insert_at
  block_start=$(grep -n 'home.sessionPath = \[' "$target" | head -1 | cut -d: -f1)

  if [[ -z "$block_start" ]]; then
    warn "Could not find 'home.sessionPath = [' in $target"
    return
  fi

  block_end=$(tail -n +"$block_start" "$target" | grep -n '^\s*\];' | head -1 | cut -d: -f1)
  insert_at=$((block_start + block_end - 1))

  insert_before_line "$target" "$insert_at" "    \"${path_entry}\""
}

# Add a font to modules/darwin/fonts.nix
add_font() {
  local font_attr="$1"
  local comment="${2:-}"
  local target="$REPO_ROOT/modules/darwin/fonts.nix"

  local comment_suffix=""
  if [[ -n "$comment" ]]; then
    comment_suffix="            # $comment"
  fi

  local block_start block_end insert_at
  block_start=$(grep -n 'fonts.packages' "$target" | head -1 | cut -d: -f1)

  if [[ -z "$block_start" ]]; then
    warn "Could not find 'fonts.packages' in $target"
    return
  fi

  block_end=$(tail -n +"$block_start" "$target" | grep -n '^\s*\];' | head -1 | cut -d: -f1)
  insert_at=$((block_start + block_end - 1))

  insert_before_line "$target" "$insert_at" "    ${font_attr}${comment_suffix}"
}

###############################################################################
# Extraction functions (what's already in Nix config)
###############################################################################

extract_managed_nixpkgs() {
  awk '/with pkgs;/,/\])/' "$REPO_ROOT/modules/home/packages.nix" \
    | grep -E '^\s{4}[a-z]' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/[[:space:]]*#.*//'
}

extract_managed_brews() {
  awk '/brews = \[/,/\];/' "$REPO_ROOT/modules/darwin/homebrew.nix" \
    | grep -E '^\s+"' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/"//g' \
    | sed 's/[[:space:]]*#.*//'
}

extract_managed_casks() {
  awk '/casks = \[/,/\];/' "$REPO_ROOT/modules/darwin/homebrew.nix" \
    | grep -E '^\s+"' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/"//g' \
    | sed 's/[[:space:]]*#.*//'
}

extract_managed_masapps() {
  awk '/masApps = \{/,/\};/' "$REPO_ROOT/modules/darwin/homebrew.nix" \
    | grep -E '^\s+"' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/=.*//' \
    | sed 's/"//g' \
    | sed 's/[[:space:]]*$//'
}

extract_managed_aliases() {
  awk '/shellAliases = \{/,/\};/' "$REPO_ROOT/modules/home/shell.nix" \
    | grep -E '^\s+[a-z]' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/[[:space:]]*=.*//'
}

extract_managed_paths() {
  awk '/home.sessionPath = \[/,/\];/' "$REPO_ROOT/modules/home/shell.nix" \
    | grep -E '^\s+"' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/"//g' \
    | sed 's/[[:space:]]*#.*//'
}

extract_managed_fonts() {
  awk '/fonts.packages/,/\];/' "$REPO_ROOT/modules/darwin/fonts.nix" \
    | grep -E '^\s+nerd-fonts\.' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/[[:space:]]*#.*//'
}

###############################################################################
# Brew-to-Nix name mapping
###############################################################################

declare -A BREW_TO_NIX=(
  [awscli]="awscli2"
  [gnu-sed]="gnused"
  [gnu-tar]="gnutar"
  [grep]="gnugrep"
  [make]="gnumake"
  [helm]="kubernetes-helm"
  [python@3.12]="python312"
  [python@3.13]="python3"
  [hashicorp/tap/terraform]="terraform"
  [hashicorp/tap/vault]="vault"
  [fluxcd/tap/flux]="fluxcd"
  [node]="nodejs"
  [node@20]="nodejs_20"
  [node@22]="nodejs_22"
  [neovim]="neovim"
  [pre-commit]="pre-commit"
  [ripgrep]="ripgrep"
  [pipx]="pipx"
  [go-critic]="go-critic"
  [findutils]="findutils"
  [coreutils]="coreutils"
  [gawk]="gawk"
  [watch]="watch"
  [ed]="ed"
)

# Resolve a Homebrew formula name to a nixpkgs attribute name
resolve_nix_name() {
  local brew_name="$1"
  if [[ -v "BREW_TO_NIX[$brew_name]" ]]; then
    echo "${BREW_TO_NIX[$brew_name]}"
    return
  fi
  # Strip tap prefix (e.g., "hashicorp/tap/terraform" -> "terraform")
  local stripped="${brew_name##*/}"
  # Remove version suffix (python@3.12 -> python)
  stripped="${stripped//@*/}"
  echo "$stripped"
}

###############################################################################
# App name to Homebrew cask name mapping
###############################################################################

# Derive cask name from app display name (lowercase, spaces to hyphens)
derive_cask_name() {
  local app_name="$1"
  echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-'
}

###############################################################################
# Apple system apps (to exclude from GUI audit)
###############################################################################

declare -A APPLE_SYSTEM_APPS=(
  ["Safari"]=1 ["FaceTime"]=1 ["Messages"]=1 ["Maps"]=1
  ["Contacts"]=1 ["Calendar"]=1 ["Reminders"]=1 ["Notes"]=1
  ["News"]=1 ["Stocks"]=1 ["Home"]=1 ["Weather"]=1
  ["Clock"]=1 ["TV"]=1 ["Music"]=1 ["Podcasts"]=1
  ["Books"]=1 ["Preview"]=1 ["Shortcuts"]=1 ["Freeform"]=1
  ["Siri"]=1 ["Font Book"]=1 ["Image Capture"]=1 ["Photo Booth"]=1
  ["System Preferences"]=1 ["System Settings"]=1 ["Mission Control"]=1
  ["Launchpad"]=1 ["App Store"]=1 ["Time Machine"]=1
  ["TextEdit"]=1 ["Calculator"]=1 ["Dictionary"]=1 ["Stickies"]=1
  ["Keychain Access"]=1 ["Migration Assistant"]=1
  ["Accessibility Inspector"]=1 ["Directory Utility"]=1
  ["Console"]=1 ["Activity Monitor"]=1 ["Disk Utility"]=1
  ["Script Editor"]=1 ["Terminal"]=1 ["Automator"]=1
  ["Chess"]=1 ["Grapher"]=1 ["VoiceOver Utility"]=1
  ["Mail"]=1 ["Photos"]=1 ["Finder"]=1 ["Screenshot"]=1
  ["Feedback Assistant"]=1 ["Voice Memos"]=1 ["QuickTime Player"]=1
  ["Passwords"]=1 ["iPhone Mirroring"]=1
  ["System Information"]=1 ["Bluetooth File Exchange"]=1
  ["Boot Camp Assistant"]=1 ["Instruments"]=1 ["FileMerge"]=1
)

###############################################################################
# Discovery functions (what's on the Mac)
###############################################################################

discover_brew_leaves() {
  brew leaves 2>/dev/null | sort
}

discover_npm_globals() {
  npm list -g --depth=0 --json 2>/dev/null \
    | jq -r '.dependencies // {} | keys[]' 2>/dev/null \
    | grep -v -E '^(npm|corepack|pnpm)$'
}

discover_pipx_packages() {
  pipx list --short 2>/dev/null | awk '{print $1}'
}

discover_gui_apps() {
  ls -1d /Applications/*.app 2>/dev/null | while IFS= read -r app_path; do
    local app_name
    app_name="$(basename "$app_path" .app)"
    if [[ ! -v "APPLE_SYSTEM_APPS[$app_name]" ]]; then
      echo "$app_name"
    fi
  done | sort
}

discover_mas_apps() {
  # Returns lines like: ID\tName (version)
  mas list 2>/dev/null
}

discover_user_fonts() {
  ls "$HOME/Library/Fonts/" 2>/dev/null | while IFS= read -r f; do
    echo "$f"
  done
}

discover_shell_config() {
  local source_file=""

  # Prefer .zshrc.backup (brownfield capture after first Nix build)
  if [[ -f "$HOME/.zshrc.backup" ]]; then
    source_file="$HOME/.zshrc.backup"
  elif [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
    # Only read .zshrc if it's NOT a symlink (i.e., not managed by Nix)
    source_file="$HOME/.zshrc"
  fi

  if [[ -z "$source_file" ]]; then
    return
  fi

  echo "SOURCE:$source_file"

  # Extract alias lines
  grep -E '^\s*alias\s+' "$source_file" 2>/dev/null | sed 's/^[[:space:]]*//' || true

  # Extract PATH additions
  grep -E 'export PATH=' "$source_file" 2>/dev/null || true
}

###############################################################################
# macOS Defaults drift detection
###############################################################################

# Mapping: nix-darwin option -> defaults domain + key + expected value
# Format: "domain|key|expected_nix_value|display_name"
get_defaults_checks() {
  # Read expected values from defaults.nix (these are the declared values)
  cat <<'CHECKS'
com.apple.dock|autohide|1|dock.autohide = true
com.apple.dock|tilesize|64|dock.tilesize = 64
com.apple.dock|minimize-to-application|1|dock.minimize-to-application = true
NSGlobalDomain|KeyRepeat|5|NSGlobalDomain.KeyRepeat = 5
NSGlobalDomain|InitialKeyRepeat|30|NSGlobalDomain.InitialKeyRepeat = 30
NSGlobalDomain|AppleInterfaceStyleSwitchesAutomatically|1|NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = true
com.apple.AppleMultitouchTrackpad|Clicking|1|trackpad.Clicking = true
CHECKS
}

###############################################################################
# Domain 1: CLI Tools
###############################################################################

audit_cli_tools() {
  header "Domain 1: CLI Tools"

  if ! command -v brew &>/dev/null; then
    warn "Homebrew not installed -- skipping CLI tool audit."
    return
  fi

  info "Discovering Homebrew leaves..."
  local brew_leaves=()
  mapfile -t brew_leaves < <(discover_brew_leaves)
  info "Found ${#brew_leaves[@]} Homebrew leaves."

  # Load managed packages
  local managed_nixpkgs=()
  mapfile -t managed_nixpkgs < <(extract_managed_nixpkgs)

  local managed_brews=()
  mapfile -t managed_brews < <(extract_managed_brews)

  # Combine managed lists for comparison
  local all_managed=()
  all_managed+=("${managed_nixpkgs[@]}")
  all_managed+=("${managed_brews[@]}")

  # Build lookup set from managed items
  declare -A managed_set
  for item in "${all_managed[@]}"; do
    managed_set["$item"]=1
  done

  # Also add nix-name variants for brew names
  for brew in "${managed_brews[@]}"; do
    local nix_name
    nix_name=$(resolve_nix_name "$brew")
    managed_set["$nix_name"]=1
    managed_set["$brew"]=1
  done

  # Check each brew leaf
  local unmanaged=()
  for leaf in "${brew_leaves[@]}"; do
    local nix_name
    nix_name=$(resolve_nix_name "$leaf")

    # Check if managed under either brew name or nix name
    if [[ -v "managed_set[$leaf]" ]] || [[ -v "managed_set[$nix_name]" ]]; then
      continue
    fi

    # Also strip tap prefix for comparison
    local stripped="${leaf##*/}"
    if [[ -v "managed_set[$stripped]" ]]; then
      continue
    fi

    unmanaged+=("$leaf")
  done

  if [[ ${#unmanaged[@]} -eq 0 ]]; then
    info "All Homebrew leaves are managed in Nix config."
    return
  fi

  info "Found ${#unmanaged[@]} unmanaged CLI tools."

  for leaf in "${unmanaged[@]}"; do
    local nix_name
    nix_name=$(resolve_nix_name "$leaf")

    # Check if available in nixpkgs
    local nix_ver=""
    nix_ver=$(nix eval --raw "nixpkgs#${nix_name}.version" 2>/dev/null || echo "")

    if [[ -n "$nix_ver" ]]; then
      triage "cli:$leaf" "$leaf (nixpkgs: $nix_name v$nix_ver)" add_nixpkg "$nix_name" "from brew: $leaf"
    else
      triage "cli:$leaf" "$leaf (Homebrew only)" add_homebrew_brew "$leaf" "unmanaged brew leaf"
    fi
  done

  # npm globals
  if command -v npm &>/dev/null; then
    info "Discovering npm globals..."
    local npm_globals=()
    mapfile -t npm_globals < <(discover_npm_globals)

    if [[ ${#npm_globals[@]} -gt 0 ]]; then
      info "Found ${#npm_globals[@]} npm globals (informational -- these are typically kept in npm)."
      for pkg in "${npm_globals[@]}"; do
        [[ -z "$pkg" ]] && continue
        printf "    - %s\n" "$pkg"
      done
    fi
  fi

  # pipx packages
  if command -v pipx &>/dev/null; then
    info "Discovering pipx packages..."
    local pipx_pkgs=()
    mapfile -t pipx_pkgs < <(discover_pipx_packages)

    if [[ ${#pipx_pkgs[@]} -gt 0 ]]; then
      info "Found ${#pipx_pkgs[@]} pipx packages (informational -- these are typically kept in pipx)."
      for pkg in "${pipx_pkgs[@]}"; do
        [[ -z "$pkg" ]] && continue
        printf "    - %s\n" "$pkg"
      done
    fi
  fi
}

###############################################################################
# Domain 2: GUI Applications
###############################################################################

audit_gui_apps() {
  header "Domain 2: GUI Applications"

  info "Scanning /Applications..."
  local gui_apps=()
  mapfile -t gui_apps < <(discover_gui_apps)
  info "Found ${#gui_apps[@]} third-party apps."

  # Load managed GUI apps
  local managed_casks=()
  mapfile -t managed_casks < <(extract_managed_casks)

  local managed_masapps=()
  mapfile -t managed_masapps < <(extract_managed_masapps)

  # Build lookup sets
  declare -A managed_gui_set

  for item in "${managed_casks[@]}"; do
    managed_gui_set["$item"]=1
  done
  for item in "${managed_masapps[@]}"; do
    managed_gui_set["$item"]=1
  done

  # Also add 1password (special case -- accessed via direct attribute path)
  managed_gui_set["1password"]=1

  local unmanaged=()
  for app_name in "${gui_apps[@]}"; do
    [[ -z "$app_name" ]] && continue

    local cask_name
    cask_name=$(derive_cask_name "$app_name")

    # Check if managed under cask name or display name
    if [[ -v "managed_gui_set[$cask_name]" ]] || [[ -v "managed_gui_set[$app_name]" ]]; then
      continue
    fi

    unmanaged+=("$app_name")
  done

  if [[ ${#unmanaged[@]} -eq 0 ]]; then
    info "All GUI apps are managed in Nix config."
    return
  fi

  info "Found ${#unmanaged[@]} unmanaged GUI apps."

  if ! command -v brew &>/dev/null; then
    warn "Homebrew not installed -- cannot look up cask availability. Skipping GUI triage."
    return
  fi

  for app_name in "${unmanaged[@]}"; do
    local cask_name
    cask_name=$(derive_cask_name "$app_name")

    # Check if Homebrew cask exists
    local brew_cask_ver=""
    brew_cask_ver=$(brew info --cask "$cask_name" --json=v2 2>/dev/null | jq -r '.casks[0].version // empty' 2>/dev/null || echo "")

    if [[ -n "$brew_cask_ver" ]]; then
      triage "gui:$app_name" "$app_name (Homebrew cask: $cask_name)" add_homebrew_cask "$cask_name" "$app_name"
    else
      warn "$app_name -- not found as Homebrew cask. Skipping."
    fi
  done
}

###############################################################################
# Domain 3: App Store Apps
###############################################################################

audit_mas_apps() {
  header "Domain 3: App Store Apps"

  if ! command -v mas &>/dev/null; then
    warn "mas CLI not installed -- skipping App Store audit."
    return
  fi

  info "Scanning App Store..."
  local mas_output=()
  mapfile -t mas_output < <(discover_mas_apps)

  if [[ ${#mas_output[@]} -eq 0 ]]; then
    info "No App Store apps found (user may not be signed in)."
    return
  fi

  info "Found ${#mas_output[@]} App Store apps."

  # Load managed masApps
  local managed_masapps=()
  mapfile -t managed_masapps < <(extract_managed_masapps)

  declare -A managed_mas_set
  for item in "${managed_masapps[@]}"; do
    managed_mas_set["$item"]=1
  done

  local unmanaged_count=0
  for line in "${mas_output[@]}"; do
    [[ -z "$line" ]] && continue

    # Parse: "ID  Name (version)"
    local mas_id="${line%% *}"
    local rest="${line#* }"
    local mas_name="${rest% (*}"

    if [[ -v "managed_mas_set[$mas_name]" ]]; then
      continue
    fi

    unmanaged_count=$((unmanaged_count + 1))
    triage "mas:$mas_name" "$mas_name (App Store ID: $mas_id)" add_masapp "$mas_name" "$mas_id"
  done

  if [[ $unmanaged_count -eq 0 ]]; then
    info "All App Store apps are managed in Nix config."
  fi
}

###############################################################################
# Domain 4: Shell Configuration
###############################################################################

audit_shell_config() {
  header "Domain 4: Shell Configuration"

  local shell_data=()
  mapfile -t shell_data < <(discover_shell_config)

  if [[ ${#shell_data[@]} -eq 0 ]]; then
    info "No non-Nix shell configuration found to import."
    return
  fi

  local source_file=""
  local aliases=()
  local path_entries=()

  for line in "${shell_data[@]}"; do
    if [[ "$line" == SOURCE:* ]]; then
      source_file="${line#SOURCE:}"
      info "Reading shell config from: $source_file"
      continue
    fi

    if [[ "$line" == alias\ * ]]; then
      aliases+=("$line")
    elif [[ "$line" == export\ PATH=* ]]; then
      path_entries+=("$line")
    fi
  done

  # Load managed aliases and paths
  local managed_aliases=()
  mapfile -t managed_aliases < <(extract_managed_aliases)

  local managed_paths=()
  mapfile -t managed_paths < <(extract_managed_paths)

  declare -A managed_alias_set
  for item in "${managed_aliases[@]}"; do
    managed_alias_set["$item"]=1
  done

  declare -A managed_path_set
  for item in "${managed_paths[@]}"; do
    managed_path_set["$item"]=1
  done

  # Process aliases
  if [[ ${#aliases[@]} -gt 0 ]]; then
    info "Found ${#aliases[@]} aliases."
    for alias_line in "${aliases[@]}"; do
      # Parse: alias name='value' or alias name="value"
      local alias_body="${alias_line#alias }"
      local alias_name="${alias_body%%=*}"
      local alias_value="${alias_body#*=}"
      # Strip surrounding quotes
      alias_value="${alias_value#[\"\']}"
      alias_value="${alias_value%[\"\']}"

      if [[ -v "managed_alias_set[$alias_name]" ]]; then
        continue
      fi

      triage "alias:$alias_name" "alias $alias_name='$alias_value'" add_shell_alias "$alias_name" "$alias_value"
    done
  fi

  # Process PATH entries
  if [[ ${#path_entries[@]} -gt 0 ]]; then
    info "Found ${#path_entries[@]} PATH exports."
    for path_line in "${path_entries[@]}"; do
      # Extract paths from export PATH=... lines
      # Common pattern: export PATH="$PATH:/some/path" or export PATH="/some/path:$PATH"
      local path_value="${path_line#export PATH=}"
      path_value="${path_value#[\"\']}"
      path_value="${path_value%[\"\']}"

      # Split on colon and extract non-variable parts
      IFS=':' read -ra path_parts <<< "$path_value"
      for part in "${path_parts[@]}"; do
        # Skip $PATH, $HOME references that are already standard
        [[ "$part" == "\$PATH" ]] && continue
        [[ "$part" == "\$HOME"* ]] && part="${part/\$HOME/$HOME}"
        [[ -z "$part" ]] && continue

        # Check if already managed
        if [[ -v "managed_path_set[$part]" ]]; then
          continue
        fi

        triage "path:$part" "PATH: $part" add_session_path "$part"
      done
    done
  fi
}

###############################################################################
# Domain 5: macOS Defaults (drift detection)
###############################################################################

audit_defaults() {
  header "Domain 5: macOS Defaults (Drift Detection)"

  info "Comparing live macOS defaults against Nix config..."

  local drift_found=0

  while IFS='|' read -r domain key expected display_name; do
    [[ -z "$domain" ]] && continue

    local live_value
    live_value=$(defaults read "$domain" "$key" 2>/dev/null || echo "UNSET")

    if [[ "$live_value" != "$expected" ]]; then
      drift_found=$((drift_found + 1))
      warn "DRIFT: $display_name"
      printf "    Nix config: %s\n" "$expected"
      printf "    Live value: %s\n" "$live_value"
      printf "    (Run 'darwin-rebuild switch' to apply the Nix value)\n"
    fi
  done < <(get_defaults_checks)

  if [[ $drift_found -eq 0 ]]; then
    info "No drift detected -- all macOS defaults match Nix config."
  else
    warn "$drift_found default(s) have drifted from Nix config."
    info "Run 'darwin-rebuild switch' (or 'macsetup rebuild') to re-apply."
  fi
}

###############################################################################
# Domain 6: Fonts
###############################################################################

audit_fonts() {
  header "Domain 6: Fonts"

  # Load managed fonts
  local managed_fonts=()
  mapfile -t managed_fonts < <(extract_managed_fonts)

  declare -A managed_font_set
  for item in "${managed_fonts[@]}"; do
    managed_font_set["$item"]=1
  done

  # Discover user fonts
  info "Scanning ~/Library/Fonts/..."
  local user_fonts=()
  mapfile -t user_fonts < <(discover_user_fonts)

  if [[ ${#user_fonts[@]} -eq 0 ]]; then
    info "No user-installed fonts found."
    return
  fi

  info "Found ${#user_fonts[@]} user-installed font files."

  # Known font file -> nerd-fonts attribute mapping
  declare -A FONT_FILE_TO_NIX=(
    ["JetBrainsMono"]="nerd-fonts.jetbrains-mono"
    ["JetBrainsMonoNerd"]="nerd-fonts.jetbrains-mono"
    ["MesloLG"]="nerd-fonts.meslo-lg"
    ["MesloLGSNerd"]="nerd-fonts.meslo-lg"
    ["FiraCode"]="nerd-fonts.fira-code"
    ["FiraCodeNerd"]="nerd-fonts.fira-code"
    ["Hack"]="nerd-fonts.hack"
    ["HackNerd"]="nerd-fonts.hack"
    ["SourceCodePro"]="nerd-fonts.sauce-code-pro"
    ["CascadiaCode"]="nerd-fonts.caskaydia-cove"
    ["UbuntuMono"]="nerd-fonts.ubuntu-mono"
    ["RobotoMono"]="nerd-fonts.roboto-mono"
    ["Inconsolata"]="nerd-fonts.inconsolata"
    ["IBMPlex"]="nerd-fonts.blex-mono"
    ["DroidSans"]="nerd-fonts.droid-sans-mono"
    ["DejaVuSans"]="nerd-fonts.dejavu-sans-mono"
  )

  local unmanaged_fonts=()
  for font_file in "${user_fonts[@]}"; do
    [[ -z "$font_file" ]] && continue

    # Try to match font file name to a known Nerd Font package
    local matched=false
    for pattern in "${!FONT_FILE_TO_NIX[@]}"; do
      if [[ "$font_file" == *"$pattern"* ]]; then
        local nix_attr="${FONT_FILE_TO_NIX[$pattern]}"
        if [[ -v "managed_font_set[$nix_attr]" ]]; then
          matched=true
          break
        fi
        # Offer to add the unmanaged font
        if ! is_ignored "font:$nix_attr"; then
          unmanaged_fonts+=("$font_file|$nix_attr")
          matched=true
          break
        fi
      fi
    done

    if [[ "$matched" == false ]]; then
      # Unknown font file -- just report it
      unmanaged_fonts+=("$font_file|")
    fi
  done

  # Deduplicate by nix_attr (many font files map to the same package)
  declare -A seen_attrs
  for entry in "${unmanaged_fonts[@]}"; do
    local font_file="${entry%%|*}"
    local nix_attr="${entry##*|}"

    if [[ -n "$nix_attr" ]]; then
      if [[ -v "seen_attrs[$nix_attr]" ]]; then
        continue
      fi
      seen_attrs["$nix_attr"]=1
      triage "font:$nix_attr" "Font: $font_file -> $nix_attr" add_font "$nix_attr" "User-installed font"
    else
      # Unknown font -- just inform
      printf "    Unrecognized font file: %s (manual review needed)\n" "$font_file"
    fi
  done
}

###############################################################################
# Main execution
###############################################################################

main() {
  header "macsetup capture -- Audit Your Mac"
  echo ""
  info "This tool scans your Mac for unmanaged items and helps you"
  info "add them to your Nix configuration."
  echo ""

  init_ignore_list

  info "Loading current Nix configuration..."
  echo ""

  # Run each domain (failure in one domain does not halt the script)
  audit_cli_tools || warn "CLI tools audit encountered an error."
  echo ""

  audit_gui_apps || warn "GUI apps audit encountered an error."
  echo ""

  audit_mas_apps || warn "App Store audit encountered an error."
  echo ""

  audit_shell_config || warn "Shell config audit encountered an error."
  echo ""

  audit_defaults || warn "Defaults drift check encountered an error."
  echo ""

  audit_fonts || warn "Fonts audit encountered an error."
  echo ""

  # Summary
  header "Capture Complete"
  echo ""
  info "  Added:   $ADDED"
  info "  Ignored: $IGNORED"
  info "  Skipped: $SKIPPED"
  echo ""

  if [[ $ADDED -gt 0 ]]; then
    read -p "  Run darwin-rebuild switch now? [y/N] " -n 1 -r rebuild_choice
    echo ""
    if [[ "$rebuild_choice" =~ ^[Yy]$ ]]; then
      info "Rebuilding..."
      cd "$REPO_ROOT"
      sudo darwin-rebuild switch --flake .#macsetup
    else
      info "Skipped. Run 'macsetup rebuild' or 'sudo darwin-rebuild switch --flake .#macsetup' when ready."
    fi
  fi
}

main "$@"
