/* 	Patient List Updater (C)2014-2015 TC
	CHIPOTLE = Children's Heart Center InPatient Online Task List Environment
*/

/*	Todo lists: 
	AHK:
		- List order (consults at end of list)
	PHP:
		- Tasks
		- Problem list editor
		- Show consult (C) and transplant (TM) patients on list.
		- Links to SCAMPs.
		- Convert to AJAX interface.
		- Convert to XML DOM rather than SimpleXML.
		- Sort list by service, Cardiology on top, consults on bottom.

*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetTitleMatchMode, 2
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
WinClose, View Downloads - Windows Internet Explorer
LV_Colors.OnMessage()

FileGetTime, iniDT, chipotle.ini
FileGetTime, exeDT, chipotle.exe
iniDT -= %exeDT%, Seconds										; Will be negative if chipotle.ini is older.
FileInstall, chipotle.ini, chipotle.ini, (iniDT<0)				; Overwrite if chipotle.exe is newer (and contains newer .ini)
;FileInstall, pscp.exe, pscp.exe								; Necessary files (?)
;FileInstall, queso.exe, queso.exe
;FileInstall, printer.png, printer.png

Sleep 500
#Persistent		; Keep program resident until ExitApp
vers := "1.6.5"
user := A_UserName
FormatTime, sessdate, A_Now, yyyyMM

gosub ReadIni
scr:=screenDims()
win:=winDim(scr)

servfold := "patlist"
if (ObjHasValue(admins,user)) {
	isAdmin := true
	if (InStr(A_WorkingDir,"AutoHotkey")) {
		tmp:=CMsgBox("Data source","Data from which system?","&Local|&Test Server|Production","Q","V")
		if (tmp="Local") {
			isLocal := true
			;FileDelete, currlist.xml
		}
		if (tmp="Test Server") {
			isLocal := false
			servfold := "testlist"
			FileDelete, currlist.xml
		}
		if (tmp="Production") {
			isLocal := false
			FileDelete, currlist.xml
		}
	}
	tmp:=CMsgBox("Administrator","Which user role?","*&Normal CHIPOTLE|&CICU CHILI|&ARNP Con Carne","Q","V")
	if (tmp~="CHILI")
		isCICU := true
	if (tmp~="ARNP")
		isARNP := true
}
if (ObjHasValue(cicuUsers,user))
	isCICU = true
if (ObjHasValue(ArnpUsers,user))
	isARNP := true

if (isCICU) {
	loc := ["CSR","CICU"]												; loc[] defines the choices offered from QueryList. You can only break your own list.
	loc["CSR"] := {"name":"Cardiac Surgery", "datevar":"GUIcsrTXT"}
	loc["CICU"] := {"name":"Cardiac ICU", "datevar":"GUIicuTXT"}
	callLoc := "CICUSur"
	mainTitle1 := "CHILI"
	mainTitle2 := "Children's Heart Center"
	mainTitle3 := "Inpatient Longitudinal Integrator"
} else if (isARNP) {
	loc := ["CSR","CICU"]
	loc["CSR"] := {"name":"Cardiac Surgery", "datevar":"GUIcsrTXT"}
	loc["CICU"] := {"name":"Cardiac ICU", "datevar":"GUIicuTXT"}
	callLoc := "CSR"
	mainTitle1 := "CON CARNE"
	mainTitle2 := "Collective Organized Notebook"
	mainTitle3 := "for Cardiac ARNP Efficiency"
} else {
	mainTitle1 := "CHIPOTLE"
	mainTitle2 := "Children's Heart Center InPatient"
	mainTitle3 := "Organized Task List Environment"
}

Docs := Object()
outGrps := []
outGrpV := {}
tmpIdxG := 0
Loop, Read, outdocs.csv
{
	tmp := tmp0 := tmp1 := tmp2 := tmp3 := tmp4 := ""
	tmpline := A_LoopReadLine
	StringSplit, tmp, tmpline, `, , `"
	if ((tmp1="Name") or (tmp1="end")) {
		continue
	}
	if (tmp1) {
		if (tmp2="" and tmp3="" and tmp4="") {							; Fields 2,3,4 blank = new group
			tmpGrp := tmp1
			tmpIdx := 0
			tmpIdxG += 1
			outGrps.Insert(tmpGrp)
			continue
		} else if (tmp4="group") {										; Field4 "group" = synonym for group name
			tmpIdx += 1													; if including names, place at END of group list to avoid premature match
			Docs[tmpGrp,tmpIdx]:=tmp1
			outGrpV[tmpGrp] := "callGrp" . tmpIdxG
		} else {														; Otherwise format Crd name to first initial, last name
			tmpIdx += 1
			StringSplit, tmpPrv, tmp1, %A_Space%`"
			tmpPrv := substr(tmpPrv1,1,1) . ". " . tmpPrv2
			Docs[tmpGrp,tmpIdx]:=tmpPrv
			outGrpV[tmpGrp] := "callGrp" . tmpIdxG
		}
	}
}
outGrpV["Other"] := "callGrp" . (tmpIdxG+1)
outGrpV["TO CALL"] := "callGrp" . (tmpIdxG+2)

fcDateline:=Forecast_val[objHasValue(Forecast_svc,"Dateline")]

SetTimer, SeekCores, 250
SetTimer, SeekWordErr, 250

initDone = true
eventlog(">>>>> Session started.")
Gosub GetIt
Gosub MainGUI
WinWaitClose, CHIPOTLE main
Gosub SaveIt
eventlog("<<<<< Session completed.")
ExitApp


;	===========================================================================================
#Include getini.ahk
;	===========================================================================================
/*	Clipboard copier
	Will wait resident until clipboard change, then will save clipboard to file.
	Tends to falsely trigger a couple of times first. Will exit after .clip successfully saved.
/
OnClipboardChange:
	FileSelectFile, clipname, 8, , Name of .clip file, *.clip
	If (clipname) {			; If blank (e.g. pressed cancel), continue; If saved, then exitapp
		IfNotInString, clipname, .clip
			clipname := clipname . ".clip"
		FileDelete %clipname%
		FileAppend %ClipboardAll%, %clipname%
		ExitApp
	}
Return

*/

