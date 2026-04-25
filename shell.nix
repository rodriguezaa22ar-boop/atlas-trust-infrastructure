{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    bashInteractive
    bats
    fd
    git
    jq
    ripgrep
    rsync
    shellcheck
    shfmt
    tmux
  ];

  shellHook = ''
    export PATH="$PWD/bin:$PATH"

    printf 'native-lab dev shell\n'
    printf 'root: %s\n' "$PWD"
    printf 'entrypoint: labctl\n'
  '';
}
