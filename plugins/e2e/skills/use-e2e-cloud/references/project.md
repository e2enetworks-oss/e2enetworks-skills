# Project

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Overview

Project commands operate at the account level. They do not require `--project-id` or `--location` — only `--alias` is needed.

Use `project list` to discover numeric project IDs before running resource commands that need `--project-id`.

**IAM-shared projects are not listed.** `project list` returns only projects **owned by this account**. If the user has been added to another account's project via IAM, that project will not appear in the listing — they must obtain the project ID from the owner (or from the project page in E2E MyAccount) and use it directly with `--project-id`. See `references/access.md` Step 5 for the user-facing flow.

## Commands

List all accessible projects for the account:

```bash
CLI project list --alias <alias>
```

Create a new project:

```bash
CLI project create --name <project-name> --alias <alias>
```

Star a project by its numeric id:

```bash
CLI project star <project-id> --alias <alias>
```

Unstar a project by its numeric id:

```bash
CLI project unstar <project-id> --alias <alias>
```

## Common Workflows

Discover available projects before setting context:

```bash
CLI project list --alias <alias>
# pick the numeric id from the output
CLI config set-context --alias <alias> --default-project-id <project-id> --default-location <location>
```

Create a new project and set it as the default context:

```bash
CLI project create --name <project-name> --alias <alias>
# use the returned project id
CLI config set-context --alias <alias> --default-project-id <new-project-id> --default-location <location>
```

## Output Rules

- show id, name, and starred status in a compact list
- after create, show the new project id and suggest setting it as the default context if needed

