This repository is a small multi-container "pods" proof-of-concept that runs four cooperating services sharing a host-mounted /data volume.

Key facts an AI code assistant should know to be productive here:

- Architecture: four lightweight services live in `services/` and are containerized under `containers/`.
  - `services/collector/collector.py` — writes randomized measurements into a SQLite DB.
  - `services/trend/trend.py` — reads recent measurements, renders a Matplotlib plot to disk.
  - `services/web/server.py` — simple Flask app that serves the generated plot.
  - `services/db_manager/db_manager.py` — periodically copies the SQLite DB to `BACKUP_DIR`.
  - `pod/pod.yaml` and `docker-compose.yml` show how containers are wired and share `/data`.

- Shared data model and integration pattern:
  - All services use a shared SQLite file (DB_PATH, default `/data/pods-poc.db`).
  - Plot and backups are written to the shared `/data` volume (paths configured in `config/app_settings.yaml`).
  - Communication is filesystem-based: one service writes data (collector), another reads it (trend), and web serves the generated artifact. There is no network RPC between services in this POC.

- Environment variables and important config locations
  - `DB_PATH` — SQLite database path (default `/data/pods-poc.db`).
  - `PLOT_PATH` / `PLOT_FILE` / `PLOT_OUTPUT_PATH` — where `trend` writes the PNG and `web` reads it.
  - `BACKUP_DIR`, `BACKUP_INTERVAL` — used by `db_manager` for backups.
  - `config/app_settings.yaml` contains the canonical defaults; runtime containers may override via env vars.

- Developer workflows (how to run & debug locally)
  - Fast local: run services directly from their `services/...` scripts. Example to run web:
    - `python services/web/server.py` (expects plot at `PLOT_PATH`).
  - Containerized: `docker-compose up --build` uses `docker-compose.yml` and container Dockerfiles under `containers/`.
  - Kubernetes-style: `pod/pod.yaml` demonstrates a single Pod running all containers.

- Patterns and conventions to follow when changing code
  - Keep services single-responsibility: collector writes measurements, trend reads/plots, web serves, db_manager backs up.
  - Filesystem-based integration — prefer writing to the shared `/data` volume rather than adding network calls unless intentionally evolving the architecture.
  - Use environment variables for runtime paths and timing. New services should read defaults from `config/app_settings.yaml` and allow overriding via env vars.

- Tests / Lint / Build notes discovered
  - There are no automated tests or lint config in the repo. Keep changes minimal and run scripts directly. After edits, run the target script to validate basic behavior (e.g., `python services/trend/trend.py` to confirm plotting runs).

- Files to reference when making changes
  - `services/collector/collector.py` — DB schema (measurements table) and insert pattern.
  - `services/trend/trend.py` — SQL query for last hour: `WHERE ts >= ?` and Matplotlib usage.
  - `services/web/server.py` — Flask routes and how plot is served (returns 404 when missing).
  - `services/db_manager/db_manager.py` — backup naming convention `pods-poc_<timestamp>.db`.
  - `config/app_settings.yaml`, `docker-compose.yml`, `pod/pod.yaml` — runtime wiring examples.

- When opening PRs
  - Document why a change alters cross-service behavior (e.g., DB schema changes, different file paths, or backup timing). Mention how you validated changes locally (which services you ran and sample output).

- Agent edit policy
  - Agents are allowed to make inline, minimal edits to repository files when explicitly requested by a human. Keep changes small, follow existing patterns, and run quick local checks (run the modified script or read it) when feasible. Document edits in the commit message or PR description and prefer non-destructive changes (do not delete unrelated code).
  - Edits that cause an executable to require root-access or modify infrastructure configs (like Dockerfiles or pod specs) need explicit human approval before proceeding.
  - After each edit review and update the `copilot-instructions.md` file to ensure the new changes are accurately reflected in these instructions.
