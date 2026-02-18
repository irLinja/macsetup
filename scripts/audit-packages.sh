#!/usr/bin/env bash
# audit-packages.sh -- Scan all CLI tools on this Mac and map to nixpkgs
#
# Outputs a categorized review file at:
#   .planning/phases/02-cli-packages/PACKAGE-REVIEW.md
#
# Safe to re-run (idempotent). Overwrites the review file each time.
# Requires: brew, jq, nix (with flakes enabled)

set -euo pipefail

###############################################################################
# Configuration
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REVIEW_FILE="$REPO_ROOT/.planning/phases/02-cli-packages/PACKAGE-REVIEW.md"
HOSTNAME="$(hostname -s 2>/dev/null || hostname)"
DATE="$(date '+%Y-%m-%d %H:%M')"

mkdir -p "$(dirname "$REVIEW_FILE")"

###############################################################################
# Brew-to-Nix name mapping (known mismatches)
###############################################################################

declare -A BREW_TO_NIX=(
  ["gnu-sed"]="gnused"
  ["gnu-tar"]="gnutar"
  ["grep"]="gnugrep"
  ["make"]="gnumake"
  ["awscli"]="awscli2"
  ["helm"]="kubernetes-helm"
  ["python@3.12"]="python312"
  ["python@3.13"]="python3"
  ["hashicorp/tap/terraform"]="terraform"
  ["hashicorp/tap/vault"]="vault"
  ["fluxcd/tap/flux"]="fluxcd"
  ["node"]="nodejs"
  ["node@20"]="nodejs_20"
  ["node@22"]="nodejs_22"
  ["pipx"]="pipx"
  ["go-critic"]="go-critic"
  ["findutils"]="findutils"
  ["coreutils"]="coreutils"
  ["gawk"]="gawk"
  ["watch"]="watch"
  ["ed"]="ed"
)

###############################################################################
# Category mapping -- assigns each brew leaf to a purpose group
###############################################################################

declare -A CATEGORY_MAP=(
  # Development Languages & Runtimes
  ["python@3.12"]="dev-lang"
  ["python@3.13"]="dev-lang"
  ["pnpm"]="dev-lang"
  ["uv"]="dev-lang"
  ["pipx"]="dev-lang"
  ["go-critic"]="dev-lang"

  # Cloud & Infrastructure
  ["awscli"]="cloud"
  ["azure-cli"]="cloud"
  ["azure/bicep/bicep"]="cloud"
  ["azure/kubelogin/kubelogin"]="cloud"
  ["hashicorp/tap/terraform"]="cloud"
  ["hashicorp/tap/vault"]="cloud"
  ["ansible"]="cloud"
  ["terraform-docs"]="cloud"
  ["terraformer"]="cloud"
  ["terraform-mcp-server"]="cloud"
  ["tflint"]="cloud"
  ["tfversion/tap/tfversion"]="cloud"
  ["checkov"]="cloud"
  ["turbot/tap/steampipe"]="cloud"
  ["turbot/tap/powerpipe"]="cloud"

  # Kubernetes
  ["helm"]="k8s"
  ["k9s"]="k8s"
  ["kind"]="k8s"
  ["stern"]="k8s"
  ["kubectx"]="k8s"
  ["istioctl"]="k8s"
  ["kyverno"]="k8s"
  ["kubescape"]="k8s"
  ["popeye"]="k8s"
  ["dive"]="k8s"
  ["cilium-cli"]="k8s"
  ["clusterctl"]="k8s"
  ["fluxcd/tap/flux"]="k8s"
  ["hubble"]="k8s"
  ["k8sgpt"]="k8s"
  ["kube-ps1"]="k8s"
  ["kubebuilder"]="k8s"
  ["kubectl-ai"]="k8s"
  ["kubent"]="k8s"
  ["skopeo"]="k8s"
  ["robusta-dev/krr/krr"]="k8s"

  # CLI Utilities
  ["ripgrep"]="cli-utils"
  ["jq"]="cli-utils"
  ["yq"]="cli-utils"
  ["yj"]="cli-utils"
  ["direnv"]="cli-utils"
  ["starship"]="cli-utils"
  ["fzf"]="cli-utils"  # not in brew leaves currently but kept for mapping
  ["tmux"]="cli-utils"
  ["z"]="cli-utils"
  ["cowsay"]="cli-utils"
  ["terminal-notifier"]="cli-utils"
  ["mongosh"]="cli-utils"
  ["homeport/tap/termshot"]="cli-utils"
  ["pkgconf"]="cli-utils"
  ["zsh-completions"]="cli-utils"
  ["renovate"]="cli-utils"
  ["peonping/tap/peon-ping"]="cli-utils"
  ["adr-tools"]="cli-utils"
  ["cookiecutter"]="cli-utils"
  ["cue"]="cli-utils"

  # GNU Core Replacements
  ["coreutils"]="gnu"
  ["gnu-sed"]="gnu"
  ["gnu-tar"]="gnu"
  ["grep"]="gnu"
  ["make"]="gnu"
  ["gawk"]="gnu"
  ["findutils"]="gnu"
  ["ed"]="gnu"
  ["watch"]="gnu"

  # Version Control
  ["gh"]="vcs"
  ["git"]="vcs"
  ["lazygit"]="vcs"
  ["pre-commit"]="vcs"
  ["gitversion"]="vcs"
  ["norwoodj/tap/helm-docs"]="vcs"

  # Networking
  ["wget"]="net"
  ["aria2"]="net"
  ["mtr"]="net"
  ["openconnect"]="net"
  ["wimlib"]="net"

  # Security & Scanning
  ["trivy"]="security"
  ["trufflehog"]="security"
  ["shellcheck"]="security"

  # Media & Other
  ["neovim"]="media"
  ["ffmpeg"]="media"
  ["hugo"]="media"
  ["powershell/tap/powershell"]="media"
)