OnClipboardChange:
*/
{
if !initDone													; Avoid clip processing before initialization complete
	return
AutoTrim Off
DllCall("OpenClipboard", "Uint", 0)
hMem := DllCall("GetClipboardData", "Uint", 1)
nLen := DllCall("GlobalSize", "Uint", hMem)						; Directly check clipboard size
DllCall("CloseClipboard")
clip = %Clipboard%
SetTimer, SeekCores, On

If (nLen>10000) {
	; *** Check if CORES clip
	;clip = %Clipboard%
	clipCkCORES := substr(clip,1,60)
	If (clipCkCORES ~= CORES_regex) {
		coresType := StrX(clipCkCORES,"CORES",1,0,"REPORT v2.0",1,0,N)
		if (coresType == CORES_type) {
			WinClose, % CORES_window
			gosub initClipSub
			Gosub processCORES
			MsgBox,,CORES data update, % n0 " total records read.`n" n1 " new records added."
		} else {
			MsgBox, 16, Wrong format!, % "Requires """ CORES_type """"
			WinClose, % CORES_window
		}
	}
} else {										; Shorter ELSE block for smaller clips
	; *** Check if CIS patient list
	clipCkCIS := ClipboardAll
	CISdelim := A_tab . A_tab . A_tab
	If (instr(clip,CISdelim)=1) and (NumGet(clipCkCIS,7,"Char")=0) and (NumGet(clipCkCIS,8,"Char")=9)  {
		Gosub initClipSub
		Gosub QueryList
		WinWaitClose, CIS List
		if !(locString) {						; Avoids error if exit QueryList
			return								; without choice.
		}
		Gosub processCIS
		
		if (location="Cards" or location="CSR" or location="TXP") {
			gosub saveCensus
		}
		if (location="CSR" or location="CICU") {
			gosub IcuMerge
		}
	;*** Check if Electronic Forecast
	} else if ((clip ~= fcDateline) and !(soText)) {
			Gosub readForecast
	}
}

Return
}

^F12::
	FileSelectFile , clipname,, %A_ScriptDir%, Select file:, AHK clip files (*.clip)
	FileRead, Clipboard, *c %clipname%
Return

;	===========================================================================================

SeekCores:
{
IfWinNotExist, % CORES_window
	return
IfWinNotExist, Print
	return
else {									; If CORES window and Print window open
	conswin := WinExist(CORES_window)
	SetTimer, SeekCores, Off
	SetKeyDelay, 40, 200
	WinClose, Print
	WinActivate, % CORES_window
	sleep 250
	ControlSend,, ^a, %CORES_window%
	sleep 500
	ControlSend,, ^c, %CORES_window%
	}
Return
}

SeekWordErr:
{
if (Word_win2 := WinExist("User Name")) {
	ControlSend,, {Enter}, ahk_id %Word_win2%
	;MsgBox,,Win 2, %Word_win2%
	return
}
If (Word_win1 := WinExist("Microsoft Office Word", "The command cannot be performed because a dialog box is open.")) {
	ControlSend,, {Esc}, ahk_id %Word_win1%
	;MsgBox,,Win 1, %Word_win1%
	return
}
Return
}

initClipSub:									;*** Initialize XML files
{
	Clipboard =
	if !IsObject(t:=y.selectSingleNode("//root")) {		; if Y is empty,
		y.addElement("root")					; then create it.
		y.addElement("lists", "root")			; space for some lists
	}
	clip_elem := Object()						; initialize the arrays
	scan_elem := Object()
	clip_array := Object()
	clip_num = 									; clear some variables
	clip_full =
	FormatTime, timenow, A_Now, yyyyMMddHHmm

	Return
}

processCIS:										;*** Parse CIS patient list
{
	filecheck()
	FileOpen(".currlock", "W")													; Create lock file.
	y := new XML("currlist.xml")												; Get latest local currlist into memory
	RemoveNode("/root/lists/" . location)
	y.addElement(location, "/root/lists", {date: timenow})
	rtfList :=
	colTmp := {"FIN":0, "MRN":0, "Sex":0, "Age":0, "Adm":0, "DOB":0, "Days":0, "Room":0, "Svc":0, "Attg":0, "Name":0}

; First pass: parse fields into arrays and field types
	colIdx := colTmp.Clone()
	Loop, parse, clip, `n, `r%A_Tab%%A_Space%
	{
		clip_num := A_Index
		clip_full := A_LoopField
		If (clip_full) break
		Loop, parse, clip_full, %A_Tab%
		{
			i:=A_LoopField
			j:=fieldType(i)
			clip_elem[clip_num,A_Index] := i									; Place each element into an array, 
			scan_elem[clip_num,A_Index] := j									; parallel array with best guess field type
		}
	}
; Second pass: scan through each column (length determined by first row)
	loop, % scan_elem[1].MaxIndex()
	{
		scan_col := A_Index
		colval := colTmp.Clone()
		Loop, % scan_elem.MaxIndex()											; read each row
		{
			colval[scan_elem[A_Index,scan_col]] ++								; increment counter for found type
		}
		bestcol := 0
		bestK := ""
		for k,v in colval														; scan each type
		{
			if (v>bestcol) {
				bestcol := v													; find highest matching column
				bestK := k
			}
		}
		if !(colIdx[bestk]) and ((bestCol/scan_elem.MaxIndex()) > 0.6) {		; store best column for each type
			colIdx[bestK] := scan_col
		}
	}
; Third pass: parse array elements according to identified field types
	Loop, % clip_elem.MaxIndex()
	{
		clip_num := A_Index	
		CIS_mrn := clip_elem[clip_num,colIdx["MRN"]]				; MRN
			MRNstring := "/root/id[@mrn='" . CIS_mrn . "']"
		if (CIS_mrn = "") {											; skip if null
			continue
		}
		CIS_name := clip_elem[clip_num,colIdx["Name"]]
			CIS_name_last := Trim(StrX(CIS_name, ,0,0, ", ",1,2))		; Last name
			CIS_name_first := Trim(StrX(CIS_name, ", ",0,2, " ",1,0))	; First name
		CIS_loc := clip_elem[clip_num,colIdx["Room"]]
			CIS_loc_unit := StrX(CIS_loc, ,0,0, " ",1,1)				; Unit
			CIS_loc_room := StrX(CIS_loc, " ",1,1, " ",1,0)				; Room number
			if (CIS_loc_room="") {
				CIS_loc_room := CIS_loc_unit
				CIS_loc_unit := ((CIS_loc_unit ~= "FA\.6\.2\d{2}\b") 
					? "CICU-F6"
					: ((CIS_loc_unit ~= "RC\.6\.\d{3}\b")
						? "SUR-R6" 
						: ""))
			}
		CIS_attg := clip_elem[clip_num,colIdx["Attg"]]					; Attending
			StrX(CIS_attg,",",1,2," ",1,2,n )							; Get ATTG last,first name
			CIS_attg := substr(CIS_attg,1,n)
		CIS_adm_full := clip_elem[clip_num,colIdx["Adm"]]				; Admit date/time
			CIS_admit := StrX(CIS_adm_full, ,0,0, " ",1,0)
		CIS_sex := clip_elem[clip_num,colIdx["Sex"]]					; Sex
		CIS_age := clip_elem[clip_num,colIdx["Age"]]					; Age
		CIS_svc := clip_elem[clip_num,colIdx["Svc"]]					; Service
		CIS_dob := clip_elem[clip_num,colIdx["DOB"]]					; DOB
		;															Now fix some issues we have with CIS labelling
		if (ObjHasValue(cicuDocs,CIS_attg) and !(RegExMatch(CIS_svc,"i)(Cardiology)|(Cardiac Surgery)|(Cardiac Transplant)"))) {
			CIS_svc := "Cardiac Surgery"
		}
		if (CIS_name_last="ZTEST")
			continue
		if !IsObject(y.selectSingleNode(MRNstring)) {				; If no MRN node exists, create it.
			y.addElement("id", "root", {mrn: CIS_mrn})
			y.addElement("demog", MRNstring)
			FetchNode("diagnoses")									; Check for existing node in Archlist,
			FetchNode("notes")										; retrieve old Dx, Notes, Plan. (Status is discarded)
			FetchNode("plan")										; Otherwise, create placeholders.
			FetchNode("prov")
		} else {													; Otherwise clear old demog & loc info.
			RemoveNode(MRNstring . "/demog")
			y.insertElement("demog", MRNstring . "/diagnoses")		; Insert before "diagnoses" node.
		}
		; Fill with data from CIS list.
		y.addElement("name_last", MRNstring . "/demog", CIS_name_last)
		y.addElement("name_first", MRNstring . "/demog", CIS_name_first)
		y.addElement("data", MRNstring . "/demog", {date: timenow})
		y.addElement("sex", MRNstring . "/demog/data", CIS_sex)
		y.addElement("dob", MRNstring . "/demog/data", CIS_dob)
		y.addElement("age", MRNstring . "/demog/data", CIS_age)
		y.addElement("service", MRNstring . "/demog/data", CIS_svc)
		y.addElement("attg", MRNstring . "/demog/data", CIS_attg)
		y.addElement("admit", MRNstring . "/demog/data", CIS_adm_full)
		y.addElement("unit", MRNstring . "/demog/data", CIS_loc_unit)
		y.addElement("room", MRNstring . "/demog/data", CIS_loc_room)
		y.addElement("mrn", "/root/lists/" . location, CIS_mrn)
		
		; Auto label Transplant patients admitted by Txp attg
		if !IsObject(y.selectSingleNode(MRNstring "/status")) {							; If no status, add it.
			y.addElement("status", MRNstring)
		}
		if (ObjHasValue(txpDocs,CIS_attg)) {											; If matches TxpDocs list
			y.selectSingleNode(MRNstring "/status").setAttribute("txp", "on")			; Set status flag.
		}
		if (location="TXP" and ((CIS_svc="Cardiology") or (CIS_svc="Cardiac Surgery"))) {	; If on TXP list AND on CRD or CSR
			y.selectSingleNode(MRNstring "/status").setAttribute("txp", "on")				; Set status flag.
		}
	}
	listsort(location)
	y.save("currlist.xml")
	eventlog(location " list updated.")
	FileDelete, .currlock
	gosub PrintIt
Return
}

processCORES: 										;*** Parse CORES Rounding/Handoff Report
{
	filecheck()
	FileOpen(".currlock", "W")													; Create lock file.
	y := new XML("currlist.xml")												; load freshest currlist into memory

	Progress, b,, Scanning...
	RemoveNode("/root/lists/cores")
	y.addElement("cores", "/root/lists", {date: timenow})

	GuiControl, Main:Text, GUIcoresTXT, %timenow%
	GuiControl, Main:Text, GUIcoresChk, ***
	Gui, Main:Submit, NoHide
	N:=1, n0:=0, n1:=0
	
	While clip {
		ptBlock := StrX( clip, "Patient Information" ,N,21, "Patient Information" ,1,19, N )
		if instr(ptBlock,"CORES Rounding") {
			ptBlock := StrX( ptBlock, "",1,1, "CORES Rounding" ,1,15)
		}
		if instr(ptBlock,"Contacts 1`r") {
			ptBlock := StrX( ptBlock, "",1,1, "Contacts 1" ,1,11)
		}
		if (ptBlock = "") {
			break   ; end of clip reached
		} else {
		NN = 1
		CORES_Loc := StrX( ptBlock, "" ,NN,2, "`r" ,1,1, NN )			; Line 1
		CORES_Name := StrX( ptBlock, "`r" ,NN,2, "`r" ,1,1, NN )		; Line 2
			CORES_name_last := Trim(StrX(CORES_name, ,0,0, ", ",1,2))			
			CORES_name_first := Trim(StrX(CORES_name, ", ",0,2, " ",1,0))	
		Progress,,, % CORES_name_last ", " CORES_name_first
		CORES_MRN := StrX( ptBlock, "`r" ,NN,2, "`r" ,1,4, NN )					; Line 3
		CORES_DCW := StrX( ptBlock, "DCW: " ,1,5, "`r" ,1,1, NN )				; skip to Line 5
		CORES_Alls := StrX( ptBlock, "Allergy: " ,1,9, "`r" ,1,1, NN )			; Line 6
		CORES_Code := StrX( ptBlock, "Code Status: " ,1,13, "`r" ,1,1, NN )		; Line 7
		CORES_HX =
		CORES_HX := StrX( ptBlock, "`r" ,NN,2, "Medications`r" ,1,12, NN )
			StringReplace, CORES_hx, CORES_hx, •%A_space%, *%A_Space%, ALL
			StringReplace, CORES_hx, CORES_hx, `r`n, <br>, ALL
			StringReplace, CORES_hx, CORES_hx, Medical History, <hr><b><i>Medical History</i></b>
			StringReplace, CORES_hx, CORES_hx, ID Statement, <hr><b><i>ID Statement</i></b>
			StringReplace, CORES_hx, CORES_hx, Active Issues, <hr><b><i>Active Issues</i></b>
			StringReplace, CORES_hx, CORES_hx, Social Hx, <hr><b><i>Social Hx</i></b>
			StringReplace, CORES_hx, CORES_hx, Action Items - To Dos, <hr><b><i>Action Items - To Dos</i></b>
		CORES_MedBlock = 
		CORES_MedBlock := StrX( ptBlock, "Medications`r" ,NN,12, "Contacts" ,1,9, NN )
		CORES_Drips := StrX( CORES_MedBlock, "`nDRIPS`r" ,1,6, "SCH MEDS" ,1,9 )
		CORES_Meds := StrX( CORES_MedBlock, "`nSCH MEDS`r" ,1,9, "PRN" ,1,4 )
		CORES_PRN := StrX( CORES_MedBlock, "`nPRN`r" ,1,4, "Contacts" ,1,9 )
			CORES_PRNdiet1 = 
			CORES_PRNdiet2 = 
			StringReplace, CORES_PRN, CORES_PRN, `nDiet, ``, All
			StringSplit, CORES_PRNdiet, CORES_PRN, ``
			CORES_PRN := CORES_PRNdiet1
			CORES_Diet := CORES_PRNdiet2
		CORES_vsBlock := StrX( ptBlock, "Vitals`r" ,NN,7, "Ins/Outs" ,1,8, NN ) ; ...,1,8, NN)
			CORES_vsWt := StrX( CORES_vsBlock, "Meas Wt:",0,8, "`r`nT " ,1,4, NNN)
				if (instr(CORES_vsWt,"No current data available")) {
					CORES_vsWt := "n/a"
				}
			CORES_vsTmp := RTrim(StrX( CORES_vsBlock, "`r`nT ",NNN,4, "HR " ,1,3, NNN), " M")
			CORES_vsHR := StrX(StrX( CORES_vsBlock, "HR ",NNN,3, "RR", 1,3, NNN),"",0,0,"MHR",1,3)
			CORES_vsRR := StrX( CORES_vsBlock, "RR",NNN,3, "`r`n", 1,1, NNN)
			CORES_vsNBP := StrX( CORES_vsBlock, "NIBP",NNN,5, "`r`n", 1,1, NNN)
			CORES_vsSat := StrX( CORES_vsBlock, "SpO2",NNN,5, "`r`n",1,1, NNN)
			CORES_vsPain := StrX( CORES_vsBlock, "`r`n" ,NNN-1 ,1, "",1,1, NNN)
		CORES_IOBlock := StrX( ptBlock, "Ins/Outs" ,NN,8, "Labs (72 Hrs)" ,1,14, NN)
			CORES_ioIn := StrX( CORES_IOBlock, "In=",0,4, "`r`n",1,1)
			CORES_ioPO := StrX( CORES_IOBlock, "Oral=",0,6, "`r`n",1,1)
			CORES_ioOut := StrX( CORES_IOBlock, "Out=",0,5, "`r`n",1,1)
			CORES_ioCT := StrX( CORES_IOBlock, "Chest Tube=",0,11, "`r`n",1,1)
			CORES_ioNet := StrX( CORES_IOBlock, "IO Net=",0,8, "`r`n",1,1)
			CORES_ioUOP := StrX( CORES_IOBlock, "UOP=",0,5, "`r`n",1,1)
		CORES_LabsBlock := StrX( ptBlock, "Labs (72 Hrs)" ,NN,24, "Notes`r" ,1,6, NN )
		CORES_NotesBlock := StrX( ptBlock, "Notes`r" ,NN,6, "CORES Round" ,1,12, NN )
		
		n0 += 1
		; List parsed, now place in XML(y)
		y.addElement("mrn", "/root/lists/cores", CORES_mrn)
		MRNstring := "/root/id[@mrn='" . CORES_mrn . "']"
		if !IsObject(y.selectSingleNode(MRNstring)) {		; If no arch record, create it.
			y.addElement("id", "root", {mrn: CORES_mrn})
			y.addElement("demog", MRNstring)
				y.addElement("name_last", MRNstring . "/demog", CORES_name_last)	
				y.addElement("name_first", MRNstring . "/demog", CORES_name_first)	; would keep since name could change
			y.addElement("diagnoses", MRNstring)
			y.addElement("notes", MRNstring)
			y.addElement("plan", MRNstring)
			n1 += 1
		}
		; Remove the old Info nodes
		Loop % (infos := y.selectNodes(MRNstring "/info")).length
		{
			tmpdt := infos.Item(A_index-1).getAttribute("date")
			tmpTD := tmpdt
			tmpTD -= A_now, Days
			if ((tmpTD < -7) or (substr(tmpdt,1,8) = substr(A_now,1,8))) {			; remove old nodes or replace info/mar from today.
			;if (tmpTD < -7)  {														; remove old nodes.
				RemoveNode(MRNstring "/info[@date='" tmpdt "']")
			}
		}
		Loop % (infos := y.selectNodes(MRNstring "/MAR")).length					; remove old MAR except for this run.
		{
			tmpdt := infos.Item(A_Index-1).getAttribute("date")
			if (tmpdt!=timenow) {
				RemoveNode(MRNstring "/MAR[@date='" tmpdt "']")
			}
		}
	
		y.addElement("info", MRNstring, {date: timenow})	; Create a new /info node
		yInfoDt := MRNstring . "/info[@date='" timenow "']"
			y.addElement("dcw", yInfoDt, CORES_DCW)
			y.addElement("allergies", yInfoDt, CORES_Alls)
			y.addElement("code", yInfoDt, CORES_Code)
			if !(y.selectSingleNode(yInfoDt "/hx").text)
				y.addElement("hx", yInfoDt, CORES_HX)
			y.addElement("vs", yInfoDt)
				y.addElement("wt", yInfoDt "/vs", StrX(CORES_vsWt,,1,1,"kg",1,2,NN))
				if (tmp:=StrX(CORES_vsWt,"(",NN,2,")",1,1))
					y.selectSingleNode(yInfoDt "/vs/wt").setAttribute("change", tmp)
				y.addElement("temp", yInfoDt "/vs", CORES_vsTmp)
				y.addElement("hr",   yInfoDt "/vs", CORES_vsHR)
				y.addElement("rr",   yInfoDt "/vs", CORES_vsRR)
				y.addElement("bp",   yInfoDt "/vs", CORES_vsNBP)
				y.addElement("spo2", yInfoDt "/vs", CORES_vsSat)
				y.addElement("pain", yInfoDt "/vs", CORES_vsPain)
			y.addElement("io", yInfoDt )
				y.addElement("in",  yInfoDt "/io", CORES_ioIn)
				y.addElement("po",  yInfoDt "/io", CORES_ioPO)
				y.addElement("out", yInfoDt "/io", CORES_ioOut)
				y.addElement("ct",  yInfoDt "/io", CORES_ioCT)
				y.addElement("net", yInfoDt "/io", CORES_ioNet)
				y.addElement("uop", yInfoDt "/io", CORES_ioUOP)
			y.addElement("labs", yInfoDt )
				parseLabs(CORES_labsBlock)
			y.addElement("notes", yInfoDt , CORES_NotesBlock)
		if !isobject(y.selectSingleNode(MRNstring "/MAR"))
			y.addElement("MAR", MRNstring)											; Create a new /MAR node
		y.selectSingleNode(MRNstring "/MAR").setAttribute("date", timenow)			; Change date to now
		if !(y.selectNodes(MRNstring "/MAR/*").length) {							; Populate only if empty
			yMarDt := MRNstring "/MAR[@date='" timenow "']"
				MedListParse("drips",CORES_Drips)
				MedListParse("meds",CORES_Meds)
				MedListParse("prn",CORES_PRN)
				MedListParse("diet",CORES_Diet)
			}
		}
	}
	Progress off
	y.save("currlist.xml")
	eventlog("CORES data updated.")
	FileDelete, .currlock
	Return
}

parseLabs(block) {
	global y, MRNstring, timenow
	yLabDt := MRNstring "/info[@date='" timenow "']/labs"
	while (block) {																	; iterate through each section of the lab block
		labsec := labGetSection(block)
		labs := labSecType(labsec.res)
		if (labs.type="CBC") {
			y.addElement("CBC", yLabDt, {old:labsec.old, new:labsec.new})
				y.addElement("legend", yLabDt "/CBC", labsec.date)
				y.addElement("WBC", yLabDt "/CBC", labs.wbc)
				y.addElement("Hgb", yLabDt "/CBC", labs.hgb)
				y.addElement("Hct", yLabDt "/CBC", labs.hct)
				y.addElement("Plt", yLabDt "/CBC", labs.plt)
				y.addElement("rest", yLabDt "/CBC", labs.rest)
		}
		if (labs.type="Lytes") {
			y.addElement("Lytes", yLabDt, {old:labsec.old, new:labsec.new})
				y.addElement("legend", yLabDt "/Lytes", labsec.date)
				y.addElement("Na", yLabDt "/Lytes", labs.na)
				y.addElement("K", yLabDt "/Lytes", labs.k)
				y.addElement("HCO3", yLabDt "/Lytes", labs.HCO3)
				y.addElement("Cl", yLabDt "/Lytes", labs.Cl)
				y.addElement("BUN", yLabDt "/Lytes", labs.BUN)
				y.addElement("Cr", yLabDt "/Lytes", labs.Cr)
				y.addElement("Glu", yLabDt "/Lytes", labs.glu)
				(labs.ABG) ? y.addElement("ABG", yLabDt "/Lytes", labs.ABG) : ""
				(labs.iCA) ? y.addElement("iCA", yLabDt "/Lytes", labs.iCA) : ""
				(labs.ALT) ? y.addElement("ALT", yLabDt "/Lytes", labs.ALT) : ""
				(labs.AST) ? y.addElement("AST", yLabDt "/Lytes", labs.AST) : ""
				(labs.PTT) ? y.addElement("PTT", yLabDt "/Lytes", labs.PTT) : ""
				(labs.INR) ? y.addElement("INR", yLabDt "/Lytes", labs.INR) : ""
				(labs.Alb) ? y.addElement("Alb", yLabDt "/Lytes", labs.Alb) : ""
				(labs.Lac) ? y.addElement("Lac", yLabDt "/Lytes", labs.Lac) : ""
				(labs.CRP) ? y.addElement("CRP", yLabDt "/Lytes", labs.CRP) : ""
				(labs.ESR) ? y.addElement("ESR", yLabDt "/Lytes", labs.ESR) : ""
				(labs.DBil) ? y.addElement("DBil", yLabDt "/Lytes", labs.DBil) : ""
				(labs.IBil) ? y.addElement("IBil", yLabDt "/Lytes", labs.IBil) : ""
				y.addElement("rest", yLabDt "/Lytes", labs.rest)
		}
		if (labs.type="Other") {
			y.addElement("Other", yLabDt, {old:labsec.old, new:labsec.new}, labsec.date)
				y.addElement("rest", yLabDt "/Other", labs.rest)
		}
	}
	return
}

labGetSection(byref block) {
/*	Separates block by date-delineated next section
	Returns result.date (date block), result.res (text block to next section)
	and truncated block byRef.
	Next iteration will keep truncating until no more block
*/
	str = \d{1,2}\/\d{1,2}\s\d{2}:\d{2}
	sepOld := "(\(\))=" str
	sepNew := "(\[\])=" str
	sep := "(\(\)|\[\])=" str 
	sepLine := "(" sep ".*)+.*\R"
	from := RegExMatch(block,"O)"sepline,match1)
	to := RegExMatch(block,"O)"sepline,match2,match1.len())
	
	blockDate := match1.value()
	RegExMatch(blockDate,"O)"sepOld,dateOld)
	RegExMatch(blockDate,"O)"sepNew,dateNew)
	
	blockNext := match2.value()
	blockRes := strX(block,blockDate,from,match1.len(),blockNext,1,match2.len(),n)
	block := substr(block,n)
	return {date:trim(blockDate," `t`r`n"), old:labDate(dateOld.value), new:labDate(dateNew.value), res:trim(blockRes," `t`r`n")}
}

labDate(str) {
	dateForm = \d{2}\/\d{2}\s\d{2}:\d{2}
	strDate := RegExMatch(str,"O)"dateForm,res)
	v := res.value()
	if !v
		return Error
	StringReplace, v, v, %A_Space%,, All
	StringReplace, v, v, /,, All
	StringReplace, v, v, :,, All
	FormatTime, yr, %A_now%, yyyy
	v := yr . v
return v
}


labSecType(block) {
	global y, MRNstring
	x := Object()
	topsec := strX(block,,1,0,"`r`n`r`n",1,2,n)
	loop, parse, topsec, `n
	{
		row := A_Index
		k := RegExReplace(trim(A_LoopField),"\s+"," ")
		StringSplit, el, k, %A_Space%
		loop, %el0%																		; generate fingerprint
		{
			sub := el%A_Index%
			if (sub ~= "\d{1,3}\.\d{1,3}") {											; decimals
				fing .= "D"
				x[row,A_Index] := sub
			}
			else if (sub ~= "\d{1,3}") {												; whole numbers
				fing .= "W"
				x[row,A_Index] := sub
			}
		}
		fing .= "N"																		; end line
	}
	botsec := SubStr(block,n)
	if (RegExMatch(botsec,"O)[67]\.\d+\s\/\s\d+\s\/\s\d+\s.*",abg)) {
		botsec := RegExReplace(botsec,"[67]\.\d{1,2}\s\/\s\d+\s\/\s\d+\s.*","")
	}
	if (RegExMatch(botsec,"O)(ICa\:)(.*)\d{1,2}",iCA)) {
		botsec := RegExReplace(botsec,"(ICa\:)(.*)\d{1,2}","")
	}
	if (RegExMatch(botsec,"O)ALT\s(.*)\d{2,4}",ALT)) {
		botsec := RegExReplace(botsec,"ALT\s(.*)\d{2,4}","")
	}
	if (RegExMatch(botsec,"O)AST\s(.*)\d{2,4}",AST)) {
		botsec := RegExReplace(botsec,"AST\s(.*)\d{2,4}","")
	}
	if (RegExMatch(botsec,"O)PTT\s>?\d{2,3}",PTT)) {
		botsec := RegExReplace(botsec,"PTT\s>?\d{2,3}","")
	}
	if (RegExMatch(botsec,"O)Pt.INR\s[<>0-9\.]+",INR)) {
		botsec := RegExReplace(botsec,"Pt.INR\s[<>0-9.]+","")
	}
	if (RegExMatch(botsec,"O)Alb\s[<>0-9\.]+",Alb)) {
		botsec := RegExReplace(botsec,"Alb\s[<>0-9.]+","")
	}
	if (RegExMatch(botsec,"O)Lac\s[<>0-9\.]+",Lac)) {
		botsec := RegExReplace(botsec,"Lac\s[<>0-9.]+","")
	}
	if (RegExMatch(botsec,"O)CRP\s[<>0-9\.]+.*",CRP)) {
		botsec := RegExReplace(botsec,"CRP\s[<>0-9.]+.*","")
	}
	if (RegExMatch(botsec,"O)ESR\s[<>0-9\.]+.*",ESR)) {
		botsec := RegExReplace(botsec,"ESR\s[<>0-9.]+.*","")
	}
	if (RegExMatch(botsec,"O)D Bili\s[<>0-9.]+.*",DBil)) {
		botsec := RegExReplace(botsec,"D Bili\s[<>0-9\.]+.*","")
	}
	if (RegExMatch(botsec,"O)I Bili\s[<>0-9.]+.*",IBil)) {
		botsec := RegExReplace(botsec,"I Bili\s[<>0-9\.]+.*","")
	}
	;~ if (RegExMatch(botsec,"O)^\s*\W+\s*\[?[0-9.]+\]?\s*?$")) {
		;~ botsec := RegExReplace(botsec,"^\s*\W+\s*\[?[0-9.]+\]?\s*?$","")
	;~ }
	
	if (fing ~= "WW.?NDW.?N") {
		return {type:"Lytes", Na:x[1,1], HCO3:x[1,2], BUN:x[1,3], K:x[2,1], Cl:x[2,2], Cr:x[2,3], Glu:x[3,1]
			, ABG:abg.value(), iCA:iCA.value(), ALT:ALT.value(), AST:AST.value(), PTT:PTT.value(), INR:INR.value()
			, Alb:Alb.value(), Lac:Lac.value(), CRP:CRP.value(), ESR:ESR.value(),DBil:DBil.value(), IBil:IBil.value()
			, rest:botsec}
	} else if (fing ~= "DDNDNWN") {
		return {type:"CBC", WBC:x[1,1], Hgb:x[1,2], Hct:x[2,1], Plt:x[3,1], rest:botsec}
	} else {
		return {type:"Other", rest:block}
	}
}

listsort(list,parm="",ord:="") {
/*	Sort a given list:
		arg list =	location list to sort (e.g. CICUSur, EP, ICUCons, CSR, CICU, TXP, Cards, Ward, PHTN)
		opt parm =	sort key from ptParse (e.g. Svc, Unit, Room, StatCons)
					if "", calcs service sort order (CSR, CRD, TXP, PICU, NICU, etc), adds points for consult and not on list.
		opt ord =	-1 for descending
	Reads MRNs from existing /root/lists/list node.
	Sorts list by criteria.
	Rewrites old node with newly sorted order.
*/
	global y, teamSort
	var := Object()
	col := ["mrn","sort","Room","Unit","Svc"]
	node := y.selectSingleNode("/root/lists/" . list)
	Loop % (mrns := node.selectNodes("mrn")).length 
	{
		mrn := mrns.Item(A_index-1).text
		pt := ptParse(mrn)
		ptSort := (inList:=ObjHasValue(teamSort,pt.svc))*10 + (pt.statcons) + (!(inList))*100
		var[A_Index] := {mrn:mrn,sort:ptSort,room:pt.Room,unit:pt.Unit,svc:pt.svc}
	}
	if !(parm) {									; special sort: Svc->Unit->Room->ptSort
		i:=5
		while i>1 {
			sort2D(var,col[i])
			i -= 1
		}
	} else {
		sort2D(var,ObjHasValue(col,parm))
	}
	removeNode("/root/lists/" list)
	FormatTime, now, A_Now, yyyyMMddHHmm
	node := y.addElement(list,"/root/lists",{date:now})
	for key,val in var {
		y.addElement("mrn","/root/lists/" list,var[A_index].mrn)
	}
;	y.viewXML()
}

Sort2D(Byref TDArray, KeyName, Order=1) {
/*	modified from https://sites.google.com/site/ahkref/custom-functions/sort2darray	
	TDArray : a two dimensional TDArray
	KeyName : the key name to be sorted
	Order: 1:Ascending 0:Descending
*/
	For index2, obj2 in TDArray {           
		For index, obj in TDArray {
			if (lastIndex = index)
				break
			if !(A_Index = 1) && ((Order=1) ? (TDArray[prevIndex][KeyName] > TDArray[index][KeyName]) : (TDArray[prevIndex][KeyName] < TDArray[index][KeyName])) {    
			   tmp := TDArray[index]
			   TDArray[index] := TDArray[prevIndex]
			   TDArray[prevIndex] := tmp  
			}         
			prevIndex := index
		}     
		lastIndex := prevIndex
	}
}

readForecast:
{
/*	Parse the block into another table:
	[3/1/15] [PM/Weekend_A] [PM/Weekend_F] [Ward_A] [Ward_F] [ICU_A] [ICU_F] ...
	[3/2/15] ... ... ...
	
	Move into /lists/forecast/call {date=20150301}/<PM_We_F>Del Toro</PM_We_F>
	
	nb: this does not appear to work with PDF clipboard
*/
	if !IsObject(y.selectSingleNode("/root/lists/forecast")) {
		y.addElement("forecast","/root/lists")
	}
	fcDate:=[]
	clipboard =
	clip_row := 0
	clip := substr(clip,(clip ~= fcDateline))
	Loop, parse, clip, `n, `r
	{
		clip_full := A_LoopField
		If !(clip_full)															; blank line exits scan
			break
		if (clip_full ~= fcDateline)											; ignore date header
			continue
		if (clip_full ~= "(\d{1,2}/\d{1,2}(/\d{2,4})?\t){3,}") {					; date line matches 3 or more date strings
			j := 0
			Loop, parse, clip_full, %A_Tab%
			{
				i := A_LoopField
				if (i ~= "\b\d{1,2}/\d{1,2}(/\d{2,4})?\b") {						; only parse actual date strings
					j ++
					tmp := parseDate(i)
					if !tmp.YYYY {
						tmp.YYYY := substr(sessdate,1,4)
					}
					tmpDt := tmp.YYYY . tmp.MM . tmp.DD
					fcDate[j] := tmpDt											; fill fcDate[1-7] with date strings
					if IsObject(y.selectSingleNode("/root/lists/forecast/call[@date='" tmpDt "']")) {
						RemoveNode("/root/lists/forecast/call[@date='" tmpDt "']")				; clear existing node
					}
					y.addElement("call","/root/lists/forecast", {date:tmpDt})					; and create node
				}
			} 
		} else {																; otherwise parse line
			Loop, parse, clip_full, %A_Tab%
			{
				tmpDt:=A_index
				i:=trim(A_LoopField)
				i:=RegExReplace(i,"\s+"," ")
				if (tmpDt=1) {													; first column is service
					if (j:=objHasValue(Forecast_val,i,"RX")) {						; match in Forecast_val array
						clip_nm := Forecast_svc[j]
					} else {
						clip_nm := i
						clip_nm := RegExReplace(clip_nm,"(\s+)|[\/\*\?]","_")	; replace space, /, \, *, ? with "_"
					}
					continue
				}
				y.addElement(clip_nm,"/root/lists/forecast/call[@date='" fcDate[tmpDt-1] "']",i)		; or create it
			}
		}
	}
	loop, % (fcN := y.selectNodes("/root/lists/forecast/call")).length			; Remove old call elements
	{
		k:=fcN.item(A_index-1)
		tmpDt := k.getAttribute("date")
		tmpDt -= A_Now, Days
		if (tmpDt < -1) {
			RemoveNode("/root/lists/forecast/call[@date='" k.getAttribute("date") "']")
		}
	}
	MsgBox Electronic Forecast updated.
	Writeout("/root/lists","forecast")
	Eventlog("Electronic Forecast updated.")
Return
}

SaveIt:
{
	vSaveIt:=true
	gosub GetIt														; recheck the server side currlist.xml
	vSaveIt:=
	
	filecheck()
	FileOpen(".currlock", "W")													; Create lock file.

	Progress, b w300, Processing...
	y := new XML("currlist.xml")									; Load freshest copy of Currlist
	yArch := new XML("archlist.xml")
	; Save all MRN, Dx, Notes, ToDo, etc in arch.xml
	Loop, % (yaN := y.selectNodes("/root/id")).length {				; Loop through each MRN in Currlist
		k := yaN.item((i:=A_Index)-1)
		kMRN := k.getAttribute("mrn")
		errnum=0
		Loop, % (yaList := y.selectNodes("/root/lists/*/mrn")).length {		; Compare each MRN against the list of
			yaMRN := yaList.item((j:=A_Index)-1).text						; MRNs in /root/lists
			if (kMRN == yaMRN) {											; If a hit, then move on
				errnum+=1
				continue
			}
		}
		if !(errnum) {								; If did not match, delete the ID/MRN
			yaMRN := yArch.selectSingleNode("/root/id[@mrn='" kMRN "']")					; Find equivalent MRN node in Archlist previously written in SaveIt.
			ArchiveNode("demog")
			ArchiveNode("diagnoses")
			ArchiveNode("prov")
			ArchiveNode("notes",1)						; ArchiveNode(node,1) to archive this node by today's date
			ArchiveNode("plan",1)
			errtext := errtext . "* " . k.selectSingleNode("demog/name_first").text . " " . k.selectSingleNode("demog/name_last").text . "`n"
			RemoveNode("/root/id[@mrn='" kMRN "']")
			eventlog(kMRN " removed from active lists.")
		}
	}

	Progress, 80, Compressing nodes...
	yArch.save("archlist.xml")						; Writeout
	if !(errnum) {
		Progress, hide
		MsgBox, 48
			, Database cleaning
			, % "The following patient records no longer appear `non any CIS census and have been removed `nfrom the active list:`n`n" . errtext
		Progress, 85
	}
	; =================================================
	y.save("currlist.xml")
	eventlog("Currlist cleaned up.")
	
	if !(isLocal) {
		Run pscp.exe -sftp -i chipotle-pr.ppk -p currlist.xml pedcards@homer.u.washington.edu:public_html/%servfold%/currlist.xml,, Min
		sleep 500																; CIS VM needs longer delay than 200ms to recognize window
		ConsWin := WinExist("ahk_class ConsoleWindowClass")
		IfWinExist ahk_id %consWin% 
		{
			ControlSend,, {y}{Enter}, ahk_id %consWin%
			Progress,, Console %consWin% found
		}
		WinWaitClose ahk_id %consWin%
		Run pscp.exe -sftp -i chipotle-pr.ppk -p logs/%sessdate%.log pedcards@homer.u.washington.edu:public_html/%servfold%/logs/%sessdate%.log,, Min
	}

	FileDelete, .currlock
	eventlog("CHIPS server updated.")
	Progress, 100, Saving updates...
	;Sleep, 1000

Return
}

GetIt:
{
	; ==================
	;FileDelete, .currlock
	; ==================
	filecheck()
	FileOpen(".currlock", "W")													; Create lock file.
	if !(vSaveIt=true)
		Progress, b w300, Reading data..., % "- = C H I P O T L E = -`nversion " vers
	else
		Progress, b w300, Consolidating data..., 
	Progress, 20
	
	if (isLocal) {
		FileCopy, currlist.xml, templist.xml
	} else {
		Run pscp.exe -sftp -i chipotle-pr.ppk -p pedcards@homer.u.washington.edu:public_html/%servfold%/currlist.xml templist.xml,, Min
		sleep 500
		ConsWin := WinExist("ahk_class ConsoleWindowClass")
		IfWinExist ahk_id %consWin% 
		{
			ControlSend,, {y}{Enter}, ahk_id %consWin%
			;Progress,, Console %consWin% found
			Progress,, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
		}
		WinWaitClose ahk_id %consWin%
	}
	Progress, 60, % dialogVals[Rand(dialogVals.MaxIndex())] "..."

	FileRead, templist, templist.xml					; the downloaded list.
		StringReplace, templist, templist, `r`n,, All	; AHK XML cannot handle the UNIX format when modified on server.
		StringReplace, templist, templist, `n,, All	
	z := new XML(templist)								; convert templist into XML object Z
	Progress,, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
	

	if !(FileExist("currlist.xml")) {
		z.save("currlist.xml")
	}
	FileDelete, oldlist.xml
	FileCopy, currlist.xml, oldlist.xml										; Backup currlist to oldlist.
	x := new XML("currlist.xml")											; Load currlist into working X.
	
;	 Get last dates
/*	 Cycle through lists
	 	Server lists are always old data. Currlist can be newer than the server.
		Copy Citrix copy for latest.
*/
	Loop, % (zList := z.selectNodes("/root/lists/*")).length {
		k := zList.item((i:=A_Index)-1).nodeName
		if !IsObject(x.selectSingleNode("/root/lists/" k)) {						; list does not exist on current XML
			x.addElement(k,"/root/lists")									; create a blank
		}
		locPath := x.selectSingleNode("/root/lists")
		locNode := locPath.selectSingleNode(k)
		locDate := locNode.getAttribute("date")
		remPath := z.selectSingleNode("/root/lists")
		remNode := remPath.selectSingleNode(k)
		remDate := remNode.getAttribute("date")
		if (remDate<locDate) {								; local edit is newer.
			continue
		} 
		if (remDate>locDate) {								; remote is newer than local.
			clone := remnode.cloneNode(true)
			locPath.replaceChild(clone,locNode)
		}
	}
	Progress,, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
	
	
/*	 Cycle through ID@MRN's
		<demog> - never modified. local info always newest.
		<info> - from CORES. never modified on server.
		<mar> - from CORES. never modified on server.
		<status> - can be updated.
		<diagnoses> - (notes, card, ep, surg, prob, prov) can be updated on either side.
		<notes/weekly> - (summary) updated on either side.
		<notes/progress> - (note) updated on either side.
		<plan/tasks> - (todo) updated on either side.
*/
	Loop, % (zID := z.selectNodes("/root/id")).length {				; Loop through each MRN in tempList
		k := zID.item((i:=A_Index)-1)
		kMRN := k.getAttribute("mrn")
		kMRNstring := "/root/id[@mrn='" kMRN "']"
		
		if !IsObject(x.selectSingleNode(kMRNstring)) {									; No MRN in X but exists in Z?
			clone := z.selectSingleNode(kMRNstring).cloneNode(true)
			x.selectSingleNode("/root").appendChild(clone)						; Copy entire MRN node from Z to X
			continue															; and move on.
		}
		; Check <status>
		compareDates(kMRNstring,"status")
		; Check <diagnoses>
		compareDates(kMRNstring,"diagnoses")
		
		compareDates(kMRNstring,"prov")
		if !IsObject(x.selectSingleNode(kMRNstring "/prov")) {
			x.addElement("prov", kMRNstring)
		}
		if IsObject(x.selectSingleNode(kMRNstring "/diagnoses/prov")) {
			clone := x.selectSingleNode(kMRNstring "/diagnoses/prov").cloneNode(true)
			x.selectSingleNode(kMRNstring).replaceChild(clone,x.selectSingleNode(kMRNstring "/prov"))
			x.selectSingleNode(kMRNstring "/diagnoses").removeChild(x.selectSingleNode(kMRNstring "/diagnoses/prov"))
		}
		
		; Check <trash>
		Loop % (zTrash := k.selectNodes("trash/*")).length { ; Loop through trash items.
			zTr := zTrash.item(A_Index-1)
			zTrCr := zTr.getAttribute("created")
			xTr := x.selectSingleNode(kMRNstring "/trash/*[@created='" zTrCr "']")
			if IsObject(xTr) and (zTr.text = xTr.text) {			; if exists in trash, skip to next
				continue
			} 
			if !IsObject(x.selectSingleNode(kMRNstring "/trash")) {		; make sure that <trash> exists
				x.addElement("trash", kMRNstring)
			}															; then copy the clone into <trash>
			clone := zTr.cloneNode(true)
			x.selectSingleNode(kMRNstring "/trash").appendChild(clone)
		}
		
		; Check <notes/weekly>
		Loop, % (zNotes := k.selectNodes("notes/weekly/summary")).length {	; Loop through each /root/id@MRN/notes/weekly/summary note.
			zWN := zNotes.item(A_Index-1)
			zWND := zWN.getAttribute("created")
			if IsObject(x.selectSingleNode(kMRNstring "/trash/summary[@created='" zWND "']"))
				continue
			Else
				compareDates(kMRNstring "/notes/weekly","summary[@created='" zWND "']")
		}
		; Check <notes/progress>
		
		; Check <plan/done>
		Loop, % (zTasks := k.selectNodes("plan/done/todo")).length {	; Loop through each /root/id@MRN/plan/done/todo.
			zTD := zTasks.item(A_Index-1)
			zWND := zTD.getAttribute("created")
			if IsObject(x.selectSingleNode(kMRNstring "/trash/todo[@created='" zWND "']"))
				continue
			else
				compareDates(kMRNstring "/plan/done","todo[@created='" zWND "']")
		}
		; Check <plan/tasks>
		Loop, % (zTasks := k.selectNodes("plan/tasks/todo")).length {	; Loop through each /root/id@MRN/plan/tasks/todo.
			zTD := zTasks.item(A_Index-1)
			zWND := zTD.getAttribute("created")
			if IsObject(x.selectSingleNode(kMRNstring "/trash/todo[@created='" zWND "']")) or IsObject(x.selectSingleNode(kMRNstring "/plan/done/todo[@created='" zWND "']"))
				continue
				; skip if index exists in completed or deleted.
			else
				compareDates(kMRNstring "/plan/tasks","todo[@created='" zWND "']")
		}
	}
	x.save("currlist.xml")
	y := new XML("currlist.xml")							; open fresh currlist.XML into Y
	;~ while (str := loc[i:=A_Index]) {						; get the dates for each of the lists
		;~ loc[str,"date"] := y.getAtt("/root/lists/" . str, "date")
	;~ }
	;~ DateCORES := y.getAtt("/root/lists/cores", "date")
	Progress 80, % dialogVals[Rand(dialogVals.MaxIndex())] "..."


	yArch := new XML("archlist.xml")
	if !IsObject(yArch.selectSingleNode("/root")) {			; if yArch is empty,
		yArch.addElement("root")					; then create it.
	}
	
	Loop, % (yN := y.selectNodes("/root/id")).length {				; Loop through each MRN in Currlist
		k := yN.item((i:=A_Index)-1)
		kMRN := k.getAttribute("mrn")
		if !IsObject(yaMRN:=yArch.selectSingleNode("/root/id[@mrn='" kMRN "']")) {		; If ID MRN node does not exist in Archlist,
			yArch.addElement("id","root", {mrn: kMRN})							; then create it
			yArch.addElement("demog","/root/id[@mrn='" kMRN "']")				; along with the placeholder children
			yArch.addElement("diagnoses","/root/id[@mrn='" kMRN "']")
			yArch.addElement("notes","/root/id[@mrn='" kMRN "']")
			yArch.addElement("plan","/root/id[@mrn='" kMRN "']")
			eventlog(kMRN " added to archlist.")
		}
		ArchiveNode("demog")
		ArchiveNode("diagnoses")
		ArchiveNode("prov")
		ArchiveNode("notes")
		ArchiveNode("plan")
	}
	Progress, 100, % dialogVals[Rand(dialogVals.MaxIndex())] "..."

	yArch.save("archlist.xml")											; Write out
	Sleep 500
	Progress, off
	FileDelete, .currlock
Return
}

SignOut:
{
	soText =
	loop, % (soList := y.selectNodes("/root/lists/" . location . "/mrn")).length {		; loop through each MRN in loc list
		soMRN := soList.item(A_Index-1).text
		k := y.selectSingleNode("/root/id[@mrn='" soMRN "']")
		so := ptParse(soMRN)
		soSumm := so.NameL ", " so.NameF "`t" so.Unit " " so.Room "`t" so.MRN "`t" so.Sex "`t" so.Age "`t" so.Svc "`n"
			. ((so.dxCard) ? "[DX] " so.dxCard "`n" : "")
			. ((so.dxEP) ? "[EP] " so.dxEP "`n" : "")
			. ((so.dxSurg) ? "[Surg] " so.dxSurg "`n" : "")
		loop, % (soNotes := y.selectNodes("/root/id[@mrn='" soMRN "']/notes/weekly/summary")).length {	; loop through each Weekly Summary note.
			soNote := soNotes.item(A_Index-1)
			soDate := breakDate(soNote.getAttribute("date"))
			soSumm .= "[" soDate.MM "/" soDate.DD "] "soNote.text . "`n"
		}
		soText .= soSumm "`n"
	}
	Clipboard := soText
	MsgBox Text has been copied to clipboard.
	eventlog(location " weekly signout.")
	soText =
Return
}

TeamTasks:
{
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

TeamTaskPt:
{
	LV_GetText(mrn, A_EventInfo, 3)
	Gui, ttask:Destroy
	Gosub PatListGet
Return	
}

PrintIt:
{
	TblC:="\cellx", tw:=1440							; Measured in twips (1440 = 1", 720 = 1/2", 360 = 1/4")
	rtfTblCols := 	  TblC . round(tw * 2.25)			; Location (e.g. tab stop at 1.5")
					. TblC . round(tw * 3.75)			; MRN
					. TblC . round(tw * 4.625)			; Sex/Age
					. TblC . round(tw * 5.625)			; DOB
					. TblC . round(tw * 6.5)			; Days
					. TblC . round(tw * 7.0)			; Admit date
					. TblC . round(tw * 7.875)			; Right margin

	rtfTblCol2 :=	  TblC . round(tw * 2.25)			; Diagnoses (below NAME)
					. TblC . round(tw * 5.625)			; Todo later (below DOB)
					. TblC . round(tw * 7.875)			; Right margin

	rtfList :=
	CIS_dx :=
	
	Loop, % (prList:=y.selectNodes("/root/lists/" location "/mrn")).length {
		kMRN := prList.item(i:=A_Index-1).text
		k := y.selectSingleNode("/root/id[@mrn='" kMRN "']")
		pr := ptParse(kMRN)
		pr_adm := parseDate(pr.Admit)
		CIS_adm := pr_adm.YYYY . pr_adm.MM . pr_adm.DD
		CIS_los := A_Now
		CIS_los -= CIS_adm, days
		pr_today :=
		pr_todo := "\fs12"
		if IsObject(pr_VS := k.selectSingleNode("info/vs")) {
			pr_todo .= "Wt = " . pr_VS.selectSingleNode("wt").text
					. ((i:=pr_VS.selectSingleNode("spo2").text) ? ", O2 = (" . StrX(i,,1,1," ",1,1,NN) . ") " . StrX(i," ",NN,1," ",1,1) : "")
					. "\line "
		}
		Loop, % (prMAR:=k.selectNodes("MAR/*")).length {
			prMed := prMAR.item(A_Index-1)
			prMedCl := prMed.getAttribute("class")
			if (prMedCl="cardiac") or (prMedCl="arrhythmia") {
				pr_todo .= "\f2s\f0" . prMed.text . "\line "
			}
		}
		Loop, % (plT:=k.selectNodes("plan/tasks/todo")).length {
			tMRN:=plT.item(A_Index-1)
			plD := tMRN.getAttribute("due")
			plDate := substr(plD,5,2) . "/" . substr(plD,7,2)
			plD -= A_Now, D
			if (plD<2)
				pr_today .= "\f2q\f0 (" . plDate . ") " . tMRN.text . "\line\fs12 "
			else
				pr_todo  .= "\f2q\f0 (" . plDate . ") " . tMRN.text . "\line\fs12 "
		}
		if (pr_call := pr.callN) {
			pr_call -= A_Now, D
			if (pr_call<2) {
				pr_today .= "\f2q\f0 (" breakDate(pr.callN).MM "/" breakDate(pr.callN).DD ") Call Dr. " pr.provCard "\line\fs12 "
			}
		}

		CIS_dx := ((pr.dxCard) ? "[[Dx]] " pr.dxCard "\line " : "")
				. ((pr.dxSurg) ?  "[[Surg]] " pr.dxSurg "\line " : "")
				. ((pr.dxEP) ? "[[EP]] " pr.dxEP "\line " : "")
				. ((pr.dxNotes) ? "[[Notes]] " pr.dxNotes : "")
		
		rtfList .= "\keepn\trowd\trgaph144\trkeep" rtfTblCols "`n\b"
			. "\intbl " . pr.nameL ", " pr.nameF ((pr.provCard) ? "\fs12  (" pr.provCard . ((pr.provSchCard) ? "//" pr.provSchCard : "") ")\fs18" : "") "\cell`n"
			. "\intbl " . pr.Unit " " pr.Room "\cell`n"
			. "\intbl " . kMRN "\cell`n"
			. "\intbl " . SubStr(pr.Sex,1,1) " " pr.Age "\cell`n" 
			. "\intbl " . pr.DOB "\cell`n"
			. "\intbl " . CIS_los "\cell`n"
			. "\intbl " . pr_adm.Date "\cell`n\b0"
			. "\row`n"
			. "\pard\trowd\trgaph144\trrh720\trkeep" . rtfTblCol2 . "`n"
			. "\intbl\fs12 " . pr_today "\cell`n"
			. "\intbl\fs12 " . CIS_dx "\line\cell`n"
			. "\intbl\fs12 " . pr_todo "\fs18\cell`n"
			. "\row`n"
	}

	FormatTime, rtfNow, A_Now, yyyyMMdd
	onCall := getCall(rtfNow)
	rtfCall := ((tmp:=onCall.Ward_A) ? "Ward: " tmp "   " : "")
			. ((tmp:=onCall.Ward_F) ? "Ward Fellow: " tmp "   " : "")
			. ((tmp:=onCall.ICU_A) ? "ICU: " tmp "   " : "")
			. ((tmp:=onCall.ICU_F) ? "ICU Fellow: " tmp "   " : "")
			. ((tmp:=onCall.TXP) ? "Txp: " tmp "   " : "")
			. ((tmp:=onCall.EP) ? "EP: " tmp "   " : "")
			. ((tmp:=onCall.TEE) ? "TEE: " tmp "   " : "")
	rtfCall .= ((rtfCall) ? "`n\line`n" : "")
			. ((tmp:=onCall.ARNP_CL) ? "ARNP Cath: " tmp "   " : "")
			. ((tmp:=onCall.ARNP_IP) ? "ARNP RC6: " tmp " 7-4594   " : "")
			. ((tmp:=onCall.CICU) ? "CICU: " tmp " 7-6503, Fellow: 7-6507   " : "")
			. ((tmp:=onCall.Reg_Con) ? "Reg Cons: " tmp "   " : "")
	rtfCall .= ((rtfCall) ? "`n\line`n" : "")
			. "\ul HC Fax: 987-3839   Clinic RN: 7-7693   Echo Lab: 7-2019   RC6.Charge RN: 7-2108,7-6200   RC6.UC Desk: 7-2021   FA6.Charge RN: 7-2475   FA6.UC Desk: 7-2040\ul0"
	
	rtfOut =
(
{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fnil\fcharset0 Calibri;}{\f2\fnil\fcharset2 Wingdings;}}
{\*\generator Msftedit 5.41.21.2510;}\viewkind4\uc1\lang9\f0\fs18\margl360\margr360\margt360\margb360
{\header\viewkind4\uc1\pard\f0\fs12\qc

)%rtfCall%
(
\par\line\fs18\b
CHIPOTLE Patient List:\~
)%locString%
(
\par\ql\b0
\par
{\trowd\trgaph144
)%rtfTblCols%
(
\intbl\b Name
\cell\intbl Location
\cell\intbl MRN
\cell\intbl Sex/Age
\cell\intbl DOB
\cell\intbl Day
\cell\intbl Admit
\cell\b0
\row}
\fs2\posx144\tx11160\ul\tab\ul0\par
}
{\footer\viewkind4\uc1\pard\f0\fs18\qc
Page \chpgn\~\~\~\~
)%user%
(
\~\~\~\~
\chdate\~\~\~\~
\chtime
\par\ql}

)%rtfList%
(
}`r`n
)
	fileout := "patlist-" . location . ".rtf"
	if FileExist(fileout) {
		FileDelete, %fileout%
	}
	FileAppend, %rtfOut%, %fileout%
	MsgBox, 4, Print now?, Print list: %locString%
	IfMsgBox, Yes
	{
		Run, print %fileout%
		eventlog(fileout " printed.")
	}
return
}

getCall(dt) {
	global y
	callObj := {}
	Loop, % (callDate:=y.selectNodes("/root/lists/forecast/call[@date='" dt "']/*")).length {
		k := callDate.item(A_Index-1)
		callEl := k.nodeName
		callVal := k.text
		callObj[callEl] := callVal
	}
	return callObj
}

saveCensus:
{
	FormatTime, censDate, A_Now, yyyyMMdd
	censDT := breakDate(censDate)
	censY := censDT.YYYY
	censM := censDT.MM
	censD := censDT.DD
	censFile := "logs/" censY censM ".xml"
	if (fileexist(censFile)) {
		cens := new XML(censFile)
	} else {
		cens := new XML("<root/>")
	}
	
	if !IsObject(cens.selectSingleNode(c1 := "/root/census[@day='" censD "']")) {
		cens.addElement("census", "/root", {day: censD})
		cens.addElement("Cards", c1)
		cens.addElement("CSR", c1)
		cens.addElement("TXP", c1)
	}
	
	if (cens.selectSingleNode(c1 "/" location).getAttribute("date"))	; if already done, then skip
		return
	
	cens.selectSingleNode(c1).replaceChild(y.selectSingleNode("/root/lists/" location).cloneNode(location="TXP" ? false : true), cens.selectSingleNode(c1 "/" location))
	cens.selectSingleNode(c1 "/" location).setAttribute("tot",cens.selectNodes(c1 "/" location "/mrn").length)
	if (location="TXP") {
		loop % (c2:=y.selectNodes("/root/id/status[@txp='on']")).length {
			cMRN := c2.item(i:=A_Index-1).parentNode.getAttribute("mrn")
			cUnit := y.selectSingleNode("/root/id[@mrn='" cMRN "']/demog/data/unit").text
			if !IsObject(cens.selectSingleNode(c1 "/TXP/" cUnit)) {
				cens.addElement(cUnit, c1 "/TXP")
			}
			cens.addElement("mrn", c1 "/TXP/" cUnit, cMRN)
		}
		cens.selectSingleNode(c1 "/TXP").setAttribute("tot",totTXP:=cens.selectNodes(c1 "/TXP//mrn").length)
		cens.selectSingleNode(c1 "/TXP/CICU").setAttribute("tot",totTxCICU:=cens.selectNodes(c1 "/TXP/CICU/mrn").length)
		cens.selectSingleNode(c1 "/TXP/SUR-R6").setAttribute("tot",totTxWard:=cens.selectNodes(c1 "/TXP/SUR-R6/mrn").length)
	}
	
	eventlog("CENSUS '" location "' updated.")
	cens.save(censFile)
	censCrd := cens.selectSingleNode(c1 "/Cards")
	censCSR := cens.selectSingleNode(c1 "/CSR")
	censTxp := cens.selectSingleNode(c1 "/TXP")
		
	if ((totCRD:=censCrd.getAttribute("tot")) and (totCSR:=censCSR.getAttribute("tot")) and (totTXP:=censTxp.getAttribute("tot"))) {
		totTxCICU := cens.selectSingleNode(c1 "/TXP/CICU").getAttribute("tot")
		totTxWard := cens.selectSingleNode(c1 "/TXP/SUR-R6").getAttribute("tot")
		FileAppend, % censM "/" censD "/" censY "," totCRD "," totCSR "," totTxCICU "," totTxWard "`n" , logs/census.csv
		eventlog("Daily census updated.")
	}
	return
}

IcuMerge:
{
	FormatTime, cicuDate, A_Now, yyyyMMdd
	tmpDT_crd := substr(y.selectSingleNode("/root/lists/Cards").getAttribute("date"),1,8)
	tmpDT_csr := substr(y.selectSingleNode("/root/lists/CSR").getAttribute("date"),1,8)
	tmpDT_cicu := substr(y.selectSingleNode("/root/lists/CICU").getAttribute("date"),1,8)

	cicuSurPath := "/root/lists/CICUSur"
	if IsObject(y.selectSingleNode(cicuSurPath)) {								; Clear the old list and refresh all
		removeNode(cicuSurPath)
	}
	y.addElement("CICUSur","/root/lists", {date:timenow})
	
	loop, % (c1:=y.selectNodes("/root/lists/CICU/mrn")).length {					; Copy existing ICU bed list to CICUSur
		y.addElement("mrn",cicuSurPath, c1.item(A_Index-1).text)
	}
	writeOut("/root/lists","CICUSur")

	if (tmpDT_csr=tmpDT_cicu) {													; Scan CSR list for SURGCNTR patients
		Loop, % (c2:=y.selectNodes("/root/lists/CSR/mrn")).length {
			c2mrn := c2.item(A_Index-1).text
			c2str := "/root/id[@mrn='" c2mrn "']"
			c2loc := y.selectSingleNode(c2str "/demog/data/unit").text
			if (c2loc="SURGCNTR") {
				y.addElement("mrn",cicuSurPath,c2mrn)
				WriteOut("/root/lists","CICUSur")
				if !IsObject(y.selectSingleNode(c2str "/plan/call"))
					y.addElement("call", c2str "/plan")
				tmpN = 
				tmpN += 1, day
				tmpN := substr(tmpN,1,8)
				y.selectSingleNode(c2str "/plan/call").setAttribute("next", tmpN)		; set a call for tomorrow
				WriteOut(c2str "/plan","call")
				eventlog(c2mrn " Call sequence auto-initiated.")
			}
		}
	}
	if (tmpDT_crd=tmpDT_cicu) {													; Scan Cards list for SURGCNTR patients
		Loop, % (c2:=y.selectNodes("/root/lists/Cards/mrn")).length {
			c2mrn := c2.item(A_Index-1).text
			c2str := "/root/id[@mrn='" c2mrn "']"
			c2loc := y.selectSingleNode("/root/id[@mrn='" c2mrn "']/demog/data/unit").text
			c2attg := y.selectSingleNode("/root/id[@mrn='" c2mrn "']/demog/data/attg").text
			if (c2loc="SURGCNTR" and ObjHasValue(CSRdocs,c2attg)) {
				y.addElement("mrn",cicuSurPath,c2mrn)
				WriteOut("/root/lists","CICUSur")
				if !IsObject(y.selectSingleNode(c2str "/plan/call"))
					y.addElement("call", c2str "/plan")
				tmpN = 
				tmpN += 1, day
				tmpN := substr(tmpN,1,8)
				y.selectSingleNode(c2str "/plan/call").setAttribute("next", tmpN)		; set a call for tomorrow
				WriteOut(c2str "/plan","call")
				eventlog(c2mrn " Call sequence auto-initiated.")
			}
		}
	}
return
}

PtParse(mrn) {
	global y
	mrnstring := "/root/id[@mrn='" mrn "']"
	pl := y.selectSingleNode(mrnstring)
	return {"NameL":pl.selectSingleNode("demog/name_last").text
		, "NameF":pl.selectSingleNode("demog/name_first").text
		, "Sex":pl.selectSingleNode("demog/data/sex").text
		, "DOB":pl.selectSingleNode("demog/data/dob").text
		, "Age":pl.selectSingleNode("demog/data/age").text
		, "Svc":pl.selectSingleNode("demog/data/service").text
		, "Unit":pl.selectSingleNode("demog/data/unit").text
		, "Room":pl.selectSingleNode("demog/data/room").text
		, "Admit":pl.selectSingleNode("demog/data/admit").text
		, "Attg":pl.selectSingleNode("demog/data/attg").text
		, "dxCard":pl.selectSingleNode("diagnoses/card").text
		, "dxEP":pl.selectSingleNode("diagnoses/ep").text
		, "dxSurg":pl.selectSingleNode("diagnoses/surg").text
		, "dxNotes":pl.selectSingleNode("diagnoses/notes").text
		, "dxProb":pl.selectSingleNode("diagnoses/prob").text
		, "statCons":(pl.selectSingleNode("status").getAttribute("cons") == "on")
		, "statTxp":(pl.selectSingleNode("status").getAttribute("txp") == "on")
		, "statRes":(pl.selectSingleNode("status").getAttribute("res") == "on")
		, "statScamp":(pl.selectSingleNode("status").getAttribute("scamp") == "on")
		, "callN":pl.selectSingleNode("plan/call").getAttribute("next")
		, "callL":pl.selectSingleNode("plan/call").getAttribute("last")
		, "callBy":pl.selectSingleNode("plan/call").getAttribute("by")
		, "CORES":pl.selectSingleNode("info/hx").text
		, "info":pl.selectSingleNode("info")
		, "MAR":pl.selectSingleNode("MAR")
		, "daily":pl.selectSingleNode("notes/daily")
		, "ccSys":pl.selectSingleNode("ccSys")
		, "ProvCard":y.getAtt(mrnstring "/prov","provCard")
		, "ProvSchCard":y.getAtt(mrnstring "/prov","SchCard")
		, "ProvEP":y.getAtt(mrnstring "/prov","provEP")
		, "ProvPCP":y.getAtt(mrnstring "/prov","provPCP")}
}

PatNode(mrn,path,node) {
	global y
	return y.selectSingleNode("/root/id[@mrn='" mrn "']/" path "/" node)
}

ReplacePatNode(path,node,value) {
	global y
	if (k := y.selectSingleNode(path "/" node)) {	; Node exists, even if empty.
		y.setText(path "/" node, value)
	} else {
		y.addElement(node, path, value)
	}
}

SetStatus(mrn,node,att,value) {
	global y, user
	k := y.selectSingleNode("/root/id[@mrn='" mrn "']/" node)
	k.setAttribute(att, ((value=1) ? "on" : ""))
	FormatTime, tmpdate, A_Now, yyyyMMddHHmmss
	k.setAttribute("ed", tmpdate)
	k.setAttribute("au", user)
}

WriteOut(path,node) {
/* 
	Prevents concurrent writing of y.MRN data. If someone is saving data (.currlock exists), script will wait
	approx 6 secs and check every 50 msec whether the lock file is removed. When available it creates clones the y.MRN
	node, loads a fresh currlist into Z (latest update), replaces the z.MRN node with the cloned y.MRN node,
	saves it, then reloads this currlist into Y.
*/
	global y
	filecheck()
	FileOpen(".currlock", "W")													; Create lock file.
	locPath := y.selectSingleNode(path)
	locNode := locPath.selectSingleNode(node)
	clone := locNode.cloneNode(true)											; make copy of y.node

	z := new XML("currlist.xml")												; open most recent existing currlist.XML into temp Z
	if !IsObject(z.selectSingleNode(path "/" node)) {
		z.addElement(node,path)
	}
	zPath := z.selectSingleNode(path)											; find same "node" in z
	zNode := zPath.selectSingleNode(node)
	zPath.replaceChild(clone,zNode)												; replace existing zNode with node clone

	z.save("currlist.xml")														; write z into currlist
	y := new XML("currlist.xml")												; reload currlist into y
	FileDelete, .currlock														; release lock file.
}

filecheck() {
	if FileExist(".currlock") {
		err=0
		Progress, , Waiting to clear lock, File write queued...
		loop 50 {
			if (FileExist(".currlock")) {
				progress, %p%
				Sleep 50
				p += 1
			} else {
				err=1
				break
			}
		}
		if !(err) {
			;~ Progress off
			;~ MsgBox This file appears to be locked.
			FileDelete, .currlock
			;~ ExitApp
		}
	} 
	progress off
}

compareDates(path,node) {
	global x, y, z, zWND, kMRNstring, dialogVals
	;progress,,%node%
	progress,, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
	if !IsObject(z.selectSingleNode(path "/" node))					; If does not exist in Z, return
		return
	if !IsObject(x.selectSingleNode(path "/" node)) {				; If no node exists in X, create a placeholder
		if (substr(node,1,7)="summary") {
			if !IsObject(x.selectSingleNode(kMRNstring "/notes"))
				x.addElement("notes", kMRNstring)
			if !IsObject(x.selectSingleNode(kMRNstring "/notes/weekly"))
				x.addElement("weekly", kMRNstring "/notes")
			x.addElement("summary", path, {created: zWND})		; Summary requires date attribute
			err := true
		} 
		if (substr(node,1,4)="todo") {
			if !IsObject(x.selectSingleNode(kMRNstring "/plan"))
				x.addElement("plan", kMRNstring)
			if !IsObject(x.selectSingleNode(kMRNstring "/plan/tasks"))
				x.addElement("tasks", kMRNstring "/plan")
			x.addElement("todo", path, {created: zWND})
			err := true
		} 
		if !(err) {
			x.addElement(node, path)							; Everything else just needs an element.
			err = true
		}
	}
	locPath := x.selectSingleNode(path)
	locNode := locPath.selectSingleNode(node)
	locDate := locNode.getAttribute("ed")
	remPath := z.selectSingleNode(path)
	remNode := remPath.selectSingleNode(node)
	remDate := remNode.getAttribute("ed")
	clone := remnode.cloneNode(true)

	if (remDate<locDate) {								; local edit is newer.
		return
	} 
	if (remDate>locDate) {								; remote is newer than local.
		locPath.replaceChild(clone,locNode)
		return
	} 
	if (remDate="") {									; No date exists.
		FormatTime, tmpdate, A_Now, yyyyMMddHHmmss		; add it.
		locNode.setAttribute("ed", tmpdate)
		return
	}
}

ArchiveNode(node,i:=0) {
	global y, yArch, kMRN											; Initialize global variables
	MRN := "/root/id[@mrn='" kMRN "']"
	x := y.selectSingleNode(MRN "/" node)							; Get "node" from k (y.id[mrn])
	if !IsObject(x) {
		;MsgBox Fail
		return
	}
	clone := x.cloneNode(true)											; make a copy
	if !IsObject(yArch.selectSingleNode(MRN "/" node))					; if no node exists,
		yArch.addElement(node,MRN)										; create it.
	arcX := yArch.selectSingleNode(MRN "/" node)						; get the node, whether existant or new
	yArch.selectSingleNode(MRN).replaceChild(clone,arcX)				; replace arcX with the clone.
	
	if ((node="demog") and (yArch.selectSingleNode(MRN "/demog/data"))){
		yArch.selectSingleNode(MRN "/demog").removeChild(yArch.selectSingleNode(MRN "/demog/data"))
	}
	
	if (i=1)	{														; create <id/archive/discharge[date=now]>
		if !IsObject(yArch.selectSingleNode(MRN "/archive")) {
			yArch.addElement("archive",MRN)
		}
		FormatTime, dcdate, A_Now, yyyyMMdd
		yArch.addElement("dc",MRN "/archive", {date: dcdate})
		yArch.selectSingleNode(MRN "/archive/dc[@date='" dcdate "']").appendChild(clone)
	}																	; move element here
}

FetchNode(node) {
	global
	local x, clone
	if IsObject(yArch.selectSingleNode(MRNstring "/" node)) {		; Node arch exists
		x := yArch.selectSingleNode(MRNstring "/" node)
		clone := x.cloneNode(true)
		y.selectSingleNode(MRNstring).appendChild(clone)			; using appendChild as no Child exists yet.
	} else {
		y.addElement(node, MRNstring)								; If no node arch exists, create placeholder
	}
}

RemoveNode(node) {
	global
	local q
	q := y.selectSingleNode(node)
	q.parentNode.removeChild(q)
}

MedListParse(medList,bList) {								; may bake in y.ssn(//id[@mrn='" mrn "'/MAR")
	global meds1, meds2, meds0, y, MRNstring, yMarDt
	tempArray = 
	medWords =
	StringReplace, bList, bList, •%A_space%, ``, ALL
	StringSplit, tempArray, bList, ``
	Loop, %tempArray0%
	{
		if (StrLen(medName:=tempArray%A_Index%)<3)													; Discard essentially blank lines
			continue
		medName:=RegExReplace(medName,"[0-9\.]+\sm(g|Eq).*Rate..IV","gtt.")
		if ObjHasValue(meds1, medName, "RX") {
			y.addElement(medlist, yMarDt, {class: "Cardiac"}, medName)
			continue
		}
		if ObjHasValue(meds2, medName, "RX") {
			y.addElement(medlist, yMarDt, {class: "Arrhythmia"}, medName)
			continue
		}
		if ObjHasValue(meds0, medName, "RX") {
			continue
		}
		else
			y.addElement(medlist, yMarDt, {class: "Other"}, medName)
	}
}

ObjHasValue(aObj, aValue, rx:="") {
; modified from http://www.autohotkey.com/board/topic/84006-ahk-l-containshasvalue-method/	
    for key, val in aObj
		if (rx="RX") {
			if (aValue ~= val) {
				return, key, Errorlevel := 0
			}
		} else {
			if (val = aValue) {
				return, key, ErrorLevel := 0
			}
		}
    return, false, errorlevel := 1
}

breakDate(x) {
; Disassembles 201502150831 into Yr=2015 Mo=02 Da=15 Hr=08 Min=31 Sec=00
	D_Yr := substr(x,1,4)
	D_Mo := substr(x,5,2)
	D_Da := substr(x,7,2)
	D_Hr := substr(x,9,2)
	D_Min := substr(x,11,2)
	D_Sec := substr(x,13,2)
	FormatTime, D_day, x, ddd
	return {"YYYY":D_Yr, "MM":D_Mo, "DD":D_Da, "ddd":D_day
		, "HH":D_Hr, "min":D_Min, "sec":D_sec}
}

parseDate(x) {
; Disassembles "2/9/2015" or "2/9/2015 8:31" into Yr=2015 Mo=02 Da=09 Hr=08 Min=31
	StringSplit, DT, x, %A_Space%
	StringSplit, DY, DT1, /
	;~ if !(DY0=3) {
		;~ ;MsgBox Wrong date format!
		;~ return
	;~ }
	StringSplit, DHM, DT2, :
	return {"MM":zDigit(DY1), "DD":zDigit(DY2), "YYYY":DY3, "hr":zDigit(DHM1), "min":zDigit(DHM2), "Date":DT1, "Time":DT2}
}

Rand( a=0.0, b=1 ) {
/*	from VxE http://www.autohotkey.com/board/topic/50564-why-no-built-in-random-function-in-ahk/?p=315957
	Rand() ; - A random float between 0.0 and 1.0 (many uses)
	Rand(6) ; - A random integer between 1 and 6 (die roll)
	Rand("") ; - New random seed (selected randomly)
	Rand("", 12345) ; - New random seed (set explicitly)
	Rand(50, 100) ; - Random integer between 50 and 100 (typical use)
*/
	IfEqual,a,,Random,,% r := b = 1 ? Rand(0,0xFFFFFFFF) : b
	Else Random,r,a,b
	Return r
}

niceDate(x) {
	if !(x)
		return error
	FormatTime, x, %x%, MM/dd/yyyy
	return x
}

zDigit(x) {
; Add leading zero to a number
	return SubStr("0" . x, -1)
}

cleanString(x) {
	replace := {"{":"[","}":"]","\":"/"}
	for what, with in replace
	{
		StringReplace, x, x, %what%, %with%, All
	}
	return x
}

fieldType(x) {
	global CIS_cols, CIS_colvals
	for k in CIS_cols
	{
		if (x ~= CIS_colvals[k]) {
			return CIS_cols[k]
		}
	}
	return error
}

FilePrepend( Text, Filename ) { 
/*	from haichen http://www.autohotkey.com/board/topic/80342-fileprependa-insert-text-at-begin-of-file-ansi-text/?p=510640
*/
    file:= FileOpen(Filename, "rw")
    text .= File.Read()
    file.pos:=0
    File.Write(text)
    File.Close()
}

eventlog(event) {
	global user, sessdate
	comp := A_ComputerName
	FormatTime, now, A_Now, yyyy.MM.dd.HH:mm:ss
	name := "logs/" . sessdate . ".log"
	txt := now " [" user "/" comp "] " event "`n"
	filePrepend(txt,name)
;	FileAppend, % timenow " ["  user "/" comp "] " event "`n", % "logs/" . sessdate . ".log"
}

screenDims() {
	W := A_ScreenWidth
	H := A_ScreenHeight
	DPI := A_ScreenDPI
	Orient := (W>H)?"L":"P"
	;MsgBox % "W: "W "`nH: "H "`nDPI: "DPI
	return {W:W, H:H, DPI:DPI, OR:Orient}
}
winDim(scr) {
	global ccFields
	num := ccFields.MaxIndex()
	if (scr.or="L") {
		aspect := (scr.W/scr.H >= 1.5) ? "W" : "N"	; 1.50-1.75 probable 16:9 aspect, 1.25-1.33 probable 4:3 aspect
		;MsgBox,, % aspect, % W/H
		wX := scr.H * ((aspect="W") ? 1.5 : 1)
		wY := scr.H-80
		rCol := wX*.3						; R column is 1/3 width
		bor := 10
		boxWf := wX-rCol-2*bor				; box fullwidth is remaining 2/3
		boxWh := boxWf/2
		boxWq := boxWf/4
		rH := 12
		demo_h := rH*8
		butn_h := rh*6
		cont_h := wY-demo_H-bor-butn_h
		field_h := (cont_h-20)/num
	} else {
		wX := scr.W
		wY := scr.H
	}
	return { BOR:Bor, wX:wX, wY:wY
		,	boxF:boxWf
		,	boxH:boxWh
		,	boxQ:boxWq
		,	demo_H:demo_H
		,	cont_H:cont_H
		,	field_H:field_H
		,	rCol:rCol
		,	rH:rH}
}


#Include gui-main.ahk
#Include gui-CallList.ahk
#Include gui-TeamList.ahk
#Include gui-PatList.ahk
#Include gui-PatListCC.ahk
#Include gui-plNotes.ahk
#Include gui-plTasks.ahk
#Include gui-plData.ahk
#Include gui-cards.ahk

#Include xml.ahk
#Include StrX.ahk
#Include Class_LV_Colors.ahk
#Include sift3.ahk
#Include CMsgBox.ahk