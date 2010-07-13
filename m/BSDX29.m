BSDX29	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ; 7/13/10 9:47am
	;;2.0;IHS WINDOWS SCHEDULING;;NOV 01, 2007
	;
	;
BSDXCPD(BSDXY,BSDXRES,BSDX44,BSDXBEG,BSDXEND)	;EP
	;Entry point for debugging
	;
	;D DEBUG^%Serenji("BSDXCP^BSDX29(.BSDXY,BSDXRES,BSDX44,BSDXBEG,BSDXEND)")
	Q
	;
BSDXCP(BSDXY,BSDXRES,BSDX44,BSDXBEG,BSDXEND)	;EP
	;Copy appointments from HOSPITAL LOCATION entry BSDX44 to BSDX RESOURCE entry BSDXRES
	;Beginning with appointments on day BSDXBEG and ending on BSDXEND, inclusive
	;
	;Returns ADO Recordset formatted fields containing count of records copied and error message:
    ;
    ; July 13 2010: D dates (BEG and END) from US format to FM Dates for i18n
	;
	;
	S BSDXY="^BSDXTMP("_$J_")"
	N BSDXI,BSDXST,ZTSK
	S BSDXI=0
	S X="ETRAP^BSDX29",@^%ZOSF("TRAP")
	S ^BSDXTMP($J,0)="T00010TASK_NUMBER^T00020ERRORID"_$C(30)
	;
	;Convert beginning and ending dates
    ;
    ;TODO:Validate FM Dates coming through
	;
	S BSDXBEG=BSDXBEG-1
	S BSDXEND=BSDXEND+1
	;
	S ZTRTN="ZTM^BSDX29",ZTDTH=$H,ZTDESC="COPY PATIENT APPTS"
	S ZTSAVE("BSDXBEG")="",ZTSAVE("BSDXEND")="",ZTSAVE("BSDX44")="",ZTSAVE("BSDXRES")=""
	D ^%ZTLOAD
	;
	S BSDXI=BSDXI+1
	S BSDXST=$S($G(ZTSK)>0:"OK",1:"Unable to create task.")
	S ^BSDXTMP($J,BSDXI)=$G(ZTSK)_"^"_BSDXST_$C(30)_$C(31)
	Q
	;
ZTMTST	;
	;
	S %DT="AE" D ^%DT S BSDXBEG=Y
	S %DT="AE" D ^%DT S BSDXEND=Y
	S BSDX44=3,BSDXSRES=1,ZTSK=3380
	D ZTM
	Q
	;
ZTMD	;EP - Debug entry point
	;D DEBUG^%Serenji("ZTM^BSDX29")
	Q
	;
