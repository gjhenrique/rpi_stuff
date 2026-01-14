RPI Observability Role
=========

This role installs and configures observability tools on a Raspberry Pi.
By default, it will:

- Install Prometheus
- Install Grafana
- Install Node Exporter
- Enable docker monitoring
- Install docker-stats exporter (for container-level monitoring)
- Configure Prometheus to scrape metrics from all the above

## Dependencies

This role depends on the following roles:

- [o11y-prereq](../o11y-prereq/README.md) - Installs prometheus-node-exporter as a systemd service
- [boilerplate](../boilerplate/README.md)
- [compose](../compose/README.md)

### Installing Node Exporter Standalone

If you only need to install `prometheus-node-exporter` without the full observability stack (Prometheus, Grafana, etc.), you can use the `o11y-prereq` role directly:

```yaml
- hosts: all
  become: true
  roles:
    - role: o11y-prereq
```

This will install and enable the `prometheus-node-exporter` systemd service, which listens on port `9100` by default.

## HDD Monitoring

This role includes support for monitoring HDD health using the smartctl exporter. To enable HDD monitoring:

1. Set `observability_enable_hdd_monitoring: true` in your variables
2. Configure the HDD devices you want to monitor in `observability_hdd_devices`

### Configuration Example

```yaml
# Enable HDD monitoring
observability_enable_hdd_monitoring: true

# Configure HDD devices to monitor
observability_hdd_devices:
  - device: "/dev/sda"
    mount_point: "/mnt/storage1"
    description: "Main storage drive"
  - device: "/dev/sdb"
    mount_point: "/mnt/backup"
    description: "Backup drive"
  - device: "/dev/sdc"
    mount_point: "/mnt/media"
    description: "Media drive"

# Customize the exporter port (default: 9633)
observability_smartctl_exporter_port: 9633
```

### What it provides

- **S.M.A.R.T. metrics**: Temperature, health status, error counts, and more
- **Device information**: Model, serial number, firmware version
- **Performance metrics**: Read/write performance, seek times
- **Health alerts**: Configurable thresholds for critical metrics

### Port Configuration

The smartctl exporter runs on port 9633 by default. This port is automatically exposed through Tailscale when HDD monitoring is enabled.

### Requirements

- smartmontools is automatically installed by the role
- The observability user must have access to `/dev/*` devices
- HDD devices must be accessible to the container
