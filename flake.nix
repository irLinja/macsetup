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

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src.follows = "brew-src";
    };

    # Homebrew itself -- must be new enough for the DSL used by the taps below
    # (nix-homebrew's own pin can lag); bump this tag when a cask or formula
    # is "unreadable" (`unknown keyword`, `undefined method ... for an instance
    # of Symbol`). 2026-10-21: homebrew-core started declaring test-only
    # resources (`resource "x", :test do`, new in brew 7.0.9); 7.0.4 took :test
    # for the resource class and died on `:test.new`. 7.0.4 -> 7.0.10.
    # 2026-11-03: homebrew-cask started writing `zap :not_required` (47 casks);
    # `Zap.from_args(cask, **directives)` before 7.0.11 took the symbol as a
    # second positional argument: `Cask 'kotlin-lsp' definition is invalid:
    # invalid 'zap' stanza: wrong number of arguments (given 2, expected 1)`
    # and activation aborted. 7.0.10 -> 7.0.12.
    #
    # nix-homebrew also copies the tail of its own release's bin/brew into the
    # wrapper it generates, so this release must have the same tail or every
    # Ruby-backed brew command dies during activation (2026-09-22: brew 6.0.17
    # still needed HOMEBREW_ORIGINAL_BREW_FILE, which nix-homebrew's 7.0.4 tail
    # no longer exported -- KeyError). A newer tag with an unchanged bin/brew
    # is fine; `macsetup doctor`, `update` and `rebuild` compare the tails.
    brew-src = {
      url = "github:Homebrew/brew/7.0.12";
      flake = false;
    };

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
    homebrew-ariga = {
      url = "github:ariga/homebrew-tap";
      flake = false;
    };
    homebrew-fluxcd = {
      url = "github:fluxcd/homebrew-tap";
      flake = false;
    };
    homebrew-cloudflare = {
      url = "github:cloudflare/homebrew-cloudflare";
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
