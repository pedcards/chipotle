MainGUI:
{
refreshCurr(1)																; Update currlist with currlock
Gui, Main:+AlwaysOnTop
Gui, Main:Color, Maroon
Gui, Main:Font, s16 wBold
Gui, Main:Add, Text, x40 y20 w180 h20 +Center, % MainTitle1
Gui, Main:Font, wNorm s8 wItalic
Gui, Main:Add, Text, x22 yp+30 w210 h20 +Center, % MainTitle2
Gui, Main:Add, Text, xp yp+14 wp hp +Center, % MainTitle3
Gui, Main:Font, wNorm

while (str := loc[i:=A_Index]) {					; get the dates for each of the lists
	strDT := breakDate(loc[str,"date"] := y.getAtt("/root/lists/" . str, "date"))
	Gui, Main:Add, Button, % "x20 y" (posy:=75+(i*25)) " w110 h20 gTeamList vE" str, % loc[str,"name"]
	Gui, Main:Add, Text, % "v" loc[str,"datevar"] " x170 y" (posy+4) " w70 h20" 
		, % strDT.MM "/" strDT.DD "  " strDT.HH ":" strDT.Min
	;Gui, 1:Add, Picture, % "x220 y" (posy+3) " gPrintOut v" str , printer.png
	loc[str,"ypos"] := posy
}
if (isCICU) {
	Gui, Main:Add, Button, % "x20 y" (posy+=25) " w110 h20 gTeamList vECICUSur", CICU+Surg patients
}
if (isARNP) {
	Gui, Main:Add, Button, % "x20 y" (posy+=25) " w110 h20 gTeamList vESurUnit", Surg Unit
	Gui, Main:Add, Button, % "x20 y" (posy+=25) " w110 h20 gTeamList vESURGCNTR", Surgery Center
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

Menu, menuSys, Add, GUACAMOLE, buttonGuac
Menu, menuSys, Add, NACHOS, buttonNachos
Menu, menuSys, Add, QUESO, buttonAdmin
Menu, menuSys, Add, CHILI, buttonChili
Menu, menuSys, Add, CON CARNE, buttonConCarne
Menu, menuSys, Add
Menu, menuSys, Add, Save && Quit..., mainGUIdone
Menu, menuSys, Add, Quit..., mainGuiclose
Menu, MenuBar, Add, System, :menuSys

Menu, menuFile, Add, Find/Add a patient, FindPt
Menu, menuFile, Add
Menu, menuFile, Add, Import Stork List, readStorkList
Menu, menuFile, Add, Update Electronic Forecast, readForecast
Menu, MenuBar, Add, File, :menuFile

Menu, menuHelp, Add, Help, buttonHelp
Menu, menuHelp, Add, About CHIPOTLE, buttonInfo
Menu, MenuBar, Add, Help, :menuHelp

Gui, Main:Menu, MenuBar

Gui, Main:Show, w260 , % "CHIPOTLE main" (servfold="testlist" ? " TEST" : "")			; draw initial GUI

WinGetPos, tmpX, tmpY, tmpW, tmpH, CHIPOTLE main										; get GUI coordinates
SysGet, tmpMon, MonitorWorkArea															; get screen params
Gui, Main:Show, % "x" (tmpMonRight-tmpW) " y" (tmpMonBottom-tmpH)						; reposition GUI relative to screen

return
}

ButtonGuac:
{
Run, "\\chmc16\Cardio\Conference\Tuesday Conference\GUACAMOLE!.exe"
Return
}

ButtonNachos:
{
MsgBox,, NACHOS,
(
NACHOS!
The Networked Aggregator for Consulting Hospitals and Outpatient Services
Interface for ad hoc entry of non-inpatient list entries. If entry point is 
via demographic banner triangulation (i.e. demographics are accurate), will 
add into archive list; data will be available/retrieved/incorporated the next 
time the patient is admitted. Could use/manage Stork Lists, integrate this 
information when the baby is admitted. Non-SCH patients (such as outside nursery 
and NICU consults) can be tracked to improve communication between providers.

Still in progress!
)
Return
}

ButtonInfo:
{
MsgBox, , About CHIPOTLE v%vers%,
(
The Children's Heart Center InPatient Organized Task List Environment is a software suite intended to improve communication, continuity of patient care, and facilitate the process for inpatient rounding and sign-outs between the many explicit and implicit Heart Center services. 

This system obviously uses PHI that has been password protected or encrypted at each level. No data is actually stored on any device, whether desktop or mobile. As when using any PHI, be wary of prying eyes.

Also, this is a work in progress. Use at your own risk! I take no responsibility for anything you do with this.

- TUC

)
Return
}

ButtonHelp:
{
MsgBox, , Basic usage,
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
return
}

ButtonAdmin:
{
If (isAdmin) {	
	Run, queso.exe
} else {
	MsgBox,, QUESO,
(
QUESO!
QUEry tool and System Operations
Administrative interface and data analysis tool.

Only available to CHIPOTLE Administrators.
)
}
return
}

ButtonChili:
{
	return
}

ButtonConCarne:
{
	isARNP := true
	return
}

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

FindPt:
{
/*	Ad hoc search/add patient
	1. If window exists with name "1451234 Smith, John - Powerchart...", grab MRN & name.
	2. Ask for MRN or name.
	3. If in currlist, pull up patlist card.
	4. Search archlist for MRN.
	5. If new record, create MRN, name, DOB, dx list, military, misc info. Save back to archlist with date created. Purge will clean out any records not validated within 2 months.
*/
	SetTitleMatchMode RegEx
	IfWinNotExist, i)-\s\d+\sOpened
	{
		SetTitleMatchMode 2
		MsgBox Must open the proper patient in CIS first!
		return
	}
	SetTitleMatchMode 2
	WinGetTitle, tmp
	;WinActivate
	RegExMatch(tmp,"O)\d{6,8}",tmpMRN)
	RegExMatch(tmp,"iO)[a-z\-]+,\s[a-z\-]+\s",tmpName)
	tmpMRN := tmpMRN.value()
	tmpName := tmpName.value()
	tmpNameL := strX(tmpName,,1,0,", ",1,2)
	tmpNameF := strX(tmpName,", ",1,2,"")
	MsgBox, 35, Select patient, % tmpMRN "`n" tmpNameF " " tmpNameL "`n`nIs this the correct patient to add/search?"
	IfMsgBox Cancel
		return
	IfMsgBox No
	{
		MsgBox Open the proper patient in CIS, then try again.
		return
	}
	IfMsgBox Yes
	{
		adhoc = true
		MRN := tmpMRN
		MRNstring := "/root/id[@mrn='" MRN "']"
		if IsObject(y.selectSingleNode(MRNstring)) {				; exists in currlist, open PatList
			gosub PatListGet
			return
		} 
		y.addElement("id", "root", {mrn: MRN})									; No MRN node exists, create it.
		y.addElement("demog", MRNstring)
			y.addElement("name_last", MRNstring "/demog", tmpNameL)
			y.addElement("name_first", MRNstring "/demog", tmpNameF)
		FetchNode("diagnoses")													; Check for existing node in Archlist,
		FetchNode("notes")														; retrieve old Dx, Notes, Plan. (Status is discarded)
		FetchNode("plan")														; Otherwise, create placeholders.
		FetchNode("prov")
		WriteOut("/root","id[@mrn='" mrn "']")
		eventlog(mrn " ad hoc created.")
		gosub PatListGet
	}
	Return
}

