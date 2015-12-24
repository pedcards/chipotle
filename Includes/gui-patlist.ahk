PatListGet:
{
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
	if (isARNP) {
		gosub PatListGUIcc
	} else {
		gosub PatListGUI
	}
	return
}
	
PatListGUI:
{
	pl_demo := ""
		. "DOB: " pl_DOB 
		. "   Age: " (instr(pl_Age,"month")?RegExReplace(pl_Age,"i)month","mo"):instr(pl_Age,"year")?RegExReplace(pl_Age,"i)year","yr"):pl_Age) 
		. "   Sex: " substr(pl_Sex,1,1) "`n`n"
		. pl_Unit " :: " pl_Room "`n"
		. pl_Svc "`n`n"
		. "Admitted: " pl_Admit "`n"
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
	Gui, Add, CheckBox, x446 yp+20 w120 h20 Checked%pl_statTxp% vpl_statTxp gplInputNote, Transplant
	Gui, Add, CheckBox, x446 yp+20 w120 h20 Checked%pl_statRes% vpl_statRes gplInputNote, Research
	Gui, Add, CheckBox, x446 yp+20 w120 h20 Checked%pl_statScamp% vpl_statScamp gplInputNote, SCAMP
	Gui, Add, CheckBox, x446 yp+20 w120 h20 Checked%pl_statMil% vpl_statMil gplInputNote, Military

	Gui, Add, Edit, x16 y132 w240 h40 gplInputNote vpl_misc, %pl_misc%
	Gui, Add, Edit, x26 y196 w540 h48 vpl_dxNotes gplInputNote, %pl_dxNotes%
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
		y.setAtt(pl_mrnstring "/status", {ed: editdate})
		y.setAtt(pl_mrnstring "/status", {au: user})
		plEditStat = 
	}
	WriteOut("/root","id[@mrn='" mrn "']")
	eventlog(mrn " saved.")
	;Gui, teamL:Show
	if (adhoc) {
		adhoc = false
		return
	}
	gosub TeamList
Return
}

pListGGuiClose:
	if ((plEditNote) or (plEditSys) or (plEditStat)) {
		MsgBox, 308, Changes not saved!, % "Are you sure?`n`nYes = Close without saving.`nNo = Try again."
		IfMsgBox No
			return
	}
	Gui, plistG:Destroy
	Gui, teamL:Show, Restore
return

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
		Gui, MarGui:Add, Tab2, w420 h440, Cardiac Meds||Other Meds
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
	}
	tmp := breakDate(CoresD)
	Gui, MarGui:Show, AutoSize, % "CORES " nicedate(CoresD) " @ " tmp.HH ":" tmp.Min
	return
}

plMARlist(group,class) {
	global
	Loop, % (plMAR := y.selectNodes(pl_mrnstring "/MAR/" group "[@class='" class "']")).length {
		plMed := plMAR.item(A_Index-1).text
		plMed = %plMed%
		LV_Add("", plMed)
	}
	;LV_ModifyCol()
}

PtParse(mrn) {
	global y
	mrnstring := "/root/id[@mrn='" mrn "']"
	pl := y.selectSingleNode(mrnstring)
	return {"NameL":pl.selectSingleNode("demog/name_last").text
		, "NameF":pl.selectSingleNode("demog/name_first").text
		, "Sex":pl.selectSingleNode("demog/data/sex").text
		, "DOB":pl.selectSingleNode("demog/data/dob").text
		, "Age":pl.selectSingleNode("demog/data/age").text
		, "Svc":pl.selectSingleNode("demog/data/service").text
		, "Unit":pl.selectSingleNode("demog/data/unit").text
		, "Room":pl.selectSingleNode("demog/data/room").text
		, "Admit":pl.selectSingleNode("demog/data/admit").text
		, "Attg":pl.selectSingleNode("demog/data/attg").text
		, "dxCard":pl.selectSingleNode("diagnoses/card").text
		, "dxEP":pl.selectSingleNode("diagnoses/ep").text
		, "dxSurg":pl.selectSingleNode("diagnoses/surg").text
		, "dxNotes":pl.selectSingleNode("diagnoses/notes").text
		, "dxProb":pl.selectSingleNode("diagnoses/prob").text
		, "misc":pl.selectSingleNode("diagnoses/misc").text
		, "statCons":(pl.selectSingleNode("status").getAttribute("cons") == "on")
		, "statRes":(pl.selectSingleNode("status").getAttribute("res") == "on")
		, "statScamp":(pl.selectSingleNode("status").getAttribute("scamp") == "on")
		, "callN":pl.selectSingleNode("plan/call").getAttribute("next")
		, "callL":pl.selectSingleNode("plan/call").getAttribute("last")
		, "callBy":pl.selectSingleNode("plan/call").getAttribute("by")
		, "CORES":pl.selectSingleNode("info/hx").text
		, "info":pl.selectSingleNode("info")
		, "MAR":pl.selectSingleNode("MAR")
		, "daily":pl.selectSingleNode("notes/daily")
		, "ccSys":pl.selectSingleNode("ccSys")
		, "ProvCard":y.getAtt(mrnstring "/prov","provCard")
		, "ProvSchCard":y.getAtt(mrnstring "/prov","SchCard")
		, "ProvCSR":y.getAtt(mrnstring "/prov","CSR")
		, "ProvEP":y.getAtt(mrnstring "/prov","provEP")
		, "ProvPCP":y.getAtt(mrnstring "/prov","provPCP")
		, "statMil":(pl.selectSingleNode("prov").getAttribute("mil") == "on")
		, "statTxp":(pl.selectSingleNode("prov").getAttribute("txp") == "on")}
}

SetStatus(mrn,node,att,value) {
	global y, user
	k := y.selectSingleNode("/root/id[@mrn='" mrn "']/" node)
	k.setAttribute(att, ((value=1) ? "on" : ""))
	FormatTime, tmpdate, A_Now, yyyyMMddHHmmss
	k.setAttribute("ed", tmpdate)
	k.setAttribute("au", user)
}

