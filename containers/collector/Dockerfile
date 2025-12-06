# containers/collector/Dockerfile
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV DB_PATH=/data/pods-poc.db

WORKDIR /app

# system deps (minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# copy project
COPY . /app

# install only runtime deps (expects requirements.txt at repo root)
RUN pip install --no-cache-dir -r /app/requirements.txt

# collector entrypoint
CMD ["python", "-u", "services/collector/collector.py"]
