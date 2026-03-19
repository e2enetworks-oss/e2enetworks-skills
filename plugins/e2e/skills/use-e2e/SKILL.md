---
name: use-e2e
description: Manage E2E Networks resources with the published npm CLI. Nodes are the main task. Also handle node actions, volumes, VPCs, and SSH keys with short natural-language output.
---

# use-e2e

Use this skill when the user wants E2E Networks infrastructure work.

Temporary release note:
- `hitesh-test` is a temporary pre-release testing package.
- The long-term public dependency is the official `e2ectl` package.
- Before this skill pack is published publicly, remove `hitesh-test` fallback/install references and rely solely on `e2ectl`.

## 1. Resolve CLI

Use this order:

- `e2ectl`
- `hitesh-test`
- if neither exists, ask:
  - install globally
  - install in this project

Install commands:

```bash
npm i -g hitesh-test
```

```bash
npm i hitesh-test
npx hitesh-test --help
```

If project-local install is chosen, use `npx hitesh-test` for later commands.

Do not spend tokens on repeated `--help` for the commands listed below. Use the documented workflows directly. Only use `--help` if a command is missing, changed, or failing unexpectedly.

## 2. Resolve Config

- run `config list`
- if aliases exist, ask:
  - use existing
  - import new
- if no usable config exists, ask:
  - use a config file already on this machine
  - upload a config file
- prefer `config import` when a file is available
- after choosing or importing a profile, check whether default project id and default location are present in the config itself
- if either one is missing, prompt for both:
  - project id
  - location
- if an existing alias is missing project or location, use `config set-context`
- if no usable alias exists, use `config import`
- if a resource command returns `Profile "<alias>" was not found`, stop and resolve config before continuing

Saved profiles live in `~/.e2e/config.json`.

## 3. Primary Workflows

- config list
- node list
- node get
- node catalog os
- node catalog plans
- node create
- node delete

## 4. Common Cloud Workflows

- inspect saved profiles and defaults
- list current nodes
- inspect one node
- discover OS, plan, image, and billing options
- create a node
- power off or power on a node
- save a node as an image
- attach a VPC to a node
- attach and mount a volume on a node
- upload and attach an SSH key to a node
- SSH into a ready node
- deploy a frontend or backend service on a node
- inspect volume plans
- create a volume
- list volumes
- inspect VPC plans
- create a VPC
- list VPCs
- list SSH keys
- upload an SSH key

## 5. Engineer Workflows

Common workflows an infrastructure or platform engineer may ask for:

- check the current fleet and node status
- provision a fresh node for an app
- upload and attach SSH access
- create and attach a VPC
- create, attach, and mount a data volume
- deploy a frontend on a node
- deploy a backend on a node
- update or redeploy an existing app
- inspect a server that is already running something
- power cycle a node and verify the final state
- save an image before risky maintenance
- retire a node safely

## 6. Node-First Behavior

Main tasks:

- list nodes
- get node details
- discover OS and plan/image pairs
- create nodes
- delete nodes
- run node actions
- verify actual node status after actions
- attach VPC, SSH key, or volume after create
- SSH into a ready node
- deploy services on a node

For create:

- ask for node name
- ask for alias or project/location context
- discover OS rows first
- discover exact plan/image values next
- use the exact returned plan and image
- if billing matters, ask hourly vs committed and use the exact committed plan id when needed

For delete:

- list or inspect first
- confirm once before delete
- treat delete as an interactive confirmed action
- if running in a non-interactive terminal, explain that delete needs confirmation and use an interactive terminal session when possible

For node actions:

- after `node action power-off`, `node action power-on`, or other state-changing actions, re-check the node with `node get <node-id>` or `node list`
- show the actual current node status from that follow-up check
- do not present only `Action ID` or action `Status: done` as the final node state

## 7. Access, Storage, and Deploy

For common provision-to-deploy work:

