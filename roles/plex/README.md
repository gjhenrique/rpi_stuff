# Plex Role

This Ansible role sets up a Plex Media Server using Docker Compose.

## Requirements

- Ansible 2.9 or higher
- Docker and Docker Compose installed on the target system
- Tailscale network service running

## Role Variables

The following variables can be set in your playbook or inventory:

- `plex_user`: Username for Plex service (default: plex)
- `plex_group`: Group name for Plex service (default: plex)
- `plex_user_id`: User ID for Plex service (default: 1000)
- `plex_group_id`: Group ID for Plex service (default: 1000)
- `plex_version`: Plex container version (default: latest)
- `plex_claim`: Plex claim token for server setup (optional)
- `plex_extra_mounts`: Additional volume mounts (optional)

## Example Playbook

```yaml
- hosts: servers
  roles:
    - role: plex
      vars:
        plex_user: plex
        plex_group: plex
        plex_claim: "claim-xxxxxxxxxxxxxxxxxxxx"
        plex_extra_mounts:
          /home/plex/media: /media
```

## Notes

- Plex configuration is stored in `/home/plex/plex`
- Media files should be placed in `/home/plex/media`
- The container is limited to 2 CPU cores to prevent overload
- The role uses Tailscale for networking
