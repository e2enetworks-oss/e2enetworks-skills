# E2E Networks Skills

Agent skill for [E2E Networks](https://e2enetworks.com), following the [Agent Skills](https://agentskills.io) format.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | bash
```

You can also install via [skills.sh](https://skills.sh):

```bash
npx skills add e2enetworks-oss/e2enetworks-skills
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

- Node provisioning and lifecycle
- SSH access and key management
- Volume create, attach, and mount
- VPC setup and attachment
- Frontend and backend deployment
- App update and redeploy
- Service checks and incident triage
- Safe power cycle with status verification
- Node retirement and cleanup

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
│               ├── maintenance.md
│               └── nodes.md
├── scripts/
│   └── install.sh
├── tests/
│   └── regression.sh
├── AGENTS.md
├── CLAUDE.md
└── rfc.md
```

## Development notes

- Keep `SKILL.md` concise and routing-focused.
- Keep workflow behavior in action-oriented references.
- Keep deep schema and reference material separate from runbooks.
- Prefer canonical CLI syntax in examples.
- Keep CLI bootstrap logic in `scripts/e2ectl-run.sh` for consistent resolution handling.

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [E2E Networks Docs](https://docs.e2enetworks.com)

## License

MIT