- create the node
- upload SSH key if none exists
- attach SSH key
- attach VPC if private networking is needed
- attach a volume if data storage is needed
- wait for the node to be ready and get its public IP
- SSH into the node
- mount the data volume on the guest OS if one was attached
- deploy the requested frontend or backend service

Ask only for missing values:

- alias
- SSH key id, or SSH key label and public key file path
- project id and location when profile defaults are missing
- node id or public IP
- private key path
- volume id and mount path when storage is involved
- repo URL or local app path
- app type
- env vars, port, or start command only if needed

Default the SSH user to `root`. Only ask for SSH user if the user explicitly gives another user or `root` fails.
Do not guess a Linux block device path. Inspect it on the node first.
Do not format a volume unless it is new and the user has allowed it.
Suggest `/data` when a mount path is needed and the user has not provided one.
Suggest `~/.ssh/id_ed25519.pub` when a public key file path is needed and the user has not provided one.
Ask for the SSH key label before upload. Suggest `node-access` if the user has no preference.
If the user says things like deploy my server, run something on the node, or check what is running on the node, treat that as an SSH and deploy workflow.

## 8. Other Package Features

If the user asks beyond nodes, this package also supports:

- node actions such as power on, power off, save image, attach VPC, attach volume, and attach SSH key
- volume plans, create, and list
- VPC plans, create, and list
- SSH key list and create

Explain these in short natural language first. Only expand into exact commands when needed.

## 9. Common Workflows

Use `CLI` below as the resolved command.

Nodes:

```bash
CLI node list --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
CLI node action power-off <node-id> --alias <profile-alias>
CLI node action power-on <node-id> --alias <profile-alias>
CLI node action save-image <node-id> --name <image-name> --alias <profile-alias>
CLI node action vpc attach <node-id> --vpc-id <vpc-id> --alias <profile-alias>
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <profile-alias>
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <profile-alias>
CLI node delete <node-id> --alias <profile-alias>
CLI node create --alias <profile-alias> --name <node-name> --plan <plan> --image <image> --billing-type committed --committed-plan-id <committed-plan-id>
```

Action verification:

```bash
CLI node action power-off <node-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
CLI node action power-on <node-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
```

If the user asked for the latest fleet state, run `node list` after the action and show the node status from there.

Delete workflow:

```bash
CLI node get <node-id> --alias <profile-alias>
CLI node delete <node-id> --alias <profile-alias>
```

Ask for confirmation once before delete.
If the CLI requires an interactive confirmation prompt, use an interactive terminal session instead of assuming a one-shot delete will succeed.

Common engineering sequences:

```bash
CLI node list --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
CLI node action save-image <node-id> --name <image-name> --alias <profile-alias>
CLI node action power-off <node-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
CLI node action power-on <node-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
```

Use this for:

- fleet checks
- pre-change backup image
- safe power cycle
- incident or maintenance follow-up

Provision and deploy:

```bash
CLI node create --alias <profile-alias> --name <node-name> --plan <plan> --image <image>
CLI ssh-key list --alias <profile-alias>
CLI ssh-key create --label <key-label> --public-key-file ~/.ssh/id_ed25519.pub --alias <profile-alias>
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <profile-alias>
CLI node action vpc attach <node-id> --vpc-id <vpc-id> --alias <profile-alias>
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
ssh -i <private-key-path> <ssh-user>@<public-ip>
scp -i <private-key-path> -r <local-path> <ssh-user>@<public-ip>:<remote-path>
```

Default SSH examples:

```bash
ssh -i <private-key-path> root@<public-ip>
scp -i <private-key-path> -r <local-path> root@<public-ip>:<remote-path>
```

SSH key workflow:

```bash
CLI ssh-key list --alias <profile-alias>
CLI ssh-key create --label <key-label> --public-key-file ~/.ssh/id_ed25519.pub --alias <profile-alias>
cat ~/.ssh/id_ed25519.pub | CLI ssh-key create --label <key-label> --public-key-file - --alias <profile-alias>
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <profile-alias>
```

