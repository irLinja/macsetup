# FYMX72C301 -- work machine (Just Eat Takeaway)
{ inputs, userConfig, pkgs, lib, ... }:
let
  hostUserConfig = userConfig // { username = "arash.haghighat"; };
in {
  imports = [
    ../profiles/work
    ../modules/darwin
    ../modules/optional/1password.nix
  ];

  # System identity (overridden for this host)
  system.primaryUser = hostUserConfig.username;

  users.users.${hostUserConfig.username} = {
    name = hostUserConfig.username;
    home = "/Users/${hostUserConfig.username}";
  };

  # Home Manager integration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; userConfig = hostUserConfig; };
  home-manager.backupFileExtension = "backup";
  home-manager.users.${hostUserConfig.username} = import ../modules/home;

  # Declarative Homebrew (nix-homebrew)
  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = hostUserConfig.username;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "peonping/homebrew-tap" = inputs.homebrew-peonping;
      "tfversion/homebrew-tap" = inputs.homebrew-tfversion;
      "theboredteam/homebrew-boring-notch" = inputs.homebrew-boredteam;
    };
  };

  # -- Host-specific overrides -----------------------------------------
  # Add packages on top of your profile's defaults:
  # home-manager.users.${hostUserConfig.username}.home.packages = with pkgs; [
  #   mongosh
  # ];
}
