# Komodo Role

This Ansible role sets up prerequisites for Komodo deployment on the grace server.

## Requirements

- Ansible 2.9 or higher
- Linux system (Debian/Ubuntu or Arch Linux)
- Root access
- Docker installed (handled by `boilerplate` role)

## Role Variables

The following variables can be set in your playbook or inventory:

- `komodo_root_directory`: Directory path for Komodo Periphery root directory (default: `/etc/komodo`)
- `komodo_install_git_crypt`: Whether to install git-crypt (default: `true`)

## Dependencies

- `boilerplate` role (installs Docker, which Komodo requires)

## Example Playbook

```yaml
- hosts: homelab_servers
  become: true
  vars:
    komodo_root_directory: /etc/komodo
    komodo_install_git_crypt: true
  roles:
    - role: boilerplate
    - role: komodo
```

## What This Role Does

1. **Installs git-crypt**: Required to unlock Komodo secrets from the git repository
   - For Debian/Ubuntu: Installs from package manager
   - For Arch Linux: Installs from package manager
2. **Creates `/etc/komodo` directory**: Periphery root directory used by Komodo Periphery container
   - Sets proper ownership (root:root) and permissions (0755)

## What This Role Does NOT Do

This role only prepares prerequisites. The following steps remain **manual** (as per Komodo's design):

1. Clone the `rpi_stuff` git repository
2. Unlock git-crypt secrets (requires git-crypt key)
3. Start Komodo manually via `docker compose` command
4. Configure Komodo UI (server setup, secrets, etc.)

See `GRACE_SETUP.md` in the `rpi-stuff-gui` repository for complete setup instructions.

## Notes

- This role is idempotent - running it multiple times will not cause issues
- git-crypt installation requires git to be installed (handled automatically)
- The `/etc/komodo` directory is used as a bind mount by the Komodo Periphery container
- Komodo itself is not managed by Ansible (by design, to avoid chicken-and-egg problem)

## License

Same as main project
