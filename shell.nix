{ pkgs ? import ./nix/nixpkgs.nix {} }:

pkgs.mkShell {
  packages = with pkgs; [
    bashInteractive
    bats
    check-jsonschema
    fd
    git
    gnupg
    jq
    open-policy-agent
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
