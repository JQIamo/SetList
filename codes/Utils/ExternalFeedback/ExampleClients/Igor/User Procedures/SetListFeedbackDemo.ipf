#pragma rtGlobals = 3		// Use modern global access method and strict wave access.
#pragma version = 2.0		// First try
#pragma IgorVersion = 6.0 // Require Igor Version 6.0 at the oldest

// Change this to whichever computer you've got SetList on
	StrConstant	kSetListIP	= "127.0.0.1"

MACRO	DemoSetListTCP()
	SetListCreateFeedback()
	SetListAddVariable("Igor_JustName")
	SetListAddVariable("Igor_DV", defaultValue=3.14)
	SetListAddVariable("Igor_SF", sequenceFunction="i/4")
	SetListAddVariable("Igor_SeqOn",sequenceFunction="i/4", sequence=1)
	SetListAddVariable("Igor_SeqOff",sequenceFunction="i/4", sequence=0)
	SetListAddVariable("Igor_IIOn",informIgor=1)
	SetListAddVariable("Igor_IIOff",informIgor=0)
	
	SetListVarCmds()
	Print SetListBuildForNow()
	SetListSendCmd(kSetListIP,"{" + SetListBuildForNow() + "}")
END

MACRO	DemoSetListMulligan(filenumber)
	Variable filenumber
	
	SetListSendCmd(kSetListIP,"{" + SetListBuildMulligan(filenumber) + "}")
END