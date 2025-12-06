# containers/web/Dockerfile
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV PLOT_PATH=/data/plot.png

WORKDIR /app

# Copy requirements first to maximize layer cache hits
COPY requirements.txt /app/requirements.txt

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && pip install --no-cache-dir --disable-pip-version-check -r /app/requirements.txt \
    && apt-get remove -y build-essential \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# copy app files
COPY . /app

EXPOSE 8000

CMD ["python", "-u", "services/web/server.py"]

# Lightweight healthcheck - verify the web server root returns 200.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD python -c "import sys,socket,urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/'); sys.exit(0)" || exit 1
