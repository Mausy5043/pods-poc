# containers/trend/Dockerfile
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV DB_PATH=/data/lektrix.db
ENV PLOT_PATH=/data/plot.png
ENV MPLBACKEND=Agg

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libfreetype6-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

RUN pip install --no-cache-dir -r /app/requirements.txt

CMD ["python", "-u", "src/trend/trend.py"]


