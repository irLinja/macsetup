{ ... }: {
  imports = [
    ./packages.nix
    ./shell.nix
    ./starship.nix
    ./git.nix
    ./dotfiles.nix
  ];

  # Home Manager state version (latest stable).
  home.stateVersion = "25.11";

  # Tolerate transient version skew while Home Manager master catches up to
  # nixpkgs-unstable after a release bump (e.g. nixpkgs 26.11 / HM 26.05).
  home.enableNixpkgsReleaseCheck = false;

  # Required for user-level shell hooks and PATH integration.
  programs.zsh.enable = true;
}
