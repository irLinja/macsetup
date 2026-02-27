# 1Password integration -- opt-in via user.nix features.onePassword = true
#
# When enabled:
# - Installs 1Password and 1Password for Safari via Homebrew
# - Configures git SSH signing via 1Password's op-ssh-sign
#
# Must be installed via Homebrew cask (not NixCasks) -- requires /Applications/
# for SSH agent and browser integration.
{ userConfig, lib, ... }:
let
  enabled = userConfig.features.onePassword or false;
in {
  # 1Password cask (only when enabled)
  homebrew.casks = lib.mkIf enabled [ "1password" ];
  homebrew.masApps = lib.mkIf enabled { "1Password for Safari" = 1569813296; };
}
