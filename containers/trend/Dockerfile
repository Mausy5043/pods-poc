# containers/trend/Dockerfile
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV DB_PATH=/data/pods-poc.db
ENV PLOT_PATH=/data/plot.png
ENV MPLBACKEND=Agg

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt /app/requirements.txt

# Install system deps temporarily to build matplotlib wheels, then remove them
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libfreetype6-dev \
    libpng-dev \
    && pip install --no-cache-dir --disable-pip-version-check -r /app/requirements.txt \
    && apt-get remove -y build-essential \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

CMD ["python", "-u", "services/trend/trend.py"]
