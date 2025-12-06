from flask import Flask, send_file
import os

PLOT_PATH = os.getenv("PLOT_PATH", "/data/plot.png")

app = Flask(__name__)

@app.get("/")
def index():
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
    if not os.path.exists(PLOT_PATH):
        return "Plot not yet generated", 404
    return send_file(PLOT_PATH, mimetype="image/png")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)

