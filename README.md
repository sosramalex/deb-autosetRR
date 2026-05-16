```
    _    ____   ___  ____    _    ____       ____  _____ ____          _   _   _ _____ ___  ____  ____  
   / \  / ___| / _ \/ ___|  / \  |  _ \     |  _ \| ____| __ )        / \ | | | |_   _/ _ \|  _ \|  _ \ 
  / _ \ \___ \| | | \___ \ / _ \ | |_) |____| | | |  _| |  _ \ _____ / _ \| | | | | || | | | |_) | |_) |
 / ___ \ ___) | |_| |___) / ___ \|  _ <_____| |_| | |___| |_) |_____/ ___ \ |_| | | || |_| |  _ <|  _ < 
/_/   \_\____/ \___/|____/_/   \_\_| \_\    |____/|_____|____/     /_/   \_\___/  |_| \___/|_| \_\_| \_\
```

# asosar-deb-autorr

Interactive Debian installer for a movie automation stack:

- Radarr
- Prowlarr
- qBittorrent nox
- Plex Media Server or Jellyfin Server

## Run On Debian

Log in as `root`, then run:

```bash
apt update
apt install -y curl
curl -fsSL https://raw.githubusercontent.com/alsosar/asosar-deb-autorr/main/install.sh -o install.sh
bash install.sh
```

If `sudo` is already configured, you can run it directly:

```bash
curl -fsSL https://raw.githubusercontent.com/alsosar/asosar-deb-autorr/main/install.sh | sudo bash
```

## What The Script Does

1. Installs base dependencies: `ca-certificates`, `curl`, `gnupg`, `lsb-release`, `libsqlite3-0`, `sqlite3`, and `wget`.
2. Downloads the official Servarr community installer.
3. Automatically installs Prowlarr.
4. Automatically installs Radarr.
5. Installs `qbittorrent-nox` and creates a systemd service for it.
6. Asks whether to install Plex Media Server, Jellyfin Server, or skip media server installation.

## Default Web Interfaces

- Radarr: `http://SERVER_IP:7878`
- Prowlarr: `http://SERVER_IP:9696`
- qBittorrent: `http://SERVER_IP:8080`
- Plex: `http://SERVER_IP:32400/web`
- Jellyfin: `http://SERVER_IP:8096`

## Notes

The Servarr installer creates the service users and installs Radarr/Prowlarr under `/opt`.

The qBittorrent service runs as user `qbittorrent` in group `media`.
