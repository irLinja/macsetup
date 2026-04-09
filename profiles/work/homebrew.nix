{ ... }: {
  # -- Custom taps (if your work uses private Homebrew taps) ---------------
  # To add a custom tap, you must ALSO add a flake input in flake.nix.
  # Step 1: Add to flake.nix inputs:
  #   homebrew-acme = { url = "github:acme/homebrew-tap"; flake = false; };
  # Step 2: Pass to nix-homebrew.taps in your host file:
  #   "acme/homebrew-tap" = inputs.homebrew-acme;
  # Step 3: Then declare brews/casks from it here:
  #   homebrew.brews = [ "acme/tap/sometool" ];
  # -----------------------------------------------------------------------

  # Work profile casks and brews are declared in modules/darwin/homebrew.nix.
  # Add work-only overrides or additions here.
}
