# Prometheus Stack

A simple, flexible Prometheus and Alertmanager stack for monitoring your homeserver infrastructure with Docker Service Discovery.

## Overview

This stack includes:

- **Prometheus v3.8.1** - Metrics collection and storage
- **Alertmanager v0.30.0** - Alert routing and notification management
- **Docker Service Discovery** - Auto-scrape containers via labelsh
- **Config override mechanism** - Customize configs without git changes
- **Rules directory on EXT_PATH** - Easy alert rule management

### Architecture

```
┌─────────────────────────────────────────┐
│         Host Network Mode                │
├─────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐     │
│  │ Prometheus   │  │ Alertmanager │     │
│  │ :9090        │  │ :9093        │     │
│  └──────┬───────┘  └──────────────┘     │
│         │                                 │
│         │ Docker Socket                   │
│         │ (Service Discovery)             │
│         │                                 │
│  ┌──────▼─────────────────────────────┐  │
│  │ Containers with                    │  │
│  │ prometheus.io/scrape=true labels   │  │
│  └────────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Prerequisites

- Docker and Docker Compose
- Komodo deployment system
- EXT_PATH mounted (e.g., `/mnt/external` or `/mnt/tank`)

## Initial Setup

### 1. Deploy via Komodo

The stack is configured in `komodo.toml` for both `lisa` and `lovelace` servers. Deploy using the Komodo UI or procedure.

### 2. Accessing Services

After deployment:

- **Prometheus**: `http://<server-ip>:9090`
- **Alertmanager**: `http://<server-ip>:9093`

Services are exposed via host network mode, accessible on localhost or the server's IP address.

### 3. Default Configuration

The stack starts with minimal default configurations:

- **Prometheus**: Scrapes itself, Alertmanager, and containers with Docker SD labels
- **Alertmanager**: Routes all alerts to a null receiver (does nothing)
- **No exporters**: Add via Docker SD labels or custom config
- **No alert rules**: Add to `${EXT_PATH}/prometheus/rules/`

### 4. Directory Structure

On the server (created automatically):

```
${EXT_PATH}/
├── prometheus/
│   ├── data/          # Prometheus TSDB data
│   ├── rules/         # Alert rules (*.rules.yml)
│   └── config/        # Custom config overrides
└── alertmanager/
    ├── data/          # Alertmanager state
    └── config/        # Custom config overrides
```

## Docker Service Discovery

### How It Works

Prometheus automatically discovers and scrapes containers with specific labels. No manual scrape config needed!

### Adding Metrics to a Container

Add labels to any service in your compose files:

```yaml
services:
  my-service:
    image: my-image:latest
    labels:
      prometheus.io/scrape: "true"        # Required
      prometheus.io/port: "8080"          # Optional
      prometheus.io/path: "/metrics"      # Optional
```

### Label Reference

| Label | Required | Default | Description |
|-------|----------|---------|-------------|
| `prometheus.io/scrape` | **Yes** | - | Set to `"true"` to enable scraping |
| `prometheus.io/address` | No | - | Full address (e.g., `localhost:9618`). Takes priority over `port` label. |
| `prometheus.io/port` | No | First exposed port | Port to scrape metrics from (constructs `localhost:PORT`) |
| `prometheus.io/path` | No | `/metrics` | HTTP path for metrics endpoint |

**Address Priority:**
1. If `prometheus.io/address` is set → use that address directly
2. Else if `prometheus.io/port` is set → use `localhost:PORT`
3. Else → use first exposed port from container

### Examples

**Example 1: Simple service with default metrics endpoint**

```yaml
services:
  api:
    image: my-api:latest
    ports:
      - "8080:8080"
    labels:
      prometheus.io/scrape: "true"
      # Uses port 8080 and /metrics automatically
```

**Example 2: Custom metrics port**

```yaml
services:
  worker:
    image: my-worker:latest
    ports:
      - "9100:9100"
    labels:
      prometheus.io/scrape: "true"
      prometheus.io/port: "9100"
```

**Example 3: Custom metrics path**

```yaml
services:
  database:
    image: postgres:latest
    labels:
      prometheus.io/scrape: "true"
      prometheus.io/port: "9187"
      prometheus.io/path: "/probe"
```

