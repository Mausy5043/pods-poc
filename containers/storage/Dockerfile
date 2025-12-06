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
    rsync \
    && pip install --no-cache-dir --disable-pip-version-check -r /app/requirements.txt \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

CMD ["python", "-u", "services/db_manager/db_manager.py"]
