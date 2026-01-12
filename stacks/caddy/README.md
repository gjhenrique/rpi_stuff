# Caddy Stack - Reverse Proxy with Google SSO

This stack provides a reverse proxy with automatic HTTPS (via Let's Encrypt) and Google OAuth authentication for your services.

## Overview

Caddy acts as a reverse proxy that:
- Provides automatic HTTPS/TLS certificates via Let's Encrypt (using Cloudflare DNS-01 challenge)
- Handles Google OAuth authentication (SSO) for protected services
- Routes traffic to services running on localhost
- Provides a unified authentication portal at `https://auth.{DOMAIN}`

## Google OAuth Setup

Before configuring secrets, you need to set up Google OAuth credentials:

1. **Go to [Google Cloud Console](https://console.cloud.google.com/)**
2. **Create OAuth 2.0 Client ID:**
   - APIs & Services → Credentials → Create Credentials → OAuth client ID
   - Application type: Web application
   - Name: `Your Homelab Caddy` (or similar)
3. **Authorized JavaScript origins:**
   ```
   https://auth.{DOMAIN}
   https://{DOMAIN}
   ```
   (Replace `{DOMAIN}` with your actual domain)
4. **Authorized redirect URIs:**
   ```
   https://auth.{DOMAIN}/oauth2/google/authorization-code-callback
   ```
   (Replace `{DOMAIN}` with your actual domain)
   - **Important:** Caddy authp uses `/oauth2/google/authorization-code-callback` as the callback path
5. **Copy credentials** for use in secrets below

## Required Secrets in Komodo UI

All secrets must be configured in **Komodo UI** (not in git). Go to Komodo UI → Secrets/Config and add:

### 1. `CADDY_GOOGLE_CLIENT_ID`

**⚠️ IMPORTANT:** Only include the client ID part, **NOT** the full `.apps.googleusercontent.com` suffix!

- **Format:** `123456789-abcdefghijklmnop.apps.googleusercontent.com` (from Google Cloud Console)
- **What to set in Komodo:** `123456789-abcdefghijklmnop` (remove `.apps.googleusercontent.com`)
- **Why:** The Caddyfile automatically adds `.apps.googleusercontent.com`, so including it would create a duplicate

**Example:**
```
❌ Wrong: 165488352304-3cph7alj5uturvrb7mu4t0grj6g9ocu6.apps.googleusercontent.com
✅ Correct: 165488352304-3cph7alj5uturvrb7mu4t0grj6g9ocu6
```

### 2. `CADDY_GOOGLE_CLIENT_SECRET`

- **Source:** Google Cloud Console → OAuth 2.0 Credentials
- **Format:** `GOCSPX-xxxxx...`
- **Set exactly as shown** in Google Cloud Console

### 3. `CADDY_JWT_SHARED_KEY`

- **Generate with:** `openssl rand -hex 32`
- **Example:** `e5b30c01cbb3ceb2eb4273ac87863bb1246384d7ccaf3a362383ac58fa328a39`
- **Purpose:** Used to sign/verify JWT tokens for authentication
- **Security:** Keep this secret! Anyone with this key can create valid authentication tokens

### 4. `CADDY_DOMAIN`

- **Format:** Your domain name (no `https://`, no trailing slash)
- **Examples:**
  - `tanaka.dev.br`
  - `pedro.example.com`
  - `services.example.com`
- **Purpose:** Base domain for all services (e.g., `emby.{DOMAIN}`, `auth.{DOMAIN}`)

### 5. `CADDY_ALLOWED_EMAILS`

- **Format:** Regex pattern for allowed email addresses
- **Examples:**
  - Single email: `^pedro@example\.com$`
  - Domain pattern: `.*@example\.com`
  - Multiple domains: `.*@example\.com|.*@gmail\.com`
  - Multiple specific users: `^(pedro|carol)@example\.com$`
- **Note:** Escape dots with `\.` in regex patterns

### 6. `CADDY_CLOUDFLARE_API_TOKEN`

- **Source:** Cloudflare Dashboard → My Profile → API Tokens
- **Permissions needed:**
  - Zone → Zone → Read
  - Zone → DNS → Edit
- **Purpose:** Used for DNS-01 ACME challenge (automatic certificate issuance/renewal)
- **Note:** Caddy uses this to create temporary DNS TXT records for Let's Encrypt validation

## How Secrets Work

1. **Secrets are configured in Komodo UI** (not in git)
2. **Komodo replaces placeholders** in `komodo.toml`:
   - `"[[CADDY_DOMAIN]]"` → actual value from Komodo UI
3. **Environment variables** are passed to the container
4. **Caddyfile uses variables** like `{$DOMAIN}` which get replaced with environment values

## Service Configuration

### Adding a New Service

1. **Add service block to Caddyfile:**
   ```caddyfile
   # my-service
   myservice.{$DOMAIN} {
       import cloudflare_tls
       authorize with mypolicy
       reverse_proxy 127.0.0.1:8080
   }
   ```

2. **Add link to authentication portal** (optional):
   ```caddyfile
   ui link "My Service" https://myservice.{$DOMAIN}/ icon "las la-icon-name"
   ```

3. **Services without authentication** (for mobile apps):
   ```caddyfile
   # immich (no auth - handled by service itself)
   photos.{$DOMAIN} {
       import cloudflare_tls
       # no authentication because of the mobile app
       reverse_proxy 127.0.0.1:2283
   }
   ```

### Current Services

The Caddyfile includes blocks for:
- `auth.{DOMAIN}` - Authentication portal
- `emby.{DOMAIN}` - Emby media server
- `dns.{DOMAIN}` - AdGuard DNS
- And more (see Caddyfile for full list)

## Port Configuration

Caddy runs with `network_mode: host`, so it:
- Listens on ports 80 (HTTP) and 443 (HTTPS) directly on the host
- Can access services on `127.0.0.1` (localhost)
- Services should expose ports on localhost (not all interfaces) for security

## Troubleshooting

### SSL Protocol Error / Invalid Response

**Symptoms:** `ERR_SSL_PROTOCOL_ERROR` when accessing services

**Causes:**
1. **Domain secret not set:** `DOMAIN=[[CADDY_DOMAIN]]` instead of actual domain
2. **Certificate not issued:** Check Caddy logs for ACME errors
3. **DNS not resolving:** Verify DNS points to your server

**Solution:**
```bash
# Check environment variables
docker exec <caddy-container> env | grep DOMAIN

# Check Caddy logs
docker logs <caddy-container> | grep -i error

# Verify secrets are set in Komodo UI and redeploy
```

### Google OAuth "invalid_client" Error

**Symptoms:** "OAuth client was not found" or "Error 401: invalid_client"

**Cause:** `CADDY_GOOGLE_CLIENT_ID` includes `.apps.googleusercontent.com` suffix

**Solution:**
1. Go to Komodo UI → Secrets
2. Update `CADDY_GOOGLE_CLIENT_ID` to remove `.apps.googleusercontent.com`
3. Redeploy Caddy stack

**Verify:**
```bash
# Should NOT have duplicate .apps.googleusercontent.com
docker logs <caddy-container> | grep client_id
```

### Google OAuth "redirect_uri_mismatch" Error

**Symptoms:** "Error 400: redirect_uri_mismatch" when trying to authenticate

**Cause:** The redirect URI in Google Cloud Console doesn't match what Caddy authp sends

**Solution:**
1. Go to Google Cloud Console → APIs & Services → Credentials
2. Edit your OAuth 2.0 Client ID
3. In **Authorized redirect URIs**, add:
   ```
   https://auth.{DOMAIN}/oauth2/google/authorization-code-callback
   ```
   (Replace `{DOMAIN}` with your actual domain, e.g., `tanaka.dev.br`)
4. Save changes and wait a few minutes for propagation

**Note:** Caddy authp uses `/oauth2/google/authorization-code-callback` as the callback path, not `/oauth2/callback` or `/oauth2/google`.

### Certificates Not Issuing

**Symptoms:** No certificates in `/data/caddy/certificates/`

**Causes:**
1. Cloudflare API token invalid or missing permissions
2. DNS not resolving to your server
3. Domain secret not set correctly

**Solution:**
1. Verify `CADDY_CLOUDFLARE_API_TOKEN` is correct
2. Test DNS: `nslookup emby.{DOMAIN}`
3. Check Caddy logs: `docker logs <caddy-container> | grep -i acme`

### Services Not Accessible

**Symptoms:** 502 Bad Gateway or connection refused

**Causes:**
1. Service not running on expected port
2. Wrong port in Caddyfile
3. Service not listening on localhost

**Solution:**
```bash
# Check if service is running
docker ps | grep <service-name>

# Check what port service is on
docker port <service-container>

# Verify Caddyfile reverse_proxy port matches
```

### Domain Variable Not Replaced

**Symptoms:** `{$DOMAIN}` appears literally in Caddyfile or `DOMAIN=[[CADDY_DOMAIN]]` in container

**Cause:** Secret not set in Komodo UI or stack not redeployed

**Solution:**
1. Set `CADDY_DOMAIN` in Komodo UI
2. **Redeploy via Komodo UI** (not just restart container)
3. Verify: `docker exec <caddy-container> env | grep DOMAIN`

## Common Issues

### Duplicate `.apps.googleusercontent.com`

**Problem:** Client ID becomes `123.apps.googleusercontent.com.apps.googleusercontent.com`

**Fix:** Remove `.apps.googleusercontent.com` from `CADDY_GOOGLE_CLIENT_ID` secret

### Secrets Not Replaced After Restart

**Problem:** Restarting container doesn't replace secrets

**Fix:** Must redeploy via Komodo UI, not just restart. Komodo replaces secrets during deployment.

### DNS Resolution Issues

**Problem:** Server can't resolve `emby.{DOMAIN}`

**Fix:** Update `/etc/resolv.conf` to point to AdGuard (127.0.0.1) or use AdGuard DNS

## Verification Checklist

After setup, verify:

- [ ] All secrets set in Komodo UI
- [ ] Stack redeployed via Komodo (not just restarted)
- [ ] `DOMAIN` environment variable shows actual domain (not `[[CADDY_DOMAIN]]`)
- [ ] `GOOGLE_CLIENT_ID` doesn't have duplicate `.apps.googleusercontent.com`
- [ ] Certificates issued: Check `/data/caddy/certificates/` or Caddy logs
- [ ] DNS resolves: `nslookup emby.{DOMAIN}`
- [ ] Authentication portal accessible: `https://auth.{DOMAIN}`
- [ ] Services accessible: `https://emby.{DOMAIN}` (after authentication)

## Useful Commands

```bash
# Check Caddy container status
docker ps | grep caddy

# View Caddy logs
docker logs <caddy-container>

# Check environment variables
docker exec <caddy-container> env | grep -E 'DOMAIN|GOOGLE|JWT'

# Test HTTPS connection
curl -v https://emby.{DOMAIN}

# Check certificate status via Caddy admin API
curl http://localhost:2019/config/apps/tls/certificates

# View actual Caddyfile (with variable substitution)
docker exec <caddy-container> cat /etc/caddy/Caddyfile
```

## References

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Caddy Security Plugin (authcrunch)](https://docs.authcrunch.com/)
- [Google OAuth Setup Guide](../docs/EXTERNAL_SETUP.md#2-google-oauthsso-setup-for-caddy)
- [Cloudflare API Token Setup](../docs/EXTERNAL_SETUP.md#14-create-cloudflare-api-token)
