# Security Group

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Overview

Security groups are sets of firewall rules attached to nodes and load balancers. Rules are defined in a
backend-compatible JSON file. The `update` command performs a **full replacement** of
the rule set — it is not additive. Always provide the complete desired rule set when updating.

- **Nodes:** attach via `node action security-group attach`
- **Load balancers:** attach at create time via `--security-group <sg-id>` on `lb create`
- **DBaaS:** security groups do **not** apply — access is controlled via IP whitelisting (`dbaas whitelist`)

## Commands

List security groups:

```bash
CLI security-group list --alias <alias>
```

Get details for a security group:

```bash
CLI security-group get <security-group-id> --alias <alias>
```

Create from a JSON rules file:

```bash
CLI security-group create \
  --name <sg-name> \
  --rules-file <path-to-rules.json> \
  --alias <alias>
```

Create with optional flags:

```bash
CLI security-group create \
  --name <sg-name> \
  --rules-file <path-to-rules.json> \
  --description "<description>" \
  --default \
  --alias <alias>
```

`--default` marks this security group as the account default.
`--rules-file -` reads rules from stdin.

Update (full rule set replacement — `--name` is required):

```bash
CLI security-group update <security-group-id> \
  --name <security-group-name> \
  --rules-file <path-to-rules.json> \
  --alias <alias>
```

Update with description change:

```bash
CLI security-group update <security-group-id> \
  --name <security-group-name> \
  --rules-file <path-to-rules.json> \
  --description "<new-description>" \
  --alias <alias>
```

Omit `--description` to keep the current description unchanged.

Delete:

```bash
CLI security-group delete <security-group-id> --force --alias <alias>
```

## Attach and Detach on a Node

Attach one or more security groups to a node (repeat `--security-group-id` for multiple):

```bash
CLI node action security-group attach <node-id> \
  --security-group-id <sg-id> \
  --alias <alias>
```

Detach one or more security groups from a node:

```bash
CLI node action security-group detach <node-id> \
  --security-group-id <sg-id> \
  --alias <alias>
```

## Common Workflows

Create a security group and attach it to a node:

```bash
# 1. Create the security group
CLI security-group create \
  --name <sg-name> \
  --rules-file rules.json \
  --alias <alias>

# 2. Note the security group id from the output
# 3. Attach to the node
CLI node action security-group attach <node-id> \
  --security-group-id <sg-id> \
  --alias <alias>

# 4. Verify
CLI node get <node-id> --alias <alias>
```

Replace the rule set on an existing security group:

```bash
# Provide the full desired rule set — this is a complete replacement, not a patch
CLI security-group update <security-group-id> \
  --name <security-group-name> \
  --rules-file updated-rules.json \
  --alias <alias>
```

Remove a security group from a node before deleting it:

```bash
CLI node action security-group detach <node-id> \
  --security-group-id <sg-id> \
  --alias <alias>
CLI security-group delete <sg-id> --force --alias <alias>
```

## Rules File Format

The `--rules-file` expects a flat JSON array of rule objects. Each rule has these fields:

| Field           | Values                                                                      |
| --------------- | --------------------------------------------------------------------------- |
| `rule_type`     | `"Inbound"` or `"Outbound"`                                                 |
| `protocol_name` | `"Custom_TCP"`, `"Custom_UDP"`, `"All"`, `"ICMP"`                           |
| `port_range`    | port number as string (e.g. `"22"`), range (e.g. `"8000-9000"`), or `"All"` |
| `network`       | CIDR string (e.g. `"0.0.0.0/0"`, `"10.0.0.0/8"`) or `"any"`                 |
| `description`   | human-readable label (optional but recommended)                             |

When the user asks to create or update a security group but has no file ready,
ask them:

- what inbound ports or protocols to allow (e.g. 22/SSH, 80/HTTP, 443/HTTPS)
- whether to restrict source to a specific IP or allow `"any"`
- whether any outbound rules are needed (default: allow all outbound)

Then construct the JSON and write it to a temp file before running the command.

### Example rules.json (web server — SSH + HTTP + all outbound)

```json
[
  {
    "rule_type": "Inbound",
    "protocol_name": "Custom_TCP",
    "port_range": "22",
    "network": "any",
    "description": "SSH access"
  },
  {
    "rule_type": "Inbound",
    "protocol_name": "Custom_TCP",
    "port_range": "80",
    "network": "any",
    "description": "HTTP"
  },
  {
    "rule_type": "Inbound",
    "protocol_name": "Custom_TCP",
    "port_range": "443",
    "network": "any",
    "description": "HTTPS"
  },
  {
    "rule_type": "Outbound",
    "protocol_name": "All",
    "port_range": "All",
    "network": "any",
    "description": "All outbound"
  }
]
```

SSH only, locked to a specific IP:

```json
[
  {
    "rule_type": "Inbound",
    "protocol_name": "Custom_TCP",
    "port_range": "22",
    "network": "<your-ip>/32",
    "description": "SSH from my IP"
  },
  {
    "rule_type": "Outbound",
    "protocol_name": "All",
    "port_range": "All",
    "network": "any",
    "description": "All outbound"
  }
]
```

Write the JSON to a temp file, then pass it to the command:

```bash
# Write rules to a temp file, then create
CLI security-group create --name <sg-name> --rules-file /tmp/rules.json --alias <alias>
```

## Output Rules

- after list, show id, name, description, and node attachment count
- after create, show the new security group id and suggest attaching it to a node or using `--security-group` on `lb create`
- after attach/detach, confirm the node and security group involved
- do not show raw JSON unless asked
