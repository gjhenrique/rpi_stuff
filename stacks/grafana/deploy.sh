#!/bin/bash
# Manual deployment script for Grafana on lovelace server
# This can be used as a quick alternative to Komodo deployment

set -e

cd "$(dirname "$0")"

# Set environment variables
export EXT_PATH=/mnt/tank
export GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-CHANGE_ME}"
export TZ=Europe/Berlin

echo "Deploying Grafana stack..."
echo "EXT_PATH: $EXT_PATH"
echo "GRAFANA_ADMIN_PASSWORD: [set]"
echo ""

# Deploy using docker compose
docker compose -f compose.yaml up -d

echo ""
echo "Grafana deployment complete!"
echo "Access Grafana at http://localhost:3000"
echo "Default admin credentials: admin / [your GRAFANA_ADMIN_PASSWORD]"
echo ""
echo "To check status: docker compose -f compose.yaml ps"
echo "To view logs: docker compose -f compose.yaml logs -f"
