BSDX17	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ; 4/28/11 10:20am
	;;1.6T1;BSDX;;May 11, 2011
	; Licensed under LGPL
	;
	;
SCHUSRD(BSDXY)	;EP
	;Entry point for debugging
	;
	;D DEBUG^%Serenji("SCHUSR^BSDX17(.BSDXY)")
	Q
	;
SCHUSR(BSDXY)	;EP
	;Return recordset of all users in NEW PERSON having BSDXZMENU key
	;Called by BSDX SCHEDULE USER
	;Test Line:
	;D SCHUSR^BSDX17(.RES)
	;
	N BSDXDUZ,BSDXKEY,BSDXI,BSDXNAM,BSDXKEYN
	S BSDXY="^BSDXTMP("_$J_")"
	K ^TEMP($J,"BSDX17")
	S BSDXI=0
	S ^BSDXTMP($J,0)="I00020USERID^T00030USERNAME"_$C(30)
	;$O Through ^VA(200,"AB",
	F BSDXKEYN="BSDXZMENU","BSDXZMGR","XUPROGMODE" S BSDXKEY=+$O(^DIC(19.1,"B",BSDXKEYN,0)) D
	. Q:'+BSDXKEY  S BSDXDUZ=0 F  S BSDXDUZ=$O(^VA(200,"AB",BSDXKEY,BSDXDUZ)) Q:'+BSDXDUZ  D
	. . Q:BSDXDUZ<1  ;IHS/HMW **1**
	. . Q:'$D(^VA(200,BSDXDUZ,0))
	. . Q:$D(^TEMP($J,"BSDX17",BSDXDUZ))
	. . S BSDXNAM=$P(^VA(200,BSDXDUZ,0),U)
	. . S BSDXI=BSDXI+1
	. . S ^TEMP($J,"BSDX17",BSDXDUZ)=""
	. . S ^BSDXTMP($J,BSDXI)=BSDXDUZ_"^"_BSDXNAM_$C(30)
	. . Q
	. Q
	;
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
