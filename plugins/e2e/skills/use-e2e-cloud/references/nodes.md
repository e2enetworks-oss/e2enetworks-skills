# Nodes

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Missing Specs — Ask Before Creating

If the user asks to create a node without specifying all required details, ask for each missing value one at a time using `AskUserQuestion` before running any command. Never assume or default any value silently.

**Step 1 — node name** (if not given):
Ask: "What would you like to name this node?"
Options: suggest 2–3 names derived from the user's stated purpose (e.g. if they said "run nginx", suggest `nginx-server`, `web-node`; if they said "postgres", suggest `postgres-node`, `db-server`). If no purpose was stated, suggest `my-node`, `node-1`. Always include `Enter a custom name` as the last option (free-text follow-up).

**Step 2 — OS** (run `node catalog os` first, then ask):
Ask: "Which operating system would you like?"
Options: one button per OS row from catalog output

**Step 3 — plan** (run `node catalog plans` for the chosen OS, then ask):
Ask: "Which plan suits your needs?"
Options: one button per plan from catalog output

**Step 4 — billing type** (if not given):
Ask: "How would you like to be billed?"
Options: `Hourly — pay as you go` / `Committed — save with a fixed term`

**Step 5 — committed plan** (only if committed billing chosen):
Ask: "Which committed plan would you like?"
Options: one button per committed option from catalog output

**Step 6 — root disk size** (only if selected plan is E1 or E1WC):
Ask: "How much root disk space do you need?"
Options: `75 GB` / `100 GB` / `150 GB` / `200 GB` / `Enter a custom size` (free-text follow-up; valid range 75–2400 GB)

**Step 7 — SSH key**:

Decide whether deployment / shell access is implied for this node:

- **Deployment implied** — the user's stated purpose involves deploying, running, installing, configuring, or SSH-ing into the node (e.g. "create a node and deploy my app", "set up nginx", "I want to SSH in", "host a backend").
- **Bare provisioning** — the user asked only to provision a node with no follow-on action that needs shell access.

**If deployment is implied — do not ask. Auto-attach the current host's SSH key:**

1. Read the local public key from `~/.ssh/id_ed25519.pub` (or `~/.ssh/id_rsa.pub` if the ed25519 key is missing). If neither exists, generate one with `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""` and proceed.
2. Run `ssh-key list` to check whether the same public key is already uploaded under any label.
3. If found, capture its `<ssh-key-id>` and attach it at create time via `--ssh-key-id`. If not found, upload it with `ssh-key create --label node-access --public-key-file ~/.ssh/id_ed25519.pub --alias <alias>`, then attach at create time.
4. Tell the user in one line what happened, e.g. "Using your local SSH key (`node-access`) so we can deploy after the node is up."

Do not surface an SSH-key question, list, or `Skip` option in this path.

**If bare provisioning — keep it optional:**

Run `ssh-key list`. If keys exist, ask: "Would you like to attach an SSH key at creation?"
Options: one button per existing key label plus `No SSH key`
If no keys exist, ask: "No SSH keys found. Would you like to upload one now?"
Options: `Yes, upload my key` / `Skip`

**Step 8 — saved image** (only if the user mentioned a saved image — run `image list` first):
Ask: "Which saved image would you like to start from?"
Options: one button per saved image name plus `None — use a standard image`

**Step 9 — private network (VPC)**:
Ask: "Would you like to connect this node to a private network?"
Options: `Yes` / `No`
If yes: run `vpc list`, ask: "Which VPC would you like to use?" with one button per VPC showing name and CIDR.

**Step 10 — reserved IP** (run `reserved-ip list` first):
Ask: "Would you like to assign a reserved IP to this node?"
Options: one button per available unattached reserved IP (showing the IP address) plus `No — use the default public IP`

**Security group:** Only include if the user explicitly specifies one. Do not ask — the CLI attaches the region default automatically.

**Step 11 — confirmation summary:**
Before running any command, display a summary of all selected options:

> Here's what will be created:
> - **Name:** `<name>`
> - **OS:** `<os>`
> - **Plan:** `<plan>`
> - **Billing:** `<hourly / committed plan>`
> - **SSH Key:** `<key label or None>`
> - **VPC:** `<vpc name or None>`
> - **Reserved IP:** `<ip or None>`

Ask: "Ready to create this node?"
Options: `Yes, create it` / `No, go back`

If "No, go back" — ask which detail they'd like to change and loop back to that step.

Do not proceed to `node create` until the user confirms with "Yes, create it".

## Catalog Discovery (required before create)

**Always run these two commands before `node create`. Never skip them.**

