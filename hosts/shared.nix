{ inputs, userConfig, pkgs, ... }: {
  imports = [ ../modules/darwin ];

  # Primary user identity (from user.nix)
  system.primaryUser = userConfig.username;

  users.users.${userConfig.username} = {
    name = userConfig.username;
    home = "/Users/${userConfig.username}";
  };

  # Home Manager integration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs userConfig; };
  home-manager.backupFileExtension = "backup";
  home-manager.users.${userConfig.username} = import ../modules/home;

  # Declarative Homebrew management via nix-homebrew
  nix-homebrew = {
    enable = true;
    enableRosetta = false;          # Apple Silicon only, no x86_64 emulation needed
    user = userConfig.username;      # Must match system.primaryUser (from user.nix)
    mutableTaps = false;            # Undeclared taps are removed — fully declarative
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "peonping/homebrew-tap" = inputs.homebrew-peonping;
      "tfversion/homebrew-tap" = inputs.homebrew-tfversion;
    };
  };
}
