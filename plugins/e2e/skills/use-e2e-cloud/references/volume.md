# Volume

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Overview

Always run `volume plans` before `volume create`. Minimum sizes vary by location
(e.g. Chennai minimum is 100 GB). Never assume a user-supplied size is valid —
verify it against the plans output first. If the requested size is not in the
plans output, show the available sizes and ask which to use.

## Commands

Inspect available sizes, IOPS, and committed options:

```bash
CLI volume plans --alias <alias>
```

Inspect a specific size:

```bash
CLI volume plans --size <size-gb> --alias <alias>
```

Inspect only currently available sizes:

```bash
CLI volume plans --available-only --alias <alias>
```

Create hourly:

```bash
CLI volume create \
  --name <volume-name> \
  --size <size-gb> \
  --billing-type hourly \
  --alias <alias>
```

Create committed:

```bash
CLI volume create \
  --name <volume-name> \
  --size <size-gb> \
  --billing-type committed \
  --committed-plan-id <committed-plan-id> \
  --post-commit-behavior auto-renew \
  --alias <alias>
```

`--post-commit-behavior` choices: `auto-renew` or `hourly-billing`.

List:

```bash
CLI volume list --alias <alias>
```

Get details:

```bash
CLI volume get <volume-id> --alias <alias>
```

Delete:

```bash
CLI volume delete <volume-id> --force --alias <alias>
```

## Attach and Mount on a Node

Attach:

```bash
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <alias>
```

Detach:

```bash
CLI node action volume detach <node-id> --volume-id <volume-id> --alias <alias>
```

After attaching, SSH into the node, inspect the device, and mount:

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
sudo mkdir -p <mount-path>
sudo mkfs.ext4 /dev/<device>      # only for new empty volumes, with user confirmation
sudo mount /dev/<device> <mount-path>
sudo blkid /dev/<device>           # get UUID for /etc/fstab
```

Suggest `/data` if no mount path is provided.
Do not guess the block device path — always run `lsblk` first.
Do not format a volume unless it is new, empty, and the user has explicitly allowed it.

## Rules

Before deleting a volume, check its status with `volume list` or `volume get`.

If status is `Attached` (or delete returns a 412 "detach first" error):
1. Tell the user the volume is attached and must be detached first.
2. Run detach:
   ```bash
   CLI node action volume detach <node-id> --volume-id <volume-id> --alias <alias>
   ```
3. Confirm with the user before proceeding to delete.
4. Only run `volume delete` after status is no longer `Attached`.

## Output Rules

- after `volume plans`, summarize available sizes, IOPS, and billing options
- after create, show volume id, name, size, and next step (attach to a node)
- after attach, say which node and volume are now connected and suggest mount steps
- do not show raw JSON unless asked

