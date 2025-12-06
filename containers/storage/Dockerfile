# containers/storage/Dockerfile
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV DB_PATH=/data/lektrix.db
ENV BACKUP_DIR=/data/backups
ENV BACKUP_INTERVAL=28800

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    rsync \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

RUN pip install --no-cache-dir -r /app/requirements.txt

CMD ["python", "-u", "src/db_manager/db_manager.py"]
