from flask import Flask, jsonify
from threading import Thread
from energyconvert import data_processing_thread, latest_results

app = Flask(__name__)

@app.route("/latest-data", methods=["GET"])
def get_latest_data():
    if latest_results["timestamp"] is None:
        return jsonify({"message": "No data available yet"}), 204
    return jsonify(latest_results), 200

if __name__ == "__main__":
    Thread(target=data_processing_thread, daemon=True).start()
    app.run(host='0.0.0.0', port=5000, debug=False)
