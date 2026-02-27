# Personal profile -- opinionated starter set for a personal development machine.
# Import this from your host file: imports = [ ../profiles/personal ];
{ ... }: {
  imports = [
    ./packages.nix
    ./homebrew.nix
  ];
}
