{ pkgs, ... }:
let
  # YouTube Music Desktop App comes from nixpkgs because homebrew-cask disabled
  # its cask (2026-09-01, fails Gatekeeper, stuck at 2.0.11). defaults.nix has
  # to re-sign it (see there), and codesign refuses the nixpkgs bundle as is:
  #   - its main executable is a shell script that execs the real binary by its
  #     /nix/store path, so the copy in /Applications/Nix Apps would run from
  #     the read-only store instead of itself;
  #   - the build zips electron without -y, which turns every framework
  #     symlink into a copy ("bundle format is ambiguous"). The app loads the
  #     top-level copies, and only those carry the Electron fuses the build
  #     sets (cookie encryption on, RunAsNode off, ...); Versions/A still holds
  #     the stock binary.
  # This links the cached build back into a regular bundle: the real binary
  # under the bundle's name, and Versions/A pointing at the top-level copies
  # behind the usual Versions/Current symlinks. Nothing compiles, and the copy
  # in /Applications/Nix Apps shrinks from 860 to 284 MB.
  ytmdesktop-app = pkgs.runCommandLocal "ytmdesktop-app" { } ''
    src="${pkgs.ytmdesktop}/Applications/YouTube Music Desktop App.app/Contents"
    dst="$out/Applications/YouTube Music Desktop App.app/Contents"
    # Skipping the script is only safe while it adds no flags or environment.
    if grep -v -e '^#!' -e '^[[:space:]]*$' "$src/MacOS/youtube-music-desktop-app" \
        | grep -qv '^exec -a "$0" "[^"]*/\.youtube-music-desktop-app-wrapped" *"$@" *$'; then
      echo "ytmdesktop's launcher script now does more than exec the app:" >&2
      cat "$src/MacOS/youtube-music-desktop-app" >&2
      exit 1
    fi
    mkdir -p "$dst/MacOS" "$dst/Frameworks"
    cp "$src/MacOS/.youtube-music-desktop-app-wrapped" "$dst/MacOS/youtube-music-desktop-app"
    for f in "$src"/*; do
      case "''${f##*/}" in
        MacOS | Frameworks) ;;
        *) ln -s "$f" "$dst/" ;;
      esac
    done
    for f in "$src"/Frameworks/*; do
      case "$f" in
        *.framework)
          fw="$dst/Frameworks/''${f##*/}"
          mkdir -p "$fw/Versions/A"
          ln -s A "$fw/Versions/Current"
          for e in "$f"/*; do
            case "''${e##*/}" in
              Versions) ;;
              *)
                ln -s "$e" "$fw/Versions/A/"
                ln -s "Versions/Current/''${e##*/}" "$fw/"
                ;;
            esac
          done
          ;;
        *) ln -s "$f" "$dst/Frameworks/" ;;
      esac
    done
  '';
in
{
  # Central list for system-level packages.
  # Add packages here rather than creating per-tool modules.
  # Populated in Phase 2.
  environment.systemPackages = with pkgs; [
    # -- System tools --

    # -- Apps (nix-darwin copies these into /Applications/Nix Apps) --
    ytmdesktop-app
  ];
}
