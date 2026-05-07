# Reserved IP

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Pricing

- **INR:** ₹199/month
- **USD:** $3/month

## Overview

Reserved IPs are static public IPv4 addresses that can be attached to and detached
from nodes independently of the node lifecycle. Use them to keep a stable IP across
node replacements or to preserve an IP before deleting a node.

**Bundled vs. unbundled:**
- All node plans **except E1** include a reserved IP bundled at no extra cost. The node's
  public IP is already a reserved IP and does not require a separate `reserved-ip create`.
- **E1 nodes do not include a bundled reserved IP.** If an E1 node needs a stable public IP,
  allocate one explicitly with `reserved-ip create` and attach it.

All commands use `<ipAddress>` (the dotted-decimal IP string) as the resource identifier,
not a numeric ID.

## Commands

List all reserved IPs:

```bash
CLI reserved-ip list --alias <alias>
```

Get details for one reserved IP:

```bash
CLI reserved-ip get <ip-address> --alias <alias>
```

Allocate a new reserved IP from the default network:

```bash
CLI reserved-ip create --alias <alias>
```

No extra flags needed — the IP is allocated automatically.

Preserve a node's current public IP as a reserved IP (before or during deletion):

```bash
CLI reserved-ip reserve node <node-id> --alias <alias>
```

Attach a reserved IP to a node:

```bash
CLI reserved-ip attach node <ip-address> --node-id <node-id> --alias <alias>
```

Detach a reserved IP from a node:

```bash
CLI reserved-ip detach node <ip-address> --node-id <node-id> --alias <alias>
```

Delete a reserved IP:

```bash
CLI reserved-ip delete <ip-address> --force --alias <alias>
```

## Common Workflows

Keep a node's IP before deleting it (two ways):

Option A — reserve then delete:
```bash
CLI reserved-ip reserve node <node-id> --alias <alias>
CLI node delete <node-id> --force --alias <alias>
```

Option B — delete with built-in reservation flag:
```bash
CLI node delete <node-id> --reserve-public-ip --force --alias <alias>
```

Allocate a fresh IP and attach to a node:

```bash
CLI reserved-ip create --alias <alias>
# note the ip_address from the output
CLI reserved-ip attach node <ip-address> --node-id <node-id> --alias <alias>
CLI node get <node-id> --alias <alias>
```

Swap a reserved IP from one node to another:

```bash
CLI reserved-ip detach node <ip-address> --node-id <old-node-id> --alias <alias>
CLI reserved-ip attach node <ip-address> --node-id <new-node-id> --alias <alias>
```

## Output Rules

- after list, show ip_address, status (attached/free), and attached node id if any
- after reserve or create, show the ip_address and suggest the next step (attach or keep for later)
- after attach, confirm the node now uses the reserved IP
- after detach, confirm the IP is now free and can be reused
- do not show raw JSON unless asked

