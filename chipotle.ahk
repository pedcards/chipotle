/* 	Patient List Updater (C)2014-2016 TC
	CHIPOTLE = Children's Heart Center InPatient Online Task List Environment
*/

/*	Todo lists: 
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetTitleMatchMode, 2
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
#Include Includes
#Persistent		; Keep program resident until ExitApp

vers := "2.1.1"
user := A_UserName
FormatTime, sessdate, A_Now, yyyyMM
WinClose, View Downloads -
LV_Colors.OnMessage()

FileGetTime, iniDT, chipotle.ini
FileGetTime, exeDT, chipotle.exe
iniDT -= %exeDT%, Seconds										; Will be negative if chipotle.ini is older.
FileInstall, chipotle.ini, chipotle.ini, (iniDT<0)				; Overwrite if chipotle.exe is newer (and contains newer .ini)
if (iniDT < 0) {
	eventlog("==============================")
	eventlog("Initialized version " vers)
	eventlog("==============================")
}
;FileInstall, pscp.exe, pscp.exe								; Necessary files (?)
;FileInstall, queso.exe, queso.exe
;FileInstall, printer.png, printer.png

Sleep 500

gosub ReadIni
scr:=screenDims()
win:=winDim(scr)

servfold := "patlist"
storkPath := "\\childrens\files\HCCardiologyFiles\Fetal"
forecastPath := "\\childrens\files\HCSchedules\Electronic Forecast"
if (InStr(A_WorkingDir,"Ahk")) {
	tmp:=CMsgBox("Data source","Data from which system?","&Local|&Test Server|Production","Q","V")
	if (tmp="Local") {
		isLocal := true
		;FileDelete, currlist.xml
		storkPath := "files\Fetal"
		forecastPath := "files\Electronic Forecast"
	}
	if (tmp="Test Server") {
		isLocal := false
		servfold := "testlist"
		;FileDelete, currlist.xml
	}
	if (tmp="Production") {
		isLocal := false
		;FileDelete, currlist.xml
	}
}
if (ObjHasValue(admins,user)) {
	isAdmin := true
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
	loc["CSR"] := {"name":"Cardiac Surgery", "datevar":"GUIcsrTXT"}		; loc["CSR"] is XML lists/CSR, "name":"Cardiac Surgery" is string on GUI
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

;*/																; add ";" to save clipboard
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

*/																; add ";" for live

