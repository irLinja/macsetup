{ lib, ... }: {
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
    "ytmdesktop-youtube-music"

    # Internet
    "arc"

    # Utilities
    "transmission"
  ];
}
