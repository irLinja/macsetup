{
  description = "macsetup - declarative macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Phase 6: GUI application channels
    nix-casks = {
      url = "github:atahanyorganci/nix-casks/archive";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Homebrew tap sources (required for mutableTaps = false)
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-peonping = {
      url = "github:PeonPing/homebrew-tap";
      flake = false;
    };
    homebrew-tfversion = {
      url = "github:tfversion/homebrew-tap";
      flake = false;
    };

    mac-app-util.url = "github:hraban/mac-app-util";

  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nix-casks, nix-homebrew, mac-app-util, ... }: {
    darwinConfigurations.macsetup = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/shared.nix
        home-manager.darwinModules.default
        nix-homebrew.darwinModules.nix-homebrew
        mac-app-util.darwinModules.default
        {
          # mac-app-util for Home Manager (Spotlight integration for NixCasks apps)
          home-manager.sharedModules = [
            mac-app-util.homeManagerModules.default
          ];
        }
      ];
    };
  };
}
