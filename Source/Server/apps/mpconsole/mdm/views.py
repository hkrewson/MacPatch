from flask import render_template, session, request, current_app, redirect, url_for
from flask_security import login_required
from flask_cors import cross_origin
from sqlalchemy import text, or_, desc
from datetime import datetime

import sys
import json
import humanize
import base64
from operator import itemgetter
from collections import OrderedDict


from .  import mdm
from .. import db
from .. model import *
from .. modes import *
from .. mplogger import *
from .. mputil import *
from .. mptasks import MPTaskJobs


@mdm.route('/enrolledDevices')
@login_required
def enrolledDevices():
	_lastSyncAt = "None"
	columns = []
	try:
		_lastSync = MDMIntuneLastSync.query.filter( MDMIntuneLastSync.tableName == MDMIntuneDevices.__tablename__ ).order_by(desc(MDMIntuneLastSync.lastSyncDateTime)).first()
		if _lastSync is not None:
			_lastSyncAt = _lastSync.lastSyncDateTime

		listCols = MDMIntuneDevices.__table__.columns
	except:
		_lastSyncAt = "Error"

	return render_template('mdm/enrolled_devices.html', data=[], columns=listCols, lastSync=_lastSyncAt)

''' AJAX Request '''
@mdm.route('/enrolledDevices/list',methods=['GET'])
#@login_required
#@cross_origin()
def enrolledDevicesList():
	cols = []
	listCols = MDMIntuneDevices.__table__.columns
	devices = MDMIntuneDevices.query.all()

	for c in listCols:
		if c.info:
			cols.append(c.name)

	_results = []
	for r in devices:
		_dict = r.asDict
		_row = {}
		for col in cols:
			if col in _dict:
				if col == 'totalStorageSpaceInBytes' or col == 'freeStorageSpaceInBytes':
					_row[col] = humanize.naturalsize(_dict[col])
				else:
					_val = None
					if _dict[col] == 0:
						_val = "False"
					elif _dict[col] == 1:
						_val = "True"
					else:
						_val = _dict[col]

					_row[col] = _val
		_results.append(OrderedDict(sorted(_row.items())) )

	return json.dumps({'data': _results}, default=json_serial), 200

@mdm.route('/corporateDevices')
@login_required
def corporateDevices():
	_lastSyncAt = "None"
	columns = []
	try:
		_lastSync = MDMIntuneLastSync.query.filter( MDMIntuneLastSync.tableName == 'mdm_intune_corporate_devices' ).order_by(desc(MDMIntuneLastSync.lastSyncDateTime)).first()
		if _lastSync is not None:
			_lastSyncAt = _lastSync.lastSyncDateTime

		schemaColumns = current_app.config["MDM_SCHEMA"]["tables"]["mdm_intune_corporate_devices"]["columns"]
		columns = sorted(schemaColumns, key = lambda i: i['order'])

	except:
		_lastSyncAt = "Error"

	return render_template('mdm/corporate_devices.html', data=[], columns=columns, lastSync=_lastSyncAt)

''' AJAX Request '''
@mdm.route('/corporateDevices/list',methods=['GET'])
@login_required
@cross_origin()
def corporateDevicesList():
	cols = []
	listCols = MDMIntuneCorporateDevices.__table__.columns
	devices = MDMIntuneCorporateDevices.query.all()

	for c in listCols:
		cols.append(c.name)

	_results = []
	for r in devices:
		_dict = r.asDict
		_row = {}
		for col in cols:
			if col in _dict:
				_row[col] = _dict[col]

		_results.append(OrderedDict(sorted(_row.items())) )

	return json.dumps({'data': _results}, default=json_serial), 200

@mdm.route('/corporateDevice/add',methods=['GET','POST'])
@login_required
def corporateDeviceAdd():
	if request.method == 'POST':
		_form = request.form
		mpTask = MPTaskJobs()
		mpTask.init_app(current_app)
		res = mpTask.AddCorporateDevice(_form['importedDeviceIdentifier'],_form['description'])
		return json.dumps({}, default=json_serial), 200

	else:
		schemaColumns = current_app.config["MDM_SCHEMA"]["tables"]["mdm_intune_corporate_devices"]["columns"]
		columns = sorted(schemaColumns, key = lambda i: i['order'])

		return render_template('mdm/corporate_devices_add.html', columns=columns)

