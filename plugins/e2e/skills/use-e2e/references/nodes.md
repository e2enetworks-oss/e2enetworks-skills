# Nodes

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Core Node Commands

List:

```bash
CLI node list --alias <alias>
```

Get:

```bash
CLI node get <node-id> --alias <alias>
```

OS discovery:

```bash
CLI node catalog os --alias <alias>
```

Plan and image discovery:

```bash
CLI node catalog plans \
  --alias <alias> \
  --display-category "<display-category>" \
  --category "<category>" \
  --os "<os>" \
  --os-version "<os-version>" \
  --billing-type all
```

Create:

```bash
CLI node create \
  --alias <alias> \
  --name <node-name> \
  --plan <plan> \
  --image <image>
```

Create with committed billing:

```bash
CLI node create \
  --alias <alias> \
  --name <node-name> \
  --plan <plan> \
  --image <image> \
  --billing-type committed \
  --committed-plan-id <committed-plan-id>
```

Delete:

```bash
CLI node delete <node-id> --force --alias <alias>
```

Ask for confirmation once before delete, then use `--force` for the actual command.

## Node Actions

Power off:

```bash
CLI node action power-off <node-id> --alias <alias>
```

Power on:

```bash
CLI node action power-on <node-id> --alias <alias>
```

Save image:

```bash
CLI node action save-image <node-id> --name <image-name> --alias <alias>
```

Attach VPC:

```bash
CLI node action vpc attach <node-id> --vpc-id <vpc-id> --alias <alias>
```

Attach volume:

```bash
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <alias>
```

Attach SSH key:

```bash
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <alias>
```

Do not use `node attach`.
Use `node action ssh-key attach` directly.

After any state-changing action, verify the actual node state:

```bash
CLI node get <node-id> --alias <alias>
```

If the user wants the current fleet view, follow with:

```bash
CLI node list --alias <alias>
```

Do not treat action `Status: done` as the final power state by itself.

## Create Rules

- ask for node name first
- use catalog discovery before create
- use exact `plan` and `image` values from catalog output
- if committed billing is requested, use the exact committed plan id returned by catalog
- if alias lookup fails, stop and resolve config before retrying
- confirm once before delete, not before every read command
- treat delete as an interactive confirmed action when the CLI prompts for confirmation

## Common Node Workflows

- inspect the current fleet with `node list`
- inspect one node with `node get`
- prepare a new node with `catalog os` and `catalog plans`
- create a node with hourly or committed billing
- upload SSH key if needed, then attach SSH key, VPC, or volume after create
- SSH into a ready node
- deploy a frontend or backend service
- mount a data volume on a chosen path
- power a node off or on
- confirm the real node status after power actions
- save a running node as an image
- attach VPC, volume, or SSH key to an existing node
- delete a node only after one confirmation
- if delete is interactive, complete it in a TTY session

## Common Engineering Workflows

- fleet inventory and node health checks
- node provisioning for a new app
- SSH access setup for a new node
- power cycle with final status verification
- save-image before risky changes
- app deploy or redeploy on a node
- incident checks on an already running server
- safe node retirement

## Provision to Deploy

Use this order for the common node lifecycle:

1. `node catalog os`
2. `node catalog plans`
3. `node create`
4. `ssh-key list`
5. `ssh-key create` if needed
6. `node action ssh-key attach`
7. `node action vpc attach` if needed
8. `node action volume attach` if needed
9. `node get`
10. SSH into the node after it is ready
11. deploy the requested service

For power actions:

1. `node action power-off` or `node action power-on`
2. `node get`
3. `node list` if the user wants the refreshed fleet status

Ask only for missing values:

- alias
- node name or node id
- SSH key id, or SSH key label and public key file path
- VPC id if needed
- volume id and mount path if needed
- private key path
- repo URL or local app path
- app type: frontend or backend

Default the SSH user to `root`. Only ask for SSH user if the user explicitly gives another user or `root` fails.
Suggest `/data` when a mount path is needed and none was provided.
Suggest `~/.ssh/id_ed25519.pub` when a public key file path is needed and none was provided.
Ask for the SSH key label before upload. Suggest `node-access` if the user has no preference.
If the user says things like deploy my server, run something on the node, or check what is running on the node, treat that as an SSH and deploy workflow.

## Upload and Attach SSH Key

List keys first:

```bash
CLI ssh-key list --alias <alias>
```

If no keys exist, upload from file:

```bash
CLI ssh-key create --label <key-label> --public-key-file ~/.ssh/id_ed25519.pub --alias <alias>
```

Or upload from stdin:

```bash
cat ~/.ssh/id_ed25519.pub | CLI ssh-key create --label <key-label> --public-key-file - --alias <alias>
```

Attach the uploaded or existing key:

```bash
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <alias>
```

Rules:

- use `--label`, not `--name`
- use `--public-key-file`, not `--key`
- ask for the SSH key label before upload
- prefer the public key file path over reading key contents into the prompt
- if the user did not provide a public key path, suggest `~/.ssh/id_ed25519.pub`
- if the user did not provide a label, suggest `node-access`
- after upload, use the returned SSH key id for attach

## SSH and Deploy

Check that the node is ready and has a reachable public IP first.

SSH:

```bash
ssh -i <private-key-path> <ssh-user>@<public-ip>
```

Default:

```bash
ssh -i <private-key-path> root@<public-ip>
```

Copy files when needed:

```bash
scp -i <private-key-path> -r <local-path> <ssh-user>@<public-ip>:<remote-path>
```

Default:

```bash
scp -i <private-key-path> -r <local-path> root@<public-ip>:<remote-path>
```

Deploy rules:

- ask for app type: frontend or backend
- ask for repo URL or local path if missing
- ask for env vars, port, build command, or start command only if needed
- prefer simple stable deploys over complex automation
- after deploy, verify the process or port and summarize the result in natural language

Common engineering uses:

- deploy a new frontend
- deploy a new backend
- update an existing frontend or backend
- inspect what is running on the server
- fix a broken service after SSH login

Power-action rules:

- after `power-off` or `power-on`, always run `node get`
- if the user asked to list nodes or see the current state, also run `node list`
- show the node status from the follow-up command, not just the action result

Delete rules:

- inspect the node first with `node get`
- ask for confirmation once
- if the CLI prompts for confirmation, use an interactive terminal
- after delete, refresh with `node list` when the user wants the updated fleet state

## Attach and Mount Volume

Attach first:

```bash
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <alias>
```

Then inspect disks on the node. Do not guess the device path:

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
```

Create the mount path:

```bash
sudo mkdir -p <mount-path>
```

Format only if the volume is new, empty, and the user has allowed it:

```bash
sudo mkfs.ext4 /dev/<device>
```

Mount:

```bash
sudo mount /dev/<device> <mount-path>
```

Get the UUID:

```bash
sudo blkid /dev/<device>
```

Persist the mount with the UUID in `/etc/fstab`.

## Output Rules

- summarize in natural language
- prefer tables or short bullet summaries
- do not show raw JSON unless asked
- after node actions, include the confirmed node status in the summary
- for node lists, prefer id, name, status, and public IP
- for node details, prefer id, name, status, plan, public IP, private IP, and created time
- after create, attach, or delete, say the next useful step
