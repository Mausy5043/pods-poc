import sqlite3
import time
from datetime import datetime
import matplotlib.pyplot as plt
import os

DB_PATH = os.getenv("DB_PATH", "/data/lektrix.db")
PLOT_PATH = os.getenv("PLOT_PATH", "/data/plot.png")

def generate_plot():
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

    plt.figure(figsize=(10, 4))
    plt.plot(timestamps, values)
    plt.title("Last Hour Measurements")
    plt.xlabel("Time")
    plt.ylabel("Value")
    plt.tight_layout()
    plt.savefig(PLOT_PATH)
    plt.close()

    print(f"[trend] Plot updated at {datetime.now()}")

def main():
    while True:
        generate_plot()
        time.sleep(60)

if __name__ == "__main__":
    main()

