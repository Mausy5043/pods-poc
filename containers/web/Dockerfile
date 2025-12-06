# containers/web/Dockerfile
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV PLOT_PATH=/data/plot.png

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

RUN pip install --no-cache-dir -r /app/requirements.txt

EXPOSE 8000

CMD ["python", "-u", "src/web/server.py"]

