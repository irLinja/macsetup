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
}
