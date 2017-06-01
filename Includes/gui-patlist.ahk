PatListGet:
{
	refreshCurr(1)																		; get most recent currlist
	if (A_GuiControl="TeamLV") {
		LV_GetText(mrn, A_EventInfo)
	}
	if (instr(A_GuiControl,"callGrp")) {
		Gui, cList:Listview, % A_GuiControl
		LV_GetText(mrn, A_EventInfo)
	}
	if (mrn="MRN") 								; blank field
		return
	Gui, teamL:Hide
	Gui, plistG:Destroy
	pl := ptParse(mrn)
	pl_mrnstring := "/root/id[@mrn='" mrn "']"
	pl_NameL := pl.nameL
	pl_NameF := pl.nameF
	pl_DOB := pl.DOB
	pl_Age := pl.Age
	pl_Sex := pl.Sex
	pl_Admit := pl.Admit
	pl_Svc := pl.Svc
	pl_Unit := pl.Unit
	pl_Room := pl.Room
	pl_Attg := pl.Attg
	pl_dxCard := pl.dxCard
	pl_dxEP := pl.dxEP
	pl_dxSurg := pl.dxSurg
	pl_dxNotes := pl.dxNotes
	pl_dxProb := pl.dxProb
	pl_misc := pl.misc
	pl_statCons := pl.statCons
	pl_statTxp := pl.statTxp
	pl_statRes := pl.statRes
	pl_statScamp := pl.statScamp
	pl_statMil := pl.statMil
	pl_statPM := pl.statPM
	pl_info := pl.info
	pl_CORES := pl.CORES
	pl_MAR := pl.MAR
	pl_daily := pl.daily
	pl_ccSys := pl.ccSys
	pl_ProvCard := pl.provCard
	pl_ProvSchCard := pl.provSchCard
	pl_ProvCSR := pl.provCSR
	pl_ProvEP := pl.provEP
	pl_ProvPCP := pl.provPCP
	pl_Call_L := pl.callL
	pl_Call_N := pl.callN
	pl_statCoBag := pl.statCoBag
	pl_statCoPillow := pl.statCoPillow
	pl_statCoTour := pl.statCoTour
	pl_noteCo := pl.coordNote
	if (isCoord) {														; Coordinator GUI
		gosub PatListCoGUI
	} else if (isARNP) {												; ConCarne GUI
		gosub PatListGUIcc
	} else {															; Generic provider GUI (everyone else)
		gosub PatListGUI
	}
	return
}
	
