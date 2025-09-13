#!/usr/bin/env bash

apk add curl

# Get OAuth token
TOKEN=$(curl -s -X POST https://login.tailscale.com/api/v2/oauth/token \
  -d "client_id=$TS_OAUTH_CLIENT" \
  -d "client_secret=$TS_OAUTH_SECRET" | \
  grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

# Create authkey
AUTHKEY_RESPONSE=$(curl -s -X POST https://api.tailscale.com/api/v2/tailnet/-/keys \
  -u "$TOKEN:" -H "Content-Type: application/json" \
  -d "{\"capabilities\":{\"devices\":{\"create\":{\"reusable\":true,\"ephemeral\":false,\"preauthorized\":true,\"tags\":[\"tag:$TS_TAG\"]}}},\"expirySeconds\":0}")

# Extract the key from JSON response
AUTHKEY=$(echo "$AUTHKEY_RESPONSE" | grep -o '"key":"[^"]*' | cut -d'"' -f4)

# Fail if AUTHKEY is empty
if [[ -z "$AUTHKEY" ]]; then
  echo "ERROR: Failed to generate authkey"
  exit 1
fi

echo "Generated authkey: $AUTHKEY"

# Logic declared on serve.yaml
if [[ -f /tailscale-serve-raw.json ]]; then
  echo "Found /tailscale-serve.json, replacing port"

  apk add sed

  sed "s/\$TS_PORT/$TS_PORT/g" /tailscale-serve-raw.json > /var/lib/tailscale/serve.json
fi

export TS_AUTHKEY="$AUTHKEY"
exec /usr/local/bin/containerboot
