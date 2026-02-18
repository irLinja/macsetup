{ ... }: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Two-line prompt: context info on top, cursor on second line.
      format = builtins.concatStringsSep "" [
        "$hostname"
        "$username"
        "$directory"
        "$git_branch"
        "$git_status"
        "$git_state"
        "$kubernetes"
        "$terraform"
        "$aws"
        "$azure"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];

      add_newline = true;

      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[>](bold red)";
      };

      hostname = {
        ssh_only = false;       # Always show hostname, not just SSH
        format = "[$hostname]($style) in ";
        style = "bold dimmed green";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
      };

      git_branch = {
        symbol = " ";          # Nerd font branch icon
        style = "bold purple";
      };

      git_status = {
        style = "bold red";
      };

      kubernetes = {
        disabled = false;       # Disabled by default in Starship -- must enable
        format = "[$symbol$context( \\($namespace\\))]($style) ";
        style = "cyan bold";
      };

      terraform = {
        format = "via [$symbol$workspace]($style) ";
      };

      aws = {
        format = "on [$symbol($profile )(\\($region\\))]($style) ";
      };

      azure = {
        disabled = false;       # Disabled by default in Starship -- must enable
        format = "on [$symbol($subscription)]($style) ";
      };

      gcloud = {
        disabled = true;        # User's existing preference
      };

      cmd_duration = {
        min_time = 2000;
        format = "took [$duration]($style) ";
      };

      # Language modules: file-detection only (keeps defaults explicit).
      nodejs.detect_files = [ "package.json" ".node-version" ];
      python.detect_files = [ "requirements.txt" "pyproject.toml" "setup.py" ".python-version" ];
      golang.detect_files = [ "go.mod" "go.sum" ];
      rust.detect_files = [ "Cargo.toml" ];
    };
  };
}
