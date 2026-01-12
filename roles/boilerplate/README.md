# Boilerplate Role

Sets up the basic requirements for the homelab server including Docker, container runtime, and system configuration.

## Features

- Installs Docker and container tools
- Configures firewall (Debian/Ubuntu)
- Allows unprivileged port binding (ports 80+)
- **Disables systemd-resolved** for DNS server deployments (AdGuard Home, Pi-hole, etc.)

## Variables

### Docker Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_repo_url` | `https://download.docker.com/linux` | Docker repository URL |

### Firewall Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `boilerplate_firewall_local_network` | `192.168.1.0/24` | Local network CIDR for firewall rules |
| `boilerplate_firewall_reset` | `false` | Reset firewall rules before applying |

### DNS Configuration (for AdGuard Home / Pi-hole)

| Variable | Default | Description |
|----------|---------|-------------|
| `boilerplate_disable_systemd_resolved` | `false` | Disable systemd-resolved to free port 53 |
| `boilerplate_upstream_dns_servers` | `[1.1.1.1, 8.8.8.8]` | Upstream DNS servers for resolv.conf |
| `boilerplate_protect_resolv_conf` | `true` | Make resolv.conf immutable to prevent DHCP overwrites |
| `boilerplate_dns_search_domain` | (undefined) | Optional search domain for DNS |

## Usage

### Basic Usage

```yaml
- hosts: homelab
  roles:
    - boilerplate
```

### With AdGuard Home / Pi-hole

To deploy a DNS server like AdGuard Home, you need to disable systemd-resolved first:

```yaml
- hosts: homelab
  roles:
    - role: boilerplate
      vars:
        boilerplate_disable_systemd_resolved: true
        boilerplate_upstream_dns_servers:
          - 1.1.1.1
          - 8.8.8.8
```

After AdGuard Home is running, you may want to update `/etc/resolv.conf` to point to `127.0.0.1` (AdGuard). To do this:

1. First, remove the immutable flag: `sudo chattr -i /etc/resolv.conf`
2. Update the nameserver: `echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf`
3. Optionally re-protect it: `sudo chattr +i /etc/resolv.conf`

## Notes

- The `boilerplate_protect_resolv_conf` option sets the immutable attribute on `/etc/resolv.conf` to prevent NetworkManager or DHCP clients from overwriting it
- This role only disables systemd-resolved on Debian-based systems (Ubuntu, Debian)
