# Security Group

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Overview

Security groups are sets of firewall rules attached to nodes. Rules are defined in a
backend-compatible JSON file. The `update` command performs a **full replacement** of
the rule set — it is not additive. Always provide the complete desired rule set when updating.

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

Update (full rule set replacement):

```bash
CLI security-group update <security-group-id> \
  --rules-file <path-to-rules.json> \
  --alias <alias>
```

Update with name or description change:

```bash
CLI security-group update <security-group-id> \
  --name <new-name> \
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

The `--rules-file` expects a backend-compatible JSON file. Ask the user to provide
the file path. If they want to pipe rules from stdin, use `--rules-file -`.

When the user asks to create or update a security group but has no file ready,
ask them:
- what inbound ports or protocols to allow (e.g. 22/SSH, 80/HTTP, 443/HTTPS)
- what source CIDRs to allow (e.g. `0.0.0.0/0` for public, specific IP for restricted)
- whether any outbound rules are needed

Then help them construct the JSON before running the command.

### Example rules.json (web server — SSH + HTTP + HTTPS)

```json
{
  "inbound_rules": [
    {
      "protocol": "tcp",
      "port_range": "22",
      "sources": { "addresses": ["0.0.0.0/0"] }
    },
    {
      "protocol": "tcp",
      "port_range": "80",
      "sources": { "addresses": ["0.0.0.0/0"] }
    },
    {
      "protocol": "tcp",
      "port_range": "443",
      "sources": { "addresses": ["0.0.0.0/0"] }
    }
  ],
  "outbound_rules": [
    {
      "protocol": "tcp",
      "port_range": "all",
      "destinations": { "addresses": ["0.0.0.0/0"] }
    }
  ]
}
```

If the user only wants SSH access (locked to their IP):

```json
{
  "inbound_rules": [
    {
      "protocol": "tcp",
      "port_range": "22",
      "sources": { "addresses": ["<your-ip>/32"] }
    }
  ],
  "outbound_rules": [
    {
      "protocol": "tcp",
      "port_range": "all",
      "destinations": { "addresses": ["0.0.0.0/0"] }
    }
  ]
}
```

Write the JSON to a temp file, then pass it to the command:

```bash
# Write rules to a temp file, then create
CLI security-group create --name <sg-name> --rules-file /tmp/rules.json --alias <alias>
```

## Output Rules

- after list, show id, name, description, and node attachment count
- after create, show the new security group id and suggest attaching it to a node
- after update, confirm which security group was updated and that the rule set was replaced
- after attach/detach, confirm the node and security group involved
- do not show raw JSON unless asked
