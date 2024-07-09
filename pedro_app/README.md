Personal use of ansible roles to my Raspberry Pi.

Roles from the common [rpi_stuff](https://github.com/gjhenrique/rpi_stuff):
- syncthing
- mount external HDD to media directory
- jellyfin
- torrent role with bot, flexget, wireguard, etc.
- photoprism and share with samba

## Install

``` shell
# Run the playbooks
ansible-playbook site.yml
```
## Encryption/Decryption of secret files

``` bash
# Create the file with a strong password to encrypt your file
ansible-vault create ~/.ansible-vault.txt

# To encrypt the file. Store a strong password somewhere safe
ansible-vault encrypt secrets.yml

# To update or add a new value
ansible-vault decrypt secrets.yml
```

Comment the line `vault_password_file` on `ansible.cfg` if you want to type the password every time. 
**Be careful to not push or commit the unencrypted file to Git**
