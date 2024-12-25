Personal use of ansible roles to my Raspberry Pi.

Roles from the common [rpi_stuff](https://github.com/gjhenrique/rpi_stuff):
- syncthing
- mount external HDD to media directory
- jellyfin
- photoprism and share with samba

## Install

``` shell
# Run the playbooks
ansible-playbook site.yml
```
## Encryption/Decryption of secret files

Using `git-crypt` for encrypting `secrets.yml`. Visit the docs for more details
