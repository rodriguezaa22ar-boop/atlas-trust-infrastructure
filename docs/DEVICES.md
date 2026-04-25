# Devices

## Current Role Map

### This Device

- Role: builder and local runtime
- Use: architecture, authoring, release staging, documentation, runtime execution, and verification

### Retired HP Lab Node

- Previous role: runtime
- Status: retired from active configuration after no-power hardware failure
- Archived target record: `docs/retired-targets/hp-lab.env`

### Memorex USB 3.1

- Role: removable encrypted lab vault
- Use: cached datasets, outputs, loot, captures, report artifacts, deployable trees
- Current attachment: local USB 3.1 device
- Observed block device: `/dev/sdc1`
- Observed label: `labvault`
- Observed format: LUKS encrypted volume
- Runtime mountpoint after unlock: usually `/run/media/ao/labvault`

### Older USB 2.0 64G Stick

- Role: recovery and provisioning media
- Connection observed: `480` Mbps
- Identity observed:
  - model: `USB Flash Disk`
  - vendor: `General`
  - serial: `3030000000005385`
- Current media state:
  - contains a NixOS installer image
  - not suitable for active tool caches or write-heavy runtime storage

## Why The Local USB Role Fits

The HP is no longer a reliable runtime. Keeping runtime execution on this
device while using the encrypted USB vault for portable state preserves the
same separation without depending on failed hardware:

- this device runs the tools
- the USB vault carries runtime state and releases when unlocked
- releases remain immutable
- mutable state stays under the runtime `shared/` directory

## Why The Older USB Role Fits

The older stick is slow enough that using it for normal lab state would be a
bad trade. It is still useful as a trusted recovery path:

- boot recovery for the HP or another lab node
- provisioning media for a clean reinstall
- known-good live environment when the internal disk or bootloader breaks

## If We Repurpose It Later

The only stronger alternative role is an encrypted release shuttle for moving
small staged tool trees between local systems. That would require wiping the
current installer image, so it should be an intentional decision.
