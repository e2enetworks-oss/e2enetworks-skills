# E2E Networks Skills

Agent skill for [E2E Networks](https://www.e2enetworks.com), following the [Agent Skills](https://agentskills.io) format.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | bash
```

Supports Claude Code, OpenAI Codex, OpenCode, Cursor or any coding agent. Run the installer again to update.

### Claude Code plugin marketplace

```
/plugin marketplace add e2enetworks-oss/e2enetworks-skills
/plugin install e2e@e2enetworks-skills
```

## Skill surface

This repo ships one installable skill:

- [`use-e2e`](plugins/e2e/skills/use-e2e/SKILL.md)

`use-e2e` is node-first. Intent routing is defined in `SKILL.md`, and execution details are split into action-oriented references.

## Workflow coverage

`use-e2e` covers:

- Profile and config setup
- Node provisioning and lifecycle
- Node actions (power, save-image, attach)
- SSH key upload and attach
- VPC create and attach
- Volume create, attach, and mount
- Frontend and backend deployment on a node
- DNS and HTTPS (Certbot)
- Fleet inventory and status checks

## Repository structure

```text
e2enetworks-skills/
├── plugins/e2e/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── hooks/
│   └── skills/
│       └── use-e2e/
│           ├── SKILL.md
│           ├── scripts/
│           │   └── e2ectl-run.sh
│           └── references/
│               ├── access.md
│               ├── nodes.md
│               └── maintenance.md
├── scripts/
│   └── install.sh
├── AGENTS.md
├── CLAUDE.md
└── rfc.md
```

## Development notes

- Keep `SKILL.md` concise and routing-focused.
- Keep workflow behavior in action-oriented references.
- Keep deep schema and reference material separate from runbooks.
- Prefer canonical CLI syntax in examples.

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [E2E Networks Docs](https://docs.e2enetworks.com)

## License

MIT
