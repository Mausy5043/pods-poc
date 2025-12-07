# Arch Linux: setup notes for pods-poc

This document contains recommended steps and notes for running pods-poc on an Arch Linux server.

1) Install prerequisites

Run:

sudo pacman -Syu
sudo pacman -S --noconfirm podman make rclone

2) Enable the Podman socket (recommended for system-wide usage)

Run:

sudo systemctl enable --now podman.socket

3) If you plan to run Podman rootless and want user units to survive logout, enable linger for your user:

Run:

sudo loginctl enable-linger $(whoami)

4) Configure rclone (interactive)

Run `rclone config` on a workstation or on the server to create `~/.config/rclone/rclone.conf`. Keep this file secure and do not commit it to source control.

5) Provide `rclone.conf` to the storage container

The storage image expects configuration in /config. When running the storage container mount your host config directory (recommended) or a single file. Examples:

# mount directory
podman run --rm -v ~/.config/rclone:/config -v /path/to/repo/data:/data -e RCLONE_REMOTE=dropbox:pods-poc pods-poc-storage:latest pull

# mount single file
podman run --rm -v ~/.config/rclone/rclone.conf:/config/rclone.conf -v /path/to/repo/data:/data -e RCLONE_REMOTE=dropbox:pods-poc pods-poc-storage:latest pull

6) Systemd notes

- If you use the example systemd units in `systemd/`, ensure they mount your rclone config into the container and that the ExecStart path to podman is correct for your system (usually /usr/bin/podman).
- On Arch the socket activation above is recommended so services can talk to Podman reliably.

7) Troubleshooting

- If `podman run` fails due to permissions when using rootless containers, try running the command as the same user who owns the `~/.config/rclone` and `data/` directories, or run the container as `root` (adjust the example systemd units accordingly).

If you'd like, I can add an Arch-specific example `systemd` unit that mounts `~/.config/rclone` and runs under `root` or under a dedicated service account.
