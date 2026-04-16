# App Deployment

This reference covers deploying frontend and backend apps onto E2E nodes over SSH.
All commands run via `ssh` and `scp` after the node is `Running` and has a public IP.

## SSH Command Rules

Each `ssh` call must do exactly one thing. Never chain `&&`, `;`, or `|` inside the SSH
argument string — this triggers a permission prompt even when `ssh *` is in the allow list.

Use `printf` with `\n` for multi-line remote writes. Escape `$` as `\$` to prevent
local shell expansion. Never use heredoc (`<<`) — it triggers an ambiguous syntax prompt.

Default SSH user is `root`. Only ask for a different user if the user explicitly
requests one or `root` fails.

## Detect App Type

Before deploying, check `package.json` or project files to determine the framework:

| Signal | Framework | Strategy |
|---|---|---|
| `vite` in devDependencies + `react`/`vue`/`svelte` | Vite SPA | Build → `dist/` → Nginx static |
| `next` in dependencies + `output: 'export'` | Next.js static | Build → `out/` → Nginx static |
| `next` in dependencies (no static export) | Next.js SSR | Upload source → `npm start` → systemd + Nginx proxy |
| `express` / `fastify` / `hono` | Node.js backend | Upload source → `node` → systemd + Nginx proxy |
| `requirements.txt` + `fastapi`/`uvicorn` | Python FastAPI | Upload → venv → uvicorn → systemd + Nginx proxy |
| `requirements.txt` + `django`/`gunicorn` | Python Django | Upload → venv → migrate → gunicorn → systemd + Nginx proxy |
| `go.mod` | Go | Build linux/amd64 binary locally → upload → systemd |
| `Dockerfile` | Docker | Install Docker → build → `docker run` |

---

## Frontend: React / Vite / Vue / Svelte

Build locally and upload `dist/`:

```bash
npm run build
scp -i <key> -r dist/* root@<public-ip>:/var/www/<app-name>/
```

Write Nginx config (one `ssh` call per action — no chaining):

```bash
ssh -i <key> root@<public-ip> "printf 'server {\n    listen 80;\n    server_name <domain>;\n    root /var/www/<app-name>;\n    index index.html;\n    location / {\n        try_files \$uri \$uri/ /index.html;\n    }\n    location ~* \\.(js|css|png|jpg|ico|svg|woff2)$ {\n        expires 1y;\n        add_header Cache-Control \"public, immutable\";\n    }\n}\n' > /etc/nginx/sites-available/<app-name>"

ssh -i <key> root@<public-ip> "ln -sf /etc/nginx/sites-available/<app-name> /etc/nginx/sites-enabled/<app-name>"

ssh -i <key> root@<public-ip> "rm -f /etc/nginx/sites-enabled/default"

ssh -i <key> root@<public-ip> "nginx -t"

ssh -i <key> root@<public-ip> "systemctl reload nginx"
```

---

## Frontend: Next.js (static export)

Set `output: 'export'` in `next.config.js`, then:

```bash
npm run build
scp -i <key> -r out/* root@<public-ip>:/var/www/<app-name>/
```

Use the same Nginx config as Vite. Add `try_files $uri $uri.html $uri/ /index.html;` for
static HTML pages.

---

## Frontend: Next.js (SSR)

```bash
scp -i <key> -r .next package.json package-lock.json next.config.js root@<public-ip>:/var/www/<app-name>/
ssh -i <key> root@<public-ip> "cd /var/www/<app-name> && npm install --omit=dev"
```

Run on port 3000 via systemd. Proxy with Nginx.

---

## Backend: Node.js (Express / Fastify / Hono)

```bash
scp -i <key> -r . root@<public-ip>:/var/www/<app-name>/
ssh -i <key> root@<public-ip> "cd /var/www/<app-name> && npm install --omit=dev"
```

Default port: 3000. Run via systemd, proxy with Nginx.

---

## Backend: Python (FastAPI + uvicorn)

