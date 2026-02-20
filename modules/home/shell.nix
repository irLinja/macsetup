{ pkgs, lib, ... }: {

  # ── Zsh Core ─────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;

    # History
    history = {
      size = 50000;
      save = 50000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      share = true;
      extended = true;
    };

    # ── Built-in Plugin Options ──────────────────────────────────
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
    };

    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" ];
    };

    historySubstringSearch.enable = true;

    # ── oh-my-zsh ─────────────────────────────────────────────────
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "kubectl"
        "terraform"
        "docker"
        "copybuffer"
        "sudo"
        "extract"
        "colored-man-pages"
      ];
      # No theme -- Starship owns the prompt
    };

    # ── Manual Plugins ───────────────────────────────────────────
    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        name = "you-should-use";
        file = "you-should-use.plugin.zsh";
        src = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
      }
    ];

    # ── Aliases ──────────────────────────────────────────────────
    shellAliases = {
      vi = "nvim";
      vim = "nvim";

      ll = "ls -lah";
      l = "ls -lh";
      gpsdir = "ls -d ./*/ | xargs -P15 -I{} sh -c \"cd {} && git pull --all --tags --prune\"";
    };

    # ── initContent (priority-ordered shell snippets) ────────────
    initContent = lib.mkMerge [

      # Priority 500: Use local starship config override if it exists
      (lib.mkOrder 500 ''
        if [[ -f "$HOME/.config/starship-local.toml" ]]; then
          export STARSHIP_CONFIG="$HOME/.config/starship-local.toml"
        fi
      '')

      # Priority 550: Add Homebrew completions to fpath before compinit (570)
      # Remove dangling symlinks first -- stale completions cause compinit errors
      (lib.mkOrder 550 ''
        if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
          for f in /opt/homebrew/share/zsh/site-functions/_*; do
            [[ -L "$f" && ! -e "$f" ]] && rm -f "$f"
          done
          fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
        fi
      '')

      # Priority 600: After compinit -- completion waiting dots
      (lib.mkOrder 600 ''
        expand-or-complete-with-dots() {
          echo -n "\e[31m...\e[0m"
          zle expand-or-complete
          zle redisplay
        }
        zle -N expand-or-complete-with-dots
        bindkey "^I" expand-or-complete-with-dots
      '')

      # Priority 600: After compinit -- completion tuning zstyles
      (lib.mkOrder 600 ''
        # Case-insensitive matching
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        # Menu-style completion selection
        zstyle ':completion:*' menu select
        # Group completions by type
        zstyle ':completion:*' group-name '''
        zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
        # fzf-tab: preview directories on cd
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath'
        # fzf-tab: switch groups with , and .
        zstyle ':fzf-tab:*' switch-group ',' '.'
      '')

      # Priority 1000: TTS notification functions
      (lib.mkOrder 1000 ''
        talk() {
          if [[ $? -eq 0 ]]; then
            say "Success!"
          else
            say "Failed!"
          fi
        }

        ktalk() {
          if [[ $? -eq 0 ]]; then
            say "As you wish master! Success!"
          else
            say "I'm sorry, master. I have failed you."
          fi
        }
      '')
    ];
  };

  # ── Companion Programs ──────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height" "40%" "--border" ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # ── PATH ────────────────────────────────────────────────────────
  home.sessionPath = [
    "$HOME/.krew/bin"
    "$HOME/.local/bin"
    "$HOME/.tfversion/bin"
    # "$HOME/.rd/bin"          # Rancher Desktop -- uncomment if used
    # "$HOME/.antigravity/bin" # uncomment if used
  ];

  # ── Environment Variables ───────────────────────────────────────
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
