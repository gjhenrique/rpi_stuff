Personal use of ansible roles to my Raspberry Pi.

Roles from [rpi_stuff](https://github.com/gjhenrique/rpi_stuff):
- duckdns
- syncthing
- mount external HDD to media directory
- jellyfin
- torrent role with bot, flexget, wireguard, etc.

Roles implemented here:
- Tailscale to access rpi from outside my home sweet home
- docker
- emby (old jellyfin and premium required)

## Install

``` shell
# Install dependencies
ansible-galaxy install -vvv --force -r requirements.yml

# Run the playbooks
ansible-playbook site.yml
```
## Encryption/Decryption of secret files

``` bash
# To encrypt the file. Store a strong password somewhere safe
ansible-vault encrypt secrets.yml

# To update or add a new value
ansible-vault decrypt secrets.yml
```

Comment the line `vault_password_file` on `ansible.cfg` if you want to type the password every time.
