# containers/collector/Dockerfile
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV DB_PATH=/data/pods-poc.db

WORKDIR /app

# copy only requirements first for better cache behaviour
COPY requirements.txt /app/requirements.txt

# install system deps temporarily if needed for building wheels, then
# remove them in the same layer to keep the final image small
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && pip install --no-cache-dir --disable-pip-version-check -r /app/requirements.txt \
    && apt-get remove -y build-essential \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# copy the rest of the application
COPY . /app

# collector entrypoint
CMD ["python", "-u", "services/collector/collector.py"]
