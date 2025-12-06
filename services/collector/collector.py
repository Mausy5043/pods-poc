import sqlite3
import time
import random
from datetime import datetime
import os

DB_PATH = os.getenv("DB_PATH", "/data/lektrix.db")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS measurements (
            ts INTEGER PRIMARY KEY,
            value REAL NOT NULL
        );
    """)
    conn.commit()
    conn.close()

def insert_measurement(value):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    ts = int(time.time())
    cur.execute("INSERT INTO measurements (ts, value) VALUES (?, ?)", (ts, value))
    conn.commit()
    conn.close()
    print(f"[collector] {datetime.fromtimestamp(ts)} value={value}")

def main():
    init_db()
    while True:
        value = random.uniform(0, 100)
        insert_measurement(value)
        time.sleep(10)

if __name__ == "__main__":
    main()

