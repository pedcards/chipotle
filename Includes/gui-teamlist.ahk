TeamList:
{
	;Gui, 1:-AlwaysOnTop
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
	Gui, teamL:Add, Button, % "w100 x10 y5 g" ((isARNP) ? "PrintARNP" : "PrintIt") " vP" location, Print list
	Gui, teamL:Add, Button, % "w100 x" ((j+20)*.30)-50 " yP+0 gOpenPrint vO" location, Open temp file
	Gui, teamL:Add, Button, % "w100 x" ((j+20)*.50)-50 " yP+0 gSignOut vS" location, Weekly Summary
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

teamLGuiClose:
	Gui, teamL:Destroy
	Gui, Main:Show
	Gui, Main:+AlwaysOnTop
Return

