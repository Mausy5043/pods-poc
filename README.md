# Pods-PoC


This GitHub repository uses `podman` to provide a small multi-container "pods" proof-of-concept. It runs four cooperating services sharing a host-mounted /data volume.
It is meant to be a proof-of-concept application to demonstrate the minimum requirements use-case for an application that executes in `podman` containers.

Using Python scripts data is gathered and stored in an SQLite3 database. Other Python scripts generate a trendgraph from the data.
A (static) webpage that displays the trendgraph is served by `nginx` to clients on the server's local network.
The database is push to or pulled from a path on a remote (eg. Dropbox) file-server with `rclone` and using the credentials supplied by the local server's admin via the configuration file `~/.config/rclone.conf`.

During installation and on updates `systemd` services are provided to
- (re)start the container pods on (re)boot,
- periodically push the database to the remote service or
- pull the database in case it is not present (if the database is also not present remotely it is created using the specification file `config/pods-poc.sql`).

Fail-over of a container is signaled in the server journal. 
