import struct # Needed for pack
import math   # Needed for .isnan()
import socket # Needed for TCP comms

def SetListMulligan(filenum):
	"""Send a Mulligan over TCP"""
	TCP_IP = '127.0.0.1'
	TCP_PORT = 50291
	
	sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	sock.connect((TCP_IP, TCP_PORT))
	sock.send(struct.pack('>i', filenum))
	sock.close()

class SetListVar:
	"""Individual variable for SetList"""
	def __init__(self, name, defaultValue=float('NaN'), sequenceFunction = float('NaN'), informIgor = float('NaN'), sequence = float('NaN')):
		self.name = name
		self.changeFlags = 0x00;
		
		if ( not math.isnan(defaultValue) ):
			self.changeFlags |= 0x02
			self.defaultValue = defaultValue
		else:
			self.defaultValue = 0.0
		
		if ( not math.isnan(sequenceFunction) ):
			self.changeFlags |= 0x01
			self.sequenceFunction = sequenceFunction
		else:
			self.sequenceFunction = ""
		
		if ( not math.isnan(informIgor) ):
			self.changeFlags |= 0x08
			self.informIgor = informIgor
		else:
			self.informIgor = False
		
		if ( not math.isnan(sequence) ):
			self.changeFlags |= 0x04
			self.sequence = sequence
		else:
			self.sequence = False

	def packString(self, toPack):
		"""Packs a string using prepended length"""
		formatString = '>i' + str(len(str(toPack))) + 's'
		return struct.pack(formatString, len(str(toPack)), str(toPack).encode('utf8'))
	
	def buildCmd(self):
		"""Handles the formatting of a variable command using the class info"""
		
		# Mark the Sequence and Inform Igor bits correctly
		if (self.sequence):
			self.changeFlags |= 0x10
		else:
			self.changeFlags &= ~0x10
			
		if (self.informIgor):
			self.changeFlags |= 0x20
		else:
			self.changeFlags &= ~0x20
		
		cmd = b'DV'
		cmd += struct.pack('>B', self.changeFlags)
		cmd += self.packString(self.name)
		cmd += struct.pack('>d', self.defaultValue)
		cmd += self.packString(self.sequenceFunction)
		return cmd
		

class SetListVarSet:
	"""Variable set for communication over TCP"""
	TCP_IP = '127.0.0.1'
	TCP_PORT = 55928
	
	def __init__(self, IP='127.0.0.1', PORT=55928):
		self.vars = []
		self.TCP_IP = IP
		self.TCP_PORT = PORT
	
	def clear(self):
		"""Empty the variable list for this set"""
		self.vars[:] = []
	
	def addVar(self, var):
		"""Adds a variable to the set"""
		self.vars.append(var)

	def __len__(self):
		"""Total number of variables in this set"""
		return len(self.vars)
	
	def buildForNow(self):
		"""Generate command byte stream for transmission over TCP, for immediate use"""
		return self._buildVarCmds() + b'EN'
		
	def buildForSeq(self):
		"""Generate command byte stream for transmission over TCP, for applying after the current sequence is over"""
		return self._buildVarCmds() + b'ES'
	
	def _buildVarCmds(self):
		"""Builds just the variable commands"""
		cmd = struct.pack('>2si', 'SS'.encode('utf8'), len(self))
		for var in self.vars:
			cmd += var.buildCmd()
		return cmd;
	
	def _sendCmd(self, cmd, respSize=1024, respNum=1):
		"""Sends a cmd over TCP after creating a connection, then reads respNum responses of size respSize bytes"""
		sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		sock.connect((self.TCP_IP, self.TCP_PORT))
		sock.send(cmd)
		response = b''
		for i in range(respNum):
			response += sock.recv(respSize)
		sock.close()
		return response
	
	def _prettyResponse(self, response):
		prettyform = ""
		while len(response) > 0:
			code = str(response[0:2])
			if code == 'OK':
				if response[2:4] == b'\0\0':
					data = 0
				else:
					data = str(response[2:4])
			elif code in ['TO', 'BC', 'NS']:
				data = str(response[2:4])
			else:
				data = struct.unpack('>i', str(response[2:6]))
			response = response[6:]
			prettyform += code + ': ' + str(data) + '\n'
		return prettyform
	
	def sendQuietlyForNow(self, pretty=False):
		"""Sends the command preceded by QU and LD commands, to suppress most responses"""
		cmd = b'QU'
		cmd += self.buildForNow()
		cmd += b'LD'
		
		resp = self._sendCmd(cmd, 6, 2)
		if pretty:
			resp = self._prettyResponse(resp)
		
		return resp
	
	def sendQuietlyForSeq(self, pretty=False):
		"""Sends the command preceded by QU and LD commands, to suppress most responses"""
		cmd = b'QU'
		cmd += self.buildForSeq()
		cmd += b'LD'
		
		resp = self._sendCmd(cmd, 6, 2)
		if pretty:
			resp = self._prettyResponse(resp)
		
		return resp
	
	def sendForNow(self, pretty=False):
		cmd = self.buildForNow()
		
		resp = self._sendCmd(cmd, 6, len(self) + 2)
		if pretty:
			resp = self._prettyResponse(resp)
		
		return resp
	
	def sendForSeq(self, pretty=False):
		cmd = self.buildForSeq()
		
		resp = self._sendCmd(cmd, 6, len(self) + 2)
		if pretty:
			resp = self._prettyResponse(resp)
		
		return resp
