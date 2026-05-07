# Atlas Supported Systems

## Support Levels

| System | Support Level | Proof Path |
| --- | --- | --- |
| NixOS | reference | `nix-shell --run './bin/dev-qa'` |
| generic Linux | supported host shell | `./bin/dev-host-check` plus Atlas read-only checks |
| macOS | supported host shell | `./bin/dev-host-check` plus Atlas read-only checks |
| WSL | supported host shell | `./bin/dev-host-check` plus Atlas read-only checks |
| container | reference-style verifier | container runtime plus Nix or host-shell checks |
| CI runner | reference automation | GitHub Actions plus local parity commands |
| source archive | read-only not-ready report | `atlas production status --strict` |
| full Git clone | full proof path | QA, Atlas self-checks, release/reviewer verification |

## Support Boundary

Supported means Atlas can report dependency status and run the applicable
read-only proof commands with clear ready or not-ready output.

Supported does not mean every optional operator workflow, external tool, or
future adapter is available on every system.
