#pragma rtGlobals = 3		// Use modern global access method and strict wave access.
#pragma version = 1.0		// First try
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
	
	cmdString = "SS" +  SetListI32String(numVars)
	Make /O/T/N=(numVars+1) commands
	Make /O/T=7/N=(numVars+1) responses
	
	commands[0] = cmdString
	
	// Break Double into bytes, temporarily
	Redimension /U/B/E=1 /N=(8,numVars) wDefVal
	
	Variable i
	FOR (i=0; i<numVars; i=i+1)
		cmdString = "DV" + num2char(wFlags[i]) + SetListPackString(wNames[i])
		Variable j
		IF (noSwap != 0)
			FOR(j=0; j<8; j=j+1)
				cmdString = cmdString + num2char(wDefVal[j][i])
			ENDFOR
		ELSE
			FOR(j=7; j>-1; j=j-1)
				cmdString = cmdString + num2char(wDefVal[j][i])
			ENDFOR
		ENDIF
		cmdString = cmdString + SetListPackString(wSeqFun[i])
		commands[i+1] = cmdString
	ENDFOR
	
	// Return Double to Double form
	Redimension /D/E=1 /N=(numVars) wDefVal
	
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

FUNCTION SetListSendCmds(IP, PORT)
	String	IP
	Variable	PORT
	
	DFREF	sdfref = GetDataFolderDFR()
	SetDataFolder $kSetListDFPath
	Wave/T	wCmds	= :commands
	Wave/T	wResp	= :responses

	String resp

	Variable numCmds = numpnts(wCmds)
	Print "Changing ", numCmds-2, "variables via TCP"
	
	Variable sockNum = 0
	Make /T/O bufferWave
	SOCKITOpenConnection /Q/TIME=5 sockNum, IP, PORT, bufferwave
	Variable i
	FOR (i=0; i<numCmds; i = i+1 )
		IF ( SOCKITisitopen(sockNum) )
			SOCKITSendNRecv /TIME=30/NBYT=6 sockNum, wCmds[i], resp
			wResp[i] = SetListPrintStr(resp)
		ELSE
			wResp[i] = "No Connection"
		ENDIF
	ENDFOR
	
	SOCKITCloseConnection(sockNum)
	
	SetDataFolder sdfref
END

FUNCTION SetListBuildForNow([noSwap])
	Variable	noSwap
	DFREF	sdfref = GetDataFolderDFR()
	SetDataFolder $kSetListDFPath
	
	// noSwap Defaults to False
	IF (ParamIsDefault(noSwap))
		noSwap = 0
	ENDIF
	
	SetListVarCmds(noSwap=noSwap)
	
	Wave/T	wCmds	= :commands
	Wave/T	wResp	= :responses
	Redimension /N=(numpnts(wCmds)+1) wCmds
	Redimension /N=(numpnts(wResp)+1) wResp
	
	wCmds[numpnts(wCmds)-1] = "EN"
	
	SetDataFolder sdfref
END

FUNCTION SetListBuildForSeq([noSwap])
	Variable	noSwap
	DFREF	sdfref = GetDataFolderDFR()
	SetDataFolder $kSetListDFPath
	
	// noSwap Defaults to False
	IF (ParamIsDefault(noSwap))
		noSwap = 0
	ENDIF
	
	SetListVarCmds(noSwap=noSwap)
	
	Wave/T	wCmds	= :commands
	Wave/T	wResp	= :responses
	Redimension /N=(numpnts(wCmds)+1) wCmds
	Redimension /N=(numpnts(wResp)+1) wResp
	
	wCmds[numpnts(wCmds)-1] = "ES"
	
	SetDataFolder sdfref
END