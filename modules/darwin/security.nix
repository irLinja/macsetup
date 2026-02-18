{ ... }: {
  # ── Touch ID / Apple Watch sudo ──────────────────────────────────
  # Writes to /etc/pam.d/sudo_local (survives macOS updates since Sonoma).
  # Fallback chain: Touch ID -> Apple Watch -> password (automatic).
  security.pam.services.sudo_local = {
    touchIdAuth = true;    # pam_tid.so -- Touch ID for sudo
    watchIdAuth = true;    # pam_watchid.so -- Apple Watch fallback
    reattach = true;       # pam_reattach.so -- Fix for tmux/screen sessions
  };
}