@mdm.route('/corporateDevice/search',methods=['POST'])
@login_required
def corporateDeviceSearch():

	_plain = []
	_dev = request.form['device'] + '%'
	client = MpClient.query.filter( or_( MpClient.computername.like(_dev) ) ).all()
	if client is not None and len(client) >= 1:
		for row in client:
			_plain.append(row.computername)

	return json.dumps({'options': _plain}, default=json_serial), 200

@mdm.route('/corporateDevice/search/host',methods=['POST'])
@login_required
def corporateDeviceSearchHost():
	_res = {}
	_dev = request.form['device']
	client = MpClient.query.filter(MpClient.computername == _dev).first()
	if client is not None:
			_res = {'cuuid':client.cuuid,'serialno':client.serialno}

	return json.dumps({'device': _res}, default=json_serial), 200

@mdm.route('/configProfiles')
@login_required
def configProfiles():
	_lastSyncAt = "None"
	columns = []
	try:
		_lastSync = MDMIntuneLastSync.query.filter( MDMIntuneLastSync.tableName == MDMIntuneConfigProfiles.__tablename__ ).order_by(desc(MDMIntuneLastSync.lastSyncDateTime)).first()
		if _lastSync is not None:
			_lastSyncAt = _lastSync.lastSyncDateTime

		schemaColumns = current_app.config["MDM_SCHEMA"]["tables"]["mdm_intune_devices_config_profiles"]["columns"]
		columns = sorted(schemaColumns, key = lambda i: i['order'])

	except:
		_lastSyncAt = "Error"

	return render_template('mdm/device_config_profiles.html', data=[], columns=columns, lastSync=_lastSyncAt)

''' AJAX Request '''
@mdm.route('/configProfiles/list',methods=['GET'])
@login_required
@cross_origin()
def configProfilesList():
	cols = []
	listCols = MDMIntuneConfigProfiles.__table__.columns
	devices = MDMIntuneConfigProfiles.query.all()

	for c in listCols:
		#if c.info:
		cols.append(c.name)

	_results = []
	for r in devices:
		_dict = r.asDictWithRID
		_row = {}
		for col in cols:
			if col in _dict:
				_row[col] = _dict[col]

		_results.append(OrderedDict(sorted(_row.items())) )

	return json.dumps({'data': _results}, default=json_serial), 200

@mdm.route('/configProfiles/payload/<string:id>',methods=['GET'])
@login_required
@cross_origin()
def deviceConfigProfilePayload(id):
	payload = None
	profile = MDMIntuneConfigProfiles.query.filter( MDMIntuneConfigProfiles.id == id ).first()
	if profile is not None:
		_profile = profile.asDict
		payload_b64 = _profile['payload']
		message_bytes = base64.b64decode(payload_b64)
		payload = message_bytes.decode()

	return render_template('mdm/device_config_profile_payload.html', payload=payload)

@mdm.route('/runSync/<string:id>',methods=['GET'])
@login_required
@cross_origin()
def runIntuneDataSync(id):
	_lastSyncAt = "Error getting sync data."
	tasks = MPTaskJobs()
	tasks.init_app(current_app,session['user'])
	try:
		if id == "corporateDevices":
			tasks.GetCorpDevices()
			_lastSync = MDMIntuneLastSync.query.filter( MDMIntuneLastSync.tableName == 'mdm_intune_corporate_devices' ).order_by(desc(MDMIntuneLastSync.lastSyncDateTime)).first()
		elif id == "enrolledDevices":
			tasks.GetEnrolledDevices()
			_lastSync = MDMIntuneLastSync.query.filter( MDMIntuneLastSync.tableName == MDMIntuneDevices.__tablename__ ).order_by(desc(MDMIntuneLastSync.lastSyncDateTime)).first()
		elif id == "deviceProfiles":
			tasks.GetDeviceConfigProfiles()
			_lastSync = MDMIntuneLastSync.query.filter( MDMIntuneLastSync.tableName == MDMIntuneConfigProfiles.__tablename__ ).order_by(desc(MDMIntuneLastSync.lastSyncDateTime)).first()

		if _lastSync is not None:
			_lastSyncAt = _lastSync.lastSyncDateTime

		return json.dumps({'lastSync': _lastSyncAt}, default=json_serial), 200
	except Exception as e:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		message=str(e.args[0]).encode("utf-8")
		log_Error('[runIntuneDataSync][Exception][Line: {}] Message: {}'.format(exc_tb.tb_lineno, message))
		return json.dumps({'lastSync': _lastSyncAt}, default=json_serial), 401