PatListGUI:
{
	refreshCurr(1)														; refresh Y with currlock
	holdlist(mrn)
	pl_demo := ""
		. "DOB: " pl_DOB 
		. "   Age: " (instr(pl_Age,"month")?RegExReplace(pl_Age,"i)month","mo"):instr(pl_Age,"year")?RegExReplace(pl_Age,"i)year","yr"):pl_Age) 
		. "   Sex: " substr(pl_Sex,1,1) "`n`n"
		. pl_Unit " :: " pl_Room "`n"
		. pl_Svc "`n`n"
		. "Admitted: " pl_Admit "`n"
	if !(pl_Unit) {																				; no unit means is an ad hoc entry
		pl_demo := "`nDemographics will be added`nwhen patient is admitted"
	}
	Gui, plistG:Destroy
	Gui, plistG:Default
	Gui, Add, Text, x26 y38 w200 h80 , % pl_demo
	Gui, Add, Text, x266 y24 w150 h30 gplInputCard, Primary Cardiologist:
	Gui, Add, Text, xp yp+14 cBlue w140 vpl_card, % pl_ProvCard
	Gui, Add, Text, xp yp+20 w150 h30 gplInputCard, Continuity Cardiologist:
	Gui, Add, Text, xp yp+14 cBlue w140 vpl_SCHcard, % pl_ProvSchCard
	Gui, Add, Text, xp yp+20 w150 h30 gplInputCard, Cardiac Surgeon:
	Gui, Add, Text, xp yp+14 cBlue w140 vpl_CSR, % pl_ProvCSR
	Gui, Add, Text, xp y140 w150 h28 , Last call:
	Gui, Add, Text, xp+50 yp w80 vCrdCall_L , % ((pl_Call_L) ? niceDate(pl_Call_L) : "---")		;substr(pl_Call_L,1,8)
	Gui, Add, Text, xp-50 yp+14 , Next call:
	Gui, Add, Text, xp+50 yp w80 vCrdCall_N, % ((pl_Call_N) ? niceDate(pl_Call_N) : "---")

	Gui, Add, CheckBox, x446 y34 w120 h20 Checked%pl_statCons% vpl_statCons gplInputNote, Consult
	Gui, Add, CheckBox, xp yp+20 w120 h20 Checked%pl_statTxp% vpl_statTxp gplInputNote, Transplant
	Gui, Add, CheckBox, xp yp+20 w120 h20 Checked%pl_statRes% vpl_statRes gplInputNote, Research
	Gui, Add, CheckBox, xp yp+20 w120 h20 Checked%pl_statScamp% vpl_statScamp gplInputNote, SCAMP
	Gui, Add, CheckBox, xp yp+20 w120 h20 Checked%pl_statMil% vpl_statMil gplInputNote, Military
	Gui, Add, CheckBox, xp yp+20 h20 Checked%pl_statPM% vpl_statPM gplInputNote, Pacemaker
	if (pl_statPM) {
		Gui, Font, s6
		Gui, Add, Button, x+m yp+3 h8 gplPMsettings, Settings
		Gui, Font
	}
	
	Gui, Add, Edit, x16 y132 w240 h40 gplInputNote vpl_misc, %pl_misc%
	Gui, Add, Edit, x26 y196 w540 h48 vpl_dxNotes gplInputNote, % pmNoteChk(pl_dxNotes)
	Gui, Add, Edit, x26 yp+70 w540 h48 vpl_dxCard gplInputNote, %pl_dxCard%
	Gui, Add, Edit, x26 yp+70 w540 h48 vpl_dxEP gplInputNote, %pl_dxEP%
	Gui, Add, Edit, x26 yp+70 w540 h48 vpl_dxSurg gplInputNote, %pl_dxSurg%
	Gui, Add, Edit, x26 yp+70 w540 h48 vpl_dxProb gplInputNote, %pl_dxProb%

	Gui, Add, Button, x36 y540 w160 h40 gplTasksList, Tasks/Todos
	Gui, Add, Button, xp+180 yp w160 h40 gplupd Disabledd, Update notes
	Gui, Add, Button, xp+180 yp w160 h40 gplSumm, Summary Notes
	Gui, Add, Button, x36 yp+44 w160 h40 v1 gplCORES, Patient History (CORES)
	Gui, Add, Button, xp+180 yp w160 h40 gplDataList Disabled, Data highlights
	Gui, Add, Button, xp+180 yp w160 h40 v2 gplMAR, Meds/Diet (CORES)

	Gui, Add, Button, x176 yp+44 w240 h40 gplSave, SAVE

	Gui, Font, Bold
	Gui, Add, GroupBox, x16 y14 w240 h160 , % pl_NameL . ", " . pl_NameF
	;Gui, Add, GroupBox, xp yp+110 w240 h50
	Gui, Add, GroupBox, x256 y14 w160 h118
	Gui, Add, GroupBox, xp yp+110 w160 h50 

	Gui, Add, GroupBox, x436 y14 w140 h160 , Status Flags
	Gui, Add, GroupBox, x16 y180 w560 h70 , Quick Notes
	Gui, Add, GroupBox, x16 yp+70 w560 h70 , Diagnoses && Problems
	Gui, Add, GroupBox, x16 yp+70 w560 h70 , EP diagnoses/problems
	Gui, Add, GroupBox, x16 yp+70 w560 h70 , Surgeries/Caths/Interventions
	Gui, Add, GroupBox, x16 yp+70 w560 h70 , Problem List
	Gui, Font, Normal

	Gui, Show, w600 h670, % "Patient Information - " pl_NameL
	plEditNote = 
	plEditStat =

Return
}

