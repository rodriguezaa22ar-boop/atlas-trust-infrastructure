# Local USB Runtime

## Current State

The HP runtime node is retired from active use. The local system now uses this
device as the execution host and the encrypted USB 3.1 vault as the portable
runtime state target.

Observed USB device:

- block device: `/dev/sdc1`
- label: `labvault`
- format: LUKS encrypted volume
- status during migration: connected but locked

## Runtime Model

Use this device for execution and activate releases into the unlocked USB vault:

```bash
./bin/labctl release build usb-runtime atlas wiremap vector egress-check
./bin/labctl deploy activate usb-runtime /run/media/ao/labvault/runtime
```

Until the encrypted vault is unlocked, the local stand-in runtime root is:

```bash
/home/ao/local-usb-runtime
```

That path uses the same `releases/`, `shared/`, and `current` layout as the USB
runtime, so it can be used for local validation without changing the release
model.

The active runtime tree will use:

- `runtime/releases/<release>/native/` for immutable tools
- `runtime/shared/targets/` for target records
- `runtime/shared/state/` for shared intel and recon runs
- `runtime/shared/sessions/` for operation and action sessions
- `runtime/shared/reports/` for reports
- `runtime/current` as the active release pointer

## Unlocking The Vault

Unlock the USB vault through the desktop file manager or with a local terminal
command such as:

```bash
udisksctl unlock -b /dev/sdc1
```

Then mount the unlocked mapper device. Desktop mounting usually places the
vault under `/run/media/ao/labvault`. If the mountpoint differs, use that path
in the `labctl deploy activate` command.

Do not format or wipe the USB vault unless explicitly changing its role.

## HP Retirement Notes

The retired HP target record is preserved at:

```bash
docs/retired-targets/hp-lab.env
```

The active `targets/` directory no longer contains `hp-lab`, and
`LAB_RUNTIME_TARGET` is now `local-usb`.
