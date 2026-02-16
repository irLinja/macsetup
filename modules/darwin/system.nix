{ ... }: {
  # Determinate Systems installer manages the Nix daemon and store,
  # so nix-darwin must not attempt to manage it.
  nix.enable = false;

  # State version for nix-darwin (6 is current for new installations).
  system.stateVersion = 6;

  # Apple Silicon only (per user decision -- no Intel support needed).
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Required for nix-darwin PATH integration and shell hook support.
  programs.zsh.enable = true;
}