# Category display names and ordering
declare -a CATEGORY_ORDER=("dev-lang" "cloud" "k8s" "cli-utils" "gnu" "vcs" "net" "security" "media")

declare -A CATEGORY_NAMES=(
  ["dev-lang"]="Development Languages & Runtimes"
  ["cloud"]="Cloud & Infrastructure"
  ["k8s"]="Kubernetes"
  ["cli-utils"]="CLI Utilities"
  ["gnu"]="GNU Core Replacements"
  ["vcs"]="Version Control"
  ["net"]="Networking"
  ["security"]="Security & Scanning"
  ["media"]="Media & Other"
)

###############################################################################
# Short descriptions for known packages
###############################################################################

declare -A DESCRIPTIONS=(
  # Dev languages
  ["python312"]="Python 3.12 interpreter"
  ["python3"]="Python 3 interpreter"
  ["pnpm"]="Fast Node.js package manager"
  ["uv"]="Fast Python package/project manager"
  ["pipx"]="Install Python CLI tools in isolated envs"
  ["go-critic"]="Opinionated Go source code linter"
  ["gopls"]="Go language server (LSP)"
  ["go-tools"]="Go static analysis tools (staticcheck)"

  # Cloud
  ["awscli2"]="AWS CLI v2"
  ["azure-cli"]="Azure CLI"
  ["terraform"]="Infrastructure as Code"
  ["vault"]="HashiCorp Vault secret management"
  ["ansible"]="Configuration management / automation"
  ["terraform-docs"]="Terraform documentation generator"
  ["terraformer"]="Generate Terraform from existing infrastructure"
  ["tflint"]="Terraform linter"
  ["checkov"]="IaC static analysis / security scanner"

  # Kubernetes
  ["kubernetes-helm"]="Helm package manager for K8s"
  ["k9s"]="Terminal UI for K8s clusters"
  ["kind"]="Kubernetes in Docker (local clusters)"
  ["stern"]="Multi-pod log tailing for K8s"
  ["kubectx"]="Switch kubectl contexts/namespaces"
  ["istioctl"]="Istio service mesh CLI"
  ["kyverno"]="K8s policy engine CLI"
  ["kubescape"]="K8s security scanner"
  ["popeye"]="K8s cluster resource sanitizer"
  ["dive"]="Docker image layer explorer"
  ["cilium-cli"]="Cilium CNI CLI"
  ["clusterctl"]="Cluster API management tool"
  ["fluxcd"]="GitOps toolkit for K8s"
  ["hubble"]="Cilium network observability"
  ["k8sgpt"]="AI-powered K8s diagnostics"
  ["kubebuilder"]="K8s operator SDK"
  ["skopeo"]="Container image operations"
  ["kubent"]="K8s API deprecation checker"

  # CLI Utilities
  ["ripgrep"]="Fast regex search (rg)"
  ["jq"]="JSON processor"
  ["yq"]="YAML/JSON/XML processor"
  ["yj"]="YAML/JSON/TOML/HCL converter"
  ["direnv"]="Directory-based env vars"
  ["starship"]="Cross-shell prompt"
  ["fzf"]="Fuzzy finder"
  ["tmux"]="Terminal multiplexer"
  ["z"]="Directory jump tool (frecency-based)"
  ["cowsay"]="ASCII cow message generator"
  ["terminal-notifier"]="macOS notification CLI"
  ["mongosh"]="MongoDB shell"
  ["pkgconf"]="Package config tool (pkg-config alternative)"
  ["zsh-completions"]="Additional zsh completion definitions"
  ["renovate"]="Automated dependency updates"
  ["adr-tools"]="Architecture Decision Records tool"
  ["cookiecutter"]="Project template scaffolding"
  ["cue"]="CUE data validation language"

  # GNU
  ["coreutils"]="GNU core utilities (ls, cat, etc.)"
  ["gnused"]="GNU sed (stream editor)"
  ["gnutar"]="GNU tar (archive tool)"
  ["gnugrep"]="GNU grep (pattern search)"
  ["gnumake"]="GNU make (build tool)"
  ["gawk"]="GNU awk (text processing)"
  ["findutils"]="GNU find/xargs"
  ["ed"]="GNU line editor"
  ["watch"]="Execute command periodically"

  # Version Control
  ["gh"]="GitHub CLI"
  ["git"]="Distributed version control"
  ["lazygit"]="Terminal UI for git"
  ["pre-commit"]="Git hook framework"

  # Networking
  ["wget"]="HTTP/FTP downloader"
  ["aria2"]="Multi-protocol parallel downloader"
  ["mtr"]="Network diagnostic (traceroute + ping)"
  ["openconnect"]="VPN client (Cisco/Juniper/etc.)"
  ["wimlib"]="Windows image file manipulation"

  # Security
  ["trivy"]="Container/IaC vulnerability scanner"
  ["trufflehog"]="Secret scanner"
  ["shellcheck"]="Shell script linter"

  # Media & Other
  ["neovim"]="Terminal text editor"
  ["ffmpeg"]="Media processing toolkit"
  ["hugo"]="Static site generator"
)

