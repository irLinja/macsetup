# Work profile -- opinionated starter set for a work/corporate machine.
# Import this from your host file: imports = [ ../profiles/work ];
{ ... }: {
  imports = [
    ./packages.nix
    ./homebrew.nix
  ];
}
