#pragma rtGlobals = 3		// Use modern global access method and strict wave access.
#pragma version = 2.0		// First try
#pragma IgorVersion = 6.0 // Require Igor Version 6.0 at the oldest

// Location of the SetListFB Data Folder
	StrConstant kSetListDFPath = root:SetListFB

	// Bit position of change flags
	Constant kFCsf	= 1
	Constant kFCdv	= 2
	Constant kFCs	= 4
	Constant kFCi	= 8
	Constant kFS	= 16
	Constant kFI		= 32
	Constant kFF	= 128

Function SetListCreateFeedback()
	DFREF sdfref = GetDataFolderDFR()
	NewDataFolder /O/S $kSetListDFPath	// Make sure SetListFB exists
	Make /D/O/N=0		defaultValues
	Make /T/O/N=0		names, sequenceFunction
	Make /U/B/O/N=0	flags
	SetDataFolder sdfref
END

Function SetListClearFeedback()
	DFREF sdfref = GetDataFolderDFR()
	SetDataFolder $kSetListDFPath
	WAVE /D defaultValues = defaultValues
	Redimension /N=0 defaultValues
	WAVE /T names = names
	Redimension /N=0 names
	WAVE /T sequenceFunction = sequenceFunction
	Redimension /N=0 sequenceFunction
	WAVE /U/B flags = flags
	Redimension /N=0 flags
	SetDataFolder sdfref
END

Function SetListAddVariable(name, [defaultValue, sequenceFunction, sequence, informIgor])
	String	name, sequenceFunction
	Variable	defaultValue, sequence, informIgor

	DFREF sdfref = GetDataFolderDFR()
	SetDataFolder $kSetListDFPath
	
	Variable changeFlags = 0
	// Assign names and default flags as needed
	IF (ParamIsDefault(defaultValue))
		defaultValue = 0.0
	ELSE
		changeFlags = changeFlags | kFCdv
	ENDIF
	
	IF (ParamIsDefault(sequenceFunction))
		sequenceFunction = ""
	ELSE
		changeFlags = changeFlags | kFCsf
	ENDIF
	
	IF (! ParamIsDefault(sequence))
		changeFlags = changeFlags | kFCs
		IF (sequence != 0)
			changeFlags = changeFlags | kFS
		ENDIF
	ENDIF
	
	IF (! ParamIsDefault(informIgor))
		changeFlags = changeFlags | kFCi
		IF (informIgor != 0)
			changeFlags = changeFlags | kFI
		ENDIF
	ENDIF
	// Done handling defaults
	
	// Set up our access to the SetListFB waves
	WAVE		wDefVal		= :defaultValues
	WAVE/T		wSeqFun	= :sequenceFunction
	WAVE/T		wNames		= :names
	WAVE		wFlags		= :flags
	
	// Store this at the beginning of the list
	InsertPoints 0, 1, wDefVal, wSeqFun, wNames, wFlags
	wDefVal[0]	= defaultValue
	wSeqFun[0]	= sequenceFunction
	wNames[0]	= name
	wFlags[0]	= changeFlags
	
	// Switch back to the folder we expect
	SetDataFolder sdfref
END

FUNCTION/S SetListVarCmds([noSwap])
	Variable	noSwap
	DFREF	sdfref = GetDataFolderDFR()
	SetDataFolder $kSetListDFPath
	
	// noSwap Defaults to False
	IF (ParamIsDefault(noSwap))
		noSwap = 0
	ENDIF
	
	String cmdString
	
	// Set up our access to the SetListFB waves
	WAVE		wDefVal		= :defaultValues
	WAVE/T		wSeqFun	= :sequenceFunction
	WAVE/T		wNames		= :names
	WAVE		wFlags		= :flags
	
	Variable numVars = numpnts(wFlags)
	
	Make /O/T/N=(numVars) commands
	
	Variable i
	FOR (i=0; i<numVars; i=i+1)
		cmdString = "{\"name\":\"" + wNames[i] + "\""
		
		cmdString = cmdString + ",\"defaultValue\":"
		IF ((wFlags[i] & kFCdv) != 0)
			cmdString = cmdString + num2str(wDefVal[i])
		ELSE
			cmdString = cmdString + "null"
		ENDIF

		cmdString = cmdString + ",\"sequenceFunction\":"
		IF ((wFlags[i] & kFCsf) != 0)
			cmdString = cmdString +"\"" + wSeqFun[i] +"\""
		ELSE
			cmdString = cmdString + "null"
		ENDIF

		cmdString = cmdString + ",\"sequence\":"
		IF ((wFlags[i] & kFCs) != 0)
			IF ((wFlags[i] & kFS) != 0)
				cmdString = cmdString + "true"
			ELSE
				cmdString = cmdString + "false"
			ENDIF
		ELSE
			cmdString = cmdString + "null"
		ENDIF

		cmdString = cmdString + ",\"informIgor\":"
		IF ((wFlags[i] & kFCi) != 0)
			IF ((wFlags[i] & kFI) != 0)
				cmdString = cmdString + "true"
			ELSE
				cmdString = cmdString + "false"
			ENDIF
		ELSE
			cmdString = cmdString + "null"
		ENDIF
		cmdString = cmdString + "}"
		commands[i] = cmdString
	ENDFOR

	SetDataFolder sdfref
	Return cmdString
