# rpi_stuff

![Github CI](https://github.com/gjhenrique/rpi_stuff/actions/workflows/local-test.yml/badge.svg)
![Ansible Galaxy](https://img.shields.io/badge/dynamic/json?style=flat&label=galaxy&prefix=v&url=https://galaxy.ansible.com/api/v2/collections/gjhenrique/rpi_stuff/&query=latest_version.version)

Collection of opinionated Ansible roles to automate some stuff I use in my day-to-day in a Raspberry Pi 4B.

This repo brings the following features:
- syncthing to synchronize documents
- secure and easy torrent download
- jellyfin for media
- automated tests with molecule

## Architecture

Every role has a [Compose](https://github.com/compose-spec/compose-spec/) file as a foundation.
By default, it uses a rootless container with podman, but it's possible to use docker if some feature is not supported.

Writing new ansible roles is incredibly easy.

1. Write a compose file and put it in `<role_dir>/templates/compose.yml.j2`

``` yaml
services:
  syncthing:
    image: lscr.io/linuxserver/syncthing:1.23.2
    ports:
      - "127.0.0.1:8384:8384"
    volumes:
      - /home/syncthing/config:/config
      - /home/syncthing/data:/data
```

1. Invoke the compose role to enable and start a new compose. By default, it uses rootless podman (even though it invokes `docker-compose`).
``` yaml
- name: Add caddy ingress
  ansible.builtin.include_role:
    name: compose
  vars:
    service_name: syncthing
    user: syncthing
```

1. (Optional): Add the subdomain. It allows users to access the service through the subdomain `syncthing.{{ caddy_domain }}`

``` yaml
- name: Add caddy ingress
  ansible.builtin.include_role:
    name: caddy
    tasks_from: subdomains
  vars:
    subdomain_name: syncthing
    subdomain_host: 127.0.0.1
    subdomain_port: 8384
    state: present
```

1. Profit?

## Support
These roles expect that you have a pacman-based distro, like Manjaro or Arch Linux, installed.
I use it on a Raspberry Pi 4B, but older versions might work.
Although I don't use an x86 machine, the molecule tests are running in it. So it (probably) works on a PC.

## Roles

### Caddy
Provides a caddy server that acts as a reverse proxy for the local services.

- It uses a self-signed certificate by default.
- Supports valid TLS certificates with Let's Encrypt and Cloudflare DNS.
Refer to the [caddy-cloudflaredns repo](https://github.com/SlothCroissant/caddy-cloudflaredns) for the documentation.

### Syncthing
Syncs [Syncthing](https://syncthing.net). Access it with https://syncthing.<< caddy_domain >>

- It uses the syncthing APT sources instead of the default repo

### Torrent
Collection of tools to automate Torrent related software.

Here are some set of features:
- iptables rules to kill torrent traffic in case the traffic is leaving unencrypted.
- Molecule tests to guarantee that the firewall is doing its job, so no regression is introduced.
- All torrent programs run in the same network namespace, so you don't need one VPN connection per container, a-la [docker-transmission-openvpn](https://github.com/haugene/docker-transmission-openvpn).
- Point to Cloudflare DNS (1.1.1.1).
- [wireguard](https://wireguard.com) connection with [gluetun](https://github.com/qdm12/gluetun). Out-of-the box support for Mullvad VPN.
- [Jackett](https://github.com/Jackett/Jackett) to search torrents in hundreds of torrent indexers. Access it with `https://jackett.<<caddy_domain>>`.
- [Transmission](https://transmissionbt.com/) to manage the torrents. Access it with `https://torrents.<<caddy_domain>>`.
- [Telegram bot](https://github.com/gjhenrique/telegram-bot-torrents/) to search torrents from Jackett and send them to Transmission
- [flexget](https://flexget.com/) to download new TV Shows with an RSS URL, rename movies and TV shows to a consistent format, and remove torrents when they're finished.
- option to allow torrent traffic without VPN. Useful for places that don't impose fines for torrent traffic

### Jellyfin
Plex is the most popular streaming service today, so it would be the safest choice.
But, at least, in my experience, the client always needs to transcode (translate the source video to a format the clients can stream) all videos in my fire stick, even though the device can play it directly.

The open-source competitor [jellyfin](https://jellyfin.org/) allows the client to play the videos directly without transcoding.
That moves the bottleneck to the network.
I stream even 4k videos smoothly from the weak Raspberry Pi in my Fire Stick.

If your client is not capable enough and you ever need to transcode in a Raspberry PI, even 1080p movies, you're in trouble.
Jellyfin allegedly supports hardware transcoding via OpenMAX, but even Raspberry Pi engineers advocate for the newer V4L2 API.
In my case, not even OpenMAX is used for transcoding via CPU kicks in, which provides a poor experience.
If I need it in the future, it's easier to send the video to my desktop machine and transcode it with `FFmpeg` manually and send the converted video back to the Raspberry Pi.

In short, avoid transcoding and invest in an adequate device that supports the most used video and audio codecs.


### Emby

Jellyfin doesn't provide a nearly feature complete Android TV app as Emby. The viewing experience is much smoother, though.


## Related
- [My usage of these roles](./app): Playbook pointing to these roles and encrypting secrets with `ansible-vault`. Feel free to use it
- [Torrent role](./roles/torrent): Manual steps required to have a functioning infrastructure
- [telegram-bot-torrents](https://github.com/gjhenrique/telegram-bot-torrents): Telegram bot to search torrents in Jackett and to upload them to Transmission
