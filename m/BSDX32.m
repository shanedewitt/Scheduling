BSDX32	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ; 9/29/10 10:21am
	;;1.5V3;BSDX;;Mar 16, 2011
	;
	;
ERROR	;
	D ERR("RPMS Error")
	Q
	;
ERR(BSDXERR)	;Error processing
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
HOSPLOCD(BSDXY)	;EP Debugging entry point
	;
	;D DEBUG^%Serenji("HOSPLOC^BSDX32(.BSDXY)")
	;
	Q
	;
HOSPLOC(BSDXY)	;EP
	;Called by BSDX HOSPITAL LOCATION
	   ;Returns all hospital locations that are active 
	;
	N BSDXI,BSDXIEN,BSDXNOD,BSDXNAM,BSDXINA,BSDXREA,BSDXSCOD
	D ^XBKVAR S X="ERROR^BSDX32",@^%ZOSF("TRAP")
	K ^BSDXTMP($J)
	S BSDXY="^BSDXTMP("_$J_")"
	S BSDXI=0
	;"SELECT BSDXIEN 'HOSPITAL_LOCATION_ID', NAME 'HOSPITAL_LOCATION', DEFAULT_PROVIDER, STOP_CODE_NUMBER, INACTIVATE_DATE, REACTIVATE_DATE FROM HOSPITAL_LOCATION";
	S ^BSDXTMP($J,BSDXI)="I00020HOSPITAL_LOCATION_ID^T00040HOSPITAL_LOCATION^T00030DEFAULT_PROVIDER^T00030STOP_CODE_NUMBER^D00020INACTIVATE_DATE^D00020REACTIVATE_DATE"_$C(30)
	;
	S BSDXNAM="" F  S BSDXNAM=$O(^SC("B",BSDXNAM)) Q:BSDXNAM=""  D
	. S BSDXIEN=$O(^SC("B",BSDXNAM,0))
	. Q:'+BSDXIEN>0
	. Q:'$D(^SC(+BSDXIEN,0))
	   . ;Q:'$$INDIV^BSDX01(+BSDXIEN)  ; if not in the same division, quit
	. S BSDXINA=$$GET1^DIQ(44,BSDXIEN_",",2505) ;INACTIVATE
	. S BSDXREA=$$GET1^DIQ(44,BSDXIEN_",",2506) ;REACTIVATE
	. I BSDXINA]""&(BSDXREA="") Q  ;Clinic is inactivated and has no reactivate date
	. S BSDXNOD=^SC(BSDXIEN,0)
	. S BSDXNAM=$P(BSDXNOD,U)
	. S BSDXSCOD=$$GET1^DIQ(44,BSDXIEN_",",8) ;STOP CODE
	. ;Calculate default provider
	. S BSDXPRV=""
	. I $D(^SC(BSDXIEN,"PR")) D
	. . S BSDXIEN1=0 F  S BSDXIEN1=$O(^SC(BSDXIEN,"PR",BSDXIEN1)) Q:'+BSDXIEN1  Q:BSDXPRV]""  D
	. . . S BSDXNOD1=$G(^SC(BSDXIEN,"PR",BSDXIEN1,0))
	. . . S:$P(BSDXNOD1,U,2)="1" BSDXPRV=$$GET1^DIQ(200,$P(BSDXNOD1,U),.01)
	. . . Q
	. . Q
	. S BSDXI=BSDXI+1
	. S ^BSDXTMP($J,BSDXI)=BSDXIEN_U_BSDXNAM_U_BSDXPRV_U_BSDXSCOD_U_BSDXINA_U_BSDXREA_$C(30)
	. Q
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
CLNSETD(BSDXY)	;EP Debugging entry point
	;
	;D DEBUG^%Serenji("CLNSET^BSDX32(.BSDXY)")
	;
	Q
	;
CLNSET(BSDXY)	;EP
	;Called by BSDX CLINIC SETUP
	;Returns CLINIC SETUP file entries for clinics which
	;are active in ^SC
	N BSDXI,BSDXIEN,BSDXNOD,BSDXNAM,BSDXINA,BSDXREA
	N BSDXCRV,BSDXVSC,BSDXMULT,BSDXREQ,BSDXPCC
	D ^XBKVAR S X="ERROR^BSDX32",@^%ZOSF("TRAP")
	K ^BSDXTMP($J)
	S BSDXY="^BSDXTMP("_$J_")"
	S BSDXI=0
	;SELECT BMXIEN 'HOSPITAL_LOCATION_ID', CLINIC_NAME 'HOSPITAL_LOCATION', CREATE_VISIT_AT_CHECK-IN? 'CREATE_VISIT', VISIT_SERVICE_CATEGORY,  MULTIPLE_CLINIC_CODES_USED?, VISIT_PROVIDER_REQUIRED,
	;GENERATE_PCCPLUS_FORMS? FROM CLINIC_SETUP_PARAMETERS
	S ^BSDXTMP($J,BSDXI)="I00020HOSPITAL_LOCATION_ID^T00040HOSPITAL_LOCATION^T00030CREATE_VISIT^T00030VISIT_SERVICE_CATEGORY^T00030MULTIPLE_CLINIC_CODES_USED?^T00030VISIT_PROVIDER_REQUIRED^T00030GENERATE_PCCPLUS_FORMS?"_$C(30)
	;
	S BSDXIEN=0 F  S BSDXIEN=$O(^BSDSC(BSDXIEN)) Q:'+BSDXIEN  D
	. Q:'$D(^SC(+BSDXIEN,0))
	. Q:'$D(^BSDSC(+BSDXIEN,0))
	. S BSDXINA=$$GET1^DIQ(44,BSDXIEN_",",2505) ;INACTIVATE
	. S BSDXREA=$$GET1^DIQ(44,BSDXIEN_",",2506) ;REACTIVATE
	. I BSDXINA]""&(BSDXREA="") Q  ;Clinic is inactivated and has no reactivate date
	. S BSDXNOD=^BSDSC(BSDXIEN,0)
	. S BSDXNAM=$$GET1^DIQ(44,BSDXIEN_",",.01)
	. S BSDXCRV=$$GET1^DIQ(9009017.2,BSDXIEN_",",.09)
	. S BSDXVSC=$$GET1^DIQ(9009017.2,BSDXIEN_",",.12)
	. S BSDXMULT=$$GET1^DIQ(9009017.2,BSDXIEN_",",.13)
	. S BSDXREQ=$$GET1^DIQ(9009017.2,BSDXIEN_",",.14)
	. S BSDXPCC=$$GET1^DIQ(9009017.2,BSDXIEN_",",.15)
	. S BSDXI=BSDXI+1
	. S ^BSDXTMP($J,BSDXI)=BSDXIEN_U_BSDXNAM_U_BSDXCRV_U_BSDXVSC_U_BSDXMULT_U_BSDXREQ_U_BSDXPCC_$C(30)
	. Q
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
