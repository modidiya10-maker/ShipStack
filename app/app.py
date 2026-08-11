from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def home():
    return jsonify({
        "service": "ShipStack",
        "message": "Application is running"
    })


@app.route("/health")
def health():
    return jsonify({
        "status": "healthy"
    })


@app.route("/info")
def info():
    return jsonify({
        "service": "ShipStack",
        "version": "1.0.0",
        "environment": "development"
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)