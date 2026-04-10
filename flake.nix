{
  description = "macsetup -- declarative macOS setup with nix-darwin and Home Manager";

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

    # -- Archived inputs (Phase 8: migrated GUI apps to Homebrew cask) --
    # nix-casks = {
    #   url = "github:atahanyorganci/nix-casks/archive";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

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
    homebrew-boredteam = {
      url = "github:TheBoredTeam/homebrew-boring-notch";
      flake = false;
    };

    # mac-app-util.url = "github:hraban/mac-app-util";

  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nix-homebrew, ... }:
  let
    lib = nixpkgs.lib;
    userConfig = import ./user.nix;

    # Auto-discover host files in hosts/ (excluding example.nix and shared.nix)
    # Each .nix file becomes a darwinConfiguration named after the file (sans .nix)
    hostFiles = lib.filterAttrs
      (name: type:
        type == "regular"
        && lib.hasSuffix ".nix" name
        && name != "default.nix"
        && name != "example.nix"
        && name != "shared.nix"    # handled by legacy macsetup entry below
      )
      (builtins.readDir ./hosts);

    mkDarwinConfig = fileName:
      nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs userConfig; };
        modules = [
          ./hosts/${fileName}
          home-manager.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
        ];
      };

    # Auto-discovered hosts (filename without .nix -> config)
    autoConfigs = lib.mapAttrs'
      (name: _: lib.nameValuePair (lib.removeSuffix ".nix" name) (mkDarwinConfig name))
      hostFiles;
  in {
    darwinConfigurations = {
      # Legacy entry -- keeps `darwin-rebuild switch --flake .#macsetup` working
      macsetup = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs userConfig; };
        modules = [
          ./hosts/shared.nix
          home-manager.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
        ];
      };
    } // autoConfigs;
  };
}