**Example 4: Service bound to localhost (not accessible via Docker network)**

```yaml
services:
  exporter:
    image: some-exporter:latest
    ports:
      - "127.0.0.1:9618:9618"  # Only accessible from host, so use host internal ip
    labels:
      prometheus.io/scrape: "true"
      prometheus.io/address: "172.17.0.1:9618"  # Use full address from docker host
      prometheus.io/path: "/metrics"
```

**When to use `prometheus.io/address`:**
- Service is bound to localhost only (not accessible via Docker network)
- Service is on a different host (e.g., `192.168.1.100:9618`)
- Service requires specific hostname resolution

### Verifying Discovery

1. Open Prometheus: `http://<server-ip>:9090`
2. Go to **Status → Targets**
3. Look for the `docker_sd` job
4. Verify your containers are listed and `UP`

## Configuration Override

### Why Override?

The default configs are minimal. You may want to:

- Add static scrape targets (exporters on other hosts)
- Configure remote write to Grafana Cloud
- Add advanced Prometheus features
- Configure Alertmanager receivers (Telegram, email, etc.)

### Overriding Prometheus Config

**Step 1: Create custom config on the server**

```bash
# SSH to the server
ssh lisa  # or lovelace

# Create config directory
mkdir -p /mnt/external/prometheus/config

# Create custom config (copy default as starting point)
nano /mnt/external/prometheus/config/prometheus.yml
```

**Step 2: Update komodo.toml**

Edit the stack environment in `komodo.toml`:

```toml
[[stack]]
name = "prometheus"
[stack.config]
server = "lisa"
repo = "gjhenrique/rpi_stuff"
run_directory = "stacks"
branch = "master"
file_paths = ["prometheus/compose.yaml"]
environment = """
EXT_PATH: /mnt/external

PROMETHEUS_RETENTION: "30d"
PROMETHEUS_CONFIG_FILE: "custom/prometheus.yml"  # Enable custom config
"""
```

**Step 3: Redeploy the stack**

Use Komodo UI or procedure to redeploy the prometheus stack.

### Overriding Alertmanager Config

Same process as Prometheus:

1. Create `/mnt/external/alertmanager/config/alertmanager.yml`
2. Set `ALERTMANAGER_CONFIG_FILE: "custom/alertmanager.yml"` in `komodo.toml`
3. Redeploy

### Example: Adding Node Exporter

Add to your custom `prometheus.yml`:

```yaml
scrape_configs:
  # ... existing configs ...

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
```

Then install node_exporter on the host or as a container.

### Example: Telegram Notifications

Create custom `/mnt/external/alertmanager/config/alertmanager.yml`:

```yaml
global:
  resolve_timeout: 5m

receivers:
  - name: 'telegram'
    telegram_configs:
      - bot_token: 'YOUR_BOT_TOKEN'
        chat_id: YOUR_CHAT_ID
        parse_mode: 'HTML'

route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h
  receiver: 'telegram'
```

## Alert Rules

### Adding Rules

**Step 1: Create a rule file on the server**

```bash
ssh lisa  # or lovelace
nano /mnt/external/prometheus/rules/my-alerts.rules.yml
```

**Step 2: Add your rules**

```yaml
groups:
  - name: my_alerts
    rules:
      - alert: HighCPUUsage
        expr: node_cpu_usage > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value }}%"
```

**Step 3: Reload Prometheus**

```bash
curl -X POST http://localhost:9090/-/reload
```

**Step 4: Verify rules are loaded**

- Open `http://<server-ip>:9090/rules`
- Check that your rule group appears

### Rule File Format

All `.rules.yml` files in `${EXT_PATH}/prometheus/rules/` are automatically loaded.

Basic structure:

```yaml
groups:
  - name: group_name
    rules:
      - alert: AlertName
        expr: metric_expression > threshold
        for: duration
        labels:
          severity: warning|critical|info
        annotations:
          summary: "Short description"
          description: "Detailed description with {{ $labels.instance }}"
```

### Example Rules

You can copy example rules from the old observability setup:

```bash
# From the rpi_automation repo
rpi_automation/pedro_app/prom_rules/files/
├── node_exporter.rules.yml
├── services.rules.yml
├── hdd_monitoring.rules.yml
└── qingping.rules.yml
```

