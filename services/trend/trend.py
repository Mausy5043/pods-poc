#!/usr/bin/env python3

"""Generate a trend plot from measurements in the shared SQLite DB."""

from __future__ import annotations

import os
import sqlite3
import time
from datetime import datetime

import matplotlib.dates as mdates
import matplotlib.pyplot as plt

DB_PATH = os.getenv("DB_PATH", "/data/pods-poc.db")
PLOT_PATH = os.getenv("PLOT_PATH", "/data/plot.png")


def generate_plot() -> None:
    """Query the last hour of measurements and write a PNG to PLOT_PATH.

    The plotting converts datetime objects to matplotlib date numbers to
    satisfy matplotlib typing expectations.
    """
    cutoff = int(time.time()) - 3600
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("SELECT ts, value FROM measurements WHERE ts >= ? ORDER BY ts ASC", (cutoff,))
    rows = cur.fetchall()
    conn.close()

    if not rows:
        print("[trend] No data for last hour.")
        return

    timestamps = [datetime.fromtimestamp(r[0]) for r in rows]
    values = [r[1] for r in rows]

    # Convert to matplotlib's internal float date format to satisfy typing.
    x = mdates.date2num(timestamps)

    plt.figure(figsize=(10, 4))
    plt.plot(x, values)
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter("%H:%M"))
    plt.title("Last Hour Measurements")
    plt.xlabel("Time")
    plt.ylabel("Value")
    plt.tight_layout()
    plt.savefig(PLOT_PATH)
    plt.close()

    print(f"[trend] Plot updated at {datetime.now()}")


def main() -> None:
    """Main loop: regenerate the plot every 60 seconds."""
    while True:
        generate_plot()
        time.sleep(60)


if __name__ == "__main__":
    main()