###############################################################################
# Helper functions
###############################################################################

# Resolve brew name to nix attribute name
resolve_nix_name() {
  local brew_name="$1"

  # Check explicit mapping first
  if [[ -v "BREW_TO_NIX[$brew_name]" ]]; then
    echo "${BREW_TO_NIX[$brew_name]}"
    return
  fi

  # Strip tap prefix (e.g., "hashicorp/tap/terraform" -> "terraform")
  local stripped="${brew_name##*/}"

  # Replace common patterns
  stripped="${stripped//@*/}"  # Remove version suffix (python@3.12 -> python)

  echo "$stripped"
}

# Get nix version for a package (empty string if not found)
get_nix_version() {
  local attr="$1"
  nix eval --raw "nixpkgs#${attr}.version" 2>/dev/null || echo ""
}

# Get brew version for a formula
get_brew_version() {
  local formula="$1"
  brew info "$formula" --json=v1 2>/dev/null | jq -r '.[0].versions.stable // empty' 2>/dev/null || echo ""
}

# Get description for a nix attr (use our table first, then fall back to generic)
get_description() {
  local nix_name="$1"
  local brew_name="$2"

  if [[ -v "DESCRIPTIONS[$nix_name]" ]]; then
    echo "${DESCRIPTIONS[$nix_name]}"
    return
  fi

  # Try to get from brew info
  local desc
  desc=$(brew info "$brew_name" --json=v1 2>/dev/null | jq -r '.[0].desc // empty' 2>/dev/null || echo "")
  if [[ -n "$desc" ]]; then
    # Truncate long descriptions
    if [[ ${#desc} -gt 60 ]]; then
      desc="${desc:0:57}..."
    fi
    echo "$desc"
    return
  fi

  echo "(no description)"
}

# Categorize a brew package
get_category() {
  local brew_name="$1"
  if [[ -v "CATEGORY_MAP[$brew_name]" ]]; then
    echo "${CATEGORY_MAP[$brew_name]}"
  else
    echo "media"  # Default to "Media & Other" as catch-all
  fi
}

###############################################################################
# Main audit logic
###############################################################################

echo "=== macsetup Package Audit ==="
echo "Scanning installed CLI tools on $(hostname)..."
echo ""

# ---- Collect brew leaves ----
echo "[1/6] Collecting Homebrew top-level formulae..."
mapfile -t BREW_LEAVES < <(brew leaves 2>/dev/null | sort)
echo "  Found ${#BREW_LEAVES[@]} brew leaves"

# ---- Scan /usr/local/bin ----
echo "[2/6] Scanning /usr/local/bin..."
USR_LOCAL_BINS=()
if [[ -d /usr/local/bin ]]; then
  mapfile -t USR_LOCAL_BINS < <(ls /usr/local/bin 2>/dev/null || true)
  echo "  Found ${#USR_LOCAL_BINS[@]} binaries"
else
  echo "  /usr/local/bin not found -- skipping"
fi

# ---- Scan ~/.local/bin ----
echo "[3/6] Scanning ~/.local/bin..."
LOCAL_BINS=()
if [[ -d "$HOME/.local/bin" ]]; then
  mapfile -t LOCAL_BINS < <(ls "$HOME/.local/bin" 2>/dev/null || true)
  echo "  Found ${#LOCAL_BINS[@]} binaries"
else
  echo "  ~/.local/bin not found -- skipping"
fi

# ---- npm globals ----
echo "[4/6] Collecting npm globals..."
NPM_GLOBALS=()
if command -v npm &>/dev/null; then
  mapfile -t NPM_GLOBALS < <(npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies // {} | keys[]' 2>/dev/null || true)
  echo "  Found ${#NPM_GLOBALS[@]} npm globals"
else
  echo "  npm not found -- skipping"
fi

# ---- pipx / pip user packages ----
echo "[5/6] Collecting Python globals (pipx/pip)..."
PIPX_PACKAGES=()
if command -v pipx &>/dev/null; then
  mapfile -t PIPX_PACKAGES < <(pipx list --short 2>/dev/null | awk '{print $1}' || true)
  echo "  Found ${#PIPX_PACKAGES[@]} pipx packages"
else
  echo "  pipx not found -- skipping"
fi

PIP_USER_PACKAGES=()
if command -v pip3 &>/dev/null; then
  mapfile -t PIP_USER_PACKAGES < <(pip3 list --user --format=json 2>/dev/null | jq -r '.[].name' 2>/dev/null || true)
  if [[ ${#PIP_USER_PACKAGES[@]} -gt 0 ]]; then
    echo "  Found ${#PIP_USER_PACKAGES[@]} pip user packages"
  fi
fi

# ---- Go binaries ----
echo "[6/6] Scanning ~/go/bin..."
GO_BINS=()
if [[ -d "$HOME/go/bin" ]]; then
  mapfile -t GO_BINS < <(ls "$HOME/go/bin" 2>/dev/null || true)
  echo "  Found ${#GO_BINS[@]} Go binaries"
else
  echo "  ~/go/bin not found -- skipping"
fi

echo ""
echo "=== Resolving nixpkgs attribute names and versions ==="
echo "(This may take a few minutes due to nix eval calls)"
echo ""

# ---- Process brew leaves ----
# Data storage: arrays keyed by category, each entry is a formatted line
declare -A CAT_ENTRIES
declare -a NOT_FOUND_ENTRIES

for cat in "${CATEGORY_ORDER[@]}"; do
  CAT_ENTRIES["$cat"]=""
done

total=${#BREW_LEAVES[@]}
count=0

for brew_name in "${BREW_LEAVES[@]}"; do
  count=$((count + 1))
  printf "\r  [%d/%d] %s                    " "$count" "$total" "$brew_name"

  nix_name=$(resolve_nix_name "$brew_name")
  nix_ver=$(get_nix_version "$nix_name")
  brew_ver=$(get_brew_version "$brew_name")
  desc=$(get_description "$nix_name" "$brew_name")
  category=$(get_category "$brew_name")

  if [[ -z "$nix_ver" ]]; then
    # Package not found in nixpkgs
    NOT_FOUND_ENTRIES+=("${brew_name} -> ${nix_name}  # ${desc} | brew=${brew_ver:-unknown} [NOT_FOUND]")
  else
    local_flag=""
    if [[ -n "$brew_ver" && "$nix_ver" != "$brew_ver" ]]; then
      local_flag=" [VERSION_DIFF]"
    fi
    entry="${nix_name}  # ${desc} | brew=${brew_ver:-unknown} nix=${nix_ver}${local_flag}"

    # Append to category
    if [[ -n "${CAT_ENTRIES[$category]:-}" ]]; then
      CAT_ENTRIES["$category"]="${CAT_ENTRIES[$category]}"$'\n'"$entry"
    else
      CAT_ENTRIES["$category"]="$entry"
    fi
  fi
done

printf "\r  Done processing %d brew leaves.                    \n" "$total"

# ---- Process Go binaries ----
echo ""
echo "=== Checking Go binaries ==="
GO_NIX_ENTRIES=()
GO_KEEP_ENTRIES=()

declare -A GO_NIX_MAP=(
  ["gopls"]="gopls"
  ["staticcheck"]="go-tools"
  ["gocritic"]="go-critic"
)

for gobin in "${GO_BINS[@]}"; do
  if [[ -v "GO_NIX_MAP[$gobin]" ]]; then
    nix_name="${GO_NIX_MAP[$gobin]}"
    nix_ver=$(get_nix_version "$nix_name")
    if [[ -n "$nix_ver" ]]; then
      desc="${DESCRIPTIONS[$nix_name]:-Go binary: $gobin}"
      GO_NIX_ENTRIES+=("${nix_name}  # ${desc} | nix=${nix_ver} (currently via go install)")
      echo "  $gobin -> $nix_name (nix=$nix_ver) -- recommend Nix"
    else
      GO_KEEP_ENTRIES+=("$gobin  # Go binary | currently via go install [NOT_IN_NIXPKGS]")
      echo "  $gobin -> not in nixpkgs -- keep in Go"
    fi
  else
    GO_KEEP_ENTRIES+=("$gobin  # Go binary | currently via go install")
    echo "  $gobin -> no known mapping -- keep in Go"
  fi
done

# ---- Process npm globals ----
echo ""
echo "=== Checking npm globals ==="
NPM_NIX_ENTRIES=()
NPM_KEEP_ENTRIES=()

for pkg in "${NPM_GLOBALS[@]}"; do
  # Skip npm itself
  [[ "$pkg" == "npm" ]] && continue

  # Check if available in nixpkgs
  nix_ver=$(get_nix_version "$pkg")
  if [[ -n "$nix_ver" ]]; then
    NPM_NIX_ENTRIES+=("${pkg}  # npm global | nix=${nix_ver} -- available in nixpkgs, consider moving")
    echo "  $pkg -> available in nixpkgs (nix=$nix_ver)"
  else
    NPM_KEEP_ENTRIES+=("$pkg  # npm global | manage with npm/pnpm")
    echo "  $pkg -> not in nixpkgs -- keep in npm"
  fi
done

# ---- Process pipx packages ----
echo ""
echo "=== Checking pipx packages ==="
PIPX_NIX_ENTRIES=()
PIPX_KEEP_ENTRIES=()

for pkg in "${PIPX_PACKAGES[@]}"; do
  nix_name="${pkg//-/_}"  # basic transform
  nix_ver=$(get_nix_version "$pkg")
  if [[ -z "$nix_ver" ]]; then
    nix_ver=$(get_nix_version "$nix_name")
  fi

  if [[ -n "$nix_ver" ]]; then
    PIPX_NIX_ENTRIES+=("${pkg}  # pipx package | nix=${nix_ver} -- available in nixpkgs, consider moving")
    echo "  $pkg -> available in nixpkgs (nix=$nix_ver)"
  else
    PIPX_KEEP_ENTRIES+=("$pkg  # pipx package | manage with pipx/uv")
    echo "  $pkg -> not in nixpkgs -- keep in pipx"
  fi
done

# ---- Check /usr/local/bin and ~/.local/bin for noteworthy non-brew tools ----
echo ""
echo "=== Checking other binary locations ==="

OTHER_BINS_ENTRIES=()

# /usr/local/bin -- filter out things managed by other tools
for bin in "${USR_LOCAL_BINS[@]}"; do
  # Skip scripts and known managed items
  case "$bin" in
    uninstall-*|*.sh) continue ;;
    code-insiders|cursor|cursor-vip) continue ;;  # IDE launchers
    determinate-nixd) continue ;;  # Nix installer
    multipass|super|tailscale) ;;  # Worth noting
    container|container-apiserver) continue ;;  # Docker internals
    *) continue ;;
  esac
  OTHER_BINS_ENTRIES+=("$bin  # /usr/local/bin | not managed by Homebrew")
done

# ~/.local/bin
for bin in "${LOCAL_BINS[@]}"; do
  case "$bin" in
    claude) continue ;;  # Managed by Anthropic
    copier|nlm) continue ;;  # Managed by pipx/other
    *-mcp*|*mcp-*) continue ;;  # MCP servers -- managed separately
    *) OTHER_BINS_ENTRIES+=("$bin  # ~/.local/bin | user-installed binary") ;;
  esac
