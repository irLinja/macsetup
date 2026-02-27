# Example host configuration -- copy this to create your own host file.
#
# Usage:
#   1. Copy: cp hosts/example.nix hosts/$(hostname -s).nix
#   2. Edit: Choose your profile, add/remove packages
#   3. Build: sudo darwin-rebuild switch --flake .#$(hostname -s)
#
# The config name matches the filename (without .nix extension).
{ inputs, userConfig, pkgs, lib, ... }: {
  imports = [
    ../profiles/personal          # or ../profiles/work
    ../modules/darwin
    ../modules/optional/1password.nix
  ];

  # System identity (from user.nix)
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

  # Declarative Homebrew (nix-homebrew)
  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = userConfig.username;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      # Add custom taps here (must also be in flake.nix inputs):
      # "peonping/homebrew-tap" = inputs.homebrew-peonping;
    };
  };

  # -- Host-specific overrides -----------------------------------------
  # Add packages on top of your profile's defaults:
  # home-manager.users.${userConfig.username}.home.packages = with pkgs; [
  #   mongosh
  # ];

  # Override Dock apps for this machine:
  # system.defaults.dock.persistent-apps = [
  #   "/Applications/Arc.app"
  #   "/Applications/Ghostty.app"
  # ];
}