Copy any of these to `/mnt/external/prometheus/rules/` and reload Prometheus.

## Environment Variables

Configure in `komodo.toml` environment section:

| Variable | Default | Description |
|----------|---------|-------------|
| `EXT_PATH` | **Required** | Base path for data (`/mnt/external` or `/mnt/tank`) |
| `PROMETHEUS_RETENTION` | `30d` | How long to keep metrics data |
| `PROMETHEUS_CONFIG_FILE` | `prometheus.yml.default` | Config file to use (set to `custom/prometheus.yml` for override) |
| `ALERTMANAGER_CONFIG_FILE` | `alertmanager.yml.default` | Alertmanager config file (set to `custom/alertmanager.yml` for override) |

## Troubleshooting

### Check Prometheus Targets

1. Open `http://<server-ip>:9090/targets`
2. Verify all targets are `UP`
3. Check error messages for `DOWN` targets

### Check Configuration

Prometheus validates config on startup. Check for errors:

```bash
docker logs prometheus
```

Or test config manually:

```bash
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml.default
```

### Reload Configuration

After changing rules or config:

```bash
curl -X POST http://localhost:9090/-/reload
```

### Check Docker Service Discovery

View discovered containers:

```bash
# Open Prometheus UI
# Go to Status → Service Discovery
# Look for docker_sd discoveries
```

### Common Issues

**Issue: Container not discovered**

- Check the `prometheus.io/scrape: "true"` label is set
- Verify container is running: `docker ps`
- Check Prometheus logs: `docker logs prometheus`

**Issue: Wrong port scraped**

- Add explicit `prometheus.io/port: "XXXX"` label
- Check Service Discovery in Prometheus UI to see detected port

**Issue: 404 on metrics endpoint**

- Verify the metrics path with `curl http://localhost:<port>/metrics`
- Add `prometheus.io/path` label if not `/metrics`

**Issue: Config not reloading**

- Ensure `--web.enable-lifecycle` flag is set (it is by default)
- Check Prometheus logs for syntax errors
- Restart container if reload fails: `docker restart prometheus`

## Advanced Topics

### Data Retention

Change retention period in `komodo.toml`:

```toml
environment = """
EXT_PATH: /mnt/external
PROMETHEUS_RETENTION: "90d"  # Keep data for 90 days
"""
```

Supported formats: `30d`, `12w`, `1y`

### Remote Write (Grafana Cloud)

Add to custom `prometheus.yml`:

```yaml
remote_write:
  - url: https://prometheus-XXX.grafana.net/api/prom/push
    basic_auth:
      username: YOUR_USERNAME
      password: YOUR_API_KEY
```

### Adding Exporters

**Option 1: Via Docker SD Labels**

Best for containerized exporters:

```yaml
services:
  node-exporter:
    image: prom/node-exporter:latest
    network_mode: host
    labels:
      prometheus.io/scrape: "true"
      prometheus.io/port: "9100"
```

**Option 2: Via Custom Config**

For host-installed exporters:

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
```

**Option 3: Via Static Config**

For exporters on other hosts:

```yaml
scrape_configs:
  - job_name: 'remote_node'
    static_configs:
      - targets: ['192.168.1.10:9100', '192.168.1.11:9100']
```

### Federation

Scrape metrics from another Prometheus instance:

```yaml
scrape_configs:
  - job_name: 'federate'
    scrape_interval: 15s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="prometheus"}'
        - '{__name__=~"job:.*"}'
    static_configs:
      - targets: ['other-prometheus:9090']
```

### Recording Rules

Create aggregations and pre-computed queries:

```yaml
groups:
  - name: example
    interval: 30s
    rules:
      - record: job:node_cpu_usage:avg
        expr: avg by(job) (rate(node_cpu_seconds_total[5m]))
```

## Links and References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Docker SD Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#docker_sd_config)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Recording Rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
- [Alert Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)

## Support

For issues specific to this stack configuration, check:

1. Docker logs: `docker logs prometheus` or `docker logs alertmanager`
2. Prometheus UI: `http://<server-ip>:9090`
3. Alertmanager UI: `http://<server-ip>:9093`
