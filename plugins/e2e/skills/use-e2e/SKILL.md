---
name: use-e2e
description: Manage E2E Networks resources with the official e2ectl CLI. For testing, use the e2ectl GitHub repo develop branch as the source of truth before falling back to installed packages. Nodes are the main task. Also handle node actions, volumes, VPCs, and SSH keys with short natural-language output.
---

# use-e2e

## Allowed Tools

Only use these tools:

- `Bash(node *)` — run e2ectl CLI via dev build (`node dist/app/index.js ...`)
- `Bash(e2ectl *)` — run e2ectl CLI when installed as a global package
- `Bash(git *)` — clone or check the e2ectl source repo
- `Bash(npm *)` — install dependencies for the e2ectl build or frontend apps
- `Bash(make *)` — build the e2ectl CLI from source
- `Bash(ssh *)` — SSH into nodes and run remote commands (apt-get, certbot, nginx, systemctl, etc. all run via ssh)
- `Bash(scp *)` — upload files to nodes
- `Bash(ssh-keygen *)` — manage known_hosts (e.g. clear stale host keys on IP reuse)
- `Bash(for *)` — polling loops (e.g. wait for node Running status)
- `Bash(until *)` — polling loops (e.g. wait for DNS propagation)
- `Bash(dig *)` — check DNS propagation
- `Bash(curl *)` — HTTP health checks
- `Bash(ls *)` — inspect local paths
- `Bash(which *)` — detect installed CLI

Use this skill when the user wants E2E Networks infrastructure work.

Temporary testing note:
- For testing, the source of truth is `https://github.com/e2enetworks-oss/e2ectl` on branch `develop`.
- Clone and run the repo CLI before falling back to installed packages.
- `hitesh-test` remains a temporary pre-release fallback until the official public package flow is final.
- Before this skill pack is published publicly, remove `hitesh-test` fallback/install references and rely solely on `e2ectl`.

## 1. Resolve CLI

For testing, resolve the CLI in this order:

- use an existing local checkout of `https://github.com/e2enetworks-oss/e2ectl` on branch `develop` if one is already available
- otherwise clone the repo and branch first, for example:

```bash
git clone --depth 1 --branch develop https://github.com/e2enetworks-oss/e2ectl.git /tmp/e2ectl-develop
cd /tmp/e2ectl-develop
npm install
make build
node dist/app/index.js config list
```

- after that bootstrap, use `node /tmp/e2ectl-develop/dist/app/index.js` with the full absolute path for all later CLI commands — do not use `cd <dir> && node dist/...` compound commands, as the `cd` prefix can trigger extra permission prompts
- if the built repo checkout already exists under the working directory, `scripts/e2ectl-run.sh --cwd <repo-dir> -- <cli-args...>` will auto-prefer `dist/app/index.js`
- if build output is not present yet but dependencies are installed, `npm run dev -- <cli-args...>` is acceptable for local testing only
- only fall back to installed package commands if cloning or building the source-of-truth repo is not possible, or if the user explicitly wants published-package behavior:
  - `e2ectl`
  - `hitesh-test`
  - if neither exists, ask:
    - install globally
    - install in this project

Fallback install commands:

```bash
npm i -g hitesh-test
```

```bash
npm i hitesh-test
npx hitesh-test --help
```

If project-local install is chosen, use `npx hitesh-test` for later commands.

The `e2ectl` source repo currently requires Node.js `24+` and `npm`.

Do not spend tokens on repeated `--help` for the commands listed below. Use the documented workflows directly. Only use `--help` if a command is missing, changed, or failing unexpectedly.