If `ssh-key list` shows no keys, upload one before trying to attach.
Use `--label`, not `--name`.
Use `--public-key-file`, not `--key`.
Do not call `node attach`; use `node action ssh-key attach`.
Ask for the SSH key label before upload instead of inventing one silently.

Mount a data volume on the node:

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
sudo mkdir -p <mount-path>
sudo mkfs.ext4 /dev/<device>
sudo mount /dev/<device> <mount-path>
sudo blkid /dev/<device>
```

Add the mounted disk to `/etc/fstab` with the returned UUID after mount.
Only run `mkfs.ext4` for a new empty volume and only after confirmation.

Volumes:

```bash
CLI volume plans --alias <profile-alias>
CLI volume create --name <volume-name> --size <size-gb> --billing-type hourly --alias <profile-alias>
CLI volume create --name <volume-name> --size <size-gb> --billing-type committed --committed-plan-id <committed-plan-id> --post-commit-behavior auto-renew --alias <profile-alias>
CLI volume list --alias <profile-alias>
```

If size is already known:

```bash
CLI volume plans --size <size-gb> --alias <profile-alias>
```

Storage workflow:

```bash
CLI volume create --name <volume-name> --size <size-gb> --billing-type hourly --alias <profile-alias>
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <profile-alias>
ssh -i <private-key-path> root@<public-ip>
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
sudo mkdir -p <mount-path>
sudo mount /dev/<device> <mount-path>
```

VPCs:

```bash
CLI vpc plans --alias <profile-alias>
CLI vpc create --name <vpc-name> --billing-type hourly --cidr-source e2e --alias <profile-alias>
CLI vpc create --name <vpc-name> --billing-type committed --committed-plan-id <committed-plan-id> --post-commit-behavior auto-renew --cidr-source custom --cidr <custom-cidr> --alias <profile-alias>
CLI vpc list --alias <profile-alias>
```

Networking workflow:

```bash
CLI vpc create --name <vpc-name> --billing-type hourly --cidr-source e2e --alias <profile-alias>
CLI node action vpc attach <node-id> --vpc-id <vpc-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
```

SSH keys:

```bash
CLI ssh-key list --alias <profile-alias>
CLI ssh-key create --label <key-label> --public-key-file ~/.ssh/id_ed25519.pub --alias <profile-alias>
cat ~/.ssh/id_ed25519.pub | CLI ssh-key create --label <key-label> --public-key-file - --alias <profile-alias>
```

App deployment workflow:

```bash
CLI node get <node-id> --alias <profile-alias>
ssh -i <private-key-path> root@<public-ip>
scp -i <private-key-path> -r <local-path> root@<public-ip>:<remote-path>
```

Use this for:

- deploy frontend
- deploy backend
- update an existing app
- inspect or fix a running server

## 10. Output Rules

- keep replies short
- prefer natural language summaries
- use `--json` only for internal parsing
- do not dump raw JSON unless asked
- do not print secrets
- for SSH or deploy work, summarize the host, path, service status, and next step instead of dumping long logs
- for node actions, summarize both the action receipt and the follow-up node status

## 11. Codex CLI UX

- start with a one-line summary of the step being taken
- ask one short question at a time
- if multiple values are missing for one task, ask for them in one compact prompt
- for node lists, show a compact summary with id, name, status, and public IP when available
- for node details, show a short readable summary with id, name, status, plan, and IPs
- for create or attach flows, say what was created or attached and the next useful step
- for errors, explain the problem in simple language and say how to fix it next
- do not show internal reasoning, repeated help text, or raw command noise unless the user asks

## References

- access and config: `references/access.md`
- nodes and node actions: `references/nodes.md`
- volumes, VPCs, SSH keys, release notes: `references/maintenance.md`
