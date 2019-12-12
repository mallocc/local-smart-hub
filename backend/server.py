#!/usr/bin/python3

from flask import Flask, request, jsonify
from flask_cors import CORS
import time
import requests
import json
from threading import Timer


app = Flask(__name__, static_url_path='', static_folder='statics', template_folder='templates' )
CORS(app)

TIMEROUT_TIME = 1
NAME = "name"
STATUS = "status"
URL = "url"

devices = {}

def addDevice(ip, device):
	devices[ip] = device

def removeDevice(ip):
	del devices[ip]
 
def requestAlive(device):
	try:
		res = requests.get("http://" + device.ip + "/alive", timeout=TIMEROUT_TIME)
		data = res.json()
		if data["alive"] == "TRUE":
			device.restartAliveTimer()
	except (requests.Timeout, requests.ConnectionError, KeyError) as e:
		removeDevice(device.ip)

class Device:
	def __init__(self, ip, name):
		self.ip = ip
		self.name = name
		self.restartAliveTimer()
  
		self.onStatus = True

	def restartAliveTimer(self):
		self.timer = Timer(TIMEROUT_TIME, requestAlive, args=[self])
		self.timer.start()
  
	def setOnStatus(self, status):
		self.onStatus = status
  
	def getJson(self):
		data = {}
		data[NAME] = self.name
		data[STATUS] = "ON" if self.onStatus else "OFF" 
		data[URL] = "/" + self.name
		return data		

	def commandOnStatus(self):
		res = requests.get("http://" + self.ip + "/")
		data = res.json() 
		if data['onState'] == "ON":
			self.onStatus = True
		else:
			self.onStatus = False
  
def getJson():
	deviceList = []
	for key, value in devices.items():
		deviceList.append(value.getJson())
	data = {}
	data["devices"] = deviceList
	return jsonify(data)

@app.route("/connect",  methods=('GET', 'POST'))
def espConnect():
    jsonstring = request.args.get('id')
    unjson = json.loads(jsonstring)
    addDevice(str(request.remote_addr), Device(str(request.remote_addr), unjson["name"]))
    return ("connected", 200)


@app.route('/esp', methods=['GET'])
def getOnStatus():
	devices["192.168.150.3"].commandOnStatus()
	return getJson()


@app.route('/refresh', methods=['GET'])
def getRefresh():
	return getJson()

@app.route('/', methods=['GET'])
def index():
	return app.send_static_file('index.html')

if __name__ == '__main__':
	app.run(debug=True, port=8000, host='0.0.0.0')
	
