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
if (isCoord) {
	gosub MakeCoordList
	Gui, Main:Add, Button, % "x20 y" (posy+=25) " w110 h20 gTeamList vECoord", Coordination
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
Menu, menuFile, Add, Read Centripetus data, getCentrip
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
	Reload
	return
}

ButtonConCarne:
{
	Reload
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

MakeCoordList:
{
	if !IsObject(y.selectSingleNode("/root/lists/Coord")) {
		y.addElement("Coord","/root/lists")
	}
	tmpCk := false
	Loop, % (plist := y.selectNodes("/root/lists/CSR/mrn")).length {					; Read all MRN in CSR list into plist. Do ICUCons too?
		kMRN := plist.item(A_Index-1).text												; Get MRN
		if (y.selectSingleNode("/root/id[@mrn='" kMRN "']/status").getAttribute("txp")="on") {		; TXP status is "on"
			continue																				; move along
		}
		if !IsObject(y.selectSingleNode("/root/lists/Coord/mrn[text()='" kMRN "']")) {	; CSR patient doesn't exist in Coord
			y.addElement("mrn","/root/lists/Coord",kMRN)								; Add to Coord
			eventlog("CSR " kMRN " added to Coord.")
			tmpCk := true																; Change made, so writeout
		}
	}
	Loop, % (plist := y.selectNodes("/root/id/diagnoses/coord")).length {				; Read any "coord" elements into plist
		kMRN := plist.item(A_Index-1).parentNode.parentNode.getAttribute("mrn")			; read <mrn>/<diagnosis>/<coord>
		if !IsObject(y.selectSingleNode("/root/lists/Coord/mrn[text()='" kMRN "']")) {
			y.addElement("mrn","/root/lists/Coord",kMRN)								; Add to Coord
			eventlog(kMRN " added to Coord list.")
			tmpCk := true																; Change made, so writeout
		}
	}
	
	Loop, % (plist := y.selectNodes("/root/lists/Coord/mrn")).length {					; Loop through all MRN in Coord
		loopCk := false																	; for when finds this MRN in any List
		kMRN := plist.item(A_Index-1).text
		Loop, % (plist0 := y.selectNodes("/root/lists/*/mrn[text()='" kMRN "']")).length {
			yaItem := plist0.item(A_index-1)											; Any node <mrn>1234568</mrn>
			yaName := yaItem.parentNode.nodeName										; Get List name
			if (yaName~="cores|Coord") {												; Skip if either CORES or Coord
				continue
			}
			loopCk := true																; assign lookCk if in a list that is not CORES or Coord
		}
		if !(loopCk) {																	; Not present in any list? i.e. discharged
			removeNode("/root/lists/Coord/mrn[text()='" kMRN "']")						; Remove from Coord list
			eventlog(kMRN " no longer on any active lists. Removed from Coord.")		; Move along to next Coord element
			tmpCk := true																; I have removed something from Coord
			continue
		}
	}
	if (tmpCk) {																		; Change made to Coord
		y.selectSingleNode("root/lists/Coord").setAttribute("date",A_now)				; Change edit attr
		writeout("/root/lists","Coord")													; Save Coord to currlist
		eventlog("Updated Coord list.")
	}
Return
}

QueryList:
{
locString := ""
if !(qldone) {
	Gui, qList:+AlwaysOnTop
	while (str1 := loc[i:=A_Index]) {
		str2 := loc[str1,"name"]
		posy := 7+(i-1)*30
		Gui, qList:Add, Button, x26 y%posy% w100 h30 gQLselect v%str1% , %str2%
	}
	posy += 60
	Gui, qList:Add, Text, x26 y%posy% w100 h32 +Center, Which CIS list?
	qldone = true
}
	Gui, qList:Show, w154 , CIS List
Return
}

QLselect:
{
	location := A_GuiControl
	locString := loc[location,"name"]
	Gui, qList:Hide
	Gosub UpdateMainGUI
	
	Return
}

UpdateMainGUI:
{
	str := loc[location,"datevar"]
	strDT := breakDate(timenow)
	posy := loc[location,"ypos"]
	GuiControl, Main:Text, %str%, % strDT.MM "/" strDT.DD "  " strDT.HH ":" strDT.Min " *"
	Gui, Main:Submit, NoHide
	;~ loc[location,"print"] := true
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
	eventlog("CLK: " clk.field " " clk.value)
	tmpName := tmpMRN := ""
	if (clk.field="MRN") {
		tmpMRN := clk.value
		MRNstring := "/root/id[@mrn='" tmpMRN "']" 
		if IsObject(y.selectSingleNode(MRNstring)) {				; exists in currlist, open PatList
			eventlog("Found MRN in currlist.")
			adhoc := true
			pl_list := [tmpMRN]
			pl_pos := 1
			progress, 100, , Reading currlist, Finding patient...
			gosub PatListGet
			progress, off
			return
		} 
		if IsObject(yArch.selectSingleNode(MRNstring)) {
			eventlog("Found MRN in archlist.")
			adhoc := true
			pl_list := [tmpMRN]
			pl_pos := 1
			progress, 100, , Reading archlist, Finding patient...
			gosub pullPtArch
			progress, off
			return
		}
	} else if (clk.field="Name") {
		tmpName := clk.value
		tmpNameL := clk.nameL
		tmpNameF := clk.nameF
		nameString := "/root/id/demog[./name_last[text()='" tmpNameL "'] and ./name_first[text()='" tmpNameF "']]"
		if IsObject(tmpNode:=y.selectSingleNode(nameString)) {
			eventlog("Found name in currlist.")
			MRN := tmpNode.parentNode.getAttribute("mrn")
			adhoc := true
			pl_list := [MRN]
			pl_pos := 1
			progress, 100, , Reading currlist, Finding patient...
			gosub PatListGet
			progress, off
			return
		}
		if IsObject(tmpNode:=yArch.selectSingleNode(nameString)) {
			eventlog("Found name in archlist.")
			MRN := tmpNode.parentNode.getAttribute("mrn")
			adhoc := true
			pl_list := [MRN]
			pl_pos := 1
			progress, 100, , Reading archlist, Finding patient...
			gosub pullPtArch
			progress, off
			return
		}
	}
	
	return
	
	getDem := true
	fetchQuit := false
	encMRN := tmpMRN
	encName := tmpName
	
	gosub fetchGUI
	
	while (getDem) {									; Repeat until we get tired of this
		clipboard :=
		ClipWait, 2
		if !ErrorLevel {								; clipboard has data
			clk := parseClip(clipboard)
			if !ErrorLevel {															; parseClip {field:value} matches valid data
				if (clk.field = "Account Number") {
					;~ fldval["dev-Enc"] := clk.value
					eventlog("CLK: Account number " clk.value)
				}
				if (clk.field = "MRN") {
					encMRN := clk.value
					eventlog("CLK: MRN " clk.value)
				}
				if (clk.field = "Name") {
					encName := clk.value
					eventlog("CLK: Name " clk.value)
				}
			}
			gosub fetchGUI							; Update GUI with new info
		}
	}
	if (fetchQuit) {
		return
	}
	
	MRN := encMRN
	tmpNameL := strX(encName,"",1,0,",",1,1)
	tmpNameF := strX(encName,", ",1,2,"",0)
	adhoc = true
	pl_list := [MRN]
	pl_pos := 1
	progress, 100, , Reading archlist, Finding patient...
	gosub pullPtArch
	progress, off
	
	Return
}

pullPtArch:
{
	MRNstring := "/root/id[@mrn='" MRN "']"
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
	Return
}

fetchGUI:
{
	fYd := 30,	fXd := 90														; fetchGUI delta Y, X
	fX1 := 12,	fX2 := fX1+fXd													; x pos for title and input fields
	fW1 := 80,	fW2 := 190														; width for title and input fields
	fH := 20																	; line heights
	fY := 10																	; y pos to start
	;~ EncNum := fldval["dev-Enc"]													; we need these non-array variables for the Gui statements
	;~ EncMRN := tmpMRN
	;~ EncName := tmpName
	demBits := ((EncMRN~="\d{6,7}") && (encName~="[A-Z \-]+, [A-Z\-](?!=\s)"))			; clear the error check
	Gui, fetch:Destroy
	Gui, fetch:+AlwaysOnTop
	
	Gui, fetch:Add, Text, % "x" fX1 " w" fW1 " h" fH " c" ((encName)?"Default":"Red") , Name
	Gui, fetch:Add, Edit, % "x" fX2 " yP-4" " w" fW2 " h" fH 
		. " readonly c" ((encName)?"Default":"Red") , % encName
	
	Gui, fetch:Add, Text, % "x" fX1 " w" fW1 " h" fH " c" ((encMRN~="\d{6,7}")?"Default":"Red") , MRN
	Gui, fetch:Add, Edit, % "x" fX2 " yP-4" " w" fW2 " h" fH 
		. " readonly c" ((encMRN~="\d{6,7}")?"Default":"Red"), % encMRN
	
	Gui, fetch:Add, Button, % "x" fX1 " yP+" fYD " h" fH+10 " w" fW1+fW2+10 " gfetchSubmit " ((demBits)?"":"Disabled"), Submit!
	Gui, fetch:Show, AutoSize, Add/Edit ad hoc patient
	return
}

fetchGuiClose:
	Gui, fetch:destroy
	getDem := false																	; break out of fetchDem loop
	fetchQuit := true
	eventlog("Manual [x] out of fetchDem.")
Return

parseClip(clip) {
/*	If clip matches "val1:val2" format, and val1 in demVals[], return field:val
	If clip contains proper Encounter Type ("Outpatient", "Inpatient", "Observation", etc), return Type, Date, Time
*/
	if (clip~="[A-Z \-]+, [A-Z \-]+") {													; matches name format "SMITH, WILLIAM JAMES"
		clip := RegExReplace(clip,"'","``")
		nameL := trim(strX(clip,"",1,0,",",1,1))
		nameF := trim(strX(clip,",",1,1," ",1,1))
		return {field:"Name", value:nameL ", " nameF, nameL:nameL, nameF:nameF}
	}
	
	demVals := ["Account Number","MRN"]
	
	StringSplit, val, clip, :															; break field into val1:val2
	if (ObjHasValue(demVals, val1)) {													; field name in demVals, e.g. "MRN","Account Number","DOB","Sex","Loc","Provider"
		return {"field":trim(val1)
				, "value":trim(val2)}
	}
	
	return Error																		; Anything else returns Error
}

fetchSubmit:
{
/*	some error checking
	Check for required elements
demVals := ["MRN","Account Number","DOB","Sex","Loc","Provider"]
*/
	Gui, fetch:Submit
	Gui, fetch:Destroy
	
	getDem := false
	return
}

