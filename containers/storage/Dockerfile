# containers/storage/Dockerfile
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV DB_PATH=/data/pods-poc.db
ENV BACKUP_DIR=/data/backups
ENV BACKUP_INTERVAL=28800

WORKDIR /app

# Copy requirements first for better cache behaviour
COPY requirements.txt /app/requirements.txt

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    && \
    # install rclone from upstream release and then install python deps
    curl -fsSL https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip \
    && unzip /tmp/rclone.zip -d /tmp \
    && mv /tmp/rclone-*-linux-amd64/rclone /usr/local/bin/rclone \
    && chmod 755 /usr/local/bin/rclone \
    && rm -rf /tmp/rclone* \
    && pip install --no-cache-dir --disable-pip-version-check -r /app/requirements.txt \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

# install utility scripts and entrypoint
COPY services/db_manager/*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["help"]
