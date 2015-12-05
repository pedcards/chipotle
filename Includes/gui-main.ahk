MainGUI:
{
Gui, Main:+AlwaysOnTop
Gui, Main:Color, Maroon
if (isAdmin) {
	Gui, Main:Add, Button, x2 y2 w25 h24 gButtonAdmin, A
}
Gui, Main:Font, s16 wBold
Gui, Main:Add, Button, x232 y2 w25 h24 BackgroundTrans gButtonInfo, i
Gui, Main:Add, Text, x40 y0 w180 h20 +Center, % MainTitle1
Gui, Main:Font, wNorm s8 wItalic
Gui, Main:Add, Text, x22 yp+30 w210 h20 +Center, % MainTitle2
Gui, Main:Add, Text, xp yp+14 wp hp +Center, % MainTitle3
Gui, Main:Font, wNorm

while (str := loc[i:=A_Index]) {					; get the dates for each of the lists
	strDT := breakDate(loc[str,"date"] := y.getAtt("/root/lists/" . str, "date"))
	Gui, Main:Add, Button, % "x20 y" (posy:=55+(i*25)) " w110 h20 gTeamList vE" str, % loc[str,"name"]
	Gui, Main:Add, Text, % "v" loc[str,"datevar"] " x170 y" (posy+4) " w70 h20" 
		, % strDT.MM "/" strDT.DD "  " strDT.HH ":" strDT.Min
	;Gui, 1:Add, Picture, % "x220 y" (posy+3) " gPrintOut v" str , printer.png
	loc[str,"ypos"] := posy
}
if (isCICU) {
	Gui, Main:Add, Button, % "x20 y" (posy+=25) " w110 h20 gTeamList vECICUSur", CICU+Surg patients
}
if (isARNP) {
	Gui, Main:Add, Button, % "x20 y" (posy+=25) " w110 h20 gTeamList vESurR6", Surg R6
}
if (isCICU or isARNP) {																				; CICU interface
	callCt:=0
	Loop, % (plist := y.selectNodes("/root/lists/" . callLoc . "/mrn")).length {
		kMRN := plist.item(i:=A_Index-1).text
		pl := ptParse(kMRN)
		if (plCall := pl.callN) {
			plCall -= substr(A_Now,1,8), Days
			if (plCall<2)
				callCt += 1
		}
	}
	Gui, Main:Add, Button, % "x20 y" (posy+=35) " w110 h20 gCallList vC" callLoc, Call list
	Gui, Main:Add, Text, % "x170 y" (posy+4) " w70 h20", % callCt
}

strCO := breakDate(DateCORES := y.getAtt("/root/lists/cores", "date"))
posy += 35
Gui, Main:Add, Text, x40 y%posy% vGUIcoresChk
Gui, Main:Add, Text, x50 y%posy% w100 h20 , CORES:
Gui, Main:Add, Text, vGUIcoresTXT x137 y%posy% w130 h20 , % strCO.MM "/" strCO.DD "  " strCO.HH ":" strCO.Min

Gui, Main:Add, Button, % "x80 y" (posy+=40) " w100 h30 gMainGUIdone", Update && Exit!

WinGetPos, , , CIS_W, CIS_H, % CIS_window
if (CIS_W) {
	CIS_W := CIS_W - 300
	CIS_H := CIS_H - posy - 120
} else {
	CIS_W := A_ScreenWidth-280
	CIS_H := A_ScreenHeight-posy-120
}

Gui, Main:Show, x%CIS_W% y%CIS_H% w260 , % "CHIPOTLE main" (servfold="testlist" ? " TEST" : "")
return
}

ButtonInfo:
{
$txt = 
(
** For CIS Patient List:
1. Select a patient list tab in CIS.
2. Select patients in the list (ctrl-A).
3. Copy highlighted names to clipboard (ctrl-C).
4. Confirm the patient list on the dialog.

** For CORES Rounding/Handoff Report:
1. Print Report -> Rounding/Handoff Report.
2. Select "Just Print" button.
3. CORES recognition will commence.
4. If it does not automatically update list, just ctrl-A + ctrl-C.
)
$txt2 =
(
The Children's Heart Center InPatient Organized Task List Environment is a software suite intended to improve communication, continuity of patient care, and facilitate the process for inpatient rounding and sign-outs between the many explicit and implicit Heart Center services. 

This system obviously uses PHI that has been password protected or encrypted at each level. No data is actually stored on any device, whether desktop or mobile. As when using any PHI, be wary of prying eyes.

Also, this is a work in progress. Use at your own risk! I take no responsibility for anything you do with this.

- TUC

)
Gui, info:Add, Text, x20 y14 w420 , %$txt2%
Gui, info:Show, w460 , CHIPOTLE v%vers%, %$txt2%

MsgBox,,% "CHIPOTLE v" vers, %$txt%
return
}

ButtonAdmin:
	Run, queso.exe
return

MainGuiClose:
	MsgBox, 308, Confirm, % "Do you want to quit without committing changes?`n`nYes = Close without saving.`nNo = Try again."
	IfMsgBox No
		return
	FileDelete .currlock
	eventlog("<<<<< Session closed by user.")
ExitApp

MainGuiDone:
	Gui, Main:Hide
Return

QueryList:
{
locString := ""
if !(qldone) {
	Gui, qList:+AlwaysOnTop
	while (str1 := loc[i:=A_Index]) {
		str2 := loc[str1,"name"]
		posy := 7+(i-1)*30
		Gui, qList:Add, Button, x26 y%posy% w100 h30 gUpdateMainGUI v%str1% , %str2%
	}
	posy += 60
	Gui, qList:Add, Text, x26 y%posy% w100 h32 +Center, Which CIS list?
	qldone = true
}
	Gui, qList:Show, w154 , CIS List
Return
}

;~ qListGuiClose:
	;~ locString := ""
	;~ Gui, qList:Hide
;~ Return

UpdateMainGUI:
{
	location := A_GuiControl
	locString := loc[location,"name"]
	str := loc[location,"datevar"]
	strDT := breakDate(timenow)
	posy := loc[location,"ypos"]
	GuiControl, Main:Text, %str%, % strDT.MM "/" strDT.DD "  " strDT.HH ":" strDT.Min " *"
	Gui, Main:Submit, NoHide
	Gui, qList:Hide
	loc[location,"print"] := true
Return
}

OpenPrint:
{
	location := substr(A_GuiControl,2)
	locString := loc[location,"name"]
	fileout := "patlist-" . location . ".rtf"
	Run, %fileout%
	MsgBox, 262192, Open temp file
, Only use this function to troubleshoot `nprinting to the local printer. `n`nChanges to this file will not `nbe saved to the CHIPOTLE database `nand will likely be lost!
	eventlog(fileout " opened in Word.")
	Return
}

