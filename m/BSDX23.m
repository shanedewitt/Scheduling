BSDX23	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ; 4/28/11 10:22am
	;;1.6T2;BSDX;;May 16, 2011
	; Licensed under LGPL
	;
	;
EVENT(BSDXEVENT,BSDXPARAM,BSDXSIP,BSDXSPT)	;EP
	;Raise event to interested clients
	;Clients are listed in ^BSDXTMP("EVENT",EVENT_NAME,IP,PORT)
	;BSDXSIP and BSDXSPT represent the sender's IP and PORT.  
	;The event will not be raised back to the sender if these are non-null
	;
	Q:'$D(^BSDXTMP("EVENT",BSDXEVENT))
	S BSDXIP=0 F  S BSDXIP=$O(^BSDXTMP("EVENT",BSDXEVENT,BSDXIP)) Q:BSDXIP=""  D
	. S BSDXPORT=0 F  S BSDXPORT=$O(^BSDXTMP("EVENT",BSDXEVENT,BSDXIP,BSDXPORT)) Q:'+BSDXPORT  D
	. . I BSDXIP=BSDXSIP Q  ;,BSDXPORT=BSDXSPT Q
	. . D CALL^%ZISTCP(BSDXIP,BSDXPORT,5)
	. . I POP K ^BSDXTMP("EVENT",BSDXEVENT,BSDXIP,BSDXPORT) Q
	. . ;U IO R X#3:5
	. . I X'="ACK" K ^BSDXTMP("EVENT",BSDXEVENT,BSDXIP,BSDXPORT) Q
	. . S BSDXPARAM=$S(BSDXPARAM="":"",1:U_BSDXPARAM)
	. . U IO W BSDXEVENT,BSDXPARAM,!
	. . D ^%ZISC
	. . Q
	. Q
	Q
	;
EVERR(BSDXEVENT,BSDXIP,BSDXPORT)	;
	;
	Q:$G(BSDXEVENT)=""
	Q:$G(BSDXIP)=""
	Q:$G(BSDXIP)=""
	K ^BSDXTMP("EVENT",BSDXEVENT,BSDXIP,BSDXPORT)
	Q
	;
REGET	;EP
	;Error trap from REGEVNT
	;
	I '$D(BSDXI) N BSDXI S BSDXI=999
	S BSDXI=BSDXI+1
	D REGERR(BSDXI,99)
	Q
	;
REGERR(BSDXI,BSDXERID)	;Error processing
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=BSDXERID_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
	;
REGEVNT(BSDXY,BSDXEVENT,BSDXIP,BSDXPORT)	;EP
	;RPC Called by client to inform RPMS server of client's interest in BSDXEVENT
	;Returns RECORDSET with field ERRORID.
	;If everything ok then ERRORID = 0;
	;
	N BSDXI
	S BSDXI=0
	S X="REGET^BSDX23",@^%ZOSF("TRAP")
	S BSDXY="^BSDXTMP("_$J_")"
	S ^BSDXTMP($J,0)="I00020ERRORID"_$C(30)
	I '+BSDXPORT D REGERR(BSDXI,1) Q
	I BSDXIP="" D REGERR(BSDXI,2) Q
	S ^BSDXTMP("EVENT",BSDXEVENT,BSDXIP,BSDXPORT)=""
	;
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)="0"_$C(30)_$C(31)
	Q
	;
UNREG(BSDXY,BSDXEVENT,BSDXIP,BSDXPORT)	;EP
	;RPC Called by client to Unregister client's interest in BSDXEVENT
	;Returns RECORDSET with field ERRORID.
	;If everything ok then ERRORID = 0;
	;
	N BSDXI
	S BSDXI=0
	S X="REGET^BSDX23",@^%ZOSF("TRAP")
	S BSDXY="^BSDXTMP("_$J_")"
	S ^BSDXTMP($J,0)="I00020ERRORID"_$C(30)
	I '+BSDXPORT D REGERR(BSDXI,1) Q
	I BSDXIP="" D REGERR(BSDXI,2) Q
	K ^BSDXTMP("EVENT",BSDXEVENT,BSDXIP,BSDXPORT)
	;
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)="0"_$C(30)_$C(31)
	Q
	;
RAISEVNT(BSDXY,BSDXEVENT,BSDXPARAM,BSDXSIP,BSDXSPT)	;EP
	;RPC Called to raise event BSDXEVENT with parameter BSDXPARAM
	;BSDXSIP and BSDXSPT represent the sender's IP and PORT.
	;If not null, these will prevent the event from being raised back
	;to the sender.
	;Returns a RECORDSET wit the field ERRORID.
	;If everything ok then ERRORID = 0;
	;
	N BSDXI
	S BSDXI=0
	S BSDXY="^BSDXTMP("_$J_")"
	S ^BSDXTMP($J,0)="I00020ERRORID"_$C(30)
	S X="REGET^BSDX23",@^%ZOSF("TRAP")
	;
	D EVENT(BSDXEVENT,BSDXPARAM,BSDXSIP,BSDXSPT)
	;
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)="0"_$C(30)_$C(31)
	Q