PatListCoGUI:
{
	refreshCurr(1)														; refresh Y with currlock
	holdlist(mrn)
	pl_demo := ""
		. "DOB: " pl_DOB 
		. "   Age: " (instr(pl_Age,"month")?RegExReplace(pl_Age,"i)month","mo"):instr(pl_Age,"year")?RegExReplace(pl_Age,"i)year","yr"):pl_Age) 
		. "   Sex: " substr(pl_Sex,1,1) "`n`n"
		. pl_Unit " :: " pl_Room "`n"
		. pl_Svc "`n`n"
		. "Admitted: " pl_Admit "`n"
	if !(pl_Unit) {																				; no unit means is an ad hoc entry
		pl_demo := "`nDemographics will be added`nwhen patient is admitted"
	}
	if !IsObject(y.selectSingleNode(pl_mrnstring "/diagnoses/coord")) {
		y.addElement("coord",pl_mrnstring "/diagnoses")
		y.addElement("stat", pl_mrnstring "/diagnoses/coord")
		y.addElement("note", pl_mrnstring "/diagnoses/coord")
	}
	Gui, plistG:Destroy
	Gui, plistG:Default
	Gui, Add, Text, x26 y38 w200 h80 , % pl_demo
	Gui, Add, Text, x266 y24 w150 h30 gplInputCard, Primary Cardiologist:
	Gui, Add, Text, xp yp+14 cBlue w140 vpl_card, % pl_ProvCard
	Gui, Add, Text, xp yp+20 w150 h30 gplInputCard, Continuity Cardiologist:
	Gui, Add, Text, xp yp+14 cBlue w140 vpl_SCHcard, % pl_ProvSchCard
	Gui, Add, Text, xp yp+20 w150 h30 gplInputCard, Cardiac Surgeon:
	Gui, Add, Text, xp yp+14 cBlue w140 vpl_CSR, % pl_ProvCSR
	Gui, Add, Text, xp y140 w150 h28 , Last call:
	Gui, Add, Text, xp+50 yp w80 vCrdCall_L , % ((pl_Call_L) ? niceDate(pl_Call_L) : "---")		;substr(pl_Call_L,1,8)
	Gui, Add, Text, xp-50 yp+14 , Next call:
	Gui, Add, Text, xp+50 yp w80 vCrdCall_N, % ((pl_Call_N) ? niceDate(pl_Call_N) : "---")

	Gui, Add, CheckBox, x446 y34 w120 h20 Checked%pl_statCoBag% vpl_statCoBag gplInputNote, Bag given
	Gui, Add, CheckBox, xp yp+20 w120 h20 Checked%pl_statCoPillow% vpl_statCoPillow gplInputNote, Heart pillow
	Gui, Add, CheckBox, xp yp+20 w120 h20 Checked%pl_statCoTour% vpl_statCoTour gplInputNote, Tour given
	;~ Gui, Add, CheckBox, xp yp+20 w120 h20 Checked%pl_statScamp% vpl_statScamp gplInputNote, SCAMP
	;~ Gui, Add, CheckBox, xp yp+20 w120 h20 Checked%pl_statMil% vpl_statMil gplInputNote, Military
	;~ Gui, Add, CheckBox, xp yp+20 h20 Checked%pl_statPM% vpl_statPM gplInputNote, Pacemaker
	
	Gui, Add, Edit, x16 y132 w240 h40 gplInputNote vpl_misc, %pl_misc%
	Gui, Add, Edit, x26 y196 w540 h60 vpl_noteCo gplInputNote, % pl_noteCo

	Gui, Add, Button, x176 yp+80 w240 h40 gplSave, SAVE
	
	Gui, Font, Bold
	Gui, Add, GroupBox, x16 y14 w240 h160 , % pl_NameL . ", " . pl_NameF
	;Gui, Add, GroupBox, xp yp+110 w240 h50
	Gui, Add, GroupBox, x256 y14 w160 h118
	Gui, Add, GroupBox, xp yp+110 w160 h50 

	Gui, Add, GroupBox, x436 y14 w140 h160 , Status Flags
	Gui, Add, GroupBox, x16 y180 w560 h82 , Coordination Notes
	
	Gui, Show, w600 AutoSize, % "Patient Information - " pl_NameL
	plEditNote = 
	plEditStat =
	plEditCoord =
	
Return	
}

