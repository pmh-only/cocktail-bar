from flask import Flask, request
from threading import Thread
from multiprocessing import Pool
from multiprocessing import cpu_count
import time
import os
import boto3
import mysql.connector
import json
import random

client = boto3.client('secretsmanager', region_name=os.environ['AWS_REGION'])
response = client.get_secret_value(
    SecretId=os.environ['SECRET_NAME'],
)

secret = json.loads(response['SecretString'])

mydb = mysql.connector.connect(
    host=secret['host'],
    user=secret['username'],
    password=secret['password'],
    database="unicorn",
    port=int(secret['port'])
)

app = Flask(__name__)

def f(x):
    timeout = time.time() + 30
    while True:
        if time.time() > timeout:
            break
        x*x

@app.route("/health")
def health():
	return { 'success': True }

@app.route("/cost",  methods=['POST'])
def main():
    def do_work(mydb, x, y):
        processes = cpu_count()
        pool = Pool(processes)
        pool.map(f, range(processes))

        mydb.reconnect()
        mycursor = mydb.cursor()

        sql = "INSERT INTO cost (id, cost) VALUES (%s, %s)"
        val = (x, str(int(random.random()*100+1) * int(y) * 10000))
        mycursor.execute(sql, val)

        mydb.commit()

    thread = Thread(target=do_work, args=(mydb, request.json['id'], request.json['duration']))
    thread.start()

    return { 'success': True }

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False, threaded=True)
