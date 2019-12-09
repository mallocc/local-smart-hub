#!/usr/bin/python3

from flask import Flask, request, jsonify
from flask_cors import CORS
import time

app = Flask(__name__, static_url_path='', static_folder='statics', template_folder='templates' )
CORS(app)

lampStatus = True
serverStatus = True
tvStatus = True

def gs(state):
	return "ON" if state else "OFF"

def getJson():
	time.sleep(1)
	return jsonify({ "devices" : [ \
					{ "name": "lamp", "status": gs(lampStatus), "url": "/lamp" }, \
					{ "name": "server", "status": gs(serverStatus), "url": "/server" }, \
					{ "name": "tv", "status": gs(tvStatus), "url": "/tv" }, \
 				] })

@app.route('/', methods=['GET'])
def index():
	return app.send_static_file('index.html')

@app.route('/refresh', methods=['GET'])
def getRefresh():
	return getJson()

@app.route('/lamp', methods=['GET'])
def getLampStatus():
	global lampStatus
	lampStatus = not lampStatus
	return getJson()

@app.route('/server', methods=['GET'])
def getServerStatus():
	global serverStatus
	serverStatus = not serverStatus
	return getJson()

@app.route('/tv', methods=['GET'])
def getTvStatus():
	global tvStatus
	tvStatus = not tvStatus
	return getJson()

if __name__ == '__main__':
	app.run(debug=True, port=80, host='0.0.0.0')
