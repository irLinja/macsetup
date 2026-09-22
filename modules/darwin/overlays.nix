# nixpkgs overlays -- apply to nix-darwin and, via home-manager.useGlobalPkgs,
# to Home Manager as well, so a package only needs overriding once.
{ ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      # nixpkgs' pre-commit pulls the full .NET SDK, coursier, go, cargo and perl
      # in as *test* dependencies, purely to exercise its `language: dotnet` (etc.)
      # hook support at build time. None of it reaches the runtime closure -- the
      # only runtime wrapper adds gitMinimal. Normally cache.nixos.org ships a
      # prebuilt pre-commit so this is invisible, but on a nixpkgs pin with no
      # cached aarch64-darwin build it turns `macsetup rebuild` into a multi-hour
      # .NET source bootstrap (dotnet-stage0-vmr).
      #
      # Three knobs are required, and each one alone is insufficient:
      #   doInstallCheck     buildPythonPackage remaps doCheck onto this; plain
      #                      `doCheck = false` is a no-op (it is already "").
      #   preCheck           interpolates "${dotnet-sdk}/share/dotnet", a string
      #                      -context dependency that survives every doCheck flag.
      #   dontUsePytestCheck what pytestCheckHook actually gates its phase on --
      #                      without it the suite still runs, now missing its deps.
      #
      # Verified: pre-commit 4.6.2 builds, `--version`/`--help` work, and the
      # runtime closure is 88 paths / 0 dotnet -- identical to the cached build.
      pre-commit = prev.pre-commit.overrideAttrs (_: {
        doInstallCheck = false;
        preCheck = "";
        dontUsePytestCheck = true;
      });
    })
  ];
}
