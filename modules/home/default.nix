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

  # Required for user-level shell hooks and PATH integration.
  programs.zsh.enable = true;
}
