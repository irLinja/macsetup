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
    InitialKeyRepeat = 20;      # stock: 25 (higher = longer delay before repeat)

    AppleMetricUnits = 1;

    # ── Appearance ─────────────────────────────────────────────────
    # Automatic light/dark switching based on time of day ("Auto" mode).
    # Do NOT also set AppleInterfaceStyle = "Dark" — that creates ambiguous state.
    # Omitted: accent color, highlight color, font smoothing, menu bar,
    # scroll bars, sidebar size (all at macOS defaults per user decision).
    AppleInterfaceStyleSwitchesAutomatically = true;  # stock: false
  };

  # ── Language & Region (extended) ─────────────────────────────────
  system.defaults.CustomUserPreferences.".GlobalPreferences" = {
    "com.apple.mouse.scaling" = 2;            # tracking speed (~70%)
    "com.apple.swipescrolldirection" = true;   # natural scrolling

    AppleLanguages = [ "en-US" "fa-US" ];
    AppleLocale = "en_US";
    AppleMeasurementUnits = "Centimeters";
    AppleMetricSystem = true;
    AppleTemperatureUnit = "Celsius";
    AppleICUForce24HourTime = false;
    AppleFirstWeekday = { gregorian = 2; };   # Monday
    AppleICUDateFormatStrings = { "1" = "d/M/yy"; };  # short date: 20/2/26
  };

  # ── Input Sources ────────────────────────────────────────────────
  system.defaults.CustomUserPreferences."com.apple.HIToolbox" = {
    AppleEnabledInputSources = [
      {
        InputSourceKind = "Keyboard Layout";
        "KeyboardLayout ID" = 0;
        "KeyboardLayout Name" = "U.S.";
      }
      {
        InputSourceKind = "Keyboard Layout";
        "KeyboardLayout ID" = -2901;
        "KeyboardLayout Name" = "Persian-ISIRI 2901";
      }
    ];
  };

  # ── Trackpad ───────────────────────────────────────────────────────
  # Omitted: natural scrolling, three-finger drag, right-click, mouse
  # scaling (all at macOS defaults per user decision).
  system.defaults.trackpad = {
    Clicking = true;            # stock: false (enables tap-to-click)
  };

  system.defaults.CustomUserPreferences."com.apple.AppleMultitouchTrackpad" = {
    Clicking = 1;               # tap-to-click (mirrors trackpad.Clicking for built-in trackpad)
  };

  # ── Mouse (Magic Mouse) ───────────────────────────────────────────
  # Both domains needed: AppleMultitouchMouse (USB) and Bluetooth variant
  system.defaults.CustomUserPreferences."com.apple.AppleMultitouchMouse" = {
    MouseButtonMode = "TwoButton";          # secondary click: right side
    MouseButtonDivision = 55;               # click zone split point
    MouseOneFingerDoubleTapGesture = 1;     # smart zoom: double-tap with one finger
    MouseTwoFingerDoubleTapGesture = 3;     # mission control: double-tap with two fingers
    MouseTwoFingerHorizSwipeGesture = 2;    # swipe between full-screen apps: two fingers
    MouseHorizontalScroll = 1;
    MouseVerticalScroll = 1;
    MouseMomentumScroll = 1;
  };

  system.defaults.CustomUserPreferences."com.apple.driver.AppleBluetoothMultitouch.mouse" = {
    MouseButtonMode = "TwoButton";
    MouseButtonDivision = 55;
    MouseOneFingerDoubleTapGesture = 1;
    MouseTwoFingerDoubleTapGesture = 3;
    MouseTwoFingerHorizSwipeGesture = 2;
    MouseHorizontalScroll = 1;
    MouseVerticalScroll = 1;
    MouseMomentumScroll = 1;
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
  # Runs after all activation steps (including Homebrew cask installs).
  # killall Dock refreshes icons so persistent-apps resolve correctly
  # even on first run when casks are installed during this same switch.
  system.activationScripts.postActivation.text = ''
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    killall Dock 2>/dev/null || true

    # Clean up dangling symlinks in Homebrew's zsh completions directory
    # (stale _brew, _brew_cask, or formula leftovers cause compinit errors)
    if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
      find /opt/homebrew/share/zsh/site-functions -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
      /opt/homebrew/bin/brew completions link 2>/dev/null || true
    fi
  '';
}