ZTM	;EP
	;Taskman entry point
	S X="ZTMERR^BSDX29",@^%ZOSF("TRAP")
	;$O through ^SC(BSDX44,"S",
	Q:'$D(ZTSK)
	N BSDXCNT,BSDXIEN,BSDXNOD,BSDXNOTE,BSDXCAN,BSDXPAT,BSDXLEN,BSDXMADE,BSDXCLRK,BSDXPAT,BSDXQUIT
	S BSDXCNT=0,BSDXQUIT=0
	S ^BSDXTMP("BSDXCOPY",ZTSK)=BSDXCNT
	TSTART
	F  S BSDXBEG=$O(^SC(BSDX44,"S",BSDXBEG)) Q:'+BSDXBEG  Q:BSDXBEG>BSDXEND  Q:BSDXQUIT  D
	. S BSDXIEN=0 F  S BSDXIEN=$O(^SC(BSDX44,"S",BSDXBEG,1,BSDXIEN)) Q:'+BSDXIEN  Q:BSDXQUIT  D
	. . S BSDXNOD=$G(^SC(BSDX44,"S",BSDXBEG,1,BSDXIEN,0))
	. . Q:'+BSDXNOD
	. . S BSDXCAN=$P(BSDXNOD,U,9)
	. . Q:BSDXCAN="C"
	. . S BSDXPAT=$P(BSDXNOD,U)
	. . S BSDXLEN=$P(BSDXNOD,U,2) ;duration in minutes
	. . S BSDXCLRK=$P(BSDXNOD,U,6) ;appt made by (clerk)
	. . S BSDXMADE=$P(BSDXNOD,U,7) ;date appt made
	. . S BSDXNOTE=$P(BSDXNOD,U,4) ;'OTHER' field contains note
	. . S BSDXCNT=BSDXCNT+$$XFER(BSDXRES,BSDXBEG,BSDXPAT,BSDXLEN,BSDXCLRK,BSDXMADE,BSDXNOTE)
	. . I +BSDXCNT,BSDXCNT#10=0 S ^BSDXTMP("BSDXCOPY",ZTSK)=BSDXCNT_" records copied." ;every 10th record
	. . I $D(^BSDXTMP("BSDXCOPY",ZTSK,"CANCEL")) S BSDXQUIT=1 ;Check for cancel flag
	. . Q
	. Q
	I 'BSDXQUIT TCOMMIT
	E  TROLLBACK
	S ^BSDXTMP("BSDXCOPY",ZTSK)=$S(BSDXQUIT:"Cancelled.  No records copied.",1:"Finished.  "_BSDXCNT_" records copied.")
	Q
	;
ZTMERR	;
	TROLLBACK
	D ^%ZTER
	Q
	;
XFER(BSDXRES,BSDXBEG,BSDXPAT,BSDXLEN,BSDXCLRK,BSDXMADE,BSDXNOTE)	;EP
	;
	;Copy record to BSDX APPOINTMENT file
	;Return 1 if record copied, otherwise 0
	;
	;$O Thru ^BSDXAPPT to determine if this appt already added
	N BSDXEND,BSDXIEN,BSDXFND,BSDXPAT2
	S BSDXIEN=0,BSDXFND=0
	F  S BSDXIEN=$O(^BSDXAPPT("ARSRC",BSDXRES,BSDXBEG,BSDXIEN)) Q:'+BSDXIEN  D  Q:BSDXFND
	. S BSDXNOD=$G(^BSDXAPPT(BSDXIEN,0))
	. Q:'+BSDXNOD
	. S BSDXPAT2=$P(BSDXNOD,U,5)
	. S BSDXFND=0
	. I BSDXPAT2=BSDXPAT S BSDXFND=1
	. Q
	Q:BSDXFND 0
	;
	;Add to BSDX APPOINTMENT
	S BSDXEND=BSDXBEG
	;Calculate ending time from beginning time and duration.
	S BSDXEND=$$ADDMIN(BSDXBEG,BSDXLEN)
	S BSDXIENS="+1,"
	S BSDXFDA(9002018.4,BSDXIENS,.01)=BSDXBEG
	S BSDXFDA(9002018.4,BSDXIENS,.02)=BSDXEND
	S BSDXFDA(9002018.4,BSDXIENS,.05)=BSDXPAT
	S BSDXFDA(9002018.4,BSDXIENS,.07)=BSDXRES
	S BSDXFDA(9002018.4,BSDXIENS,.08)=BSDXCLRK
	S BSDXFDA(9002018.4,BSDXIENS,.09)=BSDXMADE
	;
	K BSDXIEN
	D UPDATE^DIE("","BSDXFDA","BSDXIEN","BSDXMSG")
	S BSDXIEN=+$G(BSDXIEN(1))
	I '+BSDXIEN Q 0
	;
	;Add WP field
	I BSDXNOTE]"" S BSDXNOTE(.5)=BSDXNOTE,BSDXNOTE="" D
	. D WP^DIE(9002018.4,BSDXIEN_",",1,"","BSDXNOTE","BSDXMSG")
	;
	Q 1
	;
