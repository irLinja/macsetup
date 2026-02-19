{ ... }: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";  # Switch to "zap" after verifying all desired apps are declared
    };

    taps = [
      "peonping/tap"
      "tfversion/tap"
    ];

    casks = [
      # -- Productivity --
      "microsoft-outlook"         # Microsoft Outlook email client
      "microsoft-teams"           # Microsoft Teams communication
      "miro"                      # Miro collaborative whiteboard

      # -- Media --
      "spotify"                   # Music streaming

      # -- Security --
      "openvpn-connect"           # OpenVPN client
      "yubico-authenticator"      # YubiKey Authenticator (replaces discontinued YubiKey Manager)

      # -- Utilities --
      "ledger-wallet"             # Ledger hardware wallet manager
      "tailscale-app"             # Tailscale mesh VPN
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
      "kubelogin"                 # Azure K8s credential plugin
      "checkov"                   # IaC static analysis / security scanner
      "terraform"                 # Infrastructure as Code
      "vault"                     # HashiCorp Vault secret management
      "terraform-docs"            # Terraform documentation generator
      "terraform-mcp-server"      # MCP server for Terraform
      "tflint"                    # Terraform linter

      # -- Kubernetes --
      "helm"                      # Helm package manager for K8s
      "k8sgpt"                    # AI-powered K8s diagnostics
      "k9s"                       # Terminal UI for K8s clusters
      "kind"                      # Kubernetes in Docker (local clusters)
      "kubebuilder"               # K8s operator SDK
      "kubectl-ai"                # AI-powered Kubernetes assistant
      "kubectx"                   # Switch kubectl contexts/namespaces
      "stern"                     # Multi-pod log tailing for K8s

      # -- Tap Packages --
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
      # "shellcheck"              # Shell script linter
      # "trivy"                   # Container/IaC vulnerability scanner
      # "trufflehog"              # Secret scanner
      # "mongosh"                 # MongoDB shell
      # "renovate"                # Automated dependency updates
      # "yq"                      # YAML/JSON/XML processor
      # "gitversion"              # Easy semantic versioning for projects using Git
    ];
  };
}
