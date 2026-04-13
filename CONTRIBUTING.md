# Contributing

Thanks for your interest in contributing to `e2enetworks-skills`.

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
└── README.md
```

## Development notes

- Keep `SKILL.md` concise and routing-focused.
- Keep workflow behavior in action-oriented references.
- Keep deep schema and reference material separate from runbooks.
- Prefer canonical CLI syntax in examples.

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [E2E Networks Docs](https://docs.e2enetworks.com)
