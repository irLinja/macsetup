{ pkgs, inputs, ... }: {
  home.packages = (with pkgs; [
    # -- Development Languages & Runtimes --
    nodejs            # Node.js runtime (required by pnpm)
    pnpm              # Fast Node.js package manager
    uv                # Fast Python package/project manager

    # -- CLI Utilities --
    jq                # JSON processor
    ripgrep           # Fast regex search (rg)
    terminal-notifier # macOS notification CLI
    zsh-completions   # Additional zsh completion definitions

    # -- Version Control --
    gh                # GitHub CLI
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
  ]) ++ (with inputs.nix-casks.packages.${pkgs.system}; [
    # -- Development --
    ghostty             # GPU-accelerated terminal emulator
    headlamp            # Kubernetes web UI
    rancher             # Rancher Desktop (container management)
    visual-studio-code  # Code editor

    # -- Productivity --
    grammarly-desktop   # Writing assistant
    notion              # Notes and wiki
    raycast             # Spotlight replacement / launcher

    # -- Media --
    iina                # Media player

    # -- Communication --
    slack               # Team messaging
    telegram            # Messaging
    whatsapp            # Messaging

    # -- Security --
    shadowsocksx-ng     # ShadowsocksX-NG proxy
    # surfshark         # VPN client (shelved — SSL errors on corporate networks)

    # -- Utilities --
    transmission        # BitTorrent client
    # betterdisplay     # Display management (shelved)
    # monitorcontrol    # Monitor brightness/volume control (shelved)

    # -- Internet --
    arc                 # Arc browser
    # zen               # Zen browser (shelved)

    # -- Creative --
    chatgpt             # ChatGPT desktop app
    claude              # Claude desktop app
  ]);
}