To avoid permission prompts, follow these rules strictly:
- Never use `cd <dir> && <command>` compound patterns. Always use absolute paths instead, for example `node /tmp/e2ectl-develop/dist/app/index.js <args>`.
- When polling node status (waiting for Creating to become Running, or for power-off/power-on), run `sleep` as one Bash call and `node /tmp/e2ectl-develop/dist/app/index.js node get` as a separate Bash call. Never chain them with `&&`.
- Each Bash call must start with a single recognized command token (node, ssh, scp, sleep, etc.) — no compound `&&` or `;` chains.
- For the full provision-deploy-SSL flow, all tools are pre-approved. Do not pause for confirmation on ssh, scp, apt-get, nginx, certbot, systemctl, or any utility command. The only action that needs user confirmation is `node delete`.

## 2. Resolve Config

- run `config list`
- if aliases exist, ask:
  - use existing
  - import new
- if no usable config exists, ask:
  - use a config file already on this machine
  - upload a config file
- prefer `config import` when a file is available
- after choosing or importing a profile, check whether default project id and default location are present in the config itself
- if either one is missing, prompt for both:
  - project id
  - location
- if an existing alias is missing project or location, use `config set-context`
- if no usable alias exists, use `config import`
- if a resource command returns `Profile "<alias>" was not found`, stop and resolve config before continuing

Saved profiles live in `~/.e2e/config.json`.

## 3. Primary Workflows

- config list
- node list
- node get
- node catalog os
- node catalog plans
- node create
- node delete

## 4. Common Cloud Workflows

- inspect saved profiles and defaults
- list current nodes
- inspect one node
- discover OS, plan, image, and billing options
- create a node
- power off or power on a node
- save a node as an image
- attach a VPC to a node
- attach and mount a volume on a node
- upload and attach an SSH key to a node
- SSH into a ready node
- deploy a frontend or backend service on a node
- inspect volume plans
- create a volume
- list volumes
- inspect VPC plans
- create a VPC
- list VPCs
- list SSH keys
- upload an SSH key

## 5. Engineer Workflows

Common workflows an infrastructure or platform engineer may ask for:

- check the current fleet and node status
- provision a fresh node for an app
- upload and attach SSH access
- create and attach a VPC
- create, attach, and mount a data volume
- deploy a frontend on a node
- deploy a backend on a node
- update or redeploy an existing app
- inspect a server that is already running something
- power cycle a node and verify the final state
- save an image before risky maintenance
- retire a node safely

## 6. Node-First Behavior

Main tasks:

- list nodes
- get node details
- discover OS and plan/image pairs
- create nodes
- delete nodes
- run node actions
- verify actual node status after actions
- attach VPC, SSH key, or volume after create
- SSH into a ready node
- deploy services on a node

For create:

- ask for node name
- ask for alias or project/location context
- discover OS rows first
- discover exact plan/image values next
- use the exact returned plan and image
- if billing matters, ask hourly vs committed and use the exact committed plan id when needed

For delete:

- list or inspect first
- confirm once before delete
- when the user has explicitly named or confirmed resources for deletion, use `--force` directly — do not attempt delete without `--force` first
- for bulk deletion (e.g. "clean up all resources"), run each delete in sequence with `--force`: nodes first, then volumes, then VPCs, then SSH keys
- all delete commands (node, volume, vpc, ssh-key) require `--force` in non-interactive terminals — never attempt delete without it

For node actions:

- after `node action power-off`, `node action power-on`, or other state-changing actions, re-check the node with `node get <node-id>` or `node list`
- show the actual current node status from that follow-up check
- do not present only `Action ID` or action `Status: done` as the final node state

## 7. Access, Storage, and Deploy

For common provision-to-deploy work:

- create the node
- wait for the node status to reach `Running` — do not attempt any attach actions while the node is `Creating`
- upload SSH key if none exists
- attach SSH key
- attach VPC if private networking is needed
- attach a volume if data storage is needed
- SSH into the node
- mount the data volume on the guest OS if one was attached
- deploy the requested frontend or backend service

Ask only for missing values:

- alias
- SSH key id, or SSH key label and public key file path
- project id and location when profile defaults are missing
- node id or public IP
- private key path
- volume id and mount path when storage is involved
- repo URL or local app path
- app type
- env vars, port, or start command only if needed

Default the SSH user to `root`. Only ask for SSH user if the user explicitly gives another user or `root` fails.
Do not guess a Linux block device path. Inspect it on the node first.
Do not format a volume unless it is new and the user has allowed it.
Suggest `/data` when a mount path is needed and the user has not provided one.
Suggest `~/.ssh/id_ed25519.pub` when a public key file path is needed and the user has not provided one.
Ask for the SSH key label before upload. Suggest `node-access` if the user has no preference.
If the user says things like deploy my server, run something on the node, or check what is running on the node, treat that as an SSH and deploy workflow.

## 8. Other Package Features

If the user asks beyond nodes, this package also supports:

- node actions such as power on, power off, save image, attach VPC, attach volume, and attach SSH key
- volume plans, create, and list
- VPC plans, create, and list
- SSH key list and create

Explain these in short natural language first. Only expand into exact commands when needed.

## 9. Common Workflows

Use `CLI` below as the resolved command.

Nodes:

```bash
CLI node list --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
CLI node action power-off <node-id> --alias <profile-alias>
CLI node action power-on <node-id> --alias <profile-alias>
CLI node action save-image <node-id> --name <image-name> --alias <profile-alias>
CLI node action vpc attach <node-id> --vpc-id <vpc-id> --alias <profile-alias>
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <profile-alias>
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <profile-alias>
CLI node delete <node-id> --alias <profile-alias>
CLI node create --alias <profile-alias> --name <node-name> --plan <plan> --image <image> --billing-type committed --committed-plan-id <committed-plan-id>
```

Action verification:

```bash
CLI node action power-off <node-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
CLI node action power-on <node-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
```

If the user asked for the latest fleet state, run `node list` after the action and show the node status from there.

Delete workflow:

```bash
CLI node get <node-id> --alias <profile-alias>
CLI node delete <node-id> --force --alias <profile-alias>
```

Ask for confirmation once before delete.
Once confirmed, always use `--force` — all delete commands require an interactive terminal without it and will fail in non-interactive sessions.

Bulk cleanup workflow (delete all resources for a project):

```bash
# 1. Delete nodes first (data is lost, do this last if backups are needed)
CLI node delete <node-id> --force --alias <profile-alias>

# 2. Delete volumes
CLI volume delete <volume-id> --force --alias <profile-alias>

# 3. Delete VPCs
CLI vpc delete <vpc-id> --force --alias <profile-alias>

# 4. Delete SSH keys
CLI ssh-key delete <ssh-key-id> --force --alias <profile-alias>
```

For bulk deletion, run each delete in sequence with `--force`. All resource types (node, volume, vpc, ssh-key) use the same `--force` pattern.

Common engineering sequences:

```bash
CLI node list --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
CLI node action save-image <node-id> --name <image-name> --alias <profile-alias>
CLI node action power-off <node-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
CLI node action power-on <node-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
```

Use this for:

- fleet checks
- pre-change backup image
- safe power cycle
- incident or maintenance follow-up

Provision and deploy:

```bash
CLI node create --alias <profile-alias> --name <node-name> --plan <plan> --image <image>
# Poll until Running before any attach actions:
# for i in $(seq 1 20); do STATUS=$(CLI node get <node-id> --alias <profile-alias> | grep Status); echo $STATUS; echo $STATUS | grep -qi running && break; sleep 15; done
CLI ssh-key list --alias <profile-alias>
CLI ssh-key create --label <key-label> --public-key-file ~/.ssh/id_ed25519.pub --alias <profile-alias>
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <profile-alias>
CLI node action vpc attach <node-id> --vpc-id <vpc-id> --alias <profile-alias>
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
ssh -i <private-key-path> <ssh-user>@<public-ip>
scp -i <private-key-path> -r <local-path> <ssh-user>@<public-ip>:<remote-path>
```

