#pragma rtGlobals = 3		// Use modern global access method and strict wave access.
#pragma version = 1.0		// First try
#pragma IgorVersion = 6.0 // Require Igor Version 6.0 at the oldest

// Change this to whichever computer you've got SetList on
	StrConstant	kSetListIP	= "127.0.0.1"
	// Default port in SetList is 55928
	Constant	kSetListPort	= 55928
	// Default Mulligan port in SetList is 
	Constant	kSLMPort	= 50291

MACRO	DemoSetListTCP()
	SetListCreateFeedback()
	SetListAddVariable("Igor-JustName")
	SetListAddVariable("Igor-DV", defaultValue=3.14)
	SetListAddVariable("Igor-SF", sequenceFunction="i/4")
	SetListAddVariable("Igor-SeqOn",sequenceFunction="i/4", sequence=1)
	SetListAddVariable("Igor-SeqOff",sequenceFunction="i/4", sequence=0)
	SetListAddVariable("Igor-IIOn",informIgor=1)
	SetListAddVariable("Igor-IIOff",informIgor=0)
	
	SetListBuildForNow()
	SetListSendCmds(kSetListIP, kSetListPort)
END

MACRO	DemoSetListMulligan(filenumber)
	Variable filenumber
	
	SetListSendMulligan(kSetListIP,kSLMPort, filenumber)
END