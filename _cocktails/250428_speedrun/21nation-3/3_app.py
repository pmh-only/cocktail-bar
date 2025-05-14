from flask import Flask

app = Flask(__name__)

@app.route("/healthcheck")
def healthcheck():
  return {
    'code': 200
  }

@app.route("/v1/mock")
def v1mock():
  return {
    'code': 200
  }

if __name__ == "__main__":
  app.run(host='0.0.0.0', port=8080)
