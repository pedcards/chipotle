/*	CON CARNE interface test
*/

scr:=screenDim()
win:=winDim(scr)
;MsgBox % scr.W " x " scr.H " @ " scr.DPI " DPI" . "`n" . scr.OR

DrawWin:
{
	demo_h := win.rH*6
	Gui, main:Default
	Gui, Add, GroupBox, % "x"win.bor " y"win.bor " w"win.boxH " h"demo_h, here
	Gui, Add, GroupBox, % "x"win.bor+win.boxH+win.boxQ+win.bor " y"win.bor " w"win.boxQ-win.bor " h"demo_h
	Gui, Add, GroupBox, % "x"win.bor+win.boxH " y"win.bor " w"win.boxQ " h"demo_h/2+4
	Gui, Add, GroupBox, % "xP yP+"demo_h/2-4 " wP hP"
	Gui, Add, GroupBox, % "x"win.bor " y"win.bor+demo_h-4 " w"win.boxF " h"demo_h*4
	Gui, Show, % "w"win.wX " h"win.wY-80, Window
}

;MsgBox % win.wx " x " win.wy

PatListGet:
{
	pl_demo := ""
		. "DOB: " pl_DOB 
		. "   Age: " (instr(pl_Age,"month")?RegExReplace(pl_Age,"i)month","mo"):instr(pl_Age,"year")?RegExReplace(pl_Age,"i)year","yr"):pl_Age) 
		. "   Sex: " substr(pl_Sex,1,1) "`n`n"
		. pl_Unit " :: " pl_Room "`n"
		. pl_Svc "`n`n"
		. "Admitted: " pl_Admit "`n"
Gui, plistG:Add, Text, x26 y38 w200 h80 , % pl_demo
;Gui, plistG:Add, Text, x26 y74 w200 h40 , go here
Gui, plistG:Add, Text, x266 y24 w150 h30 , Primary Cardiologist:
Gui, plistG:Add, Text, xp yp+14 cBlue w150 vpl_card, % pl_ProvCard
Gui, plistG:Add, Text, xp yp+20 w150 h30 , Continuity Cardiologist:
Gui, plistG:Add, Text, xp yp+14 cBlue w150 vpl_SCHcard, % pl_ProvSchCard
Gui, plistG:Add, Text, xp y100 w150 h28 , Last call:
Gui, plistG:Add, Text, xp+50 yp w80 vCrdCall_L , ((pl_Call_L) ? niceDate(pl_Call_L) : "---")		;substr(pl_Call_L,1,8)
Gui, plistG:Add, Text, xp-50 yp+14 , Next call:
Gui, plistG:Add, Text, xp+50 yp w80 vCrdCall_N, ((pl_Call_N) ? niceDate(pl_Call_N) : "---")

Gui, plistG:Add, CheckBox, x446 y34 w120 h20 Checked%pl_statCons% vpl_statCons , Consult
Gui, plistG:Add, CheckBox, x446 yp+20 w120 h20 Checked%pl_statTxp% vpl_statTxp , Transplant
Gui, plistG:Add, CheckBox, x446 yp+20 w120 h20 Checked%pl_statRes% vpl_statRes , Research
Gui, plistG:Add, CheckBox, x446 yp+20 w120 h20 Checked%pl_statScamp% vpl_statScamp , SCAMP

Gui, plistG:Add, Edit, x26 y160 w540 h48 vpl_dxNotes , %pl_dxNotes%
Gui, plistG:Add, Edit, x26 yp+70 w540 h48 vpl_dxCard , %pl_dxCard%
Gui, plistG:Add, Edit, x26 yp+70 w540 h48 vpl_dxEP , %pl_dxEP%
Gui, plistG:Add, Edit, x26 yp+70 w540 h48 vpl_dxSurg , %pl_dxSurg%
Gui, plistG:Add, Edit, x26 yp+70 w540 h48 vpl_dxProb , %pl_dxProb%

Gui, plistG:Add, Button, x36 y504 w160 h40 , Tasks/Todos
Gui, plistG:Add, Button, xp+180 yp w160 h40  Disabledd, Data highlights
Gui, plistG:Add, Button, xp+180 yp w160 h40 , Summary Notes
Gui, plistG:Add, Button, x36 y554 w240 h40 v1 , Patient History (CORES)
Gui, plistG:Add, Button, x316 y554 w240 h40 v2 , Meds/Diet (CORES)

Gui, plistG:Font, wBold
Gui, plistG:Add, GroupBox, x16 y14 w400 h120 , % pl_NameL . ", " . pl_NameF
Gui, plistG:Add, GroupBox, x256 yp w160 h80
Gui, plistG:Add, GroupBox, xp yp+70 w160 h50 

Gui, plistG:Add, GroupBox, x436 y14 w140 h120 , Status Flags
Gui, plistG:Add, GroupBox, x16 y144 w560 h70 , Quick Notes
Gui, plistG:Add, GroupBox, x16 yp+70 w560 h70 , Diagnoses && Problems
Gui, plistG:Add, GroupBox, x16 yp+70 w560 h70 , EP diagnoses/problems
Gui, plistG:Add, GroupBox, x16 yp+70 w560 h70 , Surgeries/Caths/Interventions
Gui, plistG:Add, GroupBox, x16 yp+70 w560 h70 , Problem List
Gui, plistG:Font, wNormal
Gui, plistG:Add, Button, x176 y614 w240 h40 , SAVE

Gui, plistG:Show, w600 h670, % "Patient Information - " pl_NameL
plEditNote = 
plEditStat =

Return
}

pListGGuiClose:
ExitApp

screenDim() {
	W := A_ScreenWidth
	H := A_ScreenHeight
	DPI := A_ScreenDPI
	Orient := (W>H)?"L":"P"
	
	return {W:W, H:H, DPI:DPI, OR:Orient}
}
winDim(scr) {
	if (scr.or="L") {
		wX := scr.H
		wY := scr.H
		bor := 10
		bWf := wX-2*bor
		bWh := bWf/2
		bWq := bWf/4
	} else {
		wX := scr.W
		wY := scr.H
	}
	return { BOR:Bor, wX:wX, wY:wY
		,	boxF:bWf
		,	boxH:bWh
		,	boxQ:bWq
		,	rH:20}
}