{ pkgs, ... }: {
  home.packages = with pkgs; [
    # -- Development Languages & Runtimes --
    nodejs            # Node.js runtime (required by pnpm)
    pnpm              # Fast Node.js package manager
    uv                # Fast Python package/project manager

    # -- CLI Utilities --
    direnv            # Directory-based env vars
    jq                # JSON processor
    ripgrep           # Fast regex search (rg)
    starship          # Cross-shell prompt
    terminal-notifier # macOS notification CLI
    zsh-completions   # Additional zsh completion definitions

    # -- Version Control --
    gh                # GitHub CLI
    git               # Distributed version control
    pre-commit        # Git hook framework

    # -- Networking --
    wget              # HTTP/FTP downloader

    # -- Media & Other --
    ffmpeg            # Media processing toolkit
    hugo              # Static site generator
    neovim            # Terminal text editor

    # -- Shelved (uncomment to enable) --
    # tmux              # Terminal multiplexer
    # yj                # YAML/JSON/TOML/HCL converter
    # adr-tools         # Architecture Decision Records tool
    # cookiecutter      # Project template scaffolding
    # cue               # CUE data validation language
    # helm-docs         # Auto-generate markdown docs for helm charts
    # aria2             # Multi-protocol parallel downloader
    # mtr               # Network diagnostic (traceroute + ping)
    # openconnect       # VPN client (Cisco/Juniper/etc.)
  ];
}
