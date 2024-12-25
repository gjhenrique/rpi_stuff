## Exposed ports

Those ports are exposed via your TailScale IP address. You can access them by visiting `http://<your-tailscale-ip>:<port>`,
alternatively, you can use the `http://<your-tailscale-hostname>.<your-tailscale-domain>:<port>`.

| Service | Port         | Description    |
|---------|--------------|----------------|
| 9117    | Jackett      | Indexer        |
| 9091    | Transmission | Torrent client |
| 7878    | Radarr       | Movie manager  |
| 8989    | Sonarr       | TV Show manager|
