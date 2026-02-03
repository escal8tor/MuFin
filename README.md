# MuFin

An unofficial Jellyfin client for MuOS.

## Installation

1. Grab the [latest release](https://github.com/escal8tor/MuFin/releases).
3. Copy it to `/mnt/mmc/ARCHIVE`.
4. Install using **Archive Manager**.
5. Launch `MuFin` in the **Applications** menu.

## Setup

The client generates a configuration file on startup (at: `/mnt/mmc/MuOS/application/MuFin/config.ini`). By default, it's configured to authenticate to Jellyfin's own [demo instance](https://demo.jellyfin.org/stable/web/). To switch to your instance: 

```ini
[Host]
# Jellyfin server url. Requires protocol, host, and port.
base_url = <proto>://<ip_addr>:<port>

[Authentication]
# Auth. method (QuickConnect, or Basic). QC recommended.
method = QuickConnect

# Remove `token` if it exists.
```

You may also want to delete `MuFin/app/data/cache` (ensures all artwork is refreshed). Launch the client again, authenticate, and (hopefully) enjoy.

Also, a commented version is available at `MuFin/app/res/static/config.ini`. 
