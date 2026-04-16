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
│       └── use-e2e-cloud/
│           ├── SKILL.md
│           ├── scripts/
│           │   └── e2ectl-run.sh
│           └── references/
│               ├── access.md
│               ├── deploy.md
│               ├── docs-index.md
│               ├── nodes.md
│               ├── project.md
│               ├── reserved-ip.md
│               ├── security-group.md
│               ├── volume.md
│               └── vpc.md
├── scripts/
│   └── install.sh
├── tests/
│   └── regression.sh
├── .github/
│   └── workflows/
│       └── ci.yml
├── AGENTS.md
├── CHANGELOG.md
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
