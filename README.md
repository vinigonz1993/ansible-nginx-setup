# Nginx + Certbot Auto Configuration (Ansible)

This project automates the configuration of Nginx and Let's Encrypt (Certbot)
for both an API and a frontend application, based on settings from a `.env` file.

It installs Nginx, sets up HTTPS redirection, configures SSL certificates, and
creates production-ready server blocks for your API and frontend.

---

## Project Structure

.
├── deploy.sh                # Bash script to run the entire deployment
├── setup-nginx.yml          # Ansible playbook
├── roles/
│   └── nginx_certbot/       # Ansible role with templates & tasks
│       ├── tasks/
│       │   └── main.yml
│       └── templates/
│           └── nginx_site.conf.j2
├── .env                     # Environment variables for deployment (ignored in git)
└── .env.example             # Example env file for sharing

---

## Requirements

- Local machine: Bash, Ansible installed
- Remote server:
  - SSH access with the user specified in `.env`
  - Ubuntu/Debian-based OS (adjust packages if different)
- DNS records pointing your domain(s) to the server IP

---

## .env.example

# Server connection
SERVER_IP=123.45.67.89
SERVER_USER=ubuntu

# Let's Encrypt email (certificate registration)
EMAIL=admin@toukiai.com.br

# API configuration
API_DOMAIN=api.toukiai.com.br
API_PORT=8000
API_STATIC=/var/lib/docker/volumes/touki-agent-backend_prod_static/_data/

# Frontend configuration
FRONTEND_DOMAIN=toukiai.com.br
FRONTEND_ROOT=/var/lib/docker/volumes/touki-agent-frontend_prod-dist/_data

---

## How to Deploy

1. Clone the repository
   git clone https://github.com/your/repo.git
   cd repo

2. Copy `.env.example` to `.env` and update values
   cp .env.example .env
   nano .env

3. Run the deployment script
   chmod +x deploy.sh
   ./deploy.sh

4. Verify deployment
   - API should be available at: https://api.toukiai.com.br
   - Frontend should be available at: https://toukiai.com.br

---

## Re-running Deployment

You can safely run:
./deploy.sh

The playbook is idempotent — it will skip tasks that are already applied.

---

## What This Does

- Installs nginx, certbot, and the Certbot Nginx plugin
- Creates /var/www/certbot for certificate validation
- Configures Nginx HTTP→HTTPS redirection
- Configures SSL for both API and frontend
- Proxies API traffic to the configured port
- Serves static files for /static/ and frontend root
- Obtains SSL certificates via Let's Encrypt
- Ensures certificates auto-renew via certbot.timer

---

## Troubleshooting

- If certificate creation fails, check:
  - Your DNS records are correct and propagated
  - Port 80 and 443 are open in your server firewall
- Test Nginx config manually:
  sudo nginx -t
  sudo systemctl reload nginx

---

## License

MIT License

---

## deploy.sh

#!/usr/bin/env bash
set -euo pipefail

# Load environment variables from .env
if [[ ! -f ".env" ]]; then
  echo "❌ .env file not found"
  exit 1
fi

export $(grep -v '^#' .env | xargs)

# Check required variables
REQUIRED_VARS=("SERVER_IP" "SERVER_USER" "EMAIL" "API_DOMAIN" "API_PORT" "API_STATIC" "FRONTEND_DOMAIN" "FRONTEND_ROOT")
for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Missing required env var: $var"
    exit 1
  fi
done

# Create a temporary inventory file
INVENTORY_FILE=$(mktemp)
cat > "$INVENTORY_FILE" <<EOF
[web]
${SERVER_IP} ansible_user=${SERVER_USER}
EOF

# Run ansible-playbook
ansible-playbook \
  -i "$INVENTORY_FILE" \
  -e email="$EMAIL" \
  -e api_domain="$API_DOMAIN" \
  -e api_port="$API_PORT" \
  -e api_static="$API_STATIC" \
  -e frontend_domain="$FRONTEND_DOMAIN" \
  -e frontend_root="$FRONTEND_ROOT" \
  setup-nginx.yml

# Clean up
rm -f "$INVENTORY_FILE"

echo "✅ Deployment complete!"