plSave:
{
	Gui, plistG:Submit
	Gui, plistG:Destroy
	FormatTime, editdate, A_Now, yyyyMMddHHmmss
	if (plEditNote) {
		ReplacePatNode(pl_mrnstring "/diagnoses","notes",cleanString(pl_dxNotes))
		ReplacePatNode(pl_mrnstring "/diagnoses","card",cleanString(pl_dxCard))
		ReplacePatNode(pl_mrnstring "/diagnoses","ep",cleanString(pl_dxEP))
		ReplacePatNode(pl_mrnstring "/diagnoses","surg",cleanString(pl_dxSurg))
		ReplacePatNode(pl_mrnstring "/diagnoses","prob",cleanString(pl_dxProb))
		ReplacePatNode(pl_mrnstring "/diagnoses","misc",cleanString(pl_misc))
		y.setAtt(pl_mrnstring "/diagnoses", {ed: editdate})
		y.setAtt(pl_mrnstring "/diagnoses", {au: user})
		plEditNote = 
	}
	if (plEditsys) {
		if !isObject(y.selectSingleNode(pl_mrnstring "/ccSys")) {
			y.addElement("ccSys", pl_mrnstring)
		}
		for key,val in ccFields {
			ReplacePatNode(pl_mrnstring "/ccSys",val,cleanString(cc%val%))
		}
		y.setAtt(pl_mrnstring "/ccSys", {ed: editdate})
		y.setAtt(pl_mrnstring "/ccSys", {au: user})
		plEditSys = 
	}
	if (plEditStat) {
		if !IsObject(y.selectSingleNode(pl_mrnstring "/status")) {
			y.addElement("status", pl_mrnstring)
		}
		SetStatus(mrn,"status","cons",pl_statCons)
		SetStatus(mrn,"status","res",pl_statRes)
		SetStatus(mrn,"status","scamp",pl_statScamp)
		SetStatus(mrn,"prov","txp",pl_statTxp)
		SetStatus(mrn,"prov","mil",pl_statMil)
		SetStatus(mrn,"prov","pm",pl_statPM)
		y.setAtt(pl_mrnstring "/status", {ed: editdate})
		y.setAtt(pl_mrnstring "/status", {au: user})
		plEditStat = 
	}
	if (plEditCoord) {
		ReplacePatNode(pl_mrnstring "/diagnoses/coord","note",cleanString(pl_noteCo))
		SetStatus(mrn,"diagnoses/coord/status","bag",pl_statCoBag)
		SetStatus(mrn,"diagnoses/coord/status","pillow",pl_statCoPillow)
		SetStatus(mrn,"diagnoses/coord/status","tour",pl_statCoTour)
		plEditCoord =
	}
	WriteOut("/root","id[@mrn='" mrn "']")
	eventlog(mrn " saved.")
	holdlist(mrn,1)
	;Gui, teamL:Show
	if (adhoc) {
		adhoc = false
		return
	}
	gosub TeamList
Return
}

pListGGuiClose:
{
	if ((plEditNote) or (plEditSys) or (plEditStat)) {
		MsgBox, 308, Changes not saved!, % "Are you sure?`n`nYes = Close without saving.`nNo = Try again."
		IfMsgBox No
			return
	}
	holdlist(mrn,1)
	Gui, plistG:Destroy
	Gui, teamL:Show, Restore
return
}

plCORES:
{
	k := A_GuiControl
	StringReplace, pl_CORES, pl_CORES, <br>, `n, ALL
	StringReplace, pl_CORES, pl_CORES, <hr> ,--------------`n , ALL
	StringReplace, pl_cores, pl_cores, <b>, , All
	StringReplace, pl_cores, pl_cores, <i>, , All
	StringReplace, pl_cores, pl_cores, </b>, , All
	StringReplace, pl_cores, pl_cores, </i>, , All
	MsgBox,, % "CORES " y.selectSingleNode(pl_mrnstring "/info").getAttribute("date"), % pl_CORES
	return
}

plMAR:
{
	Gui, MarGui:Destroy
	CoresD := pl_MAR.getAttribute("date")
	tmpD := CoresD
	tmpD -= A_Now, Hours						; Datediff in hours
	if (tmpD < -24) {
		Gui, MarGui:Add, Tab, w420 h440, Meds
		Gui, MarGui:Add, Text, w400 h400 Center, % "`n`n`n`n"
			. "MAR data is older than 24 hrs`n`n"
			. "Update CORES data to refresh MAR"
	} else {
		Gui, MarGui:Add, Tab2, w420 h440, Cardiac Meds||Other Meds|Diet
		Gui, MarGui:Tab, Cardiac Meds
		Gui, MarGui:Add, ListView, Grid NoSortHdr w400 h400, Medication
		Gui, MarGui:Default
		LV_Add("", "=== DRIPS ===")
		plMARlist("drips","Arrhythmia")
		plMARlist("drips","Cardiac")
		LV_Add("","")
		LV_Add("", "=== SCHEDULED MEDS ===")
		plMARlist("meds","Arrhythmia")
		plMARlist("meds","Cardiac")
		LV_Add("","")
		LV_Add("", "=== PRN ===")
		plMARlist("prn","Arrhythmia")
		plMARlist("prn","Cardiac")
		Gui, MarGui:Tab, Other Meds
		Gui, MarGui:Add, ListView, Grid NoSortHdr w400 h400 , Medication
		Gui, MarGui:Default
		LV_Add("", "=== DRIPS ===")
		plMARlist("drips","Other")
		LV_Add("","")
		LV_Add("", "=== SCHEDULED MEDS ===")
		plMARlist("meds","Other")
		LV_Add("","")
		LV_Add("", "=== PRN ===")
		plMARlist("prn","Other")
		Gui, MarGui:Tab, Diet
		Gui, MarGui:Add, ListView, Grid NoSortHdr w400 h400, Diet
		Gui, MarGui:Default
		plMARlist("diet","Diet")
	}
	tmp := breakDate(CoresD)
	Gui, MarGui:Show, AutoSize, % "CORES " nicedate(CoresD) " @ " tmp.HH ":" tmp.Min ", MAR " plDiet()
	return
}

