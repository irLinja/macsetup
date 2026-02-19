{ inputs, pkgs, ... }: {
  imports = [ ../modules/darwin ];

  # Primary user identity (hardcoded per user decision)
  system.primaryUser = "arash";

  users.users.arash = {
    name = "arash";
    home = "/Users/arash";
  };

  # Home Manager integration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.backupFileExtension = "backup";
  home-manager.users.arash = import ../modules/home;

  # Declarative Homebrew management via nix-homebrew
  nix-homebrew = {
    enable = true;
    enableRosetta = false;          # Apple Silicon only, no x86_64 emulation needed
    user = "arash";                 # Must match system.primaryUser
    autoMigrate = true;             # Migrate existing /opt/homebrew to managed state
    mutableTaps = true;             # Allow existing taps (autoMigrate conflicts with false)
  };
}
