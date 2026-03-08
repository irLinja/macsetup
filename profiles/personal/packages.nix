{ pkgs, lib, ... }: {
  home-manager.sharedModules = [{
    home.packages = lib.mkDefault (with pkgs; [
      # Development
      nodejs
      pnpm
      uv
      neovim
      hugo

      # CLI Utilities
      jq
      ripgrep
      wget
      gh
      pre-commit
      watch
      terminal-notifier
      zsh-completions

      # Media
      ffmpeg
    ]);
  }];
}
