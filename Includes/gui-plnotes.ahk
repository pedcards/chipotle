plInputNote:
{
	if (isCICU) {
		MsgBox % "Cannot edit in CICU mode"
		gosub PatListGet
		return
	}
	;~ if (isARNP) {
		;~ MsgBox % "Cannot edit in ARNP mode"
		;~ gosub PatListGet
		;~ return
	;~ }
	i:=A_GuiControl
	if (substr(i,4,4)="stat") {							; var name "pl_statCons"
		plEditStat = true
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

plNoteEdit:
{
	LV_GetText(tmpDate, A_EventInfo,1)					; displayed date
	LV_GetText(tmp, A_EventInfo,2)						; text
	LV_GetText(tmpD, A_EventInfo,3)						; full date (for indexing)
	LV_GetText(tmpTS, A_EventInfo,4)					; created timestamp of edit (necessary?)
	
	if (tmpD="DateIdx" and A_GuiControl="WeeklyLV") {
		return											; click on blank area is null
	}
	formW:=700, formR:=5, formtype:="S"
	gosub plForm
	if (formDel) {
		MsgBox, 20, Confirm, Delete this note?
		IfMsgBox Yes 
		{
			if !IsObject(pl_mrnstring "/trash") {
				y.addElement("trash", pl_mrnstring)
				WriteOut(pl_mrnstring, "trash")
			}
			delmrnstr := pl_mrnstring "/notes/weekly/summary[@created='" formTS "']"
			y.selectSingleNode(delmrnstr).setAttribute("del", A_Now)
			y.selectSingleNode(delmrnstr).setAttribute("au", user)
			locnode := y.selectSingleNode(delmrnstr)
			y.selectSingleNode(pl_mrnstring "/notes/weekly").removeChild(locnode)
			WriteOut(pl_mrnstring "/notes","weekly")
			y.selectSingleNode(pl_mrnstring "/trash").appendChild(locnode.cloneNode(true))
			WriteOut(pl_mrnstring, "trash")
			eventlog(mrn " summary note " tmpD " deleted.")
			gosub plSumm
		}
		Return
	}
	if !(formedit=true) {
		return
	}
	if !(formsave=true) {
		return
	}
	if !IsObject(y.selectSingleNode(pl_mrnstring "/notes")) {
		y.addElement("notes", pl_mrnstring)
		WriteOut(pl_mrnstring, "notes")
	}
	if !IsObject(y.selectSingleNode(pl_mrnstring "/notes/weekly")) {
		y.addElement("weekly", pl_mrnstring "/notes")
		WriteOut(pl_mrnstring "/notes", "weekly")
	}
	if (formnew) {
		y.addelement("summary", pl_mrnstring "/notes/weekly", {date: formDT, created: formTS}, formTxt)
	} else {
		y.selectSingleNode(pl_mrnstring "/notes/weekly/summary[@created='" formTS "']").childNodes[0].nodevalue := formTxt
		y.selectSingleNode(pl_mrnstring "/notes/weekly/summary[@created='" formTS "']").setAttribute("date", formDT)
	}
	y.selectSingleNode(pl_mrnstring "/notes/weekly/summary[@created='" formTS "']").setAttribute("ed", A_Now)
	y.selectSingleNode(pl_mrnstring "/notes/weekly/summary[@created='" formTS "']").setAttribute("au", user)
	WriteOut(pl_mrnstring "/notes","weekly")
	eventlog(mrn " summary notes updated.")
	gosub plSumm
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
		FormHide:="upd"
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
	If (formtype="S")
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

