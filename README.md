# rpi_stuff

![Github CI](https://github.com/gjhenrique/rpi_stuff/actions/workflows/local-test.yml/badge.svg)
![Ansible Galaxy](https://img.shields.io/badge/dynamic/json?style=flat&label=galaxy&prefix=v&url=https://galaxy.ansible.com/api/v2/collections/gjhenrique/rpi_stuff/&query=latest_version.version)

Collection of opinionated Ansible roles to automate some stuff I use in my day-to-day in a Raspberry Pi.

This repo brings the following features:
- syncthing to synchronize files
- DuckDNS to bind the transient ISP external IP to a DNS entry
- secure and easy torrent download
- emby for media
- external disks mounted declarativelly

## Why not k*n*s or docker-swarm?
Isn't Ansible deprecated already?!
Container orchestration is all the rage today, but older versions are not powerful enought to support them.
When something goes awry, it's simpler to troubleshoot the service directly instead of going through another abstraction layer.
Shipping in containers is more straightforward, though.
Because this repo depends either on release pages or the OS repo to install these programs.

These roles use systemd to configure autostart, timers and mount points.
A counter-argument is that systemd is pretty complex, but at least it's what Raspberry Pi OS/Debian supports by default, and it's pretty lightweight, even for older Raspberry Pi versions.

With Ansible, it's possible to have tests with [molecule](https://molecule.readthedocs.io/en/latest/) and its [podman-plugin](https://github.com/ansible-community/molecule-podman) to ensure that changes won't break code.

## Support
These roles run on Raspberry Pi OS (old raspbian) Bullseye. The devices are rpi1 (armv6), rpi2/3/4 (armv7) and rpi4 (aarch64).
This repo also supports Debian Bullseye x86.
Although I don't use a x86 machine, the molecule tests are running in the ubiquitous x86. So it (probably) works.

I dogfooded these roles on a Raspberry Pi 1 for approximately one year.
I don't recommend this because the CPU was the bottleneck when encrypting packets by the VPN.
But, it's possible nevertheless if there is no other option.

## Roles

### Duckdns
Send your public IP to a [Duck DNS](https://www.duckdns.org/) record.

- Systemd timer pinging Duck DNS server periodically.

### Syncthing
Installs [Syncthing](https://syncthing.net)

- It uses the syncthing APT sources instead of default repo

### Torrent
Collection of tools to automate Torrent related software.

For now, only NordVPN with [openpyn](https://github.com/jotyGill/openpyn-nordvpn), but it's the most affordable VPN there is.

Because NordVPN is shady and might handicap the Internet throughput, the Torrent traffic is isolated into its own network namespace, and any traffic outside of the VPN is denied based on some iptables rules.

The usual traffic from other programs is sent via the unencrypted interface.
Run Mullvad or ProtonVPN in the default network namespace instead if privacy is a goal.

Here are some set of features:
- iptables rules to kill torrent traffic when the VPN is off.
- Molecule tests to guarantee that the firewall is doing its job, so no regression is introduced.
- Run all torrent programs in an isolated network namespace
- Cloudflare DNS (1.1.1.1) instead of the default NordVPN ones.
- [openpyn](https://github.com/jotyGill/openpyn-nordvpn) connecting with `OpenVPN` directly in NordVPN servers. The official client is too intrusive.
- [Jackett](https://github.com/Jackett/Jackett) to search torrents in hundreds of torrent indexers. Supported mono client for Raspberry Pi 1 because the new dotnet binary doesn't support ARMv6.
- [Transmission](https://transmissionbt.com/) to download and seed the torrent files
- [Telegram bot](https://github.com/gjhenrique/telegram-bot-torrents/) to search torrents from Jackett and send them to transmission
- out-of-box HTTPS with Nginx to access transmission and jacket (self-signed certificate)
- [flexget](https://flexget.com/) to download new TV Shows with an RSS URL, rename movies and TV shows to a pretty format, and remove torrents when they're finished.
- option to bring your own vpn. As long as it's running in the torrent namespace, it's protected
- option to allow torrrent traffic without VPN. Useful for countries that don't impose fines for torrent traffic

### Emby
Plex is the most popular streaming service today, so it would be the safest choice.
But, at least, in my experience, the client always needs to transcode (translate the source video to a format the clients can stream) all videos in my fire stick, even though the device can play it directly.
Besides, Plex doesn't look like it's very interested in supporting Raspberry PI.
Just look at the amount of +1s in this [forum request](https://forums.plex.tv/t/hardware-transcoding-for-raspberry-pi-4-plex-media-server/538779/210) to support hardware transcoding and no reply from any employee.
Their bread and butter now apparently is DVR and adding B-movies into its platform.

The competitor [emby](https://emby.media/) allows the client to play the videos directly, and no transcoding is needed.
That moves the bottleneck to the network.
I stream even 4k videos smoothly from the weak Raspberry Pi in my Fire Stick.

If your client is not capable enough and you ever need to transcode in a Raspberry PI, even 1080p movies, you're in trouble.
Emby allegedly supports hardware transcoding via OpenMAX, but even Raspberry Pi engineers advocate for the newer V4L2 API.
In my case, not even OpenMAX is used for transcoding via CPU kicks in, which provides a poor experience.
If I need it in the future, it's easier to send the video to my desktop machine and transcode it with `FFmpeg` manually and send the converted video back to the Raspberry Pi.

In short, avoid transcoding and invest in an adequate device that supports the most used video and audio codecs.

I tried to use its open-source fork [jellyfin](https://jellyfin.org/), but the client in the fire stick had some issues, but it's probably a good idea to support that if needed.

### mount
SD Cards are slower, more expensive and get corrupted more quickly when compared with HDs or SSDs.
A typical setup is to plug a disk in the USB port and use a bigger and more reliable storage.

This role allows you to mount the devices with mount points controller by systemd.
For example, every mount operation, even samba or NFS mounts, is possible with this role.

``` yaml
mount_paths:
  - mount_path: /mnt/external
    mount_from: /dev/sda1
    type: ext4
    user: user
```

## Related
- Demo: In there, you'll put all of your credentials and use the roles of this collection to automate everything
- Torrent role. 
- mine: How . The credentials are encrypted

## Roadmap
- [ ] moleculre-libvirt to test ARM architecture with  qemu/KVM. Graviton 2 in AWS doesn't support nested virtualization. Therefore, emulating from x86 to ARM is unfeasible.
So, we wait for the newer Graviton 3 or use the expensive aws metal arm. Another alternative is to use a raspberry pi 4B to test it.
- [ ] pihole
- [ ] Backup settings and documents to cloud with rclone
