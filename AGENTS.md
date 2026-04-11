# Agent Instructions: e2e Skills

This repo ships one skill: `use-e2e`.

Use it for node management first. It also supports node actions, volumes, VPCs, and SSH keys.

## Public Contract

1. Public mode is the default everywhere.
2. `scripts/install.sh` is the only public install and update entry point.
3. The installer owns the `e2ectl` lifecycle:
   - install `@e2enetworks-oss/e2ectl` globally when missing
   - ask about upgrading in interactive reruns when a newer stable version is available
   - require `--upgrade-cli` for non-interactive upgrades
   - allow `--skip-cli` as the advanced escape hatch
4. Re-running the installer updates the skill.
5. Public runtime resolution in `scripts/e2ectl-run.sh` is:
   - explicit `--bin`
   - installed `e2ectl`
   - fail with rerun-installer guidance
6. Keep temporary branch-based and pre-release package fallback language out of public docs.

## Internal Maintainer Escape Hatch

Hidden internal mode exists for maintainer testing only:

- set `E2E_SKILLS_MODE=internal` before calling `scripts/e2ectl-run.sh`
- internal resolution order is:
  - explicit `--bin`
  - built local `@e2enetworks-oss/e2ectl` checkout under `--cwd`
  - installed `e2ectl`
- do not document this mode in `README.md` or normal help text

## Skill Behavior

1. Run `config list` before resource commands.
2. If saved profiles exist, ask whether to use an existing profile or import a new one.
3. If no usable config exists, ask:
   - use a config file already on this machine
   - upload a config file
   Prefer file import.
4. After choosing or importing a profile, check that `default project id` and `default location` are present in the config itself.
5. If either one is missing, prompt for both:
   - project id
   - location
   Then update the profile with `config set-context` before any resource command.
6. If a command returns `Profile "<alias>" was not found`, stop and resolve config before trying more resource commands.
7. Do not spend tokens on repeated `--help` for commands covered by this skill. Use the documented commands directly. Only use `--help` when a command is unknown, has changed, or fails unexpectedly.
8. Keep output short and natural. Do not show raw API calls, secrets, or raw JSON unless the user asks.
9. Node work is primary:
   - list
   - get
   - catalog
   - create
   - upload and attach SSH key
   - attach VPC
   - attach and mount a volume
   - SSH into a ready node
   - deploy frontend or backend services
   - delete
   - actions
   - verify actual node status after actions
10. Other supported areas:
    - volumes
    - VPCs
    - SSH keys
11. For SSH or deploy tasks, ask only for what is missing:
    - alias
    - node id or public IP
    - SSH key id, or SSH key label and public key file path
    - volume id and mount path when storage is involved
    - private key path
    - repo URL or local app path
    - app type: frontend or backend
    - env vars, port, or start command if they are not obvious
    - whether a new empty volume may be formatted
    Default the SSH user to `root`. Only ask for SSH user if the user explicitly wants a different one or `root` fails.
    Suggest `/data` when a mount path is needed and none was given.
    Suggest `~/.ssh/id_ed25519.pub` when a public key file path is needed and none was given.
    Ask for the SSH key label before upload. Suggest `node-access` if the user has no preference.
12. If the user says things like:
    - deploy my server
    - run something on the node
    - check what is running on the node
    - fix my frontend or backend on the node
    treat that as an SSH-into-node workflow.
13. After `node action power-off`, `node action power-on`, or similar node actions, do not stop at the action result.
    Re-check the node with `node get <node-id>` or `node list` and show the actual current node status.
14. Basic Codex CLI UX rules:
    - start with a one-line summary of the step being taken
    - ask one short question at a time
    - if multiple values are missing for one task, ask for them in one compact prompt
    - show lists as compact summaries with id, name, status, and public IP when available
    - show node details as a short readable summary, not raw fields
    - after success, say what happened and the next useful step
    - after errors, explain the issue in simple language and give the next fix
15. Common engineering workflows to support:
    - fleet inventory and status checks
    - new node provisioning
    - SSH access setup
    - VPC setup and attach
    - volume create, attach, and mount
    - frontend or backend deployment on a node
    - app update or redeploy on an existing node
    - service checks or incident triage on a running node
    - safe power cycle with status verification
    - save-image before risky changes
    - safe node retirement
16. Treat `node delete` as an interactive confirmed action.
    - ask for confirmation once
    - when the user has confirmed, use `--force` for non-interactive execution
17. The full provision-deploy-SSL flow should run without extra permission prompts.
    All needed tools are pre-approved: ssh, scp, curl, apt-get, certbot, nginx, systemctl, dig, ln, rm, mkdir, sleep, kill, which, ls, cat — in addition to direct `e2ectl` commands.

## Install Paths

- Global Codex: `~/.codex/skills/use-e2e`
- Global Claude: `~/.claude/skills/use-e2e`
- Project Codex: `.codex/skills/use-e2e`
- Project Claude: `.claude/skills/use-e2e`

## Skill File

- `plugins/e2e/skills/use-e2e/SKILL.md`
