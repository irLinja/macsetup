{ pkgs, ... }: {
  # Central list for system-level packages.
  # Add packages here rather than creating per-tool modules.
  # Populated in Phase 2.
  environment.systemPackages = with pkgs; [
    # -- System tools --
  ];
}
