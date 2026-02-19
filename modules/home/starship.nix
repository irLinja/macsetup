{ ... }: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      hostname = {
        ssh_only = false;
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };

      gcloud = {
        disabled = true;
      };

      golang = {
        symbol = "";
      };
    };
  };
}