;/*
OnClipboardChange:
*/
{
if !initDone													; Avoid clip processing before initialization complete
	return
AutoTrim Off
clip = %Clipboard%																	; Get text of clipboard, exclude formatting chars
clipCk := substr(clip,1,256)														; Check first 256 bytes of clipboard

If (clipCk ~= CORES_regex) {														; Matches CORES_regex from chipotle.ini
	coresType := StrX(clipCk,"CORES",1,0,"REPORT v3.0",1,0)
	if (coresType == CORES_type) {
		SetTimer, SeekCores, On
		WinClose, % CORES_window
		gosub initClipSub
		Gosub processCORES
		MsgBox,,CORES data update, % n0 " total records read.`n" n1 " new records added."
	} else {
		MsgBox, 16, Wrong format!, % "Requires """ CORES_type """"
		WinClose, % CORES_window
	}
} else if ((clipCk ~= CIS_colRx["Name"]) 
		&& (clipCk ~= CIS_colRx["Room"])
		&& (clipCk ~= CIS_colRx["MRN"])) {												; Check for features of CIS patient list
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
} 

Return
}

^F12::
	FileSelectFile , clipname,, %A_ScriptDir%/files, Select file:, AHK clip files (*.clip)
	;clipname := "cores0301rhr.clip"
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
		ptSort := (inList:=ObjHasValue(teamSort,pt.svc,"RX"))*10 + (pt.statcons) + (!(inList))*100
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

readStorkList:
{
/*	Directly read a Stork List XLS.
	Sheets
		(1) is "Potential cCHD"
		(2) is "Neonatal echo and Regional Cons"
		(3) is archives
	
*/
	storkPath := A_WorkingDir "\files\stork.xls"
	if !FileExist(storkPath) {
		MsgBox None!
		return
	}
	if IsObject(y.selectSingleNode("/root/lists/stork")) {
		RemoveNode("/root/lists/stork")
	}
	y.addElement("stork","/root/lists"), {date:timenow}
		
	storkPath := A_WorkingDir "\files\stork.xls"
	oWorkbook := ComObjGet(storkPath)
	colArr := ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q"] ;array of column letters
	stork_hdr := Object()
	stork_cel := Object()
	Loop 
	{
		RowNum := A_Index
		chk := oWorkbook.Sheets(1).Range("A" RowNum).value
		if (RowNum=1) {
			upDate := chk
			continue
		}
		if !(chk)
			break
		Progress,,% rownum, Scanning Stork List
		Loop
		{	
			ColNum := A_Index
			if (colnum>maxcol)
				maxcol:=colnum
			cel := oWorkbook.Sheets(1).Range(colArr[ColNum] RowNum).value
			if ((cel="") && (colnum=maxcol))
				break
			if (rownum=2) {
				if (cel~="Mother's Name") {
					cel:="Names"
				}
				if (cel~="Mother.*SCH.*#") {
					cel:="Mother SCH"
				}
				if (cel~="Mother.*\sU.*#") {
					cel:="Mother UW"
				}
				if (cel~="Planned.*del.*date") {
					cel:="Planned date"
				}
				if (cel~="i)Most.*Recent.*Consult") {
					cel:="Recent dates"
				}
				if (cel~="i)cord.*blood") {
					cel:="Cord blood"
				}
				if (cel~="i)care.*plan.*ORCA") {
					cel:="Orca plan"
				}
				if (cel~="i)Continuity.*Cardio") {
					cel:="CRD"
				}
				stork_hdr[ColNum] := trim(cel)
			} else {
				stork_cel[ColNum] := cel
			}
		}
		stork_mrn := Round(stork_cel[ObjHasValue(stork_hdr,"Mother SCH")])
		if !(stork_mrn)
			continue
		y.addElement("id","/root/lists/stork",{mrn:stork_mrn})
		stork_str := "/root/lists/stork/id[@mrn='" stork_mrn "']"
		
		stork_names := stork_cel[ObjHasValue(stork_hdr,"Names")]
		if (instr(stork_names,",",,,2)) {												; A second "," means baby name present
			pos2 := RegExMatch(stork_names,"i)(?<=\s)[a-z\-\/]+,",,instr(stork_names,",",,,1))
			name2 := trim(substr(stork_names,pos2))
			name1 := trim(substr(stork_names,1,pos2-1))
			y.addElement("mother", stork_str)
				y.addElement("nameL", stork_str "/mother", trim(strX(name1,,0,0,", ",1,2)))
				y.addElement("nameF", stork_str "/mother", trim(strX(name1,", ",0,2)))
			y.addElement("baby", stork_str)
				y.addElement("nameL", stork_str "/baby", trim(strX(name2,,0,0,", ",1,2)))
				y.addElement("nameF", stork_str "/baby", trim(strX(name2,", ",0,2)))
		} else {
			y.addElement("mother", stork_str)
				y.addElement("nameL", stork_str "/mother", trim(strX(stork_names,,0,0,", ",1,2)))
				y.addElement("nameF", stork_str "/mother", trim(strX(stork_names,", ",0,2)))
		}
		
		stork_uw := stork_cel[ObjHasValue(stork_hdr,"Mother UW")]
		if (stork_uw)
			y.addElement("UW", stork_str "/mother", stork_uw)
		
		stork_home := stork_cel[ObjHasValue(stork_hdr,"Home")]
		y.addElement("home", stork_str "/mother", stork_home)
		
		stork_hosp := stork_cel[ObjHasValue(stork_hdr,"Delivery Hosp")]
		y.addElement("birth", stork_str)
		y.addElement("hosp", stork_str "/birth", stork_hosp)
		
		stork_edc := stork_cel[ObjHasValue(stork_hdr,"EDC")]
		y.addElement("edc", stork_str "/birth", stork_edc)
		
		stork_del := stork_cel[ObjHasValue(stork_hdr,"Planned date")]
		if (stork_del) {
			tmp := RegExMatch(stork_del,"\d")
			y.addElement("mode", stork_str "/birth", trim(substr(stork_del,1,tmp-1)))
			y.addElement("planned", stork_str "/birth", trim(substr(stork_del,tmp)))
		}
		
		stork_dx := stork_cel[ObjHasValue(stork_hdr,"Diagnosis")]
		y.addElement("dx", stork_str "/baby", stork_dx)
		
		stork_notes := stork_cel[ObjHasValue(stork_hdr,"Comments")]
		if (stork_notes)
			y.addElement("notes", stork_str "/baby", stork_notes)
		
		y.addElement("prov", stork_str)
		
		stork_cont := stork_cel[ObjHasValue(stork_hdr,"CRD")]
		if (stork_cont)
			y.addElement("cont", stork_str "/prov", stork_cont)
		
		stork_prv := trim(cleanSpace(stork_cel[ObjHasValue(stork_hdr,"Recent dates")]))
		nn := 0
		While (stork_prv) 
		{
			stork_prov := parsePnProv(stork_prv)
			y.addElement(stork_prov.svc, stork_str "/prov", {date:stork_prov.date}, stork_prov.prov)
		}
		
		stork_cord := stork_cel[ObjHasValue(stork_hdr,"Cord blood")]
		if (stork_cord)
			y.addElement("cord", stork_str "/birth", stork_cord)
		
		stork_orca := stork_cel[ObjHasValue(stork_hdr,"Orca Plan")]
		if (stork_orca)
			y.addElement("orca", stork_str "/birth", stork_orca)
		
	}
	Progress, Hide

	oExcel := oWorkbook.Application
	oExcel.quit

	MsgBox Stork List updated.
	Writeout("/root/lists","stork")
	Eventlog("Stork List updated.")
Return
}

parsePnProv(ByRef txt) {
	str := strX(txt,"",0,0, " ",1,1,n)
	svc := strX(str,"",0,0, "/",1,1)
	prov := strX(str,"/",1,1, "/",1,1,nn)
	dt := substr(str,nn+1)
	txt := substr(txt,n)
	return {svc:trim(svc), prov:trim(prov), date:trim(dt)}
}

readForecast:
{
/*	Read electronic forecast XLS
	\\childrens\files\HCSchedules\Electronic Forecast\2016\11-7 thru 11-13_2016 Electronic Forecast.xlsx
	Move into /lists/forecast/call {date=20150301}/<PM_We_F>Del Toro</PM_We_F>
*/
	; Find the most recently modified "*Electronic Forecast.xls" file
	fcFile := 
	fcFileLong := 
	fcRecent :=
	
	dt:=A_Now
	FormatTime, Wday,%dt%, Wday										; Today's day of the week (Sun=1)
	dt += (9-Wday), days											; Get next Monday's date
	conf := breakdate(dt)											; conf.yyyy conf.mm conf.dd
	
	Loop, Files, % forecastPath "\" conf.yyyy "\*Electronic Forecast*.xls*", F		; Scan through YYYY\Electronic Forecast.xlsx files
	{
		if InStr(A_LoopFileName,"~") {
			continue																	; skip ~tmp files
		}
		fcFile := A_LoopFileName														; filename, no path
		d1 := zDigit(strX(fcFile,"",1,0,"-",1,1)) . zDigit(strX(fcFile,"-",1,1," ",1,1))
		if (d1 = conf.mm conf.dd) {
			fcFileLong := A_LoopFileLongPath											; long path
			fcRecent := A_LoopFileTimeModified											; update most recent modified datetime 
			break
		}
	}
	if !FileExist(fcFileLong) {															; no file found
		MsgBox,48,, % "Electronic Forecast.xlsx`nfile not found!"
		return
	}
	
	; Initialize some stuff
	Progress, , % fcFile, Opening...
	if !IsObject(y.selectSingleNode("/root/lists/forecast")) {					; create if for some reason doesn't exist
		y.addElement("forecast","/root/lists")
	} 
	if (fcRecent = y.selectSingleNode("/root/lists/forecast").getAttribute("xlsdate")) { 
		Progress, off 
		MsgBox,64,, Electronic Forecast is up to date.
		return                                      ; no edits to XLS have been made 
	} 
	
	colArr := ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q"] 	; array of column letters
	fcDate:=[]																			; array of dates
	
	FileCopy, %fcFileLong%, fcTemp.xlsx, 1												; create local copy to avoid conflict if open
	oWorkbook := ComObjGet(A_WorkingDir "\fcTemp.xlsx")
	getVals := false																	; flag when have hit the Date vals row
	valsEnd := false																	; flag when reached the last row
	
	; Scan through XLSX document
	While !(valsEnd)																	; ROWS
	{
		RowNum := A_Index
		row_nm :=																		; ROW name (service name)
		if (rowNum=1) {																	; first row is title, skip
			continue
		}
		
		Loop																			; COLUMNS
		{
			colNum := A_Index															; next column
			if (colNum=1) {
				label:=true																; first column (e.g. A1) is label column
			} else {
				label:=false
			}
			if (ColNum>maxCol) {														; increment maxCol
				maxCol:=colNum
			}
			
			cel := oWorkbook.Sheets(1).Range(colArr[ColNum] RowNum).value				; Scan Sheet1 A2.. etc
			Progress, % 100*rowNum/36, % cel, % row_nm
			if ((cel="") && (colnum=maxcol)) {											; at maxCol and empty, break this cols loop
				break
			}
			if (cel~="\b\d{1,2}.\d{1,2}(.\d{2,4})?\b") {								; matches date format
				getVals := true
				tmp := parseDate(cel)													; cel date parts into tmp[]
				if !tmp.YYYY {															; get today's YYYY if not given
					tmp.YYYY := substr(sessdate,1,4)
				}
				tmpDt := tmp.YYYY . tmp.MM . tmp.DD										; tmpDt in format YYYYMMDD
				fcDate[colNum] := tmpDt													; fill fcDate[1-7] with date strings
				if !IsObject(y.selectSingleNode("/root/lists/forecast/call[@date='" tmpDt "']")) {
					y.addElement("call","/root/lists/forecast", {date:tmpDt})			; create node if doesn't exist
				}
				continue																; keep getting col dates but don't get values yet
			}
			
			if !(getVals) {																; don't start parsing until we have passed date row
				continue
			}
			
			cel := trim(RegExReplace(cel,"\s+"," "))									; remove extraneous whitespace
			if (label) {
				if !(cel) {																; blank label means we've reached the end of rows
					valsEnd := true														; flag to end
					break																; break out of LOOP to next WHILE
				}
				
				if (j:=objHasValue(Forecast_val,cel,"RX")) {							; match index value from Forecast_val
					row_nm := Forecast_svc[j]											; get abbrev string from index
				} else {
					row_nm := RegExReplace(cel,"(\s+)|[\/\*\?]","_")					; no match, create ad hoc and replace space, /, \, *, ? with "_"
				}
				continue																; results in some ROW NAME, now move to the next column
			}
			
			fcNode := "/root/lists/forecast/call[@date='" fcDate[colNum] "']"
			if !IsObject(y.selectSingleNode(fcNode "/" row_nm)) {						; create node for service person if not present
				y.addElement(row_nm,fcNode)
			}
			y.setText(fcNode "/" row_nm, cleanString(cel))								; setText changes text value for that node
		}
	}
	Progress, off
	
	oExcel := oWorkbook.Application
	oExcel.quit
	
	y.selectSingleNode("/root/lists/forecast").setAttribute("xlsdate",fcRecent)			; change forecast[@xlsdate] to the XLS mod date
	y.selectSingleNode("/root/lists/forecast").setAttribute("mod",A_Now)				; change forecast[@mod] to now

	loop, % (fcN := y.selectNodes("/root/lists/forecast/call")).length					; Remove old call elements
	{
		k:=fcN.item(A_index-1)															; each item[0] on forward
		tmpDt := k.getAttribute("date")													; date attribute
		tmpDt -= A_Now, Days															; diff dates
		if (tmpDt < -21) {																; save call schedule for 3 weeks (for TRRIQ)
			RemoveNode("/root/lists/forecast/call[@date='" k.getAttribute("date") "']")
		}
	}
	MsgBox Electronic Forecast updated.
	Writeout("/root/lists","forecast")
	Eventlog("Electronic Forecast updated.")
Return
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
	
	SurUnitPath := "/root/lists/SurUnit"											; Clear old Sur-R6 list
	if IsObject(y.selectSingleNode(SurUnitPath)) {
		removeNode(SurUnitPath)
	}
	y.addElement("SurUnit","/root/lists", {date:timenow})
	
	Loop, % (c1:=y.selectNodes("/root/lists/CSR/mrn")).length {					; Select CSR patients on SUR-R6
		c1mrn := c1.item(A_Index-1).text
		c1str := "/root/id[@mrn='" c1mrn "']"
		c1loc := y.selectSingleNode(c1str "/demog/data/unit").text
		if (c1loc=loc_Surg) {
			y.addElement("mrn",SurUnitPath,c1mrn)
		}
	}
	WriteOut("/root/lists","SurUnit")
	
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

ObjHasValue(aObj, aValue, rx:="") {
; modified from http://www.autohotkey.com/board/topic/84006-ahk-l-containshasvalue-method/	
	if (rx="med") {
		med := true
	}
    for key, val in aObj
		if (rx) {
			if (med) {													; if a med regex, preface with "i)" to make case insensitive search
				val := "i)" val
			}
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
	replace := {"{":"[", "}":"]", "\":"/"
				,"ñ":"n"}
	for what, with in replace
	{
		StringReplace, x, x, %what%, %with%, All
	}
	x := RegExReplace(x,"[^[:ascii:]]")									; filter unprintable (esc) chars
	return x
}

cleanspace(ByRef txt) {
	StringReplace txt,txt,`n,%A_Space%, All
	StringReplace txt,txt,%A_Space%.%A_Space%,.%A_Space%, All
	loop
	{
		StringReplace txt,txt,%A_Space%%A_Space%,%A_Space%, UseErrorLevel
		if ErrorLevel = 0	
			break
	}
	return txt
}

cleanwhitespace(txt) {
	Loop, Parse, txt, `n, `r
	{
		if (A_LoopField ~= "i)[a-z]+") {
			nxt .= A_LoopField "`n"
		}
	}
	return nxt
}

fieldType(x) {
	global CIS_colRx
	for key,val in CIS_colRx
	{
		if (x ~= val) {
			return key
		}
	}
	return error
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
#Include gui-Tasks.ahk
#Include gui-plData.ahk
#Include gui-cards.ahk
#Include process.ahk
#Include io.ahk
#Include labs.ahk
#Include meds.ahk
#Include print.ahk

#Include xml.ahk
#Include StrX.ahk
#Include StRegX.ahk
#Include Class_LV_Colors.ahk
#Include sift3.ahk
#Include CMsgBox.ahk