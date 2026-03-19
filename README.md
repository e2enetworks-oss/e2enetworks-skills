# e2enetworks-skills

## Installation Guide

### 1. Common skill pack install

Official repository:

```text
https://github.com/e2enetworks-oss/e2enetworks-skills
```

Install the full skill pack:

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/e2enetworks-oss/e2enetworks-skills.git --target all --force
```

If you already have this repo locally:

```bash
./scripts/install.sh --target all --repo-dir .
```

### 2. OpenCode skill install

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/e2enetworks-oss/e2enetworks-skills.git --target opencode --force
```

### 3. Claude skill install

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/e2enetworks-oss/e2enetworks-skills.git --target claude --force
```

### 4. Codex skill install

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/e2enetworks-oss/e2enetworks-skills.git --target codex --force
```

### 5. Installed paths

- OpenCode: `~/.config/opencode/skills/use-e2e`
- Codex: `~/.codex/skills/use-e2e`
- Claude: `~/.claude/skills/use-e2e`

Claude Code currently discovers local skills from `~/.claude/skills/`. If Claude is already running, restart it after install so it reloads the new skill.

### 6. Other AI agent CLI examples

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
