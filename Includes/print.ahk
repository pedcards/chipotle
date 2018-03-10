TblCols(tabs*) {
/*	tabs = array of tab stops in inches, e.g. 2.25", 3.75", 4.6"
 *	returns formatted string
 */
	TblC:="\cellx", tw:=1440							; Measured in twips (1440 = 1", 720 = 1/2", 360 = 1/4")
	for k,val in tabs
	{
		tblCols .= TblC . round(tw * val)
	}
	return tblCols
}

PrintIt() {
	global y, location, locString
	rtfTblCols := tblCols(2.25							; Location (e.g. tab stop at 1.5")
						, 3.75							; MRN
						, 4.625							; Sex/Age
						, 5.625							; DOB
						, 6.5 							; Days
						, 7.0							; Admit date
						, 7.875)						; Right margin

	rtfTblCol2 := tblCols(2.25							; Diagnoses (below NAME)
						, 5.625							; Todo later (below DOB)
						, 7.875)						; Right margin

	rtfList :=
	CIS_dx :=
	FormatTime, rtfNow, A_Now, yyyyMMdd
	
	Loop, % (prList:=y.selectNodes("/root/lists/" location "/mrn")).length {
		kMRN := prList.item(i:=A_Index-1).text
		k := y.selectSingleNode("/root/id[@mrn='" kMRN "']")
		pr := ptParse(kMRN)
		pr_adm := parseDate(pr.Admit)													; admit date
		CIS_adm := pr_adm.YYYY . pr_adm.MM . pr_adm.DD									; format date 20170415
		CIS_los := A_Now
		CIS_los -= CIS_adm, days														; los between admit and now
		
		pri := k.selectNodes("info").item(k.selectNodes("info").length-1)				; take the last Info child element
		pri_date := pri.getAttribute("date")											; date of last info entry
		pri_now := A_Now
		pri_now -= pri_date, Hours														; difference in hours since last info entry
		
		pr_today :=																		; today = col-A
		pr_todo := "\fs12"																; todo = col-C
		if (pri_now < 26) {									; only generate VS if CORES from last 24 hr or so
			pr_VS := pri.selectSingleNode("vs")
			pr_todo .= "Wt = " . pr_VS.selectSingleNode("wt").text " (" niceDate(pri_date) ")\line "
					;~ . ((i:=pr_VS.selectSingleNode("spo2").text) ? ", O2 sat = " . vsMean(i) : "") "\line "
					;~ . ((i:=pr_VS.selectSingleNode("hr").text) ? "HR = " . vsMean(i) : "")
					;~ . ((i:=pr_VS.selectSingleNode("rr").text) ? ", RR = " . vsMean(i) : "") "\line "
					;~ . ((i:=pr_VS.selectSingleNode("bp").text) ? "BP = " . vsMean(i) : "") "\line "
			Loop, % (prMAR:=k.selectNodes("MAR/*")).length {							; only generate Meds if CORES from today
				prMed := prMAR.item(A_Index-1)											; MAR items
				prMedCl := prMed.getAttribute("class")
				if (prMedCl~="Cardiac|Arrhythmia|Abx") {						; either class CARDIAC or ARRHYTHMIA
					pr_todo .= "\f2s\f0" . prMed.text . "\line "						; add to TODO column
				}
			}
		}
		Loop, % (plT:=k.selectNodes("plan/tasks/todo")).length {						; scan through <tasks/todo> items
			tMRN:=plT.item(A_Index-1)
			plD := tMRN.getAttribute("due")
			plDate := substr(plD,5,2) . "/" . substr(plD,7,2)
			plD -= A_Now, D
			if (plD<2)																	; time differnce for TODO is 1 day or less
				pr_today .= "\f2q\f0 (" . plDate . ") " . tMRN.text . "\line\fs12 "		; add to TODAY col-A
			else
				pr_todo  .= "\f2q\f0 (" . plDate . ") " . tMRN.text . "\line\fs12 "		; otherwise add to TODO col-C
		}
		if (pr_call := pr.callN) {
			pr_call -= A_Now, D															; add Call task item if callN diff less than 1 day
			if (pr_call<1) {
				pr_today .= "\f2q\f0 (" breakDate(pr.callN).MM "/" breakDate(pr.callN).DD ") Call Dr. " pr.provCard "\line\fs12 "
			}
		}
		E0best := plEchoRes(kMRN)
		pr_today .= strQ(E0best.res,"\line\line Echo " E0best.date ": ###\line ")			; add to TODAY col-A
		
		CIS_dx := strQ(RegExReplace(pr.dxCard,"[\r\n]"," * "),"[[Dx]] ###\line ")		; add <diagnosis> sections if present
				. strQ(RegExReplace(pr.dxSurg,"[\r\n]"," * "),"[[Surg]] ###\line ") 	; to the DX col-B
				. strQ(RegExReplace(pr.dxEP,"[\r\n]"," * "),  "[[EP]] ###\line ")
				. strQ(RegExReplace(pmNoteChk(pr.dxNotes),"[\r\n]"," * "), "[[Notes]] ###\line ")
		
		rtfList .= "\keepn\trowd\trgaph144\trkeep" rtfTblCols "`n\b"					; define Tbl ID row 
			. "\intbl " . pr.nameL ", " pr.nameF . strQ(pr.provCard,"\fs12  (###" strQ(pr.provSchCard,"//###") ")\fs18") "\cell`n"
			. "\intbl " . pr.Unit " " pr.Room "\cell`n"
			. "\intbl " . kMRN "\cell`n"
			. "\intbl " . SubStr(pr.Sex,1,1) " " pr.Age "\cell`n" 
			. "\intbl " . pr.DOB "\cell`n"
			. "\intbl " . CIS_los "\cell`n"
			. "\intbl " . pr_adm.Date "\cell`n\b0"
			. "\row`n"
			. "\pard\trowd\trgaph144\trrh720\trkeep" . rtfTblCol2 . "`n"				; define col-A col-B col-C
			. "\intbl\fs12 " . pr_today "\cell`n"
			. "\intbl\fs12 " . CIS_dx "\line\cell`n"
			. "\intbl\fs12 " . pr_todo "\fs18\cell`n"
			. "\row`n"
	}
	
	onCall := getCall(rtfNow)															; generate on-call header block
	rtfCall := strQ(onCall.Ward_A,"Ward: ###   ")
			. strQ(onCall.Ward_F,"Ward Fellow: ###   ")
			. strQ(onCall.ICU_A,"ICU: ###   ")
			. strQ(onCall.ICU_F,"ICU Fellow: ###   ")
			. strQ(onCall.TXP,"Txp: ###   ")
			. strQ(onCall.EP,"EP: ###   ")
			. strQ(onCall.TEE,"TEE: ###   ")
	rtfCall .= strQ(rtfCall,"`n\line`n")
			. strQ(onCall.ARNP_CL,"ARNP Cath: ###   ")
			. strQ(onCall.ARNP_IP,"ARNP RC6: ### 7-4594   ")
			. strQ(onCall.CICU,"CICU: ### 7-6503, Fellow: 7-6507, Resource Attg: 7-8532   ")
			. strQ(onCall.Reg_Con,"Reg Cons: ###   ")
	rtfCall .= strQ(rtfCall,"`n\line`n")
			. "\ul HC Fax: 987-3839   Clinic RN: 7-7693   Echo Lab: 7-2019   RC6.Charge RN: 7-2108,7-6200   RC6.UC Desk: 7-2021   FA6.Charge RN: 7-2475   FA6.UC Desk: 7-2040\ul0"
	
	rtfOut =
(
{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fnil\fcharset0 Calibri;}{\f2\fnil\fcharset2 Wingdings;}}
{\*\generator Msftedit 5.41.21.2510;}\viewkind4\uc1\lang9\f0\fs18\margl360\margr360\margt360\margb360
{\header\viewkind4\uc1\pard\f0\fs12\qc

)%rtfCall%
(
\par\line\fs18\b
CHIPOTLE Patient List:\~
)%locString%
(
\par\ql\b0
\par
{\trowd\trgaph144
)%rtfTblCols%
(
\b
\intbl Name\cell
\intbl Location\cell
\intbl MRN\cell
\intbl Sex/Age\cell
\intbl DOB\cell
\intbl Day\cell
\intbl Admit\cell
\b0
\row}
\fs2\posx144\tx11160\ul\tab\ul0\par
}
{\footer\viewkind4\uc1\pard\f0\fs18\qc
Page \chpgn\~\~\~\~
)%user%
(
\~\~\~\~
\chdate\~\~\~\~
\chtime
\par\ql}

)%rtfList%
(
}`r`n
)
	fileout := "patlist-" . location . ".rtf"
	if FileExist(fileout) {
		FileDelete, %fileout%
	}
	FileAppend, %rtfOut%, %fileout%
	
	prt := substr(A_GuiControl,1,1)
	if (prt="O") {
		Run, %fileout%
		MsgBox, 262192, Open temp file
		, % "Only use this function to troubleshoot `n"
		. "printing to the local printer. `n`n"
		. "Changes to this file will not `n"
		. "be saved to the CHIPOTLE database `n"
		. "and will likely be lost!"
		eventlog(fileout " opened in Word.")
	} else {
		Run, print %fileout%
		eventlog(fileout " printed.")
	}
return
}

