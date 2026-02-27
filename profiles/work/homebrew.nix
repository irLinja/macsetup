{ lib, ... }: {
  # -- Custom taps (if your work uses private Homebrew taps) ---------------
  # To add a custom tap, you must ALSO add a flake input in flake.nix.
  # Step 1: Add to flake.nix inputs:
  #   homebrew-acme = { url = "github:acme/homebrew-tap"; flake = false; };
  # Step 2: Pass to nix-homebrew.taps in your host file:
  #   "acme/homebrew-tap" = inputs.homebrew-acme;
  # Step 3: Then declare brews/casks from it here:
  #   homebrew.brews = lib.mkDefault [ "acme/tap/sometool" ];
  # -----------------------------------------------------------------------

  homebrew.casks = lib.mkDefault [
    # Terminal & Development
    "ghostty"
    "visual-studio-code"
    "rancher"
    "headlamp"

    # Productivity
    "raycast"
    "notion"
    "microsoft-outlook"
    "microsoft-teams"
    "miro"

    # Communication
    "slack"

    # Internet
    "arc"
  ];

  homebrew.brews = lib.mkDefault [
    # Cloud & Infrastructure (all from standard homebrew-core)
    "awscli"
    "azure-cli"
    "terraform"
    "terraform-docs"
    "tflint"
    "checkov"

    # Kubernetes
    "helm"
    "kubectl-ai"
    "kubectx"
    "k9s"
    "stern"
    "kind"
  ];
}
