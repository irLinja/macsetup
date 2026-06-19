{ pkgs, lib, ... }: {
  home-manager.sharedModules = [{
    home.packages = lib.mkDefault (with pkgs; [
      # Development
      nodejs
      pnpm
      bun
      uv
      neovim
      hugo

      # CLI Utilities
      jq
      ripgrep
      wget
      gh
      pre-commit
      terminal-notifier
      zsh-completions

      # Media
      ffmpeg
    ]);
  }];
}