PrintARNP() {
	global y, location, locString, ccFields, rtflist, pr
	
	TblC:="\cellx", tw:=1440							; Measured in twips (1440 = 1", 720 = 1/2", 360 = 1/4")
	TblBrdr:="\clbrdrt\brdrs\clbrdrl\brdrs\clbrdrb\brdrs\clbrdrr\brdrs"
	TcelX:=0
	rtfTblCol1 :=	TblBrdr "`n"											; 
					. TblC . round(tw * (TcelX+=1.5)) . TblBrdr "`n"		; Name
					. TblC . round(tw * (TcelX+=1.0)) . TblBrdr "`n"		; Location (e.g. tab stop at 1.5")
					. TblC . round(tw * (TcelX+=0.75)) . TblBrdr "`n"		; Diagnosis
					. TblC . round(tw * (TcelX+=0.85)) . TblBrdr "`n"		; DOB
					. TblC . round(tw * (TcelX+=0.85)) . TblBrdr "`n"		; Admitted
					. TblC . round(tw * (TcelX+=1.25)) . TblBrdr "`n"		; Cardiologist/Surgeon
					. TblC . round(tw * 8) "`n"								; Notes, Right margin

	rtfTblCol2 :=	TblBrdr "`n"											; 
					. TblC . round(tw * 1.0) . TblBrdr "`n"					; ccSys field
					. TblC . round(tw * 8) . TblBrdr "`n"					; Textfield (below LOCATION), Right margin
	
	rtfTblCol3 := 	TblBrdr "`n"
					. TblC . round(tw * 1.0) . TblBrdr "`n"
					. TblC . round(tw * 5.0) . TblBrdr "`n"
					. TblC . round(tw * 8) . TblBrdr "`n"

	rtfList :=
	CIS_dx :=
	hmtList := ["Nbs1:NBS#1 sent","Nbs2:NBS#2 sent","Baer:BAER passed","Oph:Ophtho","Gt:GT teaching","Seat:Car seat"
				, "Pcp:PCP","Crd:Cardiology","Ndv:Neurodev","OTPT:OT/PT/Speech"
				, "Synagis:Synagis candidate","Imms:Immunications","DC:Discharge plan","CPR:CPR"]
	
	Loop, % (prList:=y.selectNodes("/root/lists/" location "/mrn")).length {
		kMRN := prList.item(i:=A_Index-1).text
		k := y.selectSingleNode("/root/id[@mrn='" kMRN "']")
		pr := ptParse(kMRN)
		pr_adm := parseDate(pr.Admit)
		CIS_adm := pr_adm.YYYY . pr_adm.MM . pr_adm.DD
		CIS_los := A_Now
		CIS_los -= CIS_adm, days
		pr_meds :=
		pr_today :=
		pr_todo := "\fs12"
		if IsObject(pr_VS := k.selectSingleNode("info/vs")) {
			pr_todo .= "Wt = " . pr_VS.selectSingleNode("wt").text
					. ((i:=pr_VS.selectSingleNode("spo2").text) ? ", O2 = (" . StrX(i,,1,1," ",1,1,NN) . ") " . StrX(i," ",NN,1," ",1,1) : "")
					. "\line "
		}
		Loop, % (prMAR:=k.selectNodes("MAR/*")).length {
			prMed := prMAR.item(A_Index-1)
			prMedCl := prMed.getAttribute("class")
			if (prMedCl~="Cardiac|Arrhythmia|Abx") {
				pr_todo .= "\f2s\f0" . prMed.text . "\line "
				pr_meds .= "\f2s\f0" . prMed.text . "\line "
			}
		}
		Loop, % (plT:=k.selectNodes("plan/tasks/todo")).length {
			tMRN:=plT.item(A_Index-1)
			plD := tMRN.getAttribute("due")
			plDate := substr(plD,5,2) . "/" . substr(plD,7,2)
			plD -= A_Now, D
			if (plD<2)
				pr_today .= "\f2q\f0 (" . plDate . ") " . tMRN.text . "\line\fs12 "
			else
				pr_todo  .= "\f2q\f0 (" . plDate . ") " . tMRN.text . "\line\fs12 "
		}
		if (pr_call := pr.callN) {
			pr_call -= A_Now, D
			if (pr_call<2) {
				pr_today .= "\f2q\f0 (" breakDate(pr.callN).MM "/" breakDate(pr.callN).DD ") Call Dr. " pr.provCard "\line\fs12 "
			}
		}

		CIS_dx := ((pr.dxCard) ? "Dx: " pr.dxCard "\line " : "")
				. ((pr.dxSurg) ?  "Surg: " pr.dxSurg "\line " : "")
				. ((pr.dxEP) ? "EP: " pr.dxEP "\line " : "")
				. ((pr.dxNotes) ? "Notes: " pmNoteChk(pr.dxNotes) : "")
		
		if (A_Index>1) {
			rtfList .= "\page\par`n"
		}
		rtfList .= "{\trowd\trgaph144" rtfTblCol1 "\b`n"
			. "\intbl Name\cell`n"
			. "\intbl Location\cell`n"
			. "\intbl MRN\cell`n"
			. "\intbl DOB\cell`n"
			. "\intbl Admitted\cell`n"
			. "\intbl Cardiologist\cell`n"
			. "\intbl Notes\cell`n"
			. "\b0\row`n"
			. "\intbl " pr.nameL ", " pr.nameF "\line " 
				. RegExReplace(RegExReplace(pr.Age,"month","mo"),"year","yr") " " SubStr(pr.Sex,1,1) "\line "
				. pr_VS.selectSingleNode("wt").text " kg \cell`n"
			. "\intbl " pr.Room "\cell`n"
			. "\intbl " kMRN "\cell`n"
			. "\intbl " pr.DOB "\cell`n"
			. "\intbl " pr_adm.Date "\cell`n"
			. "\intbl " pr.provCard ((pr.provCSR) ? "\line\line\b CSR\b0\line " pr.provCSR : "") "\cell`n"
			. "\intbl " pr.misc "\cell`n"
			. "\row}`n"
		rtfList .= "{\trowd\trgaph144\trrh720" rtfTblCol2 "`n"
			. "\intbl\b Diagnoses\b0\cell`n"
			. "\intbl " RegExReplace(CIS_dx,"m)\R","\line\~\~\~\~\~ ") "\cell`n\row`n"
		for key,val in ccFields {
			rtfList .= "\intbl\b " RegExReplace(val,"_","/") "\b0\cell`n"
				. "\intbl " ((val="FEN") ? plDiet(pr.ccSys.selectSingleNode(val).text) : pr.ccSys.selectSingleNode(val).text) "\cell`n"
				. "\row`n"
		}
		rtfList .= "}`n"
		pr_dob := parseDate(pr.DOB)
		pr_dob := pr_dob.YYYY pr_dob.MM pr_dob.DD
		pr_dob -= A_Now, Days
		rtfList .= "{\trowd\trgaph144\trrh720" rtfTblCol3 "`n"
				. "\intbl\b Health Maint\b0\cell`n"
				. "\intbl "
		if (-pr_dob < 60) {
			for key,val in hmtList {
				opt := strX(val,,0,0,":",1,1)
				res := strX(val,":",1,1,"",1,1)
				chk := k.selectSingleNode("ccHMT/" opt).getAttribute("set")
				txt := k.selectSingleNode("ccHMT/" opt).text
				rtfList .= "\f2\'" ((chk)?"FD":"A8") "\f0\~\~" res ": " txt "\line`n"
			}
		}
		rtfList .= "\cell`n"
				. "\intbl " pr_meds "\cell`n"
				. "\row}`n"
	}

	FormatTime, rtfNow, A_Now, yyyyMMdd
	onCall := getCall(rtfNow)
	rtfCall := ((tmp:=onCall.Ward_A) ? "Ward: " tmp "   " : "")
			. ((tmp:=onCall.Ward_F) ? "Ward Fellow: " tmp "   " : "")
			. ((tmp:=onCall.ICU_A) ? "ICU: " tmp "   " : "")
			. ((tmp:=onCall.ICU_F) ? "ICU Fellow: " tmp "   " : "")
			. ((tmp:=onCall.TXP) ? "Txp: " tmp "   " : "")
			. ((tmp:=onCall.EP) ? "EP: " tmp "   " : "")
			. ((tmp:=onCall.TEE) ? "TEE: " tmp "   " : "")
	rtfCall .= ((rtfCall) ? "`n\line`n" : "")
			. ((tmp:=onCall.ARNP_CL) ? "ARNP Cath: " tmp "   " : "")
			. ((tmp:=onCall.ARNP_IP) ? "ARNP RC6: " tmp " 7-4594   " : "")
			. ((tmp:=onCall.CICU) ? "CICU: " tmp " 7-6503, Fellow: 7-6507   " : "")
			. ((tmp:=onCall.Reg_Con) ? "Reg Cons: " tmp "   " : "")
	rtfCall .= ((rtfCall) ? "`n\line`n" : "")
			. "\ul HC Fax: 987-3839   Clinic RN: 7-7693   Echo Lab: 7-2019   RC6.Charge RN: 7-2108,7-6200   RC6.UC Desk: 7-2021   FA6.Charge RN: 7-2475   FA6.UC Desk: 7-2040\ul0"
	
	rtfOut =
(
{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fnil\fcharset0 Calibri;}{\f2\fnil\fcharset2 Wingdings;}}
{\*\generator Msftedit 5.41.21.2510;}\viewkind4\uc1\lang9\f0\fs18\margl360\margr360\margt360\margb360
{\header\viewkind4\uc1\pard\f0\fs12\qc

)%rtfCall%
(
\par\line\fs18\b
CHIPOTLE Patient List:\~
)%locString%
(
\par\ql\b0
\par}

{\footer\viewkind4\uc1\pard\f0\fs18\qc
Page \chpgn\~\~\~\~
)%user%
(
\~\~\~\~
\chdate\~\~\~\~
\chtime
\par\ql}

)%rtfList%					; nope
(
}`r`n
)
	fileout := "patlist-" . location . ".rtf"
	if FileExist(fileout) {
		FileDelete, %fileout%
	}
	FileAppend, %rtfOut%, %fileout%
	
	prt := substr(A_GuiControl,1,1)
	if (prt="O") {
		Run, %fileout%
		MsgBox, 262192, Open temp file
		, % "Only use this function to troubleshoot `n"
		. "printing to the local printer. `n`n"
		. "Changes to this file will not `n"
		. "be saved to the CHIPOTLE database `n"
		. "and will likely be lost!"
		eventlog(fileout " opened in Word.")
	} else {
		Run, print %fileout%
		eventlog(fileout " printed.")
	}
	rtfList :=
return
}

strQ(var1,txt) {
/*	Print Query - Returns text based on presence of var
	var1	= var to query
	txt		= text to return with ### on spot to insert var1 if present
*/
	if (var1="") {
		return error
	}
	return RegExReplace(txt,"###",var1)
}

