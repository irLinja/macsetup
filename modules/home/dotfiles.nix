{ userConfig, lib, ... }: {
  # ── Dotfiles absorbed into Nix ──────────────────────────────────
  # Strategy: Home Manager owns these files (not symlinking external files).
  # Existing files will be backed up to *.backup on first rebuild
  # (home-manager.backupFileExtension = "backup" is set in hosts/shared.nix).

  home.file = {
    ".vimrc".text = ''
      " Environment
      set nocompatible
      set background=dark

      " Formatting
      set nowrap
      set autoindent
      set shiftwidth=2
      set expandtab
      set tabstop=2
      set softtabstop=2

      " General
      syntax on
      set autowrite
      set history=1000
      set showmode
      set showcmd
      set ruler
      set linespace=0
      set nu
      set incsearch
      set hlsearch
      set ignorecase
      set wildmenu
      set wildmode=list:longest,full
      set scrolloff=3
      set scrolljump=5

      " Key Mappings
      nnoremap Y y$

      " Remember last position
      set viminfo='10,"100,:20,%,n~/.viminfo
      function! ResCur()
          if line("'\"") <= line("$")
              normal! g`"
              return 1
          endif
      endfunction
      augroup resCur
          autocmd!
          autocmd BufWinEnter * call ResCur()
      augroup END
    '';

    ".ssh/allowed_signers" = lib.mkIf (userConfig.git.allowedSigners != null) {
      text = userConfig.git.allowedSigners + "\n";
    };

    ".npmrc".text = ''
      registry=https://registry.npmjs.org/
      prefix=''${HOME}/.npm-global
    '';

    "Library/Application Support/com.mitchellh.ghostty/config".text = ''
      font-size = 22
      theme = Elegant
      background-opacity = 0.85
      window-padding-x = 4
      window-padding-y = 4
      confirm-close-surface = false
    '';
  };
}