plMARlist(group,class) {
	global
	Loop, % (plMAR := y.selectNodes(pl_mrnstring "/MAR/" group "[@class='" class "']")).length {
		plMed := plMAR.item(A_Index-1).text
		plMed = %plMed%
		LV_Add("", plMed)
	}
	return
}

plDiet(txt:="") {
/*	Replaces DIET string in input txt string with most recent <dietStr>
	Uses [DIET: ... ] as the delimiter (could be broken if text box is replaced
	Adds [DIET:] if not present and <dietStr> is current
*/
	global pl, rtfList, pr
	if (rtfList) {
		MAR := pr.MAR
	} else {
		MAR := pl.MAR
	}
	if !IsObject(MAR.selectSingleNode("dietstr"))																; Skip if no DietStr data
		return txt
	
	; Check MAR date. currlist only keeps MAR from last date processCORES was run.
	marDate := MAR.getAttribute("date")
	
	DietStr := MAR.selectSingleNode("dietstr").text
	
	txt := instr(txt,"[DIET:") ? RegExReplace(txt, "\[DIET: .*\]", "[DIET: " DietStr "]") : "[DIET: " DietStr "] " txt
	Return txt
}

PtParse(mrn) {
	global y
	ob := Object()
	mrnstring := "/root/id[@mrn='" mrn "']"
	pl := y.selectSingleNode(mrnstring)
	ob.NameL := pl.selectSingleNode("demog/name_last").text
	ob.NameF := pl.selectSingleNode("demog/name_first").text
	ob.Sex := pl.selectSingleNode("demog/data/sex").text
	ob.DOB := pl.selectSingleNode("demog/data/dob").text
	ob.Age := pl.selectSingleNode("demog/data/age").text
	ob.Svc := pl.selectSingleNode("demog/data/service").text
	ob.Unit := pl.selectSingleNode("demog/data/unit").text
	ob.Room := pl.selectSingleNode("demog/data/room").text
	ob.Admit := pl.selectSingleNode("demog/data/admit").text
	ob.Attg := pl.selectSingleNode("demog/data/attg").text
	ob.dxEP := pl.selectSingleNode("diagnoses/ep").text
	ob.dxCard := pl.selectSingleNode("diagnoses/card").text
	ob.dxSurg := pl.selectSingleNode("diagnoses/surg").text
	ob.dxNotes := pl.selectSingleNode("diagnoses/notes").text
	ob.dxProb := pl.selectSingleNode("diagnoses/prob").text
	ob.misc := pl.selectSingleNode("diagnoses/misc").text
	ob.statCons := (pl.selectSingleNode("status").getAttribute("cons") == "on")
	ob.statRes := (pl.selectSingleNode("status").getAttribute("res") == "on")
	ob.statScamp := (pl.selectSingleNode("status").getAttribute("scamp") == "on")
	ob.callN := pl.selectSingleNode("plan/call").getAttribute("next")
	ob.callL := pl.selectSingleNode("plan/call").getAttribute("last")
	ob.callBy := pl.selectSingleNode("plan/call").getAttribute("by")
	ob.PM := pl.selectSingleNode("diagnoses/ep")
	ob.CORES := pl.selectSingleNode("info/hx").text
	ob.info := pl.selectSingleNode("info")
	ob.MAR := pl.selectSingleNode("MAR")
	ob.daily := pl.selectSingleNode("notes/daily")
	ob.ccSys := pl.selectSingleNode("ccSys")
	ob.ProvCard := y.getAtt(mrnstring "/prov","provCard")
	ob.ProvSchCard := y.getAtt(mrnstring "/prov","SchCard")
	ob.ProvCSR := y.getAtt(mrnstring "/prov","CSR")
	ob.ProvEP := y.getAtt(mrnstring "/prov","provEP")
	ob.ProvPCP := y.getAtt(mrnstring "/prov","provPCP")
	ob.statPM := (pl.selectSingleNode("prov").getAttribute("pm") == "on")
	ob.statMil := (pl.selectSingleNode("prov").getAttribute("mil") == "on")
	ob.statTxp := (pl.selectSingleNode("prov").getAttribute("txp") == "on")
	ob.statCoBag := (pl.selectSingleNode("diagnoses/coord/stat").getAttribute("bag") == "on")
	ob.statCoPillow := (pl.selectSingleNode("diagnoses/coord/stat").getAttribute("pillow") == "on")
	ob.statCoTour := (pl.selectSingleNode("diagnoses/coord/stat").getAttribute("tour") == "on") 
	ob.noteCoord := pl.selectSingleNode("diagnoses/coord/note").text
	
	return ob
}

