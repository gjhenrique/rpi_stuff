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

- [boilerplate](../boilerplate/README.md)
- [compose](../compose/README.md)
