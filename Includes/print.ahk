PrintIt:
{
	TblC:="\cellx", tw:=1440							; Measured in twips (1440 = 1", 720 = 1/2", 360 = 1/4")
	rtfTblCols := 	  TblC . round(tw * 2.25)			; Location (e.g. tab stop at 1.5")
					. TblC . round(tw * 3.75)			; MRN
					. TblC . round(tw * 4.625)			; Sex/Age
					. TblC . round(tw * 5.625)			; DOB
					. TblC . round(tw * 6.5)			; Days
					. TblC . round(tw * 7.0)			; Admit date
					. TblC . round(tw * 7.875)			; Right margin

	rtfTblCol2 :=	  TblC . round(tw * 2.25)			; Diagnoses (below NAME)
					. TblC . round(tw * 5.625)			; Todo later (below DOB)
					. TblC . round(tw * 7.875)			; Right margin

	rtfList :=
	CIS_dx :=
	
	Loop, % (prList:=y.selectNodes("/root/lists/" location "/mrn")).length {
		kMRN := prList.item(i:=A_Index-1).text
		k := y.selectSingleNode("/root/id[@mrn='" kMRN "']")
		pr := ptParse(kMRN)
		pr_adm := parseDate(pr.Admit)
		CIS_adm := pr_adm.YYYY . pr_adm.MM . pr_adm.DD
		CIS_los := A_Now
		CIS_los -= CIS_adm, days
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
			if (prMedCl="cardiac") or (prMedCl="arrhythmia") {
				pr_todo .= "\f2s\f0" . prMed.text . "\line "
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
			if (pr_call<1) {
				pr_today .= "\f2q\f0 (" breakDate(pr.callN).MM "/" breakDate(pr.callN).DD ") Call Dr. " pr.provCard "\line\fs12 "
			}
		}

		CIS_dx := ((pr.dxCard) ? "[[Dx]] " pr.dxCard "\line " : "")
				. ((pr.dxSurg) ?  "[[Surg]] " pr.dxSurg "\line " : "")
				. ((pr.dxEP) ? "[[EP]] " pr.dxEP "\line " : "")
				. ((pr.dxNotes) ? "[[Notes]] " pr.dxNotes : "")
		
		rtfList .= "\keepn\trowd\trgaph144\trkeep" rtfTblCols "`n\b"
			. "\intbl " . pr.nameL ", " pr.nameF ((pr.provCard) ? "\fs12  (" pr.provCard . ((pr.provSchCard) ? "//" pr.provSchCard : "") ")\fs18" : "") "\cell`n"
			. "\intbl " . pr.Unit " " pr.Room "\cell`n"
			. "\intbl " . kMRN "\cell`n"
			. "\intbl " . SubStr(pr.Sex,1,1) " " pr.Age "\cell`n" 
			. "\intbl " . pr.DOB "\cell`n"
			. "\intbl " . CIS_los "\cell`n"
			. "\intbl " . pr_adm.Date "\cell`n\b0"
			. "\row`n"
			. "\pard\trowd\trgaph144\trrh720\trkeep" . rtfTblCol2 . "`n"
			. "\intbl\fs12 " . pr_today "\cell`n"
			. "\intbl\fs12 " . CIS_dx "\line\cell`n"
			. "\intbl\fs12 " . pr_todo "\fs18\cell`n"
			. "\row`n"
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

PrintARNP:
{
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

	rtfList :=
	CIS_dx :=
	hmtList := ["Nbs1:NBS#1 sent","Nbs2:NBS#2 sent","Baer:BAER passed","Oph:Ophtho","Gt:GT teaching","Seat:Car seat"
				, "Pcp:PCP","Crd:Cardiology","Ndv:Neurodev","OTPT:OT/PT/Speech"
				, "Synagis:Synagis candidate","Imms:Immunications","DC:Discharge plan"]
	
	Loop, % (prList:=y.selectNodes("/root/lists/" location "/mrn")).length {
		kMRN := prList.item(i:=A_Index-1).text
		k := y.selectSingleNode("/root/id[@mrn='" kMRN "']")
		pr := ptParse(kMRN)
		pr_adm := parseDate(pr.Admit)
		CIS_adm := pr_adm.YYYY . pr_adm.MM . pr_adm.DD
		CIS_los := A_Now
		CIS_los -= CIS_adm, days
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
			if (prMedCl="cardiac") or (prMedCl="arrhythmia") {
				pr_todo .= "\f2s\f0" . prMed.text . "\line "
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
				. ((pr.dxNotes) ? "Notes: " pr.dxNotes : "")
		
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
			. "\intbl " pr.nameL ", " pr.nameF "\line " RegExReplace(RegExReplace(pr.Age,"month","mo"),"year","yr") " " SubStr(pr.Sex,1,1) "\cell`n"
			. "\intbl " pr.Room "\cell`n"
			. "\intbl " kMRN "\cell`n"
			. "\intbl " pr.DOB "\cell`n"
			. "\intbl " pr_adm.Date "\cell`n"
			. "\intbl " pr.provCard ((pr.provCSR) ? "\line\line\b CSR\b0\line " pr.provCSR : "") "\cell`n"
			. "\intbl " pr.misc "\cell`n"
			. "\row}`n"
		rtfList .= "{\trowd\trgaph144\trrh320" rtfTblCol2 "`n"
			. "\intbl\b Diagnoses\b0\cell`n"
			. "\intbl " RegExReplace(CIS_dx,"m)\R","\line\~\~\~\~\~ ") "\cell`n\row`n"
		for key,val in ccFields {
			rtfList .= "\intbl\b " RegExReplace(val,"_","/") "\b0\cell`n"
				. "\intbl " pr.ccSys.selectSingleNode(val).text "\cell`n"
				. "\row`n"
		}
		pr_dob := parseDate(pr.DOB)
		pr_dob := pr_dob.YYYY pr_dob.MM pr_dob.DD
		pr_dob -= A_Now, Days
		if (-pr_dob < 60) {
			rtfList .= "\intbl\b Health Maint\b0\cell`n"
					. "\intbl "
			for key,val in hmtList {
				opt := strX(val,,0,0,":",1,1)
				res := strX(val,":",1,1,"",1,1)
				chk := k.selectSingleNode("ccHMT/" opt).getAttribute("set")
				txt := k.selectSingleNode("ccHMT/" opt).text
				rtfList .= "\f2\'" ((chk)?"FD":"A8") "\f0\~\~" res ": " txt "\line`n"
			}
			rtfList .= "\cell`n"
					. "\row`n"
		}
		rtfList .= "}`n"
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
return
}

