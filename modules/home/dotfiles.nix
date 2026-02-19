{ ... }: {
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

    ".ssh/allowed_signers".text = ''
      arash@a12t.co ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+8Td4M6GvHcuOr9J/syhqqymwroVg6e7qRyKtlwacYVMeWUQnxMZf/XeJBjZsJ/MT82n32JYg/gNU9AG97maLzRleqTd/3B2gpRkCokliCQvcUI18U/WmmfYsA+pgvLfvbGgUzod41AoQbJlYBTCaF5JBq8ljSUZot0dg4/pv+NwjleiwO/+b5k0IcFkUSgNTpmFMH8St1VAjrEW8aQQA+NZ/j3pxomIqIlFJLwPPiNp0RsLc5vb41QTAAnaZlaVw9Ue9ZxjR+BzSPGp7c/ZuV9V1AFfaovRc/evSfIR9BFSL2PdcjF8u/7LKiKdkIxVfBq28bcgfNkZ1XpEYA5chKoPhr22QbUKkwAimu+Q2iA4AmZrwfYcE6PvtbL+E5xf7YsKqI9d+CATgPEmzW4ZtxzElT/XJyYs7XxQDYB47Py2w+GdA6mQw4uBlkyDnncmW5xf7xFAgTMzLljqRUm/6Vz/TTDrpvDQUaQ8MA9yHBWCd5J+4aPG2pyExFIY9m/vyg9VEGTibVzpL+fLrRHX+SUAtgnrFwA1LjIWnu14UllQelPqePqaijWfb6kpxpxa+Ez3eBcG6utprHmFJPJ5uY0vsV1T4FXR4QegbLcqMWmrOGX8EW2v+23VhdAfFYBxAGG2omp21W4IAKleJ82OC06sfBnbRlComiyTBKrr9tw==
    '';

    ".npmrc".text = ''
      registry=https://registry.npmjs.org/
    '';

    "Library/Application Support/com.mitchellh.ghostty/config".text = ''
      font-size = 14
      theme = dark:GruvboxDarkHard,light:GruvboxLight
      window-padding-x = 4
      window-padding-y = 4
      confirm-close-surface = false
    '';
  };
}
