o11y-prereq Role
================

This role installs and enables `prometheus-node-exporter` as a standalone systemd service.

## Purpose

This role provides a lightweight way to install just the node exporter without the full observability stack (Prometheus, Grafana, etc.). It can be used standalone or as a dependency of the `observability` role.

## What it installs

- `prometheus-node-exporter` - System metrics exporter
- `jq` - JSON parser utility
- `curl` - HTTP client
- `smartmontools` - S.M.A.R.T. monitoring tools

## Usage

### Standalone usage

To install just node_exporter on a host:

```yaml
- hosts: all
  become: true
  roles:
    - role: o11y-prereq
```

### As part of observability role

The `observability` role automatically includes this role as a dependency, so you don't need to include it separately.

## Service

The role automatically enables and starts the `prometheus-node-exporter` systemd service. The service will listen on port `9100` by default.

## Supported OS

- Debian/Ubuntu (via apt)
- Archlinux (via pacman)