`node catalog plans` requires all four flags: `--display-category`, `--category`, `--os`, `--os-version`. The correct values come from `catalog os` output — do not guess them.

Step 1 — discover valid OS rows:

```bash
CLI node catalog os --alias <alias>
```

The output table gives the exact values to use for all four flags. Pick the row that matches the OS the user wants.

Step 2 — discover plans for that OS row:

```bash
CLI node catalog plans \
  --alias <alias> \
  --display-category "<display-category from catalog os>" \
  --category "<category from catalog os>" \
  --os "<os from catalog os>" \
  --os-version "<os-version from catalog os>" \
  --billing-type all
```

Only after running both commands do you have the exact `--plan` string and `--image` value needed for `node create`.

**If you get an error about a missing required flag on `catalog plans`, stop. Run `catalog os` first — do not call `--help`.**

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

Plan and image discovery (all four OS flags required — never call bare):

```bash
CLI node catalog plans \
  --alias <alias> \
  --display-category "<display-category>" \
  --category "<category>" \
  --os "<os>" \
  --os-version "<os-version>" \
  --billing-type all
```

Create (hourly):

```bash
CLI node create \
  --alias <alias> \
  --name <node-name> \
  --plan "<full-plan-string-from-catalog>" \
  --image <image>
```

Create (committed billing):

```bash
CLI node create \
  --alias <alias> \
  --name <node-name> \
  --plan "<full-plan-string-from-catalog>" \
  --image <image> \
  --billing-type committed \
  --committed-plan-id <committed-plan-id>
```

Create (E1 / E1WC plans — `--disk` required, rejected for all other plans):

```bash
CLI node create \
  --alias <alias> \
  --name <node-name> \
  --plan "<full-plan-string-from-catalog>" \
  --image <image> \
  --disk <root-disk-size-gb>
```

Create with SSH key attached at creation time (repeatable for multiple keys):

```bash
CLI node create \
  --alias <alias> \
  --name <node-name> \
  --plan "<full-plan-string-from-catalog>" \
  --image <image> \
  --ssh-key-id <ssh-key-id>
```

Create from a saved image (add `--saved-image-template-id` to a regular create):

```bash
CLI node create \
  --alias <alias> \
  --name <node-name> \
  --plan "<full-plan-string-from-catalog>" \
  --image <catalog-image> \
  --saved-image-template-id <template-id>
```

`<catalog-image>` is the same image identifier from `node catalog plans` (e.g. `Ubuntu-24.04-Distro`). Find `<template-id>` in the `Template ID` column of `e2ectl image list`. See `references/image.md` for the full saved-image workflow.

The `--plan` value must be the exact full string from `node catalog plans` output
(e.g. `"c2.large (8 vCPUs / 16 GB RAM / 100 GB SSD)"`).
Never use the SKU shortname alone (e.g. `c2.large`) — it causes a 412 error.

Upgrade plan/image on an existing node:

```bash
CLI node upgrade <node-id> \
  --plan "<full-plan-string-from-catalog>" \
  --image <image> \
  --force \
  --alias <alias>
```

Delete:

```bash
CLI node delete <node-id> --force --alias <alias>
```

Delete and preserve the node's current public IP as a reserved IP:

```bash
CLI node delete <node-id> --reserve-public-ip --force --alias <alias>
```

Ask for confirmation once before delete. When confirmed, always use `--force`.

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

Detach primary public IPv4 (node may lose public reachability — confirm with user first):

```bash
CLI node action public-ip detach <node-id> --force --alias <alias>
```

Attach VPC (use the canonical VPC ID — the `network_id` shown by `vpc list/create`):

```bash
CLI node action vpc attach <node-id> --vpc-id <network-id> --alias <alias>
```

Optional flags: `--subnet-id`, `--private-ip`.

Detach VPC:

```bash
CLI node action vpc detach <node-id> --vpc-id <network-id> --alias <alias>
```

Attach volume:

```bash
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <alias>
```

Detach volume:

```bash
CLI node action volume detach <node-id> --volume-id <volume-id> --alias <alias>
```

Attach security group (repeatable for multiple groups):

```bash
CLI node action security-group attach <node-id> --security-group-id <sg-id> --alias <alias>
```

Detach security group (repeatable for multiple groups):

```bash
CLI node action security-group detach <node-id> --security-group-id <sg-id> --alias <alias>
```

Attach SSH key (repeatable for multiple keys):

```bash
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <alias>
```

Do not use `node attach`. Always use the `node action <resource> attach` form.
`node action ssh-key attach` only works when the node is in `Running` status.

After any state-changing action, verify the actual node state:

