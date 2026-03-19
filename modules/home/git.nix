{ userConfig, lib, ... }: {
  programs.git = {
    enable = true;

    signing = lib.mkIf (userConfig.git.signing.key != null) {
      key = userConfig.git.signing.key;
      signByDefault = userConfig.git.signing.signByDefault;
      format = userConfig.git.signing.format;
      signer = userConfig.git.signing.signer;
    };

    lfs.enable = true;

    ignores = [
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "Icon\\r"
      "._*"
      ".DocumentRevisions-V100"
      ".fseventsd"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".VolumeIcon.icns"
      ".com.apple.timemachine.donotpresent"
      ".AppleDB"
      ".AppleDesktop"
      "Network Trash Folder"
      "Temporary Items"
      ".apdisk"
    ];

    includes = [
      {
        condition = "gitdir:~/Documents/JET/";
        contents.user.email = "arash.haghighat@justeattakeaway.com";
      }
    ];

    settings = {
      user = {
        name = userConfig.fullName;
        email = userConfig.email;
      };
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        ignorecase = false;
      };
      color.ui = true;
      pull.rebase = true;
      rebase.autostash = true;
      diff.noprefix = true;
      tag = lib.mkIf (userConfig.git.signing.key != null) {
        forceSignAnnotated = true;
        gpgsign = true;
      };
      gpg.ssh.allowedSignersFile = lib.mkIf (userConfig.git.signing.key != null) "~/.ssh/allowed_signers";
      url."https://github.com/".insteadOf = "ssh://git@github.com/";
    };
  };
}