SetStatus(mrn,node,att,value) {
	global y, user
	k := y.selectSingleNode("/root/id[@mrn='" mrn "']/" node)
	k.setAttribute(att, ((value=1) ? "on" : ""))
	FormatTime, tmpdate, A_Now, yyyyMMddHHmmss
	k.setAttribute("ed", tmpdate)
	k.setAttribute("au", user)
}

plPMsettings:
{
	PM_chk := CMsgBox("Which device type?",""
		, "*&Temporary|"
		. "&Permanent"
		,"Q","")
	if (PM_chk="Temporary") {
		loop % (i := y.selectNodes(pl_MRNstring "/pacing/temp")).length {				; get <pacing> element into pl_PM
			j := i.item(A_Index-1)														; read through last <pacing/leads> element
		}
		pmDate := breakDate(j.getAttribute("ed"))
		PmSet := Object()																; clear pmSet object
		Loop % (i := j.selectNodes("*")).length {
			k := i.item(A_Index-1)														; read each element <mode>, <LRL>, etc
			PmSet[k.nodeName] := k.text													; and set value for pmSet.mode, pmSet.LRL, etc
		}
		
		Gui, PmGui:Destroy
		Gui, PmGui:Default
		Gui, Add, Text, Center, Pacemaker Settings
		Gui, Add, Text, Center, % (pmDate.MM) ? pmDate.MM "/" pmDate.DD "/" pmDate.YYYY " @ " pmDate.HH ":" pmDate.min ":" pmDate.sec : ""
		Gui, Add, Text, Section, MODE
		Gui, Add, Text, xm yp+22, LRL
		Gui, Add, Text, xm yp+22, URL
		Gui, Add, Edit, ys-2 w40 vPmSet_mode, % PmSet.mode
		Gui, Add, Edit, yp+22 w40 vPmSet_LRL, % PmSet.LRL
		Gui, Add, Edit, yp+22 w40 vPmSet_URL, % PmSet.URL
		
		Gui, Add, Text, xm+120 ys, AVI
		Gui, Add, Text, xp yp+22, PVARP
		Gui, Add, Edit, ys-2 w40 vPmSet_AVI, % PmSet.AVI
		Gui, Add, Edit, yp+22 w40 vPmSet_PVARP, % PmSet.PVARP
		
		Gui, add, text, xm yp+60 w210 h1 0x7  ;Horizontal Line > Black
		
		Gui, Font, Bold
		Gui, Add, Text, xm yp+22, Tested
		Gui, Add, Text, xm+120 yp, Programmed
		
		Gui, Font, Normal
		Gui, Add, Text, Section xm yp+22, Ap (mA)
		Gui, Add, Text, xm yp+22, As (mV)
		Gui, Add, Text, xm yp+22, Vp (mA)
		Gui, Add, Text, xm yp+22, Vs (mV)
		Gui, Add, Edit, ys-2 w40 vPmSet_ApThr, % PmSet.ApThr
		Gui, Add, Edit, yp+22 w40 vPmSet_AsThr, % PmSet.AsThr
		Gui, Add, Edit, yp+22 w40 vPmSet_VpThr, % PmSet.VpThr
		Gui, Add, Edit, yp+22 w40 vPmSet_VsThr, % PmSet.VsThr
		
		Gui, Add, Text, xm+120 ys, Ap (mA)
		Gui, Add, Text, xp yp+22, As (mV)
		Gui, Add, Text, xp yp+22, Vp (mA)
		Gui, Add, Text, xp yp+22, Vs (mV)
		Gui, Add, Edit, ys-2 w40 vPmSet_Ap, % PmSet.Ap
		Gui, Add, Edit, yp+22 w40 vPmSet_As, % PmSet.As
		Gui, Add, Edit, yp+22 w40 vPmSet_Vp, % PmSet.Vp
		Gui, Add, Edit, yp+22 w40 vPmSet_Vs, % PmSet.Vs
		
		Gui, Add, Edit, xm yp+30 w210 r2 vPmSet_notes, % PmSet.notes
		Gui, Add, Button, xm w210 Center gplPMsave, Save values
		
		Gui, -MinimizeBox -MaximizeBox
		Gui, Show, AutoSize, % PM_chk
		return
	}
	else if (PM_chk="Permanent") {
		pm_dev := y.selectSingleNode(pl_MRNstring "/diagnoses/device")
		pm_IPG := pm_dev.getAttribute("model")
		pmDate := breakDate(pm_dev.getAttribute("ed"))
		PmSet := Object()																; clear pmSet object
		Loop % (i := pm_dev.selectNodes("*")).length {
			k := i.item(A_Index-1)														; read each element <mode>, <LRL>, etc
			PmSet[k.nodeName] := k.text													; and set value for pmSet.mode, pmSet.LRL, etc
		}
		
		Gui, PmGui:Destroy
		Gui, PmGui:Default
		Gui, Add, Text, Center, Pacemaker Settings
		Gui, Add, Text, Center, % (pmDate.MM) ? pmDate.MM "/" pmDate.DD "/" pmDate.YYYY " @ " pmDate.HH ":" pmDate.min ":" pmDate.sec : ""
		
		Gui, Add, Text, Section xm yp+22, MODEL
		Gui, Add, Edit, ys-2 w160 vPmSet_model, % pm_IPG
		
		Gui, Add, Text, Section xm, MODE
		Gui, Add, Text, xm yp+22, LRL
		Gui, Add, Text, xm yp+22, URL
		Gui, Add, Edit, ys-2 w40 vPmSet_mode, % PmSet.mode
		Gui, Add, Edit, yp+22 w40 vPmSet_LRL, % PmSet.LRL
		Gui, Add, Edit, yp+22 w40 vPmSet_URL, % PmSet.URL
		
		Gui, Add, Text, xm+120 ys, AVI
		Gui, Add, Text, xp yp+22, PVARP
		Gui, Add, Edit, ys-2 w40 vPmSet_AVI, % PmSet.AVI
		Gui, Add, Edit, yp+22 w40 vPmSet_PVARP, % PmSet.PVARP
		
		Gui, add, text, xm yp+60 w210 h1 0x7  ;Horizontal Line > Black
		
		Gui, Font, Bold
		Gui, Add, Text, xm yp+22, Tested
		Gui, Add, Text, xm+120 yp, Programmed
		
		Gui, Font, Normal
		Gui, Add, Text, Section xm yp+22, Ap (V@ms)
		Gui, Add, Text, xm yp+22, As (mV)
		Gui, Add, Text, xm yp+22, Vp (V@ms)
		Gui, Add, Text, xm yp+22, Vs (mV)
		Gui, Add, Edit, ys-2 w40 vPmSet_ApThr, % PmSet.ApThr
		Gui, Add, Edit, yp+22 w40 vPmSet_AsThr, % PmSet.AsThr
		Gui, Add, Edit, yp+22 w40 vPmSet_VpThr, % PmSet.VpThr
		Gui, Add, Edit, yp+22 w40 vPmSet_VsThr, % PmSet.VsThr
		
		Gui, Add, Text, xm+120 ys, Ap (V@ms)
		Gui, Add, Text, xp yp+22, As (mV)
		Gui, Add, Text, xp yp+22, Vp (V@ms)
		Gui, Add, Text, xp yp+22, Vs (mV)
		Gui, Add, Edit, ys-2 w40 vPmSet_Ap, % PmSet.Ap
		Gui, Add, Edit, yp+22 w40 vPmSet_As, % PmSet.As
		Gui, Add, Edit, yp+22 w40 vPmSet_Vp, % PmSet.Vp
		Gui, Add, Edit, yp+22 w40 vPmSet_Vs, % PmSet.Vs
		
		Gui, Add, Edit, xm yp+30 w210 r2 vPmSet_notes, % PmSet.notes
		Gui, Add, Button, xm w210 Center gplPMsave, Save values
		
		Gui, -MinimizeBox -MaximizeBox
		Gui, Show, AutoSize, % PM_chk
		return
	} 
	MsgBox Exit
	return
}

