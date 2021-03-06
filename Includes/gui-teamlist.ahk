TeamList:
{
	;Gui, 1:-AlwaysOnTop
	refreshCurr(1)														; update Y with currlock
	Gui, teamL:Destroy
	if (A_GuiControl)
		location := substr(A_GuiControl,2)
	locString := loc[location,"name"]
	listsort(location)
	Gui, teamL:Add, ListView, -Multi NoSortHdr Grid x10 y35 gPatListGet vTeamLV, MRN|Name|Unit|Room|Service|C|T
	Gui, teamL:Default
	i:=0
	Loop, % (plist := y.selectNodes("/root/lists/" . location . "/mrn")).length {
		kMRN := plist.item(i:=A_Index-1).text
		pl := PtParse(kMRN)
		LV_Add(""
			, kMRN
			, pl.nameL ", " pl.nameF
			, pl.Unit
			, pl.Room
			, pl.Svc
			, pl.statCons ? "X" : ""
			, pl.statTrans ? "X" : "")
	}
	Gui, teamL:Font, s12,
	GuiControl, teamL:Font, TeamLV
	LV_ModifyCol()  ; Auto-size each column to fit its contents.
;	LV_ModifyCol(1, "Integer")  ; For sorting purposes.
;	LV_ModifyCol(4, "Sort")
;	LV_ModifyCol(5, "Sort")
;	LV_ModifyCol(7, "0 Integer Sort")
	j = 0
	Gui +LastFound
	Loop % LV_GetCount("Column")
	{
		SendMessage, 4125, A_Index - 1, 0, SysListView321					; for each column, get column width
		j += %ErrorLevel%
	}
	Gui, teamL:Font
	Gui, teamL:Add, Button, % "w100 x10 y5 g" ((isARNP) ? "PrintARNP" : "PrintIt") " vP" location, Print list now
	Gui, teamL:Add, Button, % "w100 x" ((j+20)*.30)-50 " yP+0 g" ((isARNP) ? "PrintARNP" : "PrintIt") " vO" location, Open in Word
	Gui, teamL:Add, Button, % "w100 x" ((j+20)*.50)-50 " yP+0 gSignOut vS" location, Email Signout
	Gui, teamL:Add, Button, % "w100 x" ((j+20)*.70)-50 " yP+0 gTeamTasks vT" location, Tasks
	Gui, teamL:Add, Button, % "w100 x" (j-85) " yP+0 gCallList vC" location, Call List

	i+=1
	if i>25
		i:=25
	if i<6
		i:=6
	tlvH := i*24+40
	GuiControl, teamL:Move, TeamLV, % "W" . (j+5) . "H" . tlvH
	Gui, teamL:Show, % "W" . (j+25) . "H" . tlvH+40, % loc[location,"name"]
	Gui, teamL:Show, % "W" . (j+25) . "H" . tlvH+40, % locString

	Return
}

TeamTasks:
{
	refreshCurr(1)
	Gui, ttask:Destroy
	Gui, ttask:Add, ListView, -Multi NoSortHdr Grid w780 vTeamTaskLV gTeamTaskPt hwndHLV
		, DateFull|Due|MRN|Name|Task
	LV_Colors.Attach(HLV,1,0,0)
	;LV_Colors.OnMessage()
	Gui, ttask:Default
	pTct := 1
	i:=0
	Loop, % (plist := y.selectNodes("/root/lists/" . location . "/mrn")).length {
		kMRN := plist.item(i:=A_Index-1).text
		pl := y.selectSingleNode("/root/id[@mrn='" kMRN "']")
		Loop, % (plT:=pl.selectNodes("plan/tasks/todo")).length {
			k:=plT.item(A_Index-1)
			LV_Add(""
				, plD := k.getAttribute("due")
				, plDate := substr(plD,5,2) . "/" . substr(plD,7,2)
				, kMRN
				, pl.selectSingleNode("demog/name_last").text . ", " . pl.selectSingleNode("demog/name_first").text
				, k.text)
			EnvSub, plD, A_Now, D
			if (plD<3) {
				LV_Colors.Row(HLV, pTct, 0xFFFF00)
			}
			if (plD<1) {
				LV_Colors.Row(HLV, pTct, 0xFF0000)
			}
			pTct += 1
		}
	}
	;LV_ModifyCol()  ; Auto-size each column to fit its contents.
	;LV_ModifyCol(1, 0)
	LV_ModifyCol(1, "0 Sort")
	LV_ModifyCol(2, "AutoHdr")
	LV_ModifyCol(3, "AutoHdr")
	LV_ModifyCol(4, "AutoHdr")
	LV_ModifyCol(5, "AutoHdr")

	if pTct>25
		pTct:=25
	if pTct<4
		pTct:=4
	tlvH := pTct*22+40
	GuiControl, ttask:Move, TeamTaskLV, % "H" tlvH
	Gui, ttask:Show, % "W800 H" tlvH+10, % location " - Team Tasks"
	GuiControl, ttask:+Redraw, %HLV%
	
Return	
}

SignOut:
{
	if (CisEnvt) {
		MsgBox, 262160, Wrong launch environment, Cannot email when launched from CIS!
		eventlog("Cannot email when launched from CIS.")
		return
	}
	soText := soSumm := 
	loop, % (soList := y.selectNodes("/root/lists/" . location . "/mrn")).length {		; loop through each MRN in loc list
		soMRN := soList.item(A_Index-1).text
		k := y.selectSingleNode("/root/id[@mrn='" soMRN "']")
		so := ptParse(soMRN)
		
		soSumm := "<b><u><i>" so.NameL ", " so.NameF "&emsp;" 
			. so.Unit " " so.Room "&emsp;" 
			. so.MRN "&emsp;" so.Sex "&emsp;" so.Age "&emsp;" 
			. so.Svc "</i></u></b><br>"
			. ((so.dxCard) ? "[DX] " so.dxCard "<br>" : "")
			. ((so.dxEP) ? "[EP] " so.dxEP "<br>" : "")
			. ((so.dxSurg) ? "[Surg] " so.dxSurg "<br>" : "")
		loop, % (soNotes := y.selectNodes("/root/id[@mrn='" soMRN "']/notes/weekly/summary")).length {	; loop through each Weekly Summary note.
			soNote := soNotes.item(A_Index-1)
			soDate := breakDate(soNote.getAttribute("date"))
			soSumm .= "[" soDate.MM "/" soDate.DD "] "soNote.text . "<br>"
		}
		soText .= soSumm "<br>"
	}
	plEml := ComObjCreate("Outlook.Application").CreateItem(0)						; Create item [0]
	plEml.BodyFormat := 2															; HTML format
	
	plEml.To := 
	plEml.Subject := location " sign-out " A_MM "-" A_DD "-" A_YYYY
	plEml.Display																	; Must display first to get default signature
	plEml.HTMLBody := soText "<br>"
		. plEml.HTMLBody															; Prepend to existing default message
	
	eventlog(location " weekly signout generated.")
	soText =
Return
}

teamLGuiClose:
	Gui, teamL:Destroy
	Gui, Main:Show
	Gui, Main:+AlwaysOnTop
Return

