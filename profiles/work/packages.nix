{ pkgs, lib, ... }: {
  home-manager.sharedModules = [{
    home.packages = lib.mkDefault (with pkgs; [
      # Development
      nodejs
      pnpm
      uv
      neovim

      # CLI Utilities
      jq
      ripgrep
      wget
      gh
      pre-commit
      zsh-completions
    ]);
  }];
}
