#!/usr/bin/env python3

"""Simple Flask server that serves the trend plot image."""

from __future__ import annotations

import os

from flask import Flask, send_file

PLOT_PATH = os.getenv("PLOT_PATH", "/data/plot.png")

app = Flask(__name__)


@app.get("/")
def index() -> str:
    """Return a tiny HTML page that references the plot endpoint."""
    return """
    <html>
      <body>
        <h1>Trend Graph</h1>
        <img src="/plot" />
      </body>
    </html>
    """


@app.get("/plot")
def plot():
    """Return the generated plot image, or 404 if it doesn't exist yet."""
    if not os.path.exists(PLOT_PATH):
        return "Plot not yet generated", 404
    return send_file(PLOT_PATH, mimetype="image/png")


if __name__ == "__main__":
    # Keep default port consistent with docker container mapping.
    app.run(host="0.0.0.0", port=8000)
