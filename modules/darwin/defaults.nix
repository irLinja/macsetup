{ ... }: {
  # ── Dock ───────────────────────────────────────────────────────────
  # Only settings that differ from stock macOS defaults.
  # Omitted: position, magnification, minimize-effect,
  # launch-animation (all at macOS defaults per user decision).
  system.defaults.dock = {
    autohide = true;                # stock: false
    tilesize = 64;                  # stock: ~48
    minimize-to-application = true; # stock: false
    show-recents = false;           # stock: true — prevent transient apps in Dock
    persistent-apps = [
      "/System/Applications/Messages.app"
      "/Applications/Arc.app"
      "/System/Applications/Mail.app"
      "/Applications/Telegram.app"
      "/Applications/Notion.app"
      "/System/Applications/Calendar.app"
      "/Applications/Slack.app"
      "/Applications/Ghostty.app"
      "/Applications/Spotify.app"
      "/System/Applications/iPhone Mirroring.app"
    ];
  };

  # ── Keyboard / Input ──────────────────────────────────────────────
  system.defaults.NSGlobalDomain = {
    KeyRepeat = 5;              # stock: 6 (lower = faster)
    InitialKeyRepeat = 30;      # stock: 25 (higher = longer delay before repeat)

    # ── Appearance ─────────────────────────────────────────────────
    # Automatic light/dark switching based on time of day ("Auto" mode).
    # Do NOT also set AppleInterfaceStyle = "Dark" — that creates ambiguous state.
    # Omitted: accent color, highlight color, font smoothing, menu bar,
    # scroll bars, sidebar size (all at macOS defaults per user decision).
    AppleInterfaceStyleSwitchesAutomatically = true;  # stock: false
  };

  # ── Trackpad ───────────────────────────────────────────────────────
  # Omitted: natural scrolling, three-finger drag, right-click, mouse
  # scaling (all at macOS defaults per user decision).
  system.defaults.trackpad = {
    Clicking = true;            # stock: false (enables tap-to-click)
  };

  # ── Finder ─────────────────────────────────────────────────────────
  # Intentionally omitted. No non-default Finder settings to declare
  # (user decision — see DFLT-02).

  # ── Software Update ────────────────────────────────────────────────
  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

  system.defaults.CustomUserPreferences."com.apple.SoftwareUpdate" = {
    AutomaticCheckEnabled = true;
    ScheduleFrequency = 1;        # check daily
    AutomaticDownload = 1;        # download in background
    CriticalUpdateInstall = 1;    # install critical updates immediately
  };

  # ── Login window ──────────────────────────────────────────────────
  system.defaults.loginwindow = {
    GuestEnabled = false;
    DisableConsoleAccess = true;
  };

  # ── Screen saver / lock ──────────────────────────────────────────
  system.defaults.screensaver = {
    askForPassword = true;
    askForPasswordDelay = 0;      # require password immediately
  };

  # ── Screenshots ───────────────────────────────────────────────────
  system.defaults.screencapture = {
    type = "png";
    disable-shadow = true;
  };

  # ── Post-activation ────────────────────────────────────────────────
  # activateSettings makes NSGlobalDomain changes (dark mode, keyboard
  # repeat rates) take effect without logout.
  # Dock restart is handled automatically by nix-darwin when dock settings
  # change — do NOT add killall Dock here.
  # NOTE: First-time dark mode auto-switch may require logout to take
  # full effect (macOS limitation, not a configuration defect).
  # Runs as root (postUserActivation was removed); activateSettings -u
  # works correctly from root context.
  system.activationScripts.postActivation.text = ''
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
