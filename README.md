# rpi_stuff

<!-- ![Github CI](https://github.com/gjhenrique/rpi_stuff/actions/workflows/local-test.yml/badge.svg) -->

Collection of opinionated Ansible roles to automate some stuff I use in my day-to-day in a Raspberry Pi 4B.

This repo brings the following features:
- syncthing to synchronize documents
- secure and easy torrent download
- jellyfin and emby for media
- automated tests with molecule (currently broken)
- service management in tailscale

## Architecture

Every role needs a [Compose](https://github.com/compose-spec/compose-spec/) file as a foundation.

Let's write a syncthing service with the compose foundation

1. Write a compose file and put it in `<role_dir>/templates/compose.yml.j2`

``` yaml
services:
  syncthing:
    image: lscr.io/linuxserver/syncthing:1.23.2
    volumes:
      - /home/syncthing/config:/config
      - /home/syncthing/data:/data
```

1. Invoke the compose role to enable and start a new compose. This role creates a new user called `syncthing`, hence the `/home/syncthing/` reference on the step above.
``` yaml
- name: Add caddy ingress
  ansible.builtin.include_role:
    name: compose
  vars:
    service_name: syncthing
    user: syncthing
```

1. (Optional 1): Add the service to your tailnet by adding these vars. The service will join your tailnet and it's accessible outside of your home. It's also possible to control who can reach this service with the Tailscale ACL.

``` yaml
    tailscale:
      enabled: true
      hostname: syncthing
      tag: "tag:syncthing"
```

Now it's possible to access the syncthing service with Tailscale, like `syncthing:8384`. If you don't wanna use Tailscale, you can use the `ports` option on your compose file.

1. (Optional 2): Backup the files daily. The [restic](./roles/restic) to create a periodic job that syncs your data daily to the configured restic remote, like s3, B2 or another machine.

``` yaml
- name: Run backup role
  ansible.builtin.include_role:
    name: restic
    tasks_from: backup
  vars:
    restic_backup_name: syncthing
    restic_backup_args: "/home/syncthing/data"
    restic_forget_args: "--keep-last 7"
    restic_schedule: "*-*-* 4:00:00"
```

1. Profit?

## Distro and Machine Support
To install `docker` and `docker-compose`, this roles expect that you have a pacman-based distro, like Manjaro or Arch Linux, or apt-based distros, like Debian.
You can skip the [boilerplate](./roles/boilerplate) if you have another distro. As long as docker and compose are installed, things should be fine.

I use it on a Raspberry Pi 4B, but older versions can work also.
Although I don't use an x86 machine, the molecule tests are running in it. So it (probably) works on x86 as well.

## Roles

### [Syncthing](./roles/syncthing)
Syncs [Syncthing](https://syncthing.net). Access it with https://syncthing.<< tailscale_domain >>:8384

### [Torrent](./roles/torrent)
Collection of tools to automate Torrent related software.

Here are some set of features:
- Optionally use [mullvad exit node](https://tailscale.com/kb/1258/mullvad-exit-nodes) Tailscale functionality to not receive any fines from your Internet Service Provider
- [Jackett](https://github.com/Jackett/Jackett) to search torrents in hundreds of torrent indexers. Access it with `https://torent:9117`.
- [Transmission](https://transmissionbt.com/) to manage the torrents. Access it with `http://torrents:9091`.
- [Telegram bot](https://github.com/gjhenrique/telegram-bot-torrents/) to search torrents from Jackett and send them to Transmission
- [flexget](https://flexget.com/) to download new TV Shows with an RSS URL, rename movies and TV shows to a consistent format, and remove torrents when they're finished.

### [Jellyfin](./roles/jellyfin)
Plex is the most popular streaming service today, so it would be the safest choice.
But, at least, in my experience, the client always needs to transcode (translate the source video to a format the clients can stream) all videos in my fire stick, even though the device can play it directly.

The open-source competitor [jellyfin](https://jellyfin.org/) allows the client to play the videos directly without transcoding.
So, That moves the bottleneck to the network and the HD.
I stream even 4k videos smoothly from the weak Raspberry Pi in my Fire Stick.

If your client is not capable enough and you ever need to transcode in a Raspberry PI, even 1080p movies, you're in trouble.
Jellyfin allegedly supports hardware transcoding via OpenMAX, but even Raspberry Pi engineers advocate for the newer V4L2 API.
In my case, not even OpenMAX is used for transcoding via CPU kicks in, which provides a poor experience.
If I need it in the future, it's easier to send the video to my desktop machine and transcode it with `FFmpeg` manually and send the converted video back to the Raspberry Pi.

In short, avoid transcoding at all costs and invest in an adequate device that supports the most used video and audio codecs.

### [Emby](./roles/emby)

Jellyfin doesn't provide a feature-complete Android TV app as [Emby](https://emby.media/). The viewing experience is much smoother, though.

### [Document sharing](./roles/share)

- A SMB server to receive documents from clients. I use [the photosync app](https://www.photosync-app.com/home) on my Androd devices to sync photos daily.
- [photoprism](https://www.photoprism.app/) to view photos. Google Photos is slow and laggy.

### Disclaimer

The ansible variables for all roles are not documented yet. For now, running and seeing where it breaks a required variable is the only alternative.

## Related
- [My usage of these roles](./app): Playbook pointing to these roles and encrypting secrets with `ansible-vault`. Feel free to use it
- [Torrent role](./roles/torrent): Manual steps required to have a functioning infrastructure
- [telegram-bot-torrents](https://github.com/gjhenrique/telegram-bot-torrents): Telegram bot to search torrents in Jackett and to upload them to Transmission
