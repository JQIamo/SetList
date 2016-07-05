import struct # Needed for pack
import math   # Needed for .isnan()
import json   # Needed for formatting our commands
import socket # Needed for TCP comms
import http.client # Needed to extract correct port

def getPort(setlistIP):
	"""Use LABVIEW service finder to get the correct port number"""
	niServiceLocator = http.client.HTTPConnection(setlistIP, port=3580, timeout=1)
	niServiceLocator.request("GET",'/SetList/JSON')
	niResponse = niServiceLocator.getresponse()
	
	# If successful, expect the response body to be "Port=<port number>\r"
	# Otherwise, it will be some (probably informative) trash, but we'll catch
	# that with by checking the response code.
	respStr = niResponse.read().decode()
	[key, port] = respStr.strip().split('=')
	niServiceLocator.close()
	
	# 200 is the response for everything being okay.
	if ((niResponse.status == 200) and ('Port' == key)):
		return int(port)
	
	# If we're here, something went wrong.  This is a demo script, so I won't bother
	# gracefully handling it.  You, dear user, should consider doing so.
	raise RuntimeError('Could not retrieve port number for JSON interface.')

def setListVariable(name, defaultValue=None, sequenceFunction = None, informIgor = None, sequence = None):
	"""Construct the appropriate dictionary with default values corresponding to not changing what is in SetList"""
	return {"name":name, "defaultValue":defaultValue, "sequenceFunction":sequenceFunction, "informIgor":informIgor, "sequence":sequence}

def setListInstantSet(variableArray):
	"""Takes an array formed from setListVariable(s) and sets it up for feedback communication"""
	if (len(variableArray) > 0):
		return {"instantVariables":variableArray}
	return {}

def setListSeqSet(arrayOfVariableArrays):
	if (len(arrayOfVariableArrays) > 0):
		return {"sequenceSets":arrayOfVariableArrays}
	return {}

def setListMulligan(mulliganArray):
	if (len(mulliganArray) > 0):
		mulliganArray = [int(i) for i in mulliganArray]
		return {"mulligan":mulliganArray}
	return {}
	
def setListAssembleCommand(mulliganDict={}, instantDict={}, sequenceArrayDict={}):
	commandDict = mulliganDict.copy()
	commandDict.update(instantDict)
	commandDict.update(sequenceArrayDict)
	return json.dumps(commandDict, separators=(',', ':'))

def packCommand(commandString):
        cmdLength=len(commandString)
        formatString=">i" + str(cmdLength) + "s"
        print(formatString)
        print(struct.pack(formatString, cmdLength, commandString.encode()))
        return struct.pack(formatString, cmdLength, commandString.encode())

def sendCommand(setlistIP, commandString, setlistPort=None):
	"""Sends a cmd over TCP after creating a connection, then reads respNum responses of size respSize bytes"""
	
	# Lookup port if we don't have it
	if (setlistPort is None):
		setlistPort = getPort(setlistIP)
	
	sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	sock.connect((setlistIP, setlistPort))
	sock.send(packCommand(commandString))
	# Four bytes for an int for total message length
	response = sock.recv(4)
	print(response)
	responseLength = struct.unpack(">i", response)[0]
	print(responseLength)
	# Load and stringify the message
	response = sock.recv(responseLength).decode()
	sock.close()
	return response
