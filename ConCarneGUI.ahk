/*	CON CARNE interface test
*/

scr:=screenDim()
MsgBox % scr.W " x " scr.H " @ " scr.DPI " DPI" . "`n"
	. scr.OR

PatListGet:
{
	Gui, plistG:Destroy
	;pl := ptParse(mrn)
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
	pl_dxCard := pl.dxCard
	pl_dxEP := pl.dxEP
	pl_dxSurg := pl.dxSurg
	pl_dxNotes := pl.dxNotes
	pl_dxProb := pl.dxProb
	pl_statCons := pl.statCons
	pl_statTxp := pl.statTxp
	pl_statRes := pl.statRes
	pl_statScamp := pl.statScamp
	pl_CORES := pl.CORES
	pl_MAR := pl.MAR
	pl_ProvCard := pl.provCard
	pl_ProvSchCard := pl.provSchCard
	pl_ProvEP := pl.provEP
	pl_ProvPCP := pl.provPCP
	pl_Call_L := pl.callL
	pl_Call_N := pl.callN
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

screenDim() {
	W := A_ScreenWidth
	H := A_ScreenHeight
	DPI := A_ScreenDPI
	Orient := (W>H)?"L":"P"
	
	return {W:W, H:H, DPI:DPI, OR:Orient}
}
