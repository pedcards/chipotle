plInputNote:
{
	;~ if (isCICU) {
		;~ MsgBox % "Cannot edit in CICU mode"
		;~ gosub PatListGet
		;~ return
	;~ }
	;~ if (isARNP) {
		;~ MsgBox % "Cannot edit in ARNP mode"
		;~ gosub PatListGet
		;~ return
	;~ }
	i:=A_GuiControl
	if (substr(i,4,4)="stat") {							; var name "pl_statCons"
		plEditStat = true
		if (i="pl_statPM") {
			GuiControlGet, j, , pl_statPM
			GuiControl, % (j)?"Enable":"Disable", Settings
		}
		eventlog(mrn " status " i " changed.")
		return
	}
	if (substr(i,1,2))="cc" {							; var name "ccFEN"
		if !(plEditSys) {
			eventlog(mrn " " i " changed.")
		}
		plEditSys = true
	} else {											; otherwise editing dx notes
		if !(plEditNote) {
			eventlog(mrn " " i " note changed.")
		}
		plEditNote = true
	}
Return
}

plSumm:
{
	formType := "S"
	formName := "summary"
	noteNode := pl_mrnstring "/notes/weekly/summary"
	noteName := "Weekly Notes"
	gosub plUpdSum
	return
}

plUpd:
{
	formType := "U"
	formName := "note"
	noteNode := pl_mrnstring "/notes/updates/note"
	noteName := "Updates Notes"
	gosub plUpdSum
	return
}

plUpdSum:
{
	Gui, updL:Destroy
	Gui, updL:Default
	Gui, Add, ListView, -Multi Grid NoSortHdr W780 gplNoteEdit vUpdateLV, Date|Note|DateIdx|Created
	i:=0
	Loop, % (plUpdates := y.selectNodes(noteNode)).length {
		plUpd := plUpdates.item(i:=A_Index-1)
		plUpdTS := plUpd.getAttribute("created")
		plUpdD := plUpd.getAttribute("date")
		tmpD := breakdate(plUpdD)
		plUpdDate := tmpD.MM "/" tmpD.DD "-" tmpD.HH . tmpD.min
		LV_Add("", plUpdDate, plUpd.text, plUpdD, plUpdTS)
	}
	LV_ModifyCol()  ; Auto-size each column to fit its contents.
	;LV_ModifyCol(1, "Integer")
	LV_ModifyCol(2, 680)
	LV_ModifyCol(3,"0 Sort")						; Sort by this hidden column (w0)
	LV_ModifyCol(4,0)
	i+=1
	if i>25
		i:=25
	if i<4
		i:=4
	tlvH := i*24
	GuiControl, Move, UpdateLV, % "H" tlvH
	Gui, Add, Button, % "w780 x10 y" tlvH+10 " gplNoteEdit", ADD A NOTE...
	Gui, Show, % "W800 H" tlvH+35 , % pl_nameL " - " noteName
	Gui, plistG:Hide
	Return
}

updLGuiClose:
	Gui, updL:Destroy
	Gui, plistG:Restore
	Return

plNoteEdit:
{
	LV_GetText(tmpDate, A_EventInfo,1)					; displayed date
	LV_GetText(tmp, A_EventInfo,2)						; text
	LV_GetText(tmpD, A_EventInfo,3)						; full date (for indexing)
	LV_GetText(tmpTS, A_EventInfo,4)					; created timestamp of edit (necessary?)
	
	if (tmpD="DateIdx" and A_GuiControl="UpdateLV") {
		return											; click on blank area is null
	}
	formW:=700, formR:=5
	;formtype:="S"
	gosub plForm
	
	formMrnStr := noteNode "[@created='" formTS "']"
	formParStr := strX(noteNode,"",1,0,"/",0,1)
	formChildName := strX(noteNode,"/",0,1)
	formParName := strX(formParStr,"/",0,1)
	
	if (formDel) {
		MsgBox, 20, Confirm, Delete this note?
		IfMsgBox Yes 
		{
			if !IsObject(pl_mrnstring "/trash") {
				y.addElement("trash", pl_mrnstring)
				WriteOut(pl_mrnstring, "trash")
			}
			y.selectSingleNode(formMrnStr).setAttribute("del", A_Now)
			y.selectSingleNode(formMrnStr).setAttribute("au", user)
			locnode := y.selectSingleNode(formMrnStr)
			y.selectSingleNode(formParStr).removeChild(locnode)
			WriteOut(pl_mrnstring "/notes",formParName)
			y.selectSingleNode(pl_mrnstring "/trash").appendChild(locnode.cloneNode(true))
			WriteOut(pl_mrnstring, "trash")
			eventlog(mrn " " noteName " " tmpD " deleted.")
			gosub plUpdSum
		}
		Return
	}
	if !(formedit=true) {
		return
	}
	if !(formsave=true) {
		return
	}
	formTxt := RegExReplace(formTxt,"[^[:print:]]")							; filter esc chars from entry
	if !IsObject(y.selectSingleNode(pl_mrnstring "/notes")) {
		y.addElement("notes", pl_mrnstring)
		WriteOut(pl_mrnstring, "notes")
	}
	if !IsObject(y.selectSingleNode(noteNode)) {
		y.addElement(formParName, pl_mrnstring "/notes")
		WriteOut(pl_mrnstring "/notes",formParName)
	}
	if (formnew) {
		y.addelement(formName, formParStr, {date: formDT, created: formTS}, formTxt)
	} else {
		y.selectSingleNode(formMrnStr).childNodes[0].nodevalue := formTxt
		y.selectSingleNode(formMrnStr).setAttribute("date", formDT)
	}
	y.selectSingleNode(formMrnStr).setAttribute("ed", A_Now)
	y.selectSingleNode(formMrnStr).setAttribute("au", user)
	WriteOut(pl_mrnstring "/notes",formParName)
	eventlog(mrn " " noteName " updated.")
	gosub plUpdSum
Return
}

