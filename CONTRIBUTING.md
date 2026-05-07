# Contributing

Thanks for your interest in contributing to `e2enetworks-skills`.

## Repository structure

```text
e2enetworks-skills/
├── plugins/e2e/
│   └── skills/
│       └── use-e2e-cloud/
│           ├── SKILL.md
│           ├── VERSION
│           ├── scripts/
│           │   └── e2ectl-run.sh
│           └── references/
│               ├── access.md
│               ├── cost-estimation.md
│               ├── dbaas.md
│               ├── deploy.md
│               ├── image.md
│               ├── load-balancer.md
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
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── workflows/
│       └── ci.yml
├── AGENTS.md
├── CHANGELOG.md
├── CLAUDE.md
├── README.md
└── VERSION
```

## Development notes

- Keep `SKILL.md` concise and routing-focused.
- Keep workflow behavior in action-oriented references.
- Keep deep schema and reference material separate from runbooks.
- User-facing prompts must speak in natural language — never expose CLI flag names, formats, or syntax to the user.

## References

- [Agent Skills Specification](https://agentskills.io/specification)