done

###############################################################################
# Generate PACKAGE-REVIEW.md
###############################################################################

echo ""
echo "=== Generating PACKAGE-REVIEW.md ==="

{
cat <<HEADER
# Package Review - macsetup

**Generated:** ${DATE}
**Source Mac:** ${HOSTNAME}
**Brew leaves:** ${#BREW_LEAVES[@]}
**npm globals:** ${#NPM_GLOBALS[@]}
**pipx packages:** ${#PIPX_PACKAGES[@]}
**Go binaries:** ${#GO_BINS[@]}

## Instructions

Review each section below. For each line:
- **Keep it** to include in your Nix configuration
- **Delete it** if you don't want it
- Lines marked \`[NOT_FOUND]\` are not available in nixpkgs -- decide to keep in brew, find alternative, or drop
- Lines marked \`[VERSION_DIFF]\` show different versions between brew and nix -- check if the difference matters to you

After editing, this file feeds into the next plan which populates \`modules/home/packages.nix\`.

---

## Packages for Nix (home.packages)

HEADER

# Write each category
for cat in "${CATEGORY_ORDER[@]}"; do
  cat_name="${CATEGORY_NAMES[$cat]}"
  entries="${CAT_ENTRIES[$cat]:-}"

  if [[ -n "$entries" ]]; then
    echo "### ${cat_name}"
    echo ""
    echo "\`\`\`"
    echo "$entries"
    echo "\`\`\`"
    echo ""
  fi
done

# Add Go binaries that should move to Nix
if [[ ${#GO_NIX_ENTRIES[@]} -gt 0 ]]; then
  echo "### Go Binaries (recommend moving to Nix)"
  echo ""
  echo "\`\`\`"
  for entry in "${GO_NIX_ENTRIES[@]}"; do
    echo "$entry"
  done
  echo "\`\`\`"
  echo ""
fi

# Add npm packages that are in nixpkgs
if [[ ${#NPM_NIX_ENTRIES[@]} -gt 0 ]]; then
  echo "### npm Globals (available in nixpkgs)"
  echo ""
  echo "\`\`\`"
  for entry in "${NPM_NIX_ENTRIES[@]}"; do
    echo "$entry"
  done
  echo "\`\`\`"
  echo ""
fi

# Add pipx packages that are in nixpkgs
if [[ ${#PIPX_NIX_ENTRIES[@]} -gt 0 ]]; then
  echo "### pipx Packages (available in nixpkgs)"
  echo ""
  echo "\`\`\`"
  for entry in "${PIPX_NIX_ENTRIES[@]}"; do
    echo "$entry"
  done
  echo "\`\`\`"
  echo ""
fi

cat <<ECOSYSTEM

---

## Packages to Keep in Ecosystem

These tools are managed by their respective ecosystems. They either don't exist
in nixpkgs or are better managed by their native package manager.

ECOSYSTEM

if [[ ${#NPM_KEEP_ENTRIES[@]} -gt 0 ]]; then
  echo "### npm globals (manage with npm/pnpm)"
  echo ""
  echo "\`\`\`"
  for entry in "${NPM_KEEP_ENTRIES[@]}"; do
    echo "$entry"
  done
  echo "\`\`\`"
  echo ""
fi

if [[ ${#PIPX_KEEP_ENTRIES[@]} -gt 0 ]]; then
  echo "### pipx globals (manage with pipx/uv)"
  echo ""
  echo "\`\`\`"
  for entry in "${PIPX_KEEP_ENTRIES[@]}"; do
    echo "$entry"
  done
  echo "\`\`\`"
  echo ""
fi

if [[ ${#GO_KEEP_ENTRIES[@]} -gt 0 ]]; then
  echo "### Go binaries (manage with go install)"
  echo ""
  echo "\`\`\`"
  for entry in "${GO_KEEP_ENTRIES[@]}"; do
    echo "$entry"
  done
  echo "\`\`\`"
  echo ""
fi

if [[ ${#OTHER_BINS_ENTRIES[@]} -gt 0 ]]; then
  echo "### Other binaries (/usr/local/bin, ~/.local/bin)"
  echo ""
  echo "\`\`\`"
  for entry in "${OTHER_BINS_ENTRIES[@]}"; do
    echo "$entry"
  done
  echo "\`\`\`"
  echo ""
fi

cat <<NOTFOUND

---

## Not Found in nixpkgs

These Homebrew formulae have no known nixpkgs equivalent. Options:
- Keep installed via Homebrew (managed by nix-homebrew in Phase 6)
- Find a nixpkgs alternative
- Drop if no longer needed

NOTFOUND

if [[ ${#NOT_FOUND_ENTRIES[@]} -gt 0 ]]; then
  echo "\`\`\`"
  for entry in "${NOT_FOUND_ENTRIES[@]}"; do
    echo "$entry"
  done
  echo "\`\`\`"
else
  echo "All packages were found in nixpkgs."
fi

echo ""
echo "---"
echo "*Generated by scripts/audit-packages.sh*"

} > "$REVIEW_FILE"

echo ""
echo "=== Audit Complete ==="
echo "Review file: $REVIEW_FILE"
echo ""
echo "Summary:"
echo "  Brew leaves:      ${#BREW_LEAVES[@]}"
echo "  Found in nixpkgs: $((${#BREW_LEAVES[@]} - ${#NOT_FOUND_ENTRIES[@]}))"
echo "  Not found:        ${#NOT_FOUND_ENTRIES[@]}"
echo "  npm globals:      ${#NPM_GLOBALS[@]}"
echo "  pipx packages:    ${#PIPX_PACKAGES[@]}"
echo "  Go binaries:      ${#GO_BINS[@]}"
echo ""
echo "Next steps:"
echo "  1. Open $REVIEW_FILE"
echo "  2. Review each section -- delete what you don't want"
echo "  3. Run 02-02-PLAN.md to populate packages.nix from your edits"