```bash
CLI node get <node-id> --alias <alias>
```

If the user wants the current fleet view, follow with:

```bash
CLI node list --alias <alias>
```

Do not treat action `Status: done` as the final power state by itself.

## Rules

- ask for node name first
- run `catalog os` then `catalog plans` — never skip catalog discovery before create
- use the exact `plan` string and `image` value from catalog output
- if committed billing is requested, use the exact committed plan id from catalog
- for E1/E1WC plans, ask for root disk size and pass `--disk`; valid range is 75–2400 GB, default is 150 GB, increments are 25 GB up to 150 GB then 50 GB above 150 GB
- reserved IP is **bundled** with all node plans except E1 — the node's public IP is already a reserved IP; no extra `reserved-ip create` needed for non-E1 nodes
- E1 nodes do **not** include a bundled reserved IP; allocate one separately if a stable public IP is needed
- if alias lookup fails, stop and resolve config before retrying
- SSH keys can be attached at create time with `--ssh-key-id` — no need for a separate attach step if the key already exists
- to create from a saved image, run `image list` first to get the `Template ID`, then add `--saved-image-template-id <template-id>` to the standard create command; `--image` still takes the catalog image identifier, not the saved image name

## Node Lifecycle Order

1. `node catalog os`
2. `node catalog plans`
3. `node create`
4. poll `node get` until status is `Running` before any attach actions
5. `ssh-key list` — upload with `ssh-key create` if needed
6. `node action ssh-key attach` (or use `--ssh-key-id` at create time)
7. `node action vpc attach` if private networking is needed
8. `node action security-group attach` if firewall rules are needed
9. `node action volume attach` if storage is needed
10. `node get` to confirm all attachments
11. SSH into the node
12. deploy the requested service

For power actions:

1. `node action power-off` or `node action power-on`
2. `node get`
3. `node list` if the user wants refreshed fleet status

## Upload and Attach SSH Key

List keys first:

```bash
CLI ssh-key list --alias <alias>
```

If no matching key exists, upload from file:

```bash
CLI ssh-key create --label <key-label> --public-key-file ~/.ssh/id_ed25519.pub --alias <alias>
```

Attach:

```bash
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <alias>
```

Rules:
- use `--label`, not `--name`
- use `--public-key-file`, not `--key`
- if a key with the same label already exists, ask: use existing or upload new?
- if `ssh-key create` returns "You cannot add the same key again", run `ssh-key list`, find the match, ask the user
- never retry `ssh-key create` with the same key content after that error
- suggest `node-access` if the user has no label preference
- suggest `~/.ssh/id_ed25519.pub` if no public key path is given

## SSH and Deploy

Check that the node is `Running` and has a public IP first.

SSH:

```bash
ssh -i <private-key-path> root@<public-ip>
```

Copy files:

```bash
scp -i <private-key-path> -r <local-path> root@<public-ip>:<remote-path>
```

Default SSH user is `root`. Only ask for a different user if the user explicitly requests one or `root` fails.

## Attach and Mount Volume

Attach:

```bash
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <alias>
```

Inspect disks on the node — do not guess the device path:

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

Get UUID and persist in `/etc/fstab`:

```bash
sudo blkid /dev/<device>
```

Suggest `/data` if no mount path is provided.

## Delete Rules

- inspect the node first with `node get`
- ask for confirmation once
- always use `--force` — all delete commands require it in non-interactive terminals
- if the user wants to keep the IP, use `--reserve-public-ip`
- after delete, refresh with `node list` if the user wants the updated fleet

## Error Recovery

| Error | Cause | Fix |
|---|---|---|
| `412` on `node create` | `--plan` is a SKU shortname, not the full string | Re-run `catalog plans`, copy the exact full string including parenthetical spec |
| `node action * attach` fails immediately | Node is still `Creating` | Poll `node get` until status is `Running`, then retry the attach |
| `You cannot add the same key again` on `ssh-key create` | Key content already uploaded under a different label | Run `ssh-key list`, find the existing key, use its id with `node action ssh-key attach` |
| `node upgrade` rejected | Plan string is a shortname or contains extra whitespace | Re-run `catalog plans` and copy the exact string from output |
| `node action vpc attach` returns "VPC not found" | VPC is still `Creating` | Poll `vpc list` until state is `Active`, then retry attach |

## Output Rules

- prefer natural language summaries
- for node lists: id, name, status, public IP
- for node details: id, name, status, plan, public IP, private IP, created time
- after actions, include the confirmed node status from the follow-up `node get`
- after create, attach, or delete, say the next useful step
- do not show raw JSON unless asked

