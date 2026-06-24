{ ... }: {
  # Homebrew 6.0 makes tap-trust checks the default (HOMEBREW_REQUIRE_TAP_TRUST),
  # refusing to load formulae/casks from non-official taps until `brew trust` has
  # been run interactively. That breaks `brew bundle` during activation for our
  # third-party taps (ariga, peonping, tfversion, theboredteam) -- e.g.
  # "Refusing to load formula ariga/tap/atlas from untrusted tap ariga/tap".
  #
  # Those taps are pinned flake inputs managed by nix-homebrew with
  # `mutableTaps = false`, so their provenance is already locked and an
  # interactive per-tap trust prompt is redundant friction. Disable the
  # requirement via Homebrew's system-wide env file.
  #
  # /etc/homebrew/brew.env is sourced first by `brew` (before the prefix/user env
  # files) and is materialised by nix-darwin's /etc activation BEFORE the Homebrew
  # bundle step, so it takes effect on the first rebuild and on fresh machines.
  # (A Home Manager file would be written only AFTER `brew bundle` runs -- too
  # late, and the bundle failure aborts activation under `set -e`.)
  environment.etc."homebrew/brew.env".text = ''
    HOMEBREW_NO_REQUIRE_TAP_TRUST=1
  '';

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Homebrew 6.0 deprecated `brew bundle --cleanup` (used by "zap"/"uninstall")
      # and made it a dry-run no-op. "check" uses the modern `brew bundle cleanup`
      # subcommand instead: no deprecation warning, and it FAILS activation when
      # undeclared formulae/casks/mas apps exist (it does not auto-remove them).
      # Prune the reported items with `brew bundle cleanup --force`.
      cleanup = "check";
    };

    # Tap sources are managed by nix-homebrew (hosts/shared.nix).
    # Declare them here so cleanup = "zap" doesn't try to untap them.
    # Custom taps (peonping, tfversion) are omitted — Homebrew finds them
    # via nix-homebrew symlinks without needing an explicit tap entry.
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
      "theboredteam/boring-notch"
    ];

    casks = [
      # -- AI / Development --
      "chatgpt"                     # ChatGPT desktop app
      "claude"                      # Claude Desktop

      # -- Development --
      "dbeaver-community"           # Universal database GUI client
      "gcloud-cli"                  # Google Cloud CLI (gcloud, gsutil, bq)
      "ghostty"                     # GPU-accelerated terminal emulator
      "headlamp"                    # Kubernetes web UI
      "kotlin-lsp"                  # Official Kotlin Language Server (JetBrains; needs JDK -> temurin@25)
      "rancher"                     # Rancher Desktop (container management)
      "temurin@25"                  # Eclipse Temurin JDK 25 (Adoptium)
      "visual-studio-code"          # Code editor

      # -- Productivity --
      "linear"                      # Linear issue tracker desktop app
      "microsoft-outlook"           # Microsoft Outlook email client
      "microsoft-teams"             # Microsoft Teams communication
      "miro"                        # Miro collaborative whiteboard
      "notion"                      # Notes and wiki
      "raycast"                     # Spotlight replacement / launcher

      # -- Communication --
      "slack"                       # Team messaging
      "telegram"                    # Messaging
      "whatsapp"                    # Messaging

      # -- Media --
      "iina"                        # Media player
      "spotify"                     # Music streaming
      "ytmdesktop-youtube-music"    # YouTube Music desktop client

      # -- Security --
      "1password"                   # Password manager (must be in /Applications for SSH agent)
      "1password-cli"               # 1Password command-line tool (op)
      "openvpn-connect"             # OpenVPN client
      "shadowsocksx-ng"             # ShadowsocksX-NG proxy
      "yubico-authenticator"        # YubiKey Authenticator

      # -- Internet --
      "arc"                         # Arc browser

      # -- Utilities --
      "ledger-wallet"               # Ledger hardware wallet manager
      "monitorcontrol"              # Monitor brightness/volume control
      "thaw"                        # Menu bar manager
      "theboredteam/boring-notch/boring-notch"  # Dynamic notch utility
      "qflipper"                    # Flipper Zero companion app
      "transmission"                # BitTorrent client

      # -- Shelved (uncomment to enable) --
      # "betterdisplay"             # Display management
      # "surfshark"                 # VPN client (SSL errors on corporate networks)
      # "zen"                       # Zen browser
    ];

    masApps = {
      # -- Productivity --
      "Amphetamine" = 937984704;

      # -- Security --
      "1Password for Safari" = 1569813296;
      "WireGuard" = 1451685025;

      # -- Utilities --
      "The Unarchiver" = 425424353;
    };

    brews = [
      # -- Cloud & Infrastructure --
      "ansible"                   # Configuration management / automation
      "awscli"                    # AWS CLI v2
      "azure-cli"                 # Azure CLI
      "googleworkspace-cli"       # CLI for Drive, Gmail, Calendar, Sheets, Docs, Chat, Admin

      "kubelogin"                 # Azure K8s credential plugin
      "checkov"                   # IaC static analysis / security scanner
      "opentofu"                  # Open-source Terraform alternative
      "terraform"                 # Infrastructure as Code
      "terraform-docs"            # Terraform documentation generator
      "terraform-mcp-server"      # MCP server for Terraform
      "tflint"                    # Terraform linter

      # -- Kubernetes --
      "helm"                      # Helm package manager for K8s
      "k8sgpt"                    # AI-powered K8s diagnostics
      "k9s"                       # Terminal UI for K8s clusters
      "kind"                      # Kubernetes in Docker (local clusters)
      "kubebuilder"               # K8s operator SDK
      "kubernetes-cli"             # kubectl - Kubernetes CLI
      "kubectl-ai"                # AI-powered Kubernetes assistant
      "kubectx"                   # Switch kubectl contexts/namespaces
      "stern"                     # Multi-pod log tailing for K8s
      "watch"                     # Execute a program periodically

      # -- Containers --
      "container"                 # Apple Containers CLI

      # -- Git / VCS --
      "glab"                      # GitLab CLI

      # -- Languages & Build Tools --
      "gradle"                    # JVM build automation tool (Groovy/Kotlin DSL)

      # -- Linting & Code Generation --
      "actionlint"                # GitHub Actions workflow linter
      "golangci-lint"             # Go linter aggregator
      "shellcheck"                # Shell script linter
      "sqlc"                      # Generate type-safe code from SQL
      "yamllint"                  # YAML linter

      # -- Tap Packages --
      "ariga/tap/atlas"           # Atlas database schema migration tool
      "peonping/tap/peon-ping"    # Sound effects and desktop notifications for AI coding agents
      "tfversion/tap/tfversion"   # Manage Terraform versions

      # -- Shelved (uncomment to enable) --
      # "bicep"                   # Bicep template language for Azure
      # "powerpipe"               # DevOps dashboards / cloud visualization
      # "steampipe"               # APIs as SQL / cloud querying
      # "terraformer"             # Generate Terraform from existing infrastructure
      # "cilium-cli"              # Cilium CNI CLI
      # "clusterctl"              # Cluster API management tool
      # "fluxcd"                  # GitOps toolkit for K8s
      # "hubble"                  # Cilium network observability
      # "istioctl"                # Istio service mesh CLI
      # "kubent"                  # K8s API deprecation checker
      # "kubescape"               # K8s security scanner
      # "kyverno"                 # K8s policy engine CLI
      # "popeye"                  # K8s cluster resource sanitizer
      # "krr"                     # K8s Resource Recommender by Robusta
      # "skopeo"                  # Container image operations
      "trivy"                    # Container/IaC vulnerability scanner
      "trufflehog"               # Secret scanner
      # "mongosh"                 # MongoDB shell
      # "renovate"                # Automated dependency updates
      "yq"                        # YAML/JSON/XML processor
      # "gitversion"              # Easy semantic versioning for projects using Git
    ];
  };
}
