plInputCard:
{
	CrdType:=A_GuiControl
	if (isARNP) {
		if (instr(CrdType,"card")) {
			ed_Crd := pl_ProvCard
			ed_type := "provCard"
			ed_var := "pl_Card"
		} else if (instr(CrdType,"CSR")) {
			ed_Crd := pl_ProvCSR
			ed_type := "CSR"
			ed_var := "pl_CSR"
		}
	} else {
		if (InStr(CrdType,"primary")) {
			ed_Crd := pl_ProvCard									; provider value
			ed_type := "provCard"									; provider attribute name
			ed_var := "pl_Card"										; GUI variable name
		} else if (InStr(CrdType,"continuity")) {
			ed_Crd := pl_ProvSchCard
			ed_type := "SchCard"
			ed_var := "pl_SCHcard"
		} else if (InStr(CrdType,"surgeon")) {
			ed_Crd := pl_ProvCSR
			ed_type := "CSR"
			ed_var := "pl_CSR"
		}
	}
	InputBox, ed_Crd, % "Change " CrdType, %ed_Crd%,,,,,,,,%ed_Crd%
	if (ed_Crd="") {
		MsgBox, 262180, % CrdType, % "Really clear this provider?"
		IfMsgBox, Yes
		{
			if !(IsObject(y.selectSingleNode(pl_mrnstring "/prov"))) {
				y.addElement("prov", pl_mrnstring)
			}
			FormatTime, editdate, A_Now, yyyyMMddHHmmss
			y.selectSingleNode(pl_mrnstring "/prov").setAttribute(ed_type,ed_Crd)
			y.setAtt(pl_mrnstring "/prov", {ed: editdate},{au: user})
			WriteOut(pl_mrnstring,"prov")
			eventlog(mrn " " CrdType " changed.")
			GuiControl, plistG:Text, %ed_var%, %ed_Crd%
			Gui, plistG:Submit, NoHide
		}
		return
	}
	tmpCrd := checkCrd(ed_Crd)
	if (tmpCrd.fuzz=0) {										; Perfect match found
		ed_Crd := tmpCrd.best
	} else {													; less than perfect
		MsgBox, 262180, % CrdType
			, % "Did you mean: " tmpCrd.best "?`n`n`n"
			. "YES = change to """ tmpCrd.best """`n`n"
			. "NO = keep """ ed_Crd """"
		IfMsgBox, Yes
			ed_Crd := tmpCrd.best
	}
	if (ed_type="SchCard") and !(checkCrd(ed_Crd).group="SCH") {
		MsgBox, 16, Provider error, Must be an SCH main campus provider!
		return
	}

	if !(IsObject(y.selectSingleNode(pl_mrnstring "/prov"))) {
		y.addElement("prov", pl_mrnstring)
	}
	FormatTime, editdate, A_Now, yyyyMMddHHmmss
	y.selectSingleNode(pl_mrnstring "/prov").setAttribute(ed_type,ed_Crd)
	y.setAtt(pl_mrnstring "/prov", {ed: editdate},{au: user})
	WriteOut(pl_mrnstring,"prov")
	eventlog(mrn " " CrdType " changed.")
	GuiControl, plistG:Text, %ed_var%, %ed_Crd%
	Gui, plistG:Submit, NoHide
	Return
}

checkCrd(x) {
/*	Compares pl_ProvCard vs array of cardiologists
	x = name
	returns array[match score, best match, best match group]
*/
	global Docs
	fuzz := 1
	for rowidx,row in Docs
	{
		for colidx,item in row
		{
			res := fuzzysearch(x,item)
			if (res<fuzz) {
				fuzz := res
				best:=item
				group:=rowidx
			}
		}
	}
	return {"fuzz":fuzz,"best":best,"group":group}
}

plCallCard:
{
	if (instr(grTab:=A_GuiControl,"callGrp")) {
		Gui, cList:Listview, % grTab
		LV_GetText(mrn, A_EventInfo,1)
		LV_GetText(plname, A_EventInfo,2)
		LV_GetText(plProv, A_EventInfo,3)
	}
	if (grTab="Last call:") {
		tmpCrd:=checkCrd(pl_ProvCard)
		if (tmpCrd.fuzz=0)
			plProv:=tmpCrd.best
	}
	if (mrn="MRN") 								; blank field
		return
	if (plProv="") {
		return
	}
	grTab := ObjHasValue(outGrpV,grTab)
	
	pl_mrnstring := "/root/id[@mrn='" mrn "']"
	pl := ptParse(mrn)
	tmpL := parseDate(pl.callL)
	Gui, cCard:Destroy
	Gui, cCard:Add, Text, x20 y30 , % "Cardiologist: `t" plProv
	Gui, cCard:Add, Text, , % "Last call: `t" ((pl.callL) ? niceDate(pl.callL) " @ " tmpL.hrmin " by " pl.callBy : "")
	Gui, cCard:Add, Text, , % "Next call: `t" ((pl.callN) ? niceDate(pl.callN) : "")
	Gui, cCard:Add, GroupBox, x10 y10 w250 h100, % plname
	Gui, cCard:Add, Button, w250 gplCallSet, Set/Reset call tasks
	Gui, cCard:Add, Button, w250 gplCardCon, Contact cardiologist
	Gui, cCard:Show, AutoSize, Call center
Return
}
	
plCallset:
{
	if !IsObject(y.selectSingleNode(pl_mrnstring "/plan/call"))
		y.addElement("call", pl_mrnstring "/plan")
	tmp:=CMsgBox("Set call tasks"
		,"`b Start call reminder tomorrow`n`n`b Select date for next reminder`n`n`b Remove existing call reminder`n`n`b Don't do anything","Tomorrow|Select|Remove|Cancel")
	if (tmp="Tomorrow") {
		tmpN = 
		tmpN += 1, day
		tmpN := substr(tmpN,1,8)
		y.selectSingleNode(pl_mrnstring "/plan/call").setAttribute("next", tmpN)				; A_now for tomorrow
		WriteOut(pl_mrnstring "/plan","call")
		eventlog(mrn " Call sequence initiated.")
	}
	if (tmp="Select") {
		MsgBox Working on it!
	}
	if (tmp="Remove") {
		y.selectSingleNode(pl_mrnstring "/plan/call").setAttribute("next", "")
		WriteOut(pl_mrnstring "/plan","call")
		eventlog(mrn " Call sequence removed.")
	}
	if (tmp="Cancel") {
		return
	}
	;GuiControl, 9:+Redraw, % "CLV" substr(grTab,0,1)
	gosub CallList
	gosub plCallCard
return
}

plCardCon:
{
	if !IsObject(y.selectSingleNode(pl_mrnstring "/plan/call"))
		y.addElement("call", pl_mrnstring "/plan")
	tmpGrp := tmpPrv :=
	
	Loop, Read, outdocs.csv
	{
		tmp := tmp0 := tmp1 := tmp2 := tmp3 := tmp4 := ""
		tmpline := A_LoopReadLine
		StringSplit, tmp, tmpline, `, , `"
		if ((tmp1) and (tmp2="" and tmp3="" and tmp4="")) {
			tmpGrp := tmp1
			continue
		}
		StringSplit, tmpPrv, tmp1, %A_Space%
		tmpPrv := substr(tmpPrv1,1,1) . ". " . tmpPrv2
		if (tmpPrv=plProv) {
			plProvGroup := tmpGrp
			plProvName := tmp1
			plProvPh1 := tmp2
			plProvPh2 := tmp3
			plProvEml := tmp4
			break
		}
	}
	provCall:=CMsgBox(plProvName " " plProvGroup
		, "Office: `t" plProvPh1 "`n`nCell: `t" plProvPh2 "`n`nEmail: `t" plProvEml
		, "call made" ((CisEnvt) ? "" : "|send email"))									; Don't include email button in CIS envt
	if (instr(provCall,"call")) {
		gosub plCallMade
	}
	if (instr(provCall,"email")) {
		plEml := ComObjCreate("Outlook.Application").CreateItem(0)						; Create item [0]
		plEml.BodyFormat := 2															; HTML format
		
		plEml.To := plProvEml
		plEml.Subject := "SCH Heart Center patient update - " substr(pl.nameF,1,1) " " substr(pl.nameL,1,1)
		plEml.Display																	; Must display first to get default signature
		plEml.HTMLBody := pl.nameF " " substr(pl.nameL,1,1) 
			. " (Admitted " strX(pl.admit,,0,0," ",1,1) ")"
			. " Diagnosis: " RegExReplace(pl.dxCard,"[\r\n]"," * ")
			. plEml.HTMLBody															; Prepend to existing default message
		
		gosub plCallMade
	}
	gosub plCallCard
return
}

plCallMade:
{
	ctype := strX(provCall,"",1,0," ",1,1)
	tmp := A_now
	tmp += 7, Days
	y.selectSingleNode(pl_mrnstring "/plan/call").setAttribute("next", substr(tmp,1,8))
	y.selectSingleNode(pl_mrnstring "/plan/call").setAttribute("last", A_now)
	y.selectSingleNode(pl_mrnstring "/plan/call").setAttribute("by", user)
	if !IsObject(y.selectSingleNode(pl_mrnstring "/plan/done")) {
		y.addElement("done", pl_mrnstring "/plan")
	}
	y.addElement(ctype, pl_mrnstring "/plan/done", {done: A_now, by: user})
	WriteOut(pl_mrnstring,"plan")
	tmp := pl.callN
	tmp -= A_Now, Days
	;plCall -= substr(A_Now,1,8), Days
	eventlog(mrn " Contact " ctype " to " plProv "." . ((pl.callN) ? " Due " niceDate(pl.callN) " (" tmp ")" : ""))
	gosub CallList
	return
}

