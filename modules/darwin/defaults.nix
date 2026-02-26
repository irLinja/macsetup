{ config, ... }:
let
  username = config.system.primaryUser;
in
{
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
  # Written in post-activation (after activateSettings -u) to avoid
  # breaking smart zoom. nix-darwin's CustomUserPreferences writes
  # trigger activateSettings to disrupt MouseExtension's live state.

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

    # Magic Mouse defaults: only written on first-time setup (UserPreferences
    # absent). Re-writing on every rebuild breaks smart zoom because
    # `defaults write` notifies MouseExtension via cfprefsd but without the
    # private XPC handshake that System Settings sends — gesture state breaks.
    if ! launchctl asuser "$(id -u ${username})" sudo --user=${username} -- defaults read com.apple.AppleMultitouchMouse UserPreferences &>/dev/null; then
      MOUSE_DOMAINS=(
        com.apple.AppleMultitouchMouse
        com.apple.driver.AppleBluetoothMultitouch.mouse
      )
      for domain in "''${MOUSE_DOMAINS[@]}"; do
        launchctl asuser "$(id -u ${username})" sudo --user=${username} -- defaults write "$domain" MouseButtonMode -string TwoButton
        launchctl asuser "$(id -u ${username})" sudo --user=${username} -- defaults write "$domain" MouseButtonDivision -int 55
        launchctl asuser "$(id -u ${username})" sudo --user=${username} -- defaults write "$domain" MouseOneFingerDoubleTapGesture -int 1
        launchctl asuser "$(id -u ${username})" sudo --user=${username} -- defaults write "$domain" MouseTwoFingerDoubleTapGesture -int 3
        launchctl asuser "$(id -u ${username})" sudo --user=${username} -- defaults write "$domain" MouseTwoFingerHorizSwipeGesture -int 2
        launchctl asuser "$(id -u ${username})" sudo --user=${username} -- defaults write "$domain" MouseHorizontalScroll -int 1
        launchctl asuser "$(id -u ${username})" sudo --user=${username} -- defaults write "$domain" MouseVerticalScroll -int 1
        launchctl asuser "$(id -u ${username})" sudo --user=${username} -- defaults write "$domain" MouseMomentumScroll -int 1
      done
    fi

    # Clean up dangling symlinks in Homebrew's zsh completions directory
    # (stale _brew, _brew_cask, or formula leftovers cause compinit errors)
    if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
      find /opt/homebrew/share/zsh/site-functions -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
      /opt/homebrew/bin/brew completions link 2>/dev/null || true
    fi
  '';
}