pmGuiGuiClose:
{
	Gui, PmGUI:Destroy
return
}

plPMsave:
{
	Gui, PmGui:Submit
	if (PM_chk="Temporary") {
		if !IsObject(y.selectSingleNode(pl_MRNstring "/pacing")) {
			y.addElement("pacing", pl_MRNstring)										; Add <pacing> element if necessary
		}
		pmNow := A_Now
		pmNowString := pl_MRNstring "/pacing/temp[@ed='" pmNow "']"
		y.addElement("temp", pl_MRNstring "/pacing", {ed:pmNow, au:user})		; and a <leads> element
			y.addElement("mode", pmNowString, PmSet_mode)
			y.addElement("LRL", pmNowString, PmSet_LRL)
			y.addElement("URL", pmNowString, PmSet_URL)
			y.addElement("AVI", pmNowString, PmSet_AVI)
			y.addElement("PVARP", pmNowString, PmSet_PVARP)
			y.addElement("ApThr", pmNowString, PmSet_ApThr)
			y.addElement("AsThr", pmNowString, PmSet_AsThr)
			y.addElement("VpThr", pmNowString, PmSet_VpThr)
			y.addElement("VsThr", pmNowString, PmSet_VsThr)
			y.addElement("Ap", pmNowString, PmSet_Ap)
			y.addElement("As", pmNowString, PmSet_As)
			y.addElement("Vp", pmNowString, PmSet_Vp)
			y.addElement("Vs", pmNowString, PmSet_Vs)
			y.addElement("notes", pmNowString, PmSet_notes)
		WriteOut(pl_mrnstring, "pacing")
	}
	if (PM_chk="Permanent") {
		if IsObject(y.selectSingleNode(pl_MRNstring "/diagnoses/device")) {			; Remove node if present
			removeNode(pl_MRNstring "/diagnoses/device")
		}
		pmNowString := pl_MRNstring "/diagnoses/device"
		y.addElement("device", pl_MRNstring "/diagnoses", {ed:A_now, au:user, model:PmSet_model, SN:PmSet_serial})		; Add <dx/ep/device> element
			y.addElement("mode", pmNowString, PmSet_mode)
			y.addElement("LRL", pmNowString, PmSet_LRL)
			y.addElement("URL", pmNowString, PmSet_URL)
			y.addElement("AVI", pmNowString, PmSet_AVI)
			y.addElement("PVARP", pmNowString, PmSet_PVARP)
			y.addElement("ApThr", pmNowString, PmSet_ApThr)
			y.addElement("AsThr", pmNowString, PmSet_AsThr)
			y.addElement("VpThr", pmNowString, PmSet_VpThr)
			y.addElement("VsThr", pmNowString, PmSet_VsThr)
			y.addElement("Ap", pmNowString, PmSet_Ap)
			y.addElement("As", pmNowString, PmSet_As)
			y.addElement("Vp", pmNowString, PmSet_Vp)
			y.addElement("Vs", pmNowString, PmSet_Vs)
			y.addElement("notes", pmNowString, PmSet_notes)
		WriteOut(pl_MRNstring "/diagnoses", "device")
	}
	eventlog(mrn " " pm_chk " pacer settings changed.")
	return
}

