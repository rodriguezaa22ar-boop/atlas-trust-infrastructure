# vector

This module is the first consumer of the shared intel spine and the first
action-layer operator console in the toolkit.

It does not replace Metasploit Framework and it does not try to be a raw
exploit shell. The point is to give the operator a cleaner control surface:

- rank action lanes from observed evidence
- explain why each lane appears
- keep navigation target-first instead of module-first
- run bounded backends without dropping into raw backend sprawl
- keep session artifacts, loot, and outcomes visible

## Commands

```bash
vector menu
vector lanes
vector lane show credentials
vector target summary 10.0.0.8
vector target services 10.0.0.8
vector target web 10.0.0.8
vector target lateral 10.0.0.8
vector candidates 10.0.0.8
vector plan lateral 10.0.0.8
vector run lateral 10.0.0.8
vector outcomes 10.0.0.8
vector session list
vector session show lateral-10.0.0.8-...
vector loot list
```

## Action Lanes

- `validate`: confirm and enrich observed surface
- `web`: bias toward HTTP and TLS follow-up
- `credentials`: bias toward auth-bearing services and packet-derived auth material
- `lateral`: bias toward movement and remote-admin surface
- `research`: turn versioned evidence into narrow follow-up research

## Bounded Backends

Each lane maps to a bounded backend:

- `validate` -> `service-refresh`
- `web` -> `http-scout`
- `credentials` -> `auth-scout`
- `lateral` -> `movement-scout`
- `research` -> `msf-module-scout`

These are not raw exploit consoles. They are disciplined operator actions that
produce artifacts, update sessions, and feed outcomes back into shared intel.

The `research` lane now uses Metasploit search when `msfconsole` is available,
while preserving the mapped fallback so the toolkit still works on machines
that do not carry the Framework yet.

## Shared Intel Consumer

Vector reads from `state/intel/`:

- `observations.jsonl`
- `entities.jsonl`
- `outcomes.jsonl`
- `relationships.jsonl`

Vector also writes back into `outcomes.jsonl`, and some lane backends publish
new observations such as:

- `service_validation`
- `web_probe`
- `lateral_surface`
- `module_candidate`

`module_candidate` records now carry enough structure to distinguish:

- mapped candidates from the toolkit
- Metasploit-backed search hits
- search terms and ranks when the Framework path is present

The first goal is not hidden automation. The first goal is better operator
judgment with a visible memory loop.

That includes packet-derived evidence from `wiremap`:

- `credential_hint` can elevate the `credentials` lane
- `capture_anomaly` can keep the `validate` lane honest when transport looks unstable

That means:

- ranked candidates instead of raw module sprawl
- plans that explain why a lane is relevant
- evidence previews pulled from prior recon
- session-backed artifacts and loot
- a stable interface for the future Metasploit-side engine