plForm:
{
/*	type = which form: summ or task
	width = window width
	rows = number of text rows
	txt = default text to edit. if
	date = date of this form, if empty default to today
	time = time of this form, if empty default to now
	btnpress = returns which button pressed
	
	function returns results in:
	formTXT = text result
	formDT = date +/- time for the entry
	formTS = timestamp (if needed)
*/
	if (formW="")
		formW:=720
	if (formR="")
		formR:=5
	formnew:="", formEdit:="", formSave:="", formDel:=""
	formtype := SubStr(formtype,1,1)
	if (formtype="S") {
		FormHide:="updL"
	}
	if (formtype="U") {
		FormHide:="updL"
	}
	if (formtype="T") {
		FormHide:="tlist"
	}
	if (formtype="D") {
		FormHide:="dlist"
	}
	formTS := tmpTS
	if (tmpD="DateIdx") {
		formnew := true
		tmp := ""
		tmpD := A_Now
		formTS := tmpD
	}
	formTxt := tmp
	formDT := tmpD
	i:=(formW/3)-30
	Gui, %formHide%:Hide
	Gui, formUI:Destroy
	Gui, formUI:New, +hwndFormHwnd
	Gui, formUI:Add, GroupBox, % "x5 y0 w" (formW-10) " h" (formR*16)+40
	Gui, formUI:Add, Edit, % "x10 y10 w" (formW-20) " h" (formR*16) " vformTXT gplFormChg", %tmp%
	Gui, formUI:Add, DateTime, % "x10 y" (formR*16)+12 " w100 vformDT gplFormChg Choose" tmpD, MM/dd/yyyy
	If (formtype~="[SU]")
		Gui, formUI:Add, DateTime, % "xp+110 yp w60 vformT gplFormChg", Time
	Gui, formUI:Add, Button, % "x10 yp+50 w" i " gplFormSave", SAVE
	Gui, formUI:Add, Button, % "xp+" i+33 " yp w" i " gformUIGuiClose", Cancel
	Gui, formUI:Add, Button, % (formnew ? "Disabled ":"") "xp+" i+33 " yp w" i " gformUIDelete", Delete
	GuiControl, formUI:Text, formT, HH:mm
	GuiControl, , formT, %tmpD%
	Gui, formUI:Show, % "w" formW " h" (formR*16)+100 , % (formnew ? "New ":"") (formtype="S" ? "Summary " tmpdate : (formtype="T" ? "Task " tmpdate : plDataType " " tmpD))

	WinWaitClose ahk_id %FormHwnd%
Return
}

plFormChg:
{
	formEdit:=true
	Return
}

formUIGuiClose:
	if (formEdit) {
		MsgBox, 308, Changes not saved!, % "Are you sure?`n`nYes = Close without saving.`nNo = Try again."
		IfMsgBox No
			return
	}
	Gui, formUI:Destroy
	Gui, %FormHide%:Show
Return

formUIDelete:
{
	formDel:=true
	Gui, formUI:Destroy
	Gui, %FormHide%:Show
	Return
}

plFormSave:
{
	formSave:=true
	Gui, formUI:Submit, NoHide
	Gui, formUI:Destroy
	Gui, %FormHide%:Show
	formDT := substr(formDT,1,8) . substr(formT,9,6)
Return
}

GetNotes(mrn,type) {
	if (type="weekly") {
		node := "/notes/weekly/summary"
	} else if (type="updates") {
		node := "/notes/updates/note"
	} else {
		return error
	}
	global y
	Loop, % (notes := y.selectNodes("/root/id[@mrn='" mrn "']" node)).length {
		note := notes.item(A_Index-1)
		date := breakDate(note.getAttribute("date"))
		text .= "[" date.MM "/" date.DD "] " note.text . "`n"
	}
	return text
}

