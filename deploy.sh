#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f ".env" ]]; then
  echo "❌ .env file not found"
  exit 1
fi

export $(grep -v '^#' .env | xargs)

REQUIRED_VARS=("SERVER_IP" "SERVER_USER" "EMAIL" "API_DOMAIN" "API_PORT" "API_STATIC" "FRONTEND_DOMAIN" "FRONTEND_ROOT")
for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Missing required env var: $var"
    exit 1
  fi
done

INVENTORY_FILE=$(mktemp)
cat > "$INVENTORY_FILE" <<EOF
[web]
${SERVER_IP} ansible_user=${SERVER_USER}
EOF

ansible-playbook \
  -i "$INVENTORY_FILE" \
  -e email="$EMAIL" \
  -e api_domain="$API_DOMAIN" \
  -e api_port="$API_PORT" \
  -e api_static="$API_STATIC" \
  -e frontend_domain="$FRONTEND_DOMAIN" \
  -e frontend_root="$FRONTEND_ROOT" \
  setup-nginx.yml

rm -f "$INVENTORY_FILE"

echo "✅ Deployment complete!"
