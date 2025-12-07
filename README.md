# Pods-PoC


This GitHub repository uses `podman` to provide a small multi-container "pods" proof-of-concept. It runs four cooperating services sharing a host-mounted /data volume.
It is meant to be a proof-of-concept application to demonstrate the minimum requirements use-case for an application that executes in `podman` containers.

Using Python scripts data is gathered and stored in an SQLite3 database. Other Python scripts generate a trendgraph from the data.
A (static) webpage that displays the trendgraph is served by `nginx` to clients on the server's local network.
- (re)start the container pods on (re)boot,
# Pods-PoC

This repository is a small multi-container proof-of-concept that runs four cooperating services in Podman containers. All services share a host-mounted `/data` volume. The services are intentionally simple:

- `collector` — writes simulated measurements into an SQLite DB.
- `trend` — reads recent measurements and renders a Matplotlib PNG to `/data`.
- `web` — serves the generated PNG over HTTP.
- `db_manager` / storage image — performs one-shot backup/pull/push operations (script-driven) using `rclone`.

The project provides both simple local scripts (run Python directly) and a Podman-based workflow (Makefile + Pod/containers). `rclone` is used to push/pull the SQLite DB to a remote (for example: Dropbox). By default the repository expects an `rclone.conf` to be supplied by mounting `~/.config/rclone` (or a single `rclone.conf`) into the storage container.

## Installation

Prerequisites:

- Podman (or Docker if you prefer; Makefile targets use `podman`).
- Make (for the provided `Makefile` targets).

On macOS you can install Podman via Homebrew:

```bash
brew install podman
podman machine init
podman machine start
```

On Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y podman make
```

On Arch Linux:

```bash
sudo pacman -Syu
sudo pacman -S --noconfirm podman make
```

Optionally install `rclone` on the host (only needed if you want to run `rclone config` or run pushes/pulls directly on the host):

```bash
sudo pacman -S --noconfirm rclone
```

If running on an Arch server you likely want Podman to be available system-wide. Enable the socket so services and tools can talk to Podman:

```bash
sudo systemctl enable --now podman.socket
```

For rootless usage on a multi-user system you may also need to enable lingering for the service account so user systemd units can run after logout:

```bash
sudo loginctl enable-linger $(whoami)
```

Note: the repository's `Makefile` contains an `install-deps` target that will attempt to detect your platform and install Podman (where supported). The `Makefile` intentionally does not install `rclone` on the host — `rclone` runs inside the `containers/storage` image and the container must be given a configured `rclone.conf` via a volume mount.

## Quick start (Podman + Makefile)

Build images (this calls `ensure-deps` first):

```bash
make build
```

Initial install (build + start pod). If you want the storage image to pull a DB from a remote on first start, pass `RCLONE_REMOTE` (example shows Dropbox remote name):

```bash
make install RCLONE_REMOTE=dropbox:pods-poc
```

Start (create pod if needed and start services):

```bash
make start RCLONE_REMOTE=dropbox:pods-poc
```

Perform a one-off DB pull using the storage image (you must provide `RCLONE_REMOTE`):

```bash
make pull-db RCLONE_REMOTE=dropbox:pods-poc
```

If you need guidance on how to provide `rclone.conf` to the storage container, run:

```bash
make rclone-config
```

Example manual `podman run` that mounts a host `rclone` config directory and performs a pull:

```bash
podman run --rm -v ~/.config/rclone:/config -v $(pwd)/data:/data -e RCLONE_REMOTE=dropbox:pods-poc pods-poc-storage:latest pull
```

## Running locally (without containers)

For local development you can run individual Python services directly (collector/trend/db_manager). The web front-end is served by the `containers/web` nginx image in normal operation; to preview the static page locally without containers, use a simple static HTTP server from the directory that contains `index.html` and a `data/` directory with a `plot.png`:

```bash
python -m http.server 8000 --directory containers/web
# then open http://localhost:8000 in your browser
```

When running in containers the Makefile maps host port `8000` → container port `80` so the site is available at `http://<host>:8000`.

## rclone / credentials

`rclone` is required inside the storage container image. The container expects to find credentials/config at `/config` (so mount your host `~/.config/rclone` or the single `rclone.conf` file into the container when running pull/push operations). Do **not** commit `rclone.conf` to source control.

## Systemd examples (optional)

There are example `systemd` service and timer units in `examples/systemd/` showing how to schedule periodic backup/push jobs using the storage image. These units expect the storage image and a mounted `rclone` config on the host.

## Where to look next

- `services/collector/collector.py` — DB schema and insert pattern.
- `services/trend/trend.py` — SQL query and Matplotlib plotting.
- `containers/web/index.html` — static front-end served by nginx; the generated plot is read from the mounted `/data/plot.png`.
- `services/db_manager/scripts/` — helper shell scripts used by the storage image.
- `config/app_settings.yaml` — canonical runtime defaults.

If you'd like, I can add a short `docs/` page with step-by-step screenshots or a script to bootstrap `rclone` configuration for testing.