END

FUNCTION/S SetListPackString(str)
	String str
	Variable val = strlen(str)
	
	String packedString = SetListI32String(val) + str
	
	Return  packedString
END

FUNCTION/S SetListI32String(num)
	Variable num
	
	String packedString = num2char((num & 0xFF000000) / 0x01000000)
	
	packedString =  packedString + num2char((num & 0x00FF0000) / 0x00010000)
	packedString =  packedString + num2char((num & 0x0000FF00) / 0x00000100)
	packedString =  packedString + num2char((num & 0x000000FF))
	
	Return packedString
END

FUNCTION/S SetListPrintStr(str)
	String str
	
	Variable len = strlen(str)
	Variable i
	String noNulls = ""
	FOR (i=0; i<len; i=i+1)
		Variable charNum = char2num(str[i])
		IF (charNum < 32 || charNum > 126)
			String code
			sprintf code, "%o", charNum
			noNulls = noNulls + "(0" + code + ")"
		ELSE
			noNulls = noNulls + str[i]
		ENDIF
	ENDFOR
	
	RETURN noNulls
END

FUNCTION SetListSendCmd(IP, COMMAND, [PORT])
	String	IP, COMMAND
	Variable	PORT
	
	DFREF	sdfref = GetDataFolderDFR()
	SetDataFolder $kSetListDFPath

	String/G resp
	String sendCmd = SetListPackString(COMMAND)
	
	IF(ParamIsDefault(PORT))
		PORT = SetListGetPortCmds(IP)
	ENDIF

	Print "Contact SetList at " + IP + ":" + num2str(PORT)

	Variable sockNum = 0
	Make /T/O bufferWave
	SOCKITOpenConnection /Q/TIME=5 sockNum, IP, PORT, bufferwave
	IF ( SOCKITisitopen(sockNum) )
		SOCKITSendNRecv /TIME=5 sockNum, sendCmd, resp
		resp = SetListPrintStr(resp)
	ELSE
		resp = "No Connection"
	ENDIF
	Print resp
	SOCKITCloseConnection(sockNum)
	
	SetDataFolder sdfref
END

FUNCTION SetListGetPortCmds(IP)
	String	IP
	
	return NumberByKey("Port", FetchURL("http://"+IP+":3580/SetList/JSON"), "=")
END

FUNCTION/S SetListBuildForNow([noSwap])
	Variable	noSwap
	DFREF	sdfref = GetDataFolderDFR()
	SetDataFolder $kSetListDFPath
	
	// noSwap Defaults to False
	IF (ParamIsDefault(noSwap))
		noSwap = 0
	ENDIF
	
	SetListVarCmds(noSwap=noSwap)
	
	Wave/T	wCmds	= :commands
	Variable varCount = numpnts(wCmds)
	
	String cmdString = "\"instantVariables\":[" + wCmds[0]
	
	Variable i
	FOR(i=1; i<varCount; i+=1)
		cmdString = cmdString + "," + wCmds[i]
	ENDFOR
	cmdString = cmdString + "]"
	
	SetDataFolder sdfref
	return cmdString
END

FUNCTION/S SetListBuildForSeq([noSwap])
	Variable	noSwap
	DFREF	sdfref = GetDataFolderDFR()
	SetDataFolder $kSetListDFPath
	
	// noSwap Defaults to False
	IF (ParamIsDefault(noSwap))
		noSwap = 0
	ENDIF
	
	SetListVarCmds(noSwap=noSwap)
	
	Wave/T	wCmds	= :commands
	Variable varCount = numpnts(wCmds)
	
	String cmdString = "\"sequenceSets\":[[" + wCmds[0]
	
	Variable i
	FOR(i=1; i<varCount; i+=1)
		cmdString = cmdString + "," + wCmds[i]
	ENDFOR
	cmdString = cmdString + "]]"
	
	SetDataFolder sdfref
	return cmdString
END

FUNCTION/S SetListBuildMulligan(Mulligan)
	Variable Mulligan
	String cmdString = "\"mulligan\":[" + num2str(Mulligan) + "]"
	return cmdString
END
