{ ... }: {
  programs.git = {
    enable = true;

    signing = {
      key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+8Td4M6GvHcuOr9J/syhqqymwroVg6e7qRyKtlwacYVMeWUQnxMZf/XeJBjZsJ/MT82n32JYg/gNU9AG97maLzRleqTd/3B2gpRkCokliCQvcUI18U/WmmfYsA+pgvLfvbGgUzod41AoQbJlYBTCaF5JBq8ljSUZot0dg4/pv+NwjleiwO/+b5k0IcFkUSgNTpmFMH8St1VAjrEW8aQQA+NZ/j3pxomIqIlFJLwPPiNp0RsLc5vb41QTAAnaZlaVw9Ue9ZxjR+BzSPGp7c/ZuV9V1AFfaovRc/evSfIR9BFSL2PdcjF8u/7LKiKdkIxVfBq28bcgfNkZ1XpEYA5chKoPhr22QbUKkwAimu+Q2iA4AmZrwfYcE6PvtbL+E5xf7YsKqI9d+CATgPEmzW4ZtxzElT/XJyYs7XxQDYB47Py2w+GdA6mQw4uBlkyDnncmW5xf7xFAgTMzLljqRUm/6Vz/TTDrpvDQUaQ8MA9yHBWCd5J+4aPG2pyExFIY9m/vyg9VEGTibVzpL+fLrRHX+SUAtgnrFwA1LjIWnu14UllQelPqePqaijWfb6kpxpxa+Ez3eBcG6utprHmFJPJ5uY0vsV1T4FXR4QegbLcqMWmrOGX8EW2v+23VhdAfFYBxAGG2omp21W4IAKleJ82OC06sfBnbRlComiyTBKrr9tw==";
      signByDefault = true;
      format = "ssh";
      signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
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

    settings = {
      user = {
        name = "Arash Haghighat";
        email = "arash@a12t.co";
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
      tag = {
        forceSignAnnotated = true;
        gpgsign = true;
      };
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      url."https://github.com/".insteadOf = "ssh://git@github.com/";
    };
  };
}