pmNoteChk(txt) {
	global y, pl_MRNstring
	if IsObject(y.selectSingleNode(pl_MRNstring "/pacing")) {
		loop % (i := y.selectNodes(pl_MRNstring "/pacing/temp")).length {				; get <pacing> element into pl_PM
			j := i.item(A_Index-1)														; read through last <pacing/leads> element
		}
		pl_pmStr := pl_MRNstring "/pacing/temp[@ed='" j.getAttribute("ed") "']"
		
		pm_str := "[PM Temp " y.getText(pl_pmStr "/mode") " "
				. ((tmp:=y.getText(pl_pmStr "/LRL")) ? tmp : "")
				. ((tmp:=y.getText(pl_pmStr "/URL")) ? "-" tmp : "")
				. ", "
				. ((tmp:=y.getText(pl_pmStr "/ApThr")) ? tmp : "")
				. ((tmp:=y.getText(pl_pmStr "/Ap")) ? " => " tmp " mA" : "")
				. ((tmp:=y.getText(pl_pmStr "/VpThr")) ? tmp : "")
				. ((tmp:=y.getText(pl_pmStr "/Vp")) ? " => " tmp " mA" : "")
				. "] "
	}
	if IsObject(y.selectSingleNode(pl_MRNstring "/diagnoses/device")) {
		pl_pmStr := pl_MRNstring "/diagnoses/device"
		pm_str := "[PM " y.getText(pl_pmStr "/mode") " "
				. ((tmp:=y.getText(pl_pmStr "/LRL")) ? tmp : "")
				. ((tmp:=y.getText(pl_pmStr "/URL")) ? "-" tmp : "")
				. "] "
	}
	txt := pm_str RegExReplace(txt, "\[PM .*\] ")
Return txt	
}