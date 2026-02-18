{ pkgs, ... }: {
  # ── Programming Fonts ───────────────────────────────────────────
  # Installed to /Library/Fonts/Nix Fonts (system-level, available to all apps).
  # Uses modern per-font nerd-fonts.* syntax (not the deprecated monolithic nerdfonts package).
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono   # Primary programming font
    nerd-fonts.meslo-lg         # Terminal font (Starship/p10k compatible)
    nerd-fonts.fira-code        # Ligature-enabled programming font
    nerd-fonts.symbols-only     # Nerd Font icon glyphs without replacing main font
  ];
}
