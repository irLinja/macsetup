{ pkgs, ... }: {
  # Central list for user-level packages.
  # Add packages here rather than creating per-tool modules.
  # Populated in Phase 2.
  home.packages = with pkgs; [
    # -- User tools --
  ];
}
