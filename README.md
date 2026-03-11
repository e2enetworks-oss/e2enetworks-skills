# e2e-skills

## Installation Guide

### 1. Common skill pack install

Replace `<ORG>` with your GitHub org or user.

Install the full skill pack:

```bash
curl -fsSL https://raw.githubusercontent.com/<ORG>/e2e-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/<ORG>/e2e-skills.git --target all --force
```

If you already have this repo locally:

```bash
./scripts/install.sh --target all --repo-dir .
```

### 2. Claude plugin install

```bash
curl -fsSL https://raw.githubusercontent.com/<ORG>/e2e-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/<ORG>/e2e-skills.git --target claude --force
```

### 3. Codex skill install

```bash
curl -fsSL https://raw.githubusercontent.com/<ORG>/e2e-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/<ORG>/e2e-skills.git --target codex --force
```

### 4. Installed paths

- Codex: `~/.codex/skills/use-e2e`
- Claude: `~/.claude/plugins/e2e`

### 5. Other AI agent CLI examples

OpenCode example:

```bash
opencode .
```

OpenCode one-shot example:

```bash
opencode run --dir "$PWD" "Use the use-e2e skill."
```

Amp example:

```bash
amp skill add ./plugins/e2e/skills/use-e2e --global --overwrite --name use-e2e
```

Verify Amp skill install:

```bash
amp skill list
```

## License

MIT. See [LICENSE](LICENSE).
