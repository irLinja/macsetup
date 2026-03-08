{ lib, ... }: {
  homebrew.brews = lib.mkDefault [
    "watch"
  ];

  homebrew.casks = lib.mkDefault [
    # Terminal & Development
    "ghostty"
    "visual-studio-code"
    "rancher"

    # Productivity
    "raycast"
    "notion"

    # Communication
    "slack"
    "telegram"
    "whatsapp"

    # Media
    "spotify"
    "iina"

    # Internet
    "arc"

    # Utilities
    "transmission"
  ];
}
