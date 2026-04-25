# wiremap

This module is a color-guided, workflow-first network recon console built
around upstream `nmap` plus packet capture.

It is not a watered-down clone of upstream `nmap`, and it is not a Wireshark
replacement. The point is to give you a task-first operator layer:

- pick a named workflow instead of stitching stages together by hand
- drop into profiles only when you want lower-level control
- navigate profiles by color-coded task category
- optionally capture the traffic around the scan
- review the scan output and PCAP from one place
- keep run artifacts under a single state path
- publish structured findings into the shared intel store

## Commands

```bash
wiremap menu
wiremap workflow list
wiremap workflow show perimeter-sweep
wiremap workflow plan web-stack 192.168.1.1 eth0
wiremap workflow run lateral-check 192.168.1.1 eth0
wiremap analyze brief ./state/wiremap-runs/<run>
wiremap analyze services ./state/wiremap-runs/<run>
wiremap analyze web-focus ./state/wiremap-runs/<run>
wiremap analyze lateral-trace ./state/wiremap-runs/<run>
wiremap analyze service-diff ./state/wiremap-runs/<baseline> ./state/wiremap-runs/<candidate>
wiremap capture inspect ./state/wiremap-runs/<run>
wiremap capture streams ./state/wiremap-runs/<run>
wiremap capture creds ./state/wiremap-runs/<run>
wiremap capture anomalies ./state/wiremap-runs/<run>
wiremap profile list
wiremap profile show service
wiremap plan fast 192.168.1.1 eth0
wiremap run service 192.168.1.1 eth0
wiremap review <run-dir-or-pcap>
wiremap prune 5
```

## Named Workflows

- `perimeter-sweep`: move from host presence to common service picture
- `web-stack`: bias toward HTTP/TLS surface with supporting context
- `lateral-check`: bias toward internal admin and movement surfaces
- `udp-scout`: bounded UDP-first survey with host context
- `full-exposure`: escalate from presence to full TCP service mapping

## Built-In Profiles

- `discover`: discovery-oriented host mapping
- `fast`: quick baseline for responsive targets
- `service`: service fingerprinting on common ports
- `full-tcp`: deeper TCP sweep with service probing
- `web`: focused web attack-surface baseline
- `admin`: common admin and internal movement services
- `udp-top`: focused UDP sketch

## Wireshark Hybrid Model

The hybrid is capture-oriented, not GUI-oriented.

- scan with `nmap`
- capture with `tcpdump`
- inspect protocols and packet samples with `capture inspect`
- summarize conversations with `capture streams`
- surface auth material with `capture creds`
- surface resets and retransmissions with `capture anomalies`
- decode with `tshark` when available
- fall back to `tcpdump`-based views when `tshark` is missing

That keeps the workflow terminal-native and runtime-friendly for the local USB
runtime.

## Operator Interface

The interface is intentionally tuned for recall and speed:

- workflows are the main navigation layer
- category badges are color coordinated
- plans are split into scan and capture sections
- the menu stays workflow-first instead of flag-first
- profile detail explains when to use a profile, not just how it is built
- workflow detail explains the full staged path before you run it

## Saved-Run Analysis

Wiremap now has a post-scan intelligence layer for saved runs:

- `analyze brief`: build an operator-facing decision summary with next moves
- `analyze services`: extract a clean open-service inventory
- `analyze web-focus`: isolate likely web-facing surfaces
- `analyze lateral-trace`: isolate admin and movement-relevant surfaces
- `analyze service-diff`: compare two runs and show added or removed services

This keeps the useful interpretation inside the tool instead of pushing you
back into raw `nmap` text every time.

The brief layer is the top of the stack:

- summarize exposure quickly
- surface likely priorities
- suggest the next workflow to run

## Vector Boundary

`wiremap` and `vector` should not collapse into the same tool.

- `wiremap` owns discovery, capture, packet evidence, and saved-run analysis
- `vector` owns ranking, bounded action lanes, sessions, and backend control
- `wiremap` publishes packet-derived hints into shared intel
- `vector` consumes those hints so action stays relevant without becoming a packet console

## Shared Intel Publisher

Completed runs now publish structured records under `state/intel/`:

- `observations.jsonl`: host state, open service, web surface, lateral surface
- `entities.jsonl`: host and service records
- `outcomes.jsonl`: run-level counts and status
- `relationships.jsonl`: host-to-service exposure links

This is the first shared memory layer for the toolkit. It lets future tools
consume stable facts without scraping `wiremap` output text directly.

Packet analysis now deepens that store as well:

- `capture creds` can publish `credential_hint` observations
- `capture anomalies` can publish `capture_anomaly` observations

## Storage Discipline

Runs are written under `state/wiremap-runs/`.

To keep the tree clean:

- plan before running when you only need command review
- use selected profiles instead of arbitrary sprawl
- prune old run directories when they stop being useful
