{ ... }: {
  # ── Touch ID / Apple Watch sudo ──────────────────────────────────
  # Writes to /etc/pam.d/sudo_local (survives macOS updates since Sonoma).
  # Fallback chain: Touch ID -> Apple Watch -> password (automatic).
  security.pam.services.sudo_local = {
    touchIdAuth = true;    # pam_tid.so -- Touch ID for sudo
    watchIdAuth = true;    # pam_watchid.so -- Apple Watch fallback
    reattach = true;       # pam_reattach.so -- Fix for tmux/screen sessions
  };

  # ── Firewall ─────────────────────────────────────────────────────
  # Uses socketfilterfw under the hood (replaces deprecated system.defaults.alf
  # which wrote to a plist Apple no longer reads).
  # Gatekeeper is ON by default in macOS — not declared (stock default).
  networking.applicationFirewall = {
    enable = true;    # stock: disabled
  };

  # ── FileVault ────────────────────────────────────────────────────
  # FileVault is enabled on this Mac but cannot be managed declaratively
  # by nix-darwin (requires interactive authentication and recovery key
  # generation). Verify manually:
  #   fdesetup status
}
