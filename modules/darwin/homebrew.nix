{ ... }: {
  # Tap trust: Homebrew refuses to load formulae/casks from non-official taps
  # that have not been trusted. nix-darwin writes every `brews`/`casks` entry
  # below into the Brewfile as `trusted: true`, and `brew bundle` records those
  # in ~/.homebrew/trust.json before it loads anything (`--force-cleanup` then
  # rewrites the file to exactly the Brewfile's entries). A fully-qualified tap
  # entry ("ariga/tap/atlas") therefore needs no extra step, on fresh machines
  # too. Do not bring back HOMEBREW_NO_REQUIRE_TAP_TRUST: brew 7 deprecated it
  # (a warning on every brew run), and it switched the check off for every tap,
  # not just these. If XDG_CONFIG_HOME is ever exported, interactive brew reads
  # $XDG_CONFIG_HOME/homebrew/trust.json, which activation (sudo, clean
  # environment) never writes.
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      # Upgrades run from `macsetup rebuild/update` after activation instead
      # (finish_switch in ./macsetup), as ONE `brew upgrade` process. Every
      # `brew` start revokes sudo approvals (brew.sh: sudo --reset-timestamp)
      # and `brew bundle` starts one brew per cask, so every cask with a root
      # installer (microsoft-outlook, microsoft-teams, gcloud-cli,
      # openvpn-connect, temurin@25, ...) asked for sudo again. A bare
      # `darwin-rebuild switch` therefore installs and removes packages but
      # never upgrades them.
      upgrade = false;
      # "zap": undeclared formulae/casks are REMOVED on every activation (casks
      # get `brew uninstall --zap`, which wipes their app data too) -- ad-hoc
      # `brew install`s do not survive a rebuild.
      #
      # History: Homebrew 6.0 turned `brew bundle --cleanup` (zap's old
      # mechanism) into a dry-run no-op, so this was `cleanup = "check"`
      # (abort-on-undeclared) from 2026-07 to 2026-08. Current nix-darwin
      # passes `--zap --force-cleanup` instead, which the pinned brew
      # (>= 6.0.16) executes for real -- verified in both pinned sources.
      # Taps referenced by Brewfile entries (ariga, fluxcd, ...) are never
      # untapped; the declared taps below cover the remainder.
      cleanup = "zap";
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
      "bruno"                       # Open-source API client (Postman alternative)
      "dbeaver-community"           # Universal database GUI client
      "gcloud-cli"                  # Google Cloud CLI (gcloud, gsutil, bq)
      "ghostty"                     # GPU-accelerated terminal emulator
      "headlamp"                    # Kubernetes web UI
      "kotlin-lsp"                  # Official Kotlin Language Server (JetBrains; needs JDK -> temurin@25)
      "rancher"                     # Rancher Desktop (container management)
      "session-manager-plugin"      # AWS SSM Session Manager plugin for the AWS CLI (root pkg installer)
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
      # "ytmdesktop-youtube-music" -- disabled 2026-09-01 (fails Gatekeeper) and stuck at 2.0.11; nixpkgs ytmdesktop instead (modules/darwin/packages.nix)

      # -- Security --
      "1password"                   # Password manager (must be in /Applications for SSH agent)
      "1password-cli"               # 1Password command-line tool (op)
      "openvpn-connect"             # OpenVPN client
      "shadowsocksx-ng"             # ShadowsocksX-NG proxy -- cask disabled 2026-09-01 (fails Gatekeeper), kept on purpose: brew keeps the installed 1.10.3 but refuses to install it on a new Mac
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
      "pulumi"                    # Infrastructure as Code in general-purpose languages
      # "terraform" -- not in homebrew-core (hashicorp/tap only); tfversion (Tap Packages) manages it, and a brew copy shadows ~/.tfversion/bin in interactive shells
      "terraform-docs"            # Terraform documentation generator
      "terraform-mcp-server"      # MCP server for Terraform
      "tflint"                    # Terraform linter

      # -- Kubernetes --
      "cilium-cli"                # Cilium CNI CLI
      "clusterctl"                # Cluster API management CLI
      "helm"                      # Helm package manager for K8s
      "hubble"                    # Cilium network observability
      "k8sgpt"                    # AI-powered K8s diagnostics
      "k9s"                       # Terminal UI for K8s clusters
      "kind"                      # Kubernetes in Docker (local clusters)
      "kubebuilder"               # K8s operator SDK
      "kubeconform"               # K8s manifest schema validator
      "kubernetes-cli"             # kubectl - Kubernetes CLI
      "kubectl-ai"                # AI-powered Kubernetes assistant
      "kubectx"                   # Switch kubectl contexts/namespaces
      "kubescape"                 # K8s security scanner
      "kyverno"                   # K8s policy engine CLI
      "popeye"                    # K8s cluster resource sanitizer
      "stern"                     # Multi-pod log tailing for K8s
      "talosctl"                  # Talos Linux cluster management CLI
      "watch"                     # Execute a program periodically

      # -- Containers --
      "container"                 # Apple Containers CLI
      "crane"                     # Container image copy/inspect tool

      # -- Git / VCS --
      "glab"                      # GitLab CLI

      # -- Languages & Build Tools --
      "gradle"                    # JVM build automation tool (Groovy/Kotlin DSL)

      # -- Databases --
      "mysql-client"              # MySQL CLI (keg-only: mysql is not linked into /opt/homebrew/bin)

      # -- macOS --
      "terminal-notifier"         # macOS notification CLI -- on brew (bottled), not nixpkgs: cctools ld SIGTRAPs linking it from source on the current nixpkgs pin

      # -- Security --
      "age"                       # Simple, modern file encryption (age, age-keygen)

      # -- Linting & Code Generation --
      "actionlint"                # GitHub Actions workflow linter
      "golangci-lint"             # Go linter aggregator
      "shellcheck"                # Shell script linter
      "sqlc"                      # Generate type-safe code from SQL
      "yamllint"                  # YAML linter

      # -- Tap Packages --
      "ariga/tap/atlas"           # Atlas database schema migration tool
      "cloudflare/cloudflare/cf-terraforming"  # Import Cloudflare resources into Terraform/OpenTofu
      "fluxcd/tap/flux"           # FluxCD GitOps toolkit CLI for K8s (tap-only, not in core)
      "peonping/tap/peon-ping"    # Sound effects and desktop notifications for AI coding agents
      "tfversion/tap/tfversion"   # Manage Terraform versions

      # -- Shelved (uncomment to enable) --
      # "bicep"                   # Bicep template language for Azure
      # "powerpipe"               # DevOps dashboards / cloud visualization
      # "steampipe"               # APIs as SQL / cloud querying
      # "terraformer"             # Generate Terraform from existing infrastructure
      # "clusterctl"              # Cluster API management tool
      # "istioctl"                # Istio service mesh CLI
      # "kubent"                  # K8s API deprecation checker
      # "krr"                     # K8s Resource Recommender by Robusta
      # "skopeo"                  # Container image operations
      "trivy"                    # Container/IaC vulnerability scanner
      "trufflehog"               # Secret scanner
      # "mongosh"                 # MongoDB shell -- now installed from nixpkgs (modules/home/packages.nix)
      # "renovate"                # Automated dependency updates
      "yq"                        # YAML/JSON/XML processor
      # "gitversion"              # Easy semantic versioning for projects using Git
    ];
  };
}