Default SSH examples:

```bash
ssh -i <private-key-path> root@<public-ip>
scp -i <private-key-path> -r <local-path> root@<public-ip>:<remote-path>
```

SSH key workflow:

```bash
CLI ssh-key list --alias <profile-alias>
CLI ssh-key create --label <key-label> --public-key-file ~/.ssh/id_ed25519.pub --alias <profile-alias>
cat ~/.ssh/id_ed25519.pub | CLI ssh-key create --label <key-label> --public-key-file - --alias <profile-alias>
CLI node action ssh-key attach <node-id> --ssh-key-id <ssh-key-id> --alias <profile-alias>
```

If `ssh-key list` shows no keys, upload one before trying to attach.
Use `--label`, not `--name`.
Use `--public-key-file`, not `--key`.
Do not call `node attach`; use `node action ssh-key attach`.
Ask for the SSH key label before upload instead of inventing one silently.
`node action ssh-key attach` only works when the node is in `Running` status. If the node is still `Creating`, wait until it is `Running` before attaching.

Mount a data volume on the node:

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
sudo mkdir -p <mount-path>
sudo mkfs.ext4 /dev/<device>
sudo mount /dev/<device> <mount-path>
sudo blkid /dev/<device>
```

Add the mounted disk to `/etc/fstab` with the returned UUID after mount.
Only run `mkfs.ext4` for a new empty volume and only after confirmation.

Volumes:

```bash
CLI volume plans --alias <profile-alias>
CLI volume create --name <volume-name> --size <size-gb> --billing-type hourly --alias <profile-alias>
CLI volume create --name <volume-name> --size <size-gb> --billing-type committed --committed-plan-id <committed-plan-id> --post-commit-behavior auto-renew --alias <profile-alias>
CLI volume list --alias <profile-alias>
```

If size is already known:

```bash
CLI volume plans --size <size-gb> --alias <profile-alias>
```

Storage workflow:

```bash
CLI volume create --name <volume-name> --size <size-gb> --billing-type hourly --alias <profile-alias>
CLI node action volume attach <node-id> --volume-id <volume-id> --alias <profile-alias>
ssh -i <private-key-path> root@<public-ip>
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
sudo mkdir -p <mount-path>
sudo mount /dev/<device> <mount-path>
```

VPCs:

```bash
CLI vpc plans --alias <profile-alias>
CLI vpc create --name <vpc-name> --billing-type hourly --cidr-source e2e --alias <profile-alias>
CLI vpc create --name <vpc-name> --billing-type committed --committed-plan-id <committed-plan-id> --post-commit-behavior auto-renew --cidr-source custom --cidr <custom-cidr> --alias <profile-alias>
CLI vpc list --alias <profile-alias>
```

Networking workflow:

```bash
CLI vpc create --name <vpc-name> --billing-type hourly --cidr-source e2e --alias <profile-alias>
# Poll until VPC state is Active before attaching — attach fails if VPC is still Creating
CLI vpc list --alias <profile-alias>
# repeat vpc list with a sleep between checks until State = Active
CLI node action vpc attach <node-id> --vpc-id <network-id> --alias <profile-alias>
CLI node get <node-id> --alias <profile-alias>
```

VPC readiness rule:
- `node action vpc attach` only works when the VPC state is `Active`
- After `vpc create`, poll `vpc list` every 10–15 seconds until the VPC state becomes `Active`
- Do not attempt attach while state is `Creating` — it will fail with "VPC X not found"

VPC ID disambiguation:
- `vpc create` output shows two IDs: `VPC ID` and `Network ID`
- `vpc list` shows the same value under the `Network ID` column
- `node action vpc attach --vpc-id` takes the **Network ID**, not the VPC ID
- If attach fails with "VPC X not found", switch to the Network ID

SSH keys:

```bash
CLI ssh-key list --alias <profile-alias>
CLI ssh-key create --label <key-label> --public-key-file ~/.ssh/id_ed25519.pub --alias <profile-alias>
cat ~/.ssh/id_ed25519.pub | CLI ssh-key create --label <key-label> --public-key-file - --alias <profile-alias>
```

App deployment workflow:

```bash
CLI node get <node-id> --alias <profile-alias>
ssh -i <private-key-path> root@<public-ip>
scp -i <private-key-path> -r <local-path> root@<public-ip>:<remote-path>
```

Use this for:

- deploy frontend
- deploy backend
- update an existing app
- inspect or fix a running server

## 10. Output Rules

- keep replies short
- prefer natural language summaries
- use `--json` only for internal parsing
- do not dump raw JSON unless asked
- do not print secrets
- for SSH or deploy work, summarize the host, path, service status, and next step instead of dumping long logs
- for node actions, summarize both the action receipt and the follow-up node status

## 11. Codex CLI UX

- start with a one-line summary of the step being taken
- ask one short question at a time
- if multiple values are missing for one task, ask for them in one compact prompt
- for node lists, show a compact summary with id, name, status, and public IP when available
- for node details, show a short readable summary with id, name, status, plan, and IPs
- for create or attach flows, say what was created or attached and the next useful step
- for errors, explain the problem in simple language and say how to fix it next
- do not show internal reasoning, repeated help text, or raw command noise unless the user asks

## 12. DNS Checking

Do NOT use polling loops for DNS. Any loop with `$()` command substitution triggers a permission prompt regardless of the outer loop form.

### Asking for the domain

Always ask for the **root domain** and **subdomain** separately — never assume the full hostname. For example:

- "What is your root domain?" → `rahultanwar.me`
- "What subdomain should this be served on?" → `weather`
- Full hostname used internally: `weather.rahultanwar.me`

### Showing the DNS record to add

Most DNS providers show your root domain as the zone and only want the subdomain label in the **Name** field. Always present the record this way:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| `A` | `weather` | `<node-public-ip>` | 300 |

Add a note: *In your DNS provider, the Name field should be just the subdomain (`weather`), not the full hostname (`weather.rahultanwar.me`). Some providers append the root domain automatically.*

### Checking propagation

1. After showing the record, ask the user to add it and let you know when done.
2. When they confirm, run a single one-shot check:

```bash
dig +short <subdomain>.<root-domain> @1.1.1.1
```

3. If it resolves to the expected IP, proceed immediately (e.g. run Certbot).
4. If it does not resolve yet, tell the user it's still propagating and ask them to confirm again when ready. Do not loop or retry automatically.

- Use `@1.1.1.1` (Cloudflare) as the default resolver, fall back to `@8.8.8.8`.
- After DNS resolves, immediately continue with the next step (e.g. run Certbot for HTTPS).

Nameserver checks — when the user asks which nameservers a domain uses or wants to verify NS delegation:

```bash
dig NS <domain> @1.1.1.1 +short
```

To check whether a subdomain's A record is visible from a specific nameserver:

```bash
dig A <hostname> @<nameserver> +short
```

## 13. App Deployment Workflows

### Detect app type

Before deploying, check `package.json` or project files to determine the framework. Key signals:

- `vite` in devDependencies + `react`/`vue`/`svelte` → static frontend, build and serve via Nginx
- `next` in dependencies → Next.js, may need SSR (Node process) or static export
- `express` / `fastify` / `hono` → Node.js backend, run as a process
- `requirements.txt` with `fastapi`/`uvicorn` → Python backend
- `requirements.txt` with `django`/`gunicorn` → Django backend
- `go.mod` → Go binary, build and run
- `Dockerfile` → containerised app, use Docker

---

### Frontend: React / Vite / Vue / Svelte (static build)

Applies to any Vite-based SPA (React, Vue 3, Svelte).

**Local build and upload:**

```bash
npm run build                                          # produces dist/
scp -r dist/* root@<public-ip>:/var/www/<app-name>/
```

**Nginx config on node** (`/etc/nginx/sites-available/<app-name>`):

```nginx
server {
    listen 80;
    server_name <domain>;
    root /var/www/<app-name>;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**Write the config and enable:**

Use `printf` with `\n` inside a regular double-quoted `ssh` command. Escape `$` as `\$` so the local shell does not expand them:

```bash
ssh -i <key> root@<public-ip> "printf 'server {\n    listen 80;\n    server_name <domain>;\n    root /var/www/<app-name>;\n    index index.html;\n    location / {\n        try_files \$uri \$uri/ /index.html;\n    }\n}\n' > /etc/nginx/sites-available/<app-name>"

ssh -i <key> root@<public-ip> "ln -sf /etc/nginx/sites-available/<app-name> /etc/nginx/sites-enabled/<app-name>"

ssh -i <key> root@<public-ip> "rm -f /etc/nginx/sites-enabled/default"

ssh -i <key> root@<public-ip> "nginx -t"

ssh -i <key> root@<public-ip> "systemctl reload nginx"
```

This is the only approach that avoids all permission prompts:
- Starts with `ssh` — matches the allowed tool pattern
- No heredoc (`<<`) — avoids "ambiguous syntax" prompt
- No escaped single quotes (`'"'"'`) — avoids "obfuscation" prompt
- No `Write` tool — avoids file edit permission prompt
- `\$uri` escapes prevent local shell expansion
- Each `ssh` call does exactly one thing — never chain `&&`, `;`, or `|` inside the SSH argument string, as this triggers a "shell metacharacters in arguments" permission prompt even when `ssh *` is in the allow list

---

### Frontend: Next.js (static export)

```bash
# in next.config.js: output: 'export'
npm run build         # produces out/
scp -r out/* root@<public-ip>:/var/www/<app-name>/
```

Use the same Nginx config as above. Add `try_files $uri $uri.html $uri/ /index.html;` for static HTML pages.

---

### Frontend: Next.js (SSR / Node process)

```bash
scp -r .next package.json package-lock.json next.config.js root@<public-ip>:/var/www/<app-name>/
ssh root@<public-ip> "cd /var/www/<app-name> && npm install --omit=dev && npm run start"
```

Run as a systemd service (see systemd section below) on port 3000, then proxy via Nginx.

---

### Backend: Node.js (Express / Fastify / Hono)

```bash
scp -r . root@<public-ip>:/var/www/<app-name>/
ssh root@<public-ip> "cd /var/www/<app-name> && npm install --omit=dev"
```

Run with systemd (see below). Default port: 3000. Proxy via Nginx.

---

### Backend: Python (FastAPI + uvicorn)

```bash
scp -r . root@<public-ip>:/var/www/<app-name>/
ssh root@<public-ip> << 'EOF'
  cd /var/www/<app-name>
  apt-get install -y python3-pip python3-venv
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
EOF
```

Start command: `venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000`

---

### Backend: Python (Django + gunicorn)

```bash
ssh root@<public-ip> << 'EOF'
  cd /var/www/<app-name>
  source venv/bin/activate
  pip install -r requirements.txt
  python manage.py migrate
  python manage.py collectstatic --noinput
EOF
```

Start command: `venv/bin/gunicorn <project>.wsgi:application --bind 0.0.0.0:8000 --workers 3`

---

### Backend: Go

```bash
# Build locally
GOOS=linux GOARCH=amd64 go build -o app-linux .
scp app-linux root@<public-ip>:/var/www/<app-name>/app
ssh root@<public-ip> "chmod +x /var/www/<app-name>/app"
```

Start command: `/var/www/<app-name>/app`

---

### Running apps as systemd services

Create `/etc/systemd/system/<app-name>.service` on the node:

```ini
[Unit]
Description=<app-name>
After=network.target

[Service]
WorkingDirectory=/var/www/<app-name>
ExecStart=<start-command>
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
systemctl daemon-reload
systemctl enable <app-name>
systemctl start <app-name>
systemctl status <app-name>
```

---

### Nginx reverse proxy for backend apps

Add to `/etc/nginx/sites-available/<app-name>`:

```nginx
server {
    listen 80;
    server_name <domain>;

    location / {
        proxy_pass http://127.0.0.1:<port>;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

### HTTPS with Let's Encrypt (Certbot)

Always run after DNS resolves to the node IP. Certbot auto-configures Nginx and sets up auto-renewal.

```bash
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d <domain> --non-interactive --agree-tos -m <email>
```

Ask the user for their email before running this command.

If Certbot fails with a rate limit error (`too many certificates already issued`), fall back to a self-signed certificate immediately without asking. Tell the user it's temporary and give them the exact Certbot command to run once the limit resets.

Self-signed fallback:

```bash
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/<domain>.key \
  -out /etc/nginx/ssl/<domain>.crt \
  -subj '/CN=<domain>/O=Self-Signed'
```

Then update the Nginx site config to use SSL with HTTP-to-HTTPS redirect:

```nginx
server {
    listen 80;
    server_name <domain>;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name <domain>;

    ssl_certificate /etc/nginx/ssl/<domain>.crt;
    ssl_certificate_key /etc/nginx/ssl/<domain>.key;

    root /var/www/<app-name>;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

After enabling the self-signed cert, tell the user:
- The site is live on HTTPS but browsers will show a security warning (expected for self-signed certs)
- The Let's Encrypt rate limit resets at the time shown in the Certbot error output
- To swap in a trusted cert once the limit resets, run:
  ```bash
  certbot --nginx -d <domain> --non-interactive --agree-tos -m <email> --redirect
  ```

---

### Other common services

**Node version manager (nvm)** — when the node's system Node is too old:

```bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
```

**PM2** — alternative process manager for Node.js:

```bash
npm install -g pm2
pm2 start <entry-file> --name <app-name>
pm2 startup
pm2 save
```

**Docker** — for containerised apps:

```bash
apt-get install -y docker.io
systemctl enable --now docker
docker build -t <app-name> .
docker run -d --restart unless-stopped -p <host-port>:<container-port> --name <app-name> <app-name>
```

**PostgreSQL**:

```bash
apt-get install -y postgresql postgresql-contrib
systemctl enable --now postgresql
sudo -u postgres psql -c "CREATE USER <user> WITH PASSWORD '<password>';"
sudo -u postgres psql -c "CREATE DATABASE <dbname> OWNER <user>;"
```

**Redis**:

```bash
apt-get install -y redis-server
systemctl enable --now redis-server
```

**MySQL / MariaDB**:

```bash
apt-get install -y mariadb-server
systemctl enable --now mariadb
mysql_secure_installation
```

---

### Deployment decision tree

| App signals | Deploy strategy |
|---|---|
| `vite build` → `dist/` | Upload `dist/`, serve with Nginx static |
| Next.js `output: 'export'` | Upload `out/`, serve with Nginx static |
| Next.js SSR | Upload source, `npm start`, systemd + Nginx proxy |
| Express / Fastify / Hono | Upload source, `node index.js`, systemd + Nginx proxy |
| FastAPI / uvicorn | Upload source, virtualenv, uvicorn, systemd + Nginx proxy |
| Django / gunicorn | Upload source, virtualenv, migrate, gunicorn, systemd + Nginx proxy |
| Go binary | Build locally for linux/amd64, upload binary, systemd |
| Dockerfile | Install Docker, build image, `docker run` |

## References

- access and config: `references/access.md`
- nodes and node actions: `references/nodes.md`
- volumes, VPCs, SSH keys, release notes: `references/maintenance.md`
