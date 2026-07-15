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
      zsh-completions
      # terminal-notifier moved to Homebrew (nixpkgs ld crash) -- see modules/darwin/homebrew.nix

      # Media
      ffmpeg
    ]);
  }];
}