```bash
scp -i <key> -r . root@<public-ip>:/var/www/<app-name>/
ssh -i <key> root@<public-ip> "apt-get install -y python3-pip python3-venv"
ssh -i <key> root@<public-ip> "python3 -m venv /var/www/<app-name>/venv"
ssh -i <key> root@<public-ip> "cd /var/www/<app-name> && venv/bin/pip install -r requirements.txt"
```

Start command: `venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000`

---

## Backend: Python (Django + gunicorn)

```bash
scp -i <key> -r . root@<public-ip>:/var/www/<app-name>/
ssh -i <key> root@<public-ip> "apt-get install -y python3-pip python3-venv"
ssh -i <key> root@<public-ip> "python3 -m venv /var/www/<app-name>/venv"
ssh -i <key> root@<public-ip> "cd /var/www/<app-name> && venv/bin/pip install -r requirements.txt"
ssh -i <key> root@<public-ip> "cd /var/www/<app-name> && venv/bin/python manage.py migrate"
ssh -i <key> root@<public-ip> "cd /var/www/<app-name> && venv/bin/python manage.py collectstatic --noinput"
```

Start command: `venv/bin/gunicorn <project>.wsgi:application --bind 0.0.0.0:8000 --workers 3`

---

## Backend: Go

Build for Linux locally, then upload:

```bash
GOOS=linux GOARCH=amd64 go build -o app-linux .
scp -i <key> app-linux root@<public-ip>:/var/www/<app-name>/app
ssh -i <key> root@<public-ip> "chmod +x /var/www/<app-name>/app"
```

Start command: `/var/www/<app-name>/app`

---

## Running as a systemd Service

Write the unit file (one `ssh` call):

```bash
ssh -i <key> root@<public-ip> "printf '[Unit]\nDescription=<app-name>\nAfter=network.target\n\n[Service]\nWorkingDirectory=/var/www/<app-name>\nExecStart=<start-command>\nRestart=always\nRestartSec=5\nStandardOutput=journal\nStandardError=journal\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/<app-name>.service"

ssh -i <key> root@<public-ip> "systemctl daemon-reload"
ssh -i <key> root@<public-ip> "systemctl enable <app-name>"
ssh -i <key> root@<public-ip> "systemctl start <app-name>"
ssh -i <key> root@<public-ip> "systemctl status <app-name>"
```

---

## Nginx Reverse Proxy (backend apps)

```bash
ssh -i <key> root@<public-ip> "printf 'server {\n    listen 80;\n    server_name <domain>;\n    location / {\n        proxy_pass http://127.0.0.1:<port>;\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade \$http_upgrade;\n        proxy_set_header Connection upgrade;\n        proxy_set_header Host \$host;\n        proxy_set_header X-Real-IP \$remote_addr;\n        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n        proxy_cache_bypass \$http_upgrade;\n    }\n}\n' > /etc/nginx/sites-available/<app-name>"

ssh -i <key> root@<public-ip> "ln -sf /etc/nginx/sites-available/<app-name> /etc/nginx/sites-enabled/<app-name>"
ssh -i <key> root@<public-ip> "rm -f /etc/nginx/sites-enabled/default"
ssh -i <key> root@<public-ip> "nginx -t"
ssh -i <key> root@<public-ip> "systemctl reload nginx"
```

---

## HTTPS with Let's Encrypt (Certbot)

Always run after DNS resolves to the node IP. Ask the user for their email first.

```bash
ssh -i <key> root@<public-ip> "apt-get install -y certbot python3-certbot-nginx"
ssh -i <key> root@<public-ip> "certbot --nginx -d <domain> --non-interactive --agree-tos -m <email>"
```

If Certbot fails with a rate-limit error (`too many certificates already issued`), fall
back to a self-signed certificate immediately without asking:

```bash
ssh -i <key> root@<public-ip> "mkdir -p /etc/nginx/ssl"
ssh -i <key> root@<public-ip> "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/<domain>.key -out /etc/nginx/ssl/<domain>.crt -subj '/CN=<domain>/O=Self-Signed'"
```

Then write an SSL Nginx config:

```bash
ssh -i <key> root@<public-ip> "printf 'server {\n    listen 80;\n    server_name <domain>;\n    return 301 https://\$host\$request_uri;\n}\nserver {\n    listen 443 ssl;\n    server_name <domain>;\n    ssl_certificate /etc/nginx/ssl/<domain>.crt;\n    ssl_certificate_key /etc/nginx/ssl/<domain>.key;\n    root /var/www/<app-name>;\n    index index.html;\n    location / {\n        try_files \$uri \$uri/ /index.html;\n    }\n}\n' > /etc/nginx/sites-available/<app-name>"
ssh -i <key> root@<public-ip> "nginx -t"
ssh -i <key> root@<public-ip> "systemctl reload nginx"
```

Tell the user: site is live on HTTPS but browsers will show a security warning.
Give them the Certbot command to run once the rate limit resets:

```bash
certbot --nginx -d <domain> --non-interactive --agree-tos -m <email> --redirect
```

---

## DNS Checking

Do NOT use polling loops for DNS. Any loop with `$()` substitution triggers a permission prompt.

Always ask for the **root domain** and **subdomain** separately:

- "What is your root domain?" → `example.com`
- "What subdomain?" → `api`
- Full hostname: `api.example.com`

Show the DNS record to add:

| Type | Name | Value | TTL |
|---|---|---|---|
| `A` | `api` | `<node-public-ip>` | 300 |

Note: the Name field should be just the subdomain label. Some providers append the root domain automatically.

After the user adds the record and confirms:

```bash
dig +short <subdomain>.<root-domain> @1.1.1.1
```

- If it resolves to the expected IP, continue immediately (run Certbot, etc.)
- If not, tell the user it's still propagating and ask them to confirm again when ready.

Use `@1.1.1.1` (Cloudflare) as default, fall back to `@8.8.8.8`.

Nameserver check:

```bash
dig NS <domain> @1.1.1.1 +short
```

Check from a specific nameserver:

```bash
dig A <hostname> @<nameserver> +short
```

---

## Common Services

**Node version manager (nvm)** — when system Node is too old:

```bash
ssh -i <key> root@<public-ip> "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
ssh -i <key> root@<public-ip> "source ~/.bashrc && nvm install 20 && nvm use 20"
```

**PM2** — alternative Node.js process manager:

```bash
ssh -i <key> root@<public-ip> "npm install -g pm2"
ssh -i <key> root@<public-ip> "cd /var/www/<app-name> && pm2 start <entry-file> --name <app-name>"
ssh -i <key> root@<public-ip> "pm2 startup"
ssh -i <key> root@<public-ip> "pm2 save"
```

**Docker**:

```bash
ssh -i <key> root@<public-ip> "apt-get install -y docker.io"
ssh -i <key> root@<public-ip> "systemctl enable --now docker"
ssh -i <key> root@<public-ip> "docker build -t <app-name> /var/www/<app-name>"
ssh -i <key> root@<public-ip> "docker run -d --restart unless-stopped -p <host-port>:<container-port> --name <app-name> <app-name>"
```

**PostgreSQL**:

```bash
ssh -i <key> root@<public-ip> "apt-get install -y postgresql postgresql-contrib"
ssh -i <key> root@<public-ip> "systemctl enable --now postgresql"
ssh -i <key> root@<public-ip> "sudo -u postgres psql -c \"CREATE USER <user> WITH PASSWORD '<password>';\""
ssh -i <key> root@<public-ip> "sudo -u postgres psql -c \"CREATE DATABASE <dbname> OWNER <user>;\""
```

**Redis**:

```bash
ssh -i <key> root@<public-ip> "apt-get install -y redis-server"
ssh -i <key> root@<public-ip> "systemctl enable --now redis-server"
```

**MySQL / MariaDB**:

```bash
ssh -i <key> root@<public-ip> "apt-get install -y mariadb-server"
ssh -i <key> root@<public-ip> "systemctl enable --now mariadb"
ssh -i <key> root@<public-ip> "mysql_secure_installation"
```

---

## Output Rules

- after deploy, summarize: app name, URL or IP, service status, and next step
- for failed deploys, show the error line and the fix — not the full log
- do not dump long stdout unless the user asks

## Docs

- Official documentation: https://docs.e2enetworks.com/docs/myaccount/node/nodes