ERR(BSDXI,BSDXCNT,BSDXERR)	;Error processing
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=BSDXCNT_"^"_BSDXERR_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
ETRAP	;EP Error trap entry
	D ^%ZTER
	I '$D(BSDXI) N BSDXI S BSDXI=999
	S BSDXI=BSDXI+1
	D ERR(BSDXI,$G(BSDXCNT),"Routine: BSDX29, Error: "_$G(%ZTERROR))
	Q
	;
CPSTAT(BSDXY,BSDXTSK)	;EP
	;Return status (copied record count) of tasked job having ZTSK=BSDXTSK
	;
	S BSDXY="^BSDXTMP("_$J_")"
	N BSDXI,BSDXCNT
	S BSDXI=0
	S X="ETRAP^BSDX29",@^%ZOSF("TRAP")
	S ^BSDXTMP($J,0)="T00020RECORD_COUNT^T00020ERRORID"_$C(30)
	S BSDXCNT=$G(^BSDXTMP("BSDXCOPY",BSDXTSK))
	I BSDXCNT["Finished" K ^BSDXTMP("BSDXCOPY",BSDXTSK)
	I BSDXCNT["Cancelled" K ^BSDXTMP("BSDXCOPY",BSDXTSK)
	;I $D(^BSDXTMP("BSDXCOPY",BSDXTSK,"CANCEL")) K ^BSDXTMP("BSDXCOPY",BSDXTSK)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=BSDXCNT_"^"_"OK"_$C(30)_$C(31)
	Q
	;
CPCANC(BSDXY,BSDXTSK)	;EP
	;Signal tasked job having ZTSK=BSDXTSK to cancel
	;Returns current record count of copy process
	;
	S BSDXY="^BSDXTMP("_$J_")"
	N BSDXI,BSDXCNT
	S BSDXI=0
	S X="ETRAP^BSDX29",@^%ZOSF("TRAP")
	S ^BSDXTMP($J,0)="T00020RECORD_COUNT^T00020ERRORID"_$C(30)
	S BSDXCNT=$G(^BSDXTMP("BSDXCOPY",BSDXTSK))
	I BSDXCNT["FINISHED" K ^BSDXTMP("BSDXCOPY",BSDXTSK)
	E  S ^BSDXTMP("BSDXCOPY",BSDXTSK,"CANCEL")=""
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=BSDXCNT_"^"_"OK"_$C(30)_$C(31)
	Q
	;
ADDMIN(BSDXSTRT,BSDXLEN)	;
	;
	;Add BSDXLEN minutes to time BSDXSTRT and return end time
	N BSDXEND,BSDXH,BSDXM,BSDXSTIM,BSDXETIM
	S BSDXEND=$P(BSDXSTRT,".")
	;
	;Convert start time to minutes past midnight
	S BSDXSTIM=$P(BSDXSTRT,".",2)
	S BSDXSTIM=BSDXSTIM_"0000"
	S BSDXSTIM=$E(BSDXSTIM,1,4)
	S BSDXH=$E(BSDXSTIM,1,2)
	S BSDXH=BSDXH*60
	S BSDXH=BSDXH+$E(BSDXSTIM,3,4)
	;
	;Add duration to find minutes past midnight of end time
	S BSDXETIM=BSDXH+BSDXLEN
	;
	;Convert back to a time
	S BSDXH=BSDXETIM\60
	S BSDXH="00"_BSDXH
	S BSDXH=$E(BSDXH,$L(BSDXH)-1,$L(BSDXH))
	S BSDXM=BSDXETIM#60
	S BSDXM="00"_BSDXM
	S BSDXM=$E(BSDXM,$L(BSDXM)-1,$L(BSDXM))
	S BSDXETIM=BSDXH_BSDXM
	I BSDXETIM>2400 S BSDXETIM=2400
	S $P(BSDXEND,".",2)=BSDXETIM
	Q BSDXEND
