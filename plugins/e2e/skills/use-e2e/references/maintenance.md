# Other Features

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Volumes

Common workflow:

- inspect volume plans
- create hourly or committed volume
- attach a volume to a node
- mount the volume on the node at a chosen path
- list volumes

Common engineering use:

- add a data disk to a running server
- prepare storage before deploying an app

Inspect plans:

```bash
CLI volume plans --alias <alias>
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

List:

```bash
CLI volume list --alias <alias>
```

If size is already known:

```bash
CLI volume plans --size <size-gb> --alias <alias>
```

Attach to a node:

```bash
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <alias>
```

After attach, SSH into the node, detect the disk with `lsblk`, and mount it on the requested path.
Do not format an attached device unless it is a new empty volume and the user has allowed it.

## VPCs

Common workflow:

- inspect VPC plans
- create hourly or committed VPC
- list VPCs

Common engineering use:

- add private networking to a node
- prepare app networking before deploy

Inspect plans:

```bash
CLI vpc plans --alias <alias>
```

Create hourly:

```bash
CLI vpc create \
  --name <vpc-name> \
  --billing-type hourly \
  --cidr-source e2e \
  --alias <alias>
```

Create committed or custom CIDR:

```bash
CLI vpc create \
  --name <vpc-name> \
  --billing-type committed \
  --committed-plan-id <committed-plan-id> \
  --post-commit-behavior auto-renew \
  --cidr-source custom \
  --cidr <custom-cidr> \
  --alias <alias>
```

List:

```bash
CLI vpc list --alias <alias>
```

## SSH Keys

Common workflow:

- list current SSH keys
- upload a public key from file
- upload a public key from stdin
- attach the SSH key to a node

Common engineering use:

- enable access to a newly created node
- prepare SSH access before deploy or incident work

List:

```bash
CLI ssh-key list --alias <alias>
```

Create from file:

```bash
CLI ssh-key create \
  --label <key-label> \
  --public-key-file ~/.ssh/id_ed25519.pub \
  --alias <alias>
```

Create from stdin:

```bash
cat ~/.ssh/id_ed25519.pub | CLI ssh-key create \
  --label <key-label> \
  --public-key-file - \
  --alias <alias>
```

Attach to a node:

```bash
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <alias>
```

If `ssh-key list` returns no keys:

- ask for the SSH key label before upload
- suggest `~/.ssh/id_ed25519.pub` as the public key path
- suggest `node-access` if the user has no label preference
- upload first, then attach with the returned SSH key id

Do not use:

- `--name`
- `--key`
- `node attach`

## Install

```bash
npm install -g @e2enetworks-oss/e2ectl
```
