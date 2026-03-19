---
name: use-e2e
description: Manage E2E Networks resources. Use nodes first, then actions, volumes, VPCs, and SSH keys. Keep output short.
---

# use-e2e

CLI order:

- `hitesh-test`
- `e2ectl`
- if missing, ask whether to install globally or in this project

Config:

- run `config list`
- if aliases exist, ask whether to use existing or import new
- if no usable config exists, ask whether to use a config file already on this machine or upload a config file
- prefer `config import` when a file is available
- after choosing or importing a profile, check whether default project id and default location are present in the config itself
- if either one is missing, prompt for both before resource commands
- if a resource command returns `Profile "<alias>" was not found`, stop and resolve config first

Primary workflows:

- `node list`
- `node get`
- `node catalog os`
- `node catalog plans`
- `node create`
- `node delete`

Common cloud workflows:

- inspect current nodes
- inspect one node
- create a node
- power off or power on a node
- verify the actual node status after a power action
- save image from a node
- upload SSH key if needed, then attach VPC, volume, or SSH key to a node
- mount an attached volume on the node
- SSH into a ready node
- deploy a frontend or backend service on the node
- create and list volumes
- create and list VPCs
- list and upload SSH keys

Also supported:

- `node action ...`
- `volume ...`
- `vpc ...`
- `ssh-key ...`

Do not spend tokens on repeated `--help` for known workflows.
Use `--json` only for internal parsing.
Do not show raw API calls, secrets, or raw JSON unless asked.
For SSH or deploy work, ask only for the missing values and summarize the final host, path, and service status.
For SSH key work, use `ssh-key list`, `ssh-key create --label --public-key-file`, and `node action ssh-key attach` directly.
Ask for the SSH key label before upload. Suggest `node-access` if needed.
Default the SSH user to `root` unless the user explicitly provides another user.
Treat prompts like deploy my server, run something on the node, or check what is running as SSH/deploy workflows.
After `node action power-off` or `node action power-on`, run `node get` or `node list` and show the actual node status.
Treat `node delete` as an interactive confirmed workflow when the CLI prompts for confirmation.
