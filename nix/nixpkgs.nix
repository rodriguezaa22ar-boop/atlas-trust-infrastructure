{ system ? builtins.currentSystem
, config ? {}
, overlays ? []
}:

let
  # M195 pins the reference toolchain. To update intentionally:
  # 1. Choose a nixpkgs revision.
  # 2. Run: nix-prefetch-url --unpack https://github.com/NixOS/nixpkgs/archive/<rev>.tar.gz
  # 3. Update rev and sha256 together, then run the full QA gate.
  rev = "34268251cf55";
  sha256 = "0fyhfg417schp15y0prf57q0dnrpdvw6dabb8f47ws76hpy70yqv";
  src = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    inherit sha256;
  };
in
import src {
  inherit system config overlays;
}
