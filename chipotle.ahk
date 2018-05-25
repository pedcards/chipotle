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

vers := "2.4.3.5"
user := A_UserName
FormatTime, sessdate, A_Now, yyyyMM
eventlog(">>>>> Session started.")
if WinExist("View Downloads -") {
	WinClose, View Downloads -
	eventlog("Launched from CIS")
} else {
	eventlog("Launched from Citrix")
}
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
CisEnvt := WinExist("ahk_exe powerchart.exe") ? true : false
if (CisEnvt) {
	eventlog("CIS visible.")
}

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
	tmp:=CMsgBox("Administrator","Which user role?","*&Normal CHIPOTLE|&CICU CHILI|&ARNP Con Carne|Coordinator","Q","V")
	if (tmp~="CHILI")
		isCICU := true
	if (tmp~="ARNP")
		isARNP := true
	if (tmp~="Coord")
		isCoord := true
}
if (ObjHasValue(coordusers,user)) {
	isCoord := true
}
if (ObjHasValue(cicuUsers,user)) {
	isCICU = true
}
if (ObjHasValue(ArnpUsers,user)) {
	isARNP := true
}
if (ObjHasValue(pharmUsers,user)) {
	isARNP := true
	isPharm := true
}

mainTitle1 := "CHIPOTLE"												; Default title, unless changed below
mainTitle2 := "Children's Heart Center InPatient"
mainTitle3 := "Organized Task List Environment"

if (isCICU) {
	loc := makeLoc("CSR","CICU")										; loc[] defines the choices offered from QueryList. You can only break your own list.
	callLoc := "CICUSur"
	mainTitle1 := "CHILI"
	mainTitle2 := "Children's Heart Center"
	mainTitle3 := "Inpatient Longitudinal Integrator"
} else if (isARNP) {
	loc := makeLoc("CSR","CICU","Cards")
	callLoc := "CSR"
	mainTitle1 := "CON CARNE"
	mainTitle2 := "Collective Organized Notebook"
	mainTitle3 := "for Cardiac ARNP Efficiency"
} else if (isCoord) {
	loc := makeLoc("CSR","CICU","Cards","ICUCons")
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
Gosub GetIt
Gosub MainGUI

WinWaitClose, CHIPOTLE main
Gosub SaveIt
eventlog("<<<<< Session completed.")
sleep, 2000
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
		processCORES(clip)
	} else {
		MsgBox, 16, Wrong format!, % "Requires """ CORES_type """"
		WinClose, % CORES_window
	}
} else if ((clipCk ~= CIS_colRx["Name"]) 
		&& ((clipCk ~= CIS_colRx["Room"]) or (clipCk ~= CIS_colRx["Locn"]))
		&& (clipCk ~= CIS_colRx["MRN"])) {												; Check for features of CIS patient list
	Gosub initClipSub
	processCIS(clip)
	if !(locString) {						; Avoids error if exit QueryList
		return								; without choice.
	}
	
	if (location="Cards" or location="CSR" or location="TXP") {
		gosub saveCensus
	}
	if (location="CSR" or location="CICU") {
		IcuMerge()
	}
} else if ((clipCk ~= "MRN:\d{6,8}") || (clipCk ~= "^[A-Z '\-]+, [A-Z .'()\-]+$")) {
	clk := parseClip(clipCk)
	gosub findPt
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

initClipSub:									;*** Initialize some stuff
{
	Clipboard =
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
		if (list="TXP" and ((pt.Svc="Cardiology") or (pt.Svc="Cardiac Surgery"))) {						; If on TXP list AND on CRD or CSR
			y.selectSingleNode("/root/id[@mrn='" mrn "']/status").setAttribute("txp", "on")				; Set status flag.
		}
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

readStorkList() {
/*	Directly read a Stork List XLS.
	Sheets
		(1) is "Potential cCHD"
		(2) is "Neonatal echo and Regional Cons"
		(3) is archives
	
*/
	global y
		, stork_hdr, stork_cel
	
	storkPath := A_WorkingDir "\files\fetal\stork.xlsx"
	if !FileExist(storkPath) {
		MsgBox None!
		return
	}
	progress,,Opening file...,Initialization
	if IsObject(y.selectSingleNode("/root/lists/stork")) {
		RemoveNode("/root/lists/stork")
	}
	y.addElement("stork","/root/lists"), {date:timenow}
		
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
		stork_mrn := Round(storkVal("Mother SCH"))
		progress, % 100*RowNum/40, Scanning records..., % stork_mrn
		if !(stork_mrn)
			continue
		y.addElement("id","/root/lists/stork",{mrn:stork_mrn})
		stork_str := "/root/lists/stork/id[@mrn='" stork_mrn "']"
		
		stork_names := storkVal("Names")
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
		y.addElement("UW", stork_str "/mother", storkVal("Mother UW"))
		y.addElement("home", stork_str "/mother", storkVal("Home"))
		
		y.addElement("birth", stork_str)
		y.addElement("hosp", stork_str "/birth", storkVal("Delivery Hosp"))
		y.addElement("edc", stork_str "/birth", storkVal("EDC"))
		
		y.addElement("mode", stork_str "/birth",stregX(storkVal("Planned date"),"",1,0,"\d",1))
		y.addElement("planned", stork_str "/birth",stregX(storkVal("Planned date") "<<<","\d",1,0,"<<<",1))
		
		y.addElement("dx", stork_str "/baby", storkVal("Diagnosis"))
		
		y.addElement("notes", stork_str "/baby", storkVal("Comments"))
		
		y.addElement("cont", stork_str)
		getPnProv("CRD", stork_str "/cont")
		
		y.addElement("enc", stork_str)
		getPnProv("Recent dates", stork_str "/enc")
		
		y.addElement("cord", stork_str "/birth", storkVal("Cord blood"))
		
		y.addElement("orca", stork_str "/birth", storkVal("Orca Plan"))
	}
	Progress, Hide

	oExcel := oWorkbook.Application
	oExcel.quit

	MsgBox Stork List updated.
	Writeout("/root/lists","stork")
	Eventlog("Stork List updated.")
Return
}

getPnProv(cel,node) {
	global y
	
	cel := trim(cleanSpace(storkVal(cel))," `t`r`n")									; Make some corrections for common typos
	cel := RegExReplace(cel,"([:\/]) ","$1")
	cel := RegExReplace(cel,";",":")
	cel := RegExReplace(cel,"([[:alpha:]])(\d)","$1/$2")
	
	loop, parse, cel, %A_Space%, `r`n
	{
		prov := parsePnProv(A_LoopField)
		y.addElement("prov", node, {svc:prov.svc,date:prov.date}, prov.prov)
	}
}

parsePnProv(txt) {
	svc := stregX(txt,"",1,0,"[:\/]",1,nn)
	prov := stregX(txt "<<<","[:\/]",1,1,"(\/)|(<<<)",1,nn)
	dt := substr(txt,nn+1)
	return {svc:trim(svc), prov:trim(prov," ()"), date:trim(dt)}
}

storkVal(val) {
	global stork_cel, stork_hdr
	res := stork_cel[ObjHasValue(stork_hdr,val)]
	return res
}

readForecast() {
/*	Read electronic forecast XLS
	\\childrens\files\HCSchedules\Electronic Forecast\2016\11-7 thru 11-13_2016 Electronic Forecast.xlsx
	Move into /lists/forecast/call {date=20150301}/<PM_We_F>Del Toro</PM_We_F>
*/
	global y
		, dialogVals, forecastPath
	
	; Get Qgenda items
	fcMod := substr(y.selectSingleNode("/root/lists/forecast").getAttribute("mod"),1,8) 
	if !(fcMod = substr(A_now,1,8)) {													; Forecast has not been scanned today
		readQgenda()																	; Read Qgenda once daily
	}
	
	; Find the most recently modified "*Electronic Forecast.xls" file
	eventlog("Check electronic forecast.")
	progress,, Updating schedules, Scanning forecast files...
	
	fcLast :=
	fcNext :=
	fcFile := 
	fcFileLong := 
	fcRecent :=
	
	dp:=A_Now
	FormatTime, Wday,%dt%, Wday															; Today's day of the week (Sun=1)
	dp += (2-Wday), days																; Get last Monday's date
	tmp := breakdate(dp)
	fcLast := tmp.mm tmp.dd																; date string "0602" from last week's fc
	
	dt:=A_Now
	dt += (9-Wday), days																; Get next Monday's date
	tmp := breakdate(dt)
	fcNext := tmp.mm tmp.dd																; date string "0609" for next week's fc
	
	Loop, Files, % forecastPath "\" tmp.yyyy "\*Electronic Forecast*.xls*", F			; Scan through YYYY\Electronic Forecast.xlsx files
	{
		fcFile := A_LoopFileName														; filename, no path
		fcFileLong := A_LoopFileLongPath												; long path
		fcRecent := A_LoopFileTimeModified												; most recent file modified
		if InStr(fcFile,"~") {
			continue																	; skip ~tmp files
		}
		d1 := zDigit(strX(fcFile,"",1,0,"-",1,1)) . zDigit(strX(fcFile,"-",1,1," ",1,1))	; zdigit numerals string from filename "2-19 thru..."
		fcNode := y.selectSingleNode("/root/lists/forecast")							; fcNode = Forecast Node
		
		if (d1=fcNext) {																; this is next week's schedule
			tmp := fcNode.getAttribute("next")											; read the fcNode attr for next week DT-mod (0205-20180202155212)
			if ((strX(tmp,"",1,0,"-",1,1) = fcNext) && (strX(tmp,"-",1,1,"",0) = fcRecent)) { ; this file's M attr matches last adjusted fcNode next attr
				eventlog(fcFile " already done.")
				continue																; if attr date and file unchanged, go to next file
			}
			fcNode.setAttribute("next",fcNext "-" fcRecent)								; otherwise, this is unscanned
			eventlog("fcNext " fcNext "-" fcRecent)
		} else if (d1=fcLast) {															; matches last Monday's schedule
			tmp := fcNode.getAttribute("last")
			if ((strX(tmp,"",1,0,"-",1,1) = fcLast) && (strX(tmp,"-",1,1,"",0) = fcRecent)) { ; this file's M attr matches last week's fcNode last attr
				eventlog(fcFile " already done.")
				continue																; skip to next if attr date and file unchanged
			}
			fcNode.setAttribute("last",fcLast "-" fcRecent)								; otherwise, this is unscanned
			eventlog("fcLast " fcLast "-" fcRecent)										
		} else {																		; does not match either fcNext or fcLast
			continue																	; skip to next file
		}
		
		Progress,, Updating schedules, % fcFile
		FileCopy, %fcFileLong%, fcTemp.xlsx, 1											; create local copy to avoid conflict if open
		eventlog("Parsing " fcFileLong)
		parseForecast(fcRecent)															; parseForecast on this file (unprocessed NEXT or LAST)
	}
	if !FileExist(fcFileLong) {															; no file found
		EventLog("Electronic Forecast.xlsx file not found!")
	}
	
	Progress, off	
	
return
}

parseForecast(fcRecent) {
	global y
		, forecast_val, forecast_svc
	
	; Initialize some stuff
	if !IsObject(y.selectSingleNode("/root/lists/forecast")) {							; create if for some reason doesn't exist
		y.addElement("forecast","/root/lists")
	} 
	colArr := ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q"] 	; array of column letters
	fcDate:=[]																			; array of dates
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
				progress,, Scanning forecast, % row_nm
				continue																; results in some ROW NAME, now move to the next column
			}
			
			fcNode := "/root/lists/forecast/call[@date='" fcDate[colNum] "']"
			if !IsObject(y.selectSingleNode(fcNode "/" row_nm)) {						; create node for service person if not present
				y.addElement(row_nm,fcNode)
			}
			y.setText(fcNode "/" row_nm, cleanString(cel))								; setText changes text value for that node
		}
	}
	
	oExcel := oWorkbook.Application
	oExcel.DisplayAlerts := false
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
	Writeout("/root/lists","forecast")
	Eventlog("Electronic Forecast " fcRecent " updated.")
Return
}

readQgenda() {
/*	Fetch upcoming call schedule in Qgenda
	Parse JSON into call elements
	Move into /lists/forecast/call {date=20150301}/<PM_We_F>Del Toro</PM_We_F>
*/
	global y
	
	t0 := t1 := A_now
	t1 += 14, Days
	FormatTime,t0, %t0%, MM/dd/yyyy
	FormatTime,t1, %t1%, MM/dd/yyyy
	IniRead, q_com, qgenda.ppk, api, com
	IniRead, q_eml, qgenda.ppk, api, eml
	
	qg_fc := {"CALL":"PM_We_A"
			, "fCall":"PM_We_F"
			, "EP Call":"EP"
			, "ICU":"ICU_A"
			, "TXP Inpt":"Txp"
			, "IW":"Ward_A"}
	
	progress, , Updating schedules, Auth Qgenda...
	url := "https://api.qgenda.com/v2/login"
	str := httpGetter("POST",url,q_eml
		,"Content-Type=application/x-www-form-urlencoded")
	qAuth := parseJSON(str)[1]																; MsgBox % qAuth[1].access_token
	
	progress, , Updating schedules, Reading Qgenda...
	url := "https://api.qgenda.com/v2/schedule"
		. "?companyKey=" q_com
		. "&startDate=" t0
		. "&endDate=" t1
		. "&$select=Date,TaskName,StaffLName,StaffFName"
		. "&$filter="
		.	"("
		.		"TaskName eq 'CALL'"
		.		" or TaskName eq 'fCall'"
	;	.		" or TaskName eq 'CATH LAB'"
	;	.		" or TaskName eq 'CATH RES'"
		.		" or TaskName eq 'EP Call'"
	;	.		" or TaskName eq 'Fetal Call'"
		.		" or TaskName eq 'ICU'"
	;	.		" or TaskName eq 'TEE/ECHO'"
	;	.		" or TaskName eq 'TEE Call'"
		.		" or TaskName eq 'TXP Inpt'"
	;	.		" or TaskName eq 'TXP Res'"
		.		" or TaskName eq 'IW'"
		.	")"
		.	" and IsPublished"
		.	" and not IsStruck"
		. "&$orderby=Date,TaskName"
		. "&" q_eml
	str := httpGetter("GET",url,
		,"Authorization= bearer " qAuth.access_token
		,"Content-Type=application/json")
	
	progress, , Updating schedules, Parsing JSON...
	qOut := parseJSON(str)
	
	progress, , Updating schedules, Updating Forecast...
	Loop, % qOut.MaxIndex()
	{
		i := A_Index
		qDate := parseDate(qOut[i,"Date"])										; Date array
		qTask := qg_fc[qOut[i,"TaskName"]]										; Call name
		qNameF := qOut[i,"StaffFName"]
		qNameL := qOut[i,"StaffLName"]
		if (qNameL~="^[A-Z]{2}[a-z]") {											; Remove first initial if present
			qNameL := SubStr(qNameL,2)
		}
		if (qNameL~="Mallenahalli|Chikkabyrappa") {								; Special fix for Sathish and his extra long name
			qNameL:="Mallenahalli Chikkabyrappa"
		}
		if (qNameL qNameF = "NelsonJames") {									; Special fix to make Tony findable on paging call site
			qNameF:="Tony"
		}
		
		tmpDt := qDate.YYYY . qDate.MM . qDate.DD								; tmpDt in format YYYYMMDD
		if !IsObject(y.selectSingleNode("/root/lists/forecast/call[@date='" tmpDt "']")) {
			y.addElement("call","/root/lists/forecast", {date:tmpDt})			; create node if doesn't exist
		}
		
		fcNode := "/root/lists/forecast/call[@date='" tmpDt "']"
		if !IsObject(y.selectSingleNode(fcNode "/" qTask)) {					; create node for service person if not present
			y.addElement(qTask,fcNode)
		}
		y.setText(fcNode "/" qTask, qNameF " " qNameL)							; setText changes text value for that node
		y.selectSingleNode("/root/lists/forecast").setAttribute("mod",A_Now)	; change forecast[@mod] to now
	}
	
	Writeout("/root/lists","forecast")
	Eventlog("Qgenda " t0 "-" t1 " updated.")
	
	FileCopy, archlist.xml, archback\%A_now%.xml
	eventLog("archlist.xml backed up.")
	
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

IcuMerge() {
	global y, timenow, loc_surg, csrDocs
	
	;~ FormatTime, cicuDate, A_Now, yyyyMMdd
	tmpDT_crd := substr(y.selectSingleNode("/root/lists/Cards").getAttribute("date"),1,8)
	tmpDT_csr := substr(y.selectSingleNode("/root/lists/CSR").getAttribute("date"),1,8)
	tmpDT_cicu := substr(y.selectSingleNode("/root/lists/CICU").getAttribute("date"),1,8)

	cicuSurPath := "/root/lists/CICUSur"
	if IsObject(y.selectSingleNode(cicuSurPath)) {										; Clear the old list and refresh all
		removeNode(cicuSurPath)
	}
	y.addElement("CICUSur","/root/lists", {date:timenow})
	
	loop, % (c1:=y.selectNodes("/root/lists/CICU/mrn")).length {						; Copy existing ICU bed list to CICUSur
		y.addElement("mrn",cicuSurPath, c1.item(A_Index-1).text)
	}
	writeOut("/root/lists","CICUSur")
	
	SurUnitPath := "/root/lists/SurUnit"												; Clear old Sur-R6 list
	if IsObject(y.selectSingleNode(SurUnitPath)) {
		removeNode(SurUnitPath)
	}
	y.addElement("SurUnit","/root/lists", {date:timenow})
	
	Loop, % (c1:=y.selectNodes("/root/lists/CSR/mrn")).length {							; Copy CSR patients on SUR-R6
		c1mrn := c1.item(A_Index-1).text												; to SurUnitPath
		c1str := "/root/id[@mrn='" c1mrn "']"
		c1loc := y.selectSingleNode(c1str "/demog/data/unit").text
		if (c1loc=loc_Surg) {
			y.addElement("mrn",SurUnitPath,c1mrn)
		}
	}
	WriteOut("/root/lists","SurUnit")
	
	if (tmpDT_csr=tmpDT_cicu) {															; When both CSR and CICU up to date
		Loop, % (c2:=y.selectNodes("/root/lists/CSR/mrn")).length {						; Scan CSR list for SURGCNTR patients
			c2mrn := c2.item(A_Index-1).text
			c2str := "/root/id[@mrn='" c2mrn "']"
			c2loc := y.selectSingleNode(c2str "/demog/data/unit").text
			if (c2loc="SURGCNTR") {
				y.addElement("mrn",cicuSurPath,c2mrn)									; and add to cicuSurPath
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
		WriteOut("/root/lists","CICUSur")
	}
	if (tmpDT_crd=tmpDT_cicu) {															; When both CARDS and CICU are up to date
		Loop, % (c2:=y.selectNodes("/root/lists/Cards/mrn")).length {					; Scan Cards list for SURGCNTR patients
			c2mrn := c2.item(A_Index-1).text
			c2str := "/root/id[@mrn='" c2mrn "']"
			c2loc := y.selectSingleNode(c2str "/demog/data/unit").text
			c2attg := y.selectSingleNode(c2str "/demog/data/attg").text
			if (c2loc="SURGCNTR" and ObjHasValue(CSRdocs,c2attg)) {						; Cards list, SurgCntr, and CSR attg
				y.addElement("mrn",cicuSurPath,c2mrn)									; add to cicuSurPath					
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
		WriteOut("/root/lists","CICUSur")
	}
return
}

getCentrip() {
	global y
	c := new XML("data_in\centripetus\CentripData.xml")
	
	loop, % (nodes:=c.selectNodes("/xml/CentripData/Surgery")).Length
	{
		progress % 100*A_index/20
		el := []
		k := nodes.item(A_index-1)
		el.uid := nodeTxt(k,"CaseNumber")
		el.mrn := nodeTxt(k,"MRN")
		dtmp := parseDate(nodeTxt(k,"SurgDt"))
		el.dt := substr(dtmp.YYYY dtmp.MM dtmp.DD dtmp.hr dtmp.min "00",1,14)
		el.surgeon := strX(nodeTxt(k,"Surgeon"),"",1,1,",",1)
		el.cpb := nodeTxt(k,"CPBTm")
		el.xc := nodeTxt(k,"XClampTm")
		loop, % (procs:=k.selectNodes(".//Procedure")).Length
		{
			pr := procs.item(A_Index-1)
			el.procs .= strQ(nodeTxt(pr,"Description"),"###; ")
		}
		ptStr := "/root/id[@mrn='" el.mrn "']"
		prStr := ptStr "/data/procs/surg[@case='" el.uid "']"
		if !IsObject(y.selectSingleNode(ptStr)) {										; No id@mrn in currlist
			continue
		}
		if IsObject(y.selectSingleNode(prStr)) {										; Surgery already captured
			continue
		}
		makeNodes(el.mrn,"data/procs")
		y.addElement("surg",ptStr "/data/procs",{case:el.uid})
		y.addElement("date",prStr,el.dt)
		y.addElement("surgeon",prStr,el.surgeon)
		y.addElement("times",prStr,{cpb:el.cpb,xc:el.xc})
		y.addElement("desc",prStr,trim(el.procs," `;"))
		
		writeout(ptStr,"data")
		eventlog("Updated Centripetus data for " el.mrn)
	}
	progress, off
	return
}

nodeTxt(node,el) {
	x := node.selectSingleNode(el).text
	return x
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
; Disassembles dates into Yr=2015 Mo=02 Da=09 Hr=08 Min=31
	; 03 Jan 2016
	mo := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
	if (x~="i)(\d{1,2})[\-\s\.](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[\-\s\.](\d{2,4})") {
		StringSplit, DT, x, %A_Space%-.
		return {"DD":zDigit(DT1), "MM":zDigit(objHasValue(mo,DT2)), "MMM":DT2, "YYYY":year4dig(DT3)}
	}
	
	; 03_06_17 or 03_06_2017
	if (x~="\d{1,2}_\d{1,2}_\d{2,4}") {
		StringSplit, DT, x, _
		return {"MM":zDigit(DT1), "DD":zDigit(DT2), "MMM":mo[DT2], "YYYY":year4dig(DT3)}
	}
	
	; 2017-02-11
	if RegExMatch(x,"(\d{4})-(\d{2})-(\d{2})",DT) {
		return {"YYYY":DT1, "MM":DT2, "DD":DT3}
	}
	
	; Mar 9, 2015 (8:33 am)?
	if (x~="i)^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{1,2}, \d{4}") {
		StringSplit, DT, x, %A_Space%
		StringSplit, DHM, DT4, :
		return {"MM":zDigit(objHasValue(mo,DT1)),"DD":zDigit(trim(DT2,",")),"YYYY":DT3
			,	hr:zDigit((DT5~="i)p")?(DHM1+12):DHM1),min:DHM2}
	}
	
	; 02/09/2015 (8:33 am)?
	if (x~="\d{1,2}[\-/_\.]\d{1,2}[\-/_\.]\d{4}") {
		RegExMatch(x,"(\d{1,2})[\-/_\.](\d{1,2})[\-/_\.](\d{4})",d)
		RegExMatch(x,"(\d{1,2}):(\d{2})(:\d{2})?(.*)(AM|PM)?",t)
		if (t6="pm" and t1<12) {
			t1 += 12
		}
		return {MM:zDigit(d1),DD:zDigit(d2),YYYY:d3
			,	hr:zDigit(t1),min:t2,sec:trim(t3,":"),AMPM:trim(t4)}
	}
	
	; Remaining are "2/9/2015" or "2/9/2015 8:31" 
	StringSplit, DT, x, %A_Space%
	StringSplit, DY, DT1, /
	StringSplit, DHM, DT2, :
	return {"MM":zDigit(DY1), "DD":zDigit(DY2), "YYYY":year4dig(DY3), "hr":zDigit(DHM1), "min":zDigit(DHM2), "Date":DT1, "Time":DT2}
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

year4dig(x) {
	if (StrLen(x)=4) {
		return x
	}
	if (StrLen(x)=2) {
		return (x<50)?("20" x):("19" x)
	}
	return error
}

zDigit(x) {
; Add leading zero to a number
	return SubStr("0" . x, -1)
}

cleanString(x) {
	replace := {"{":"["															; substitutes for common error-causing chars
				,"}":"]"
				, "\":"/"
				,chr(241):"n"}
				
	for what, with in replace													; convert each WHAT to WITH substitution
	{
		StringReplace, x, x, %what%, %with%, All
	}
	
	x := RegExReplace(x,"[^[:ascii:]]")											; filter remaining unprintable (esc) chars
	
	StringReplace, x,x, `r`n,`n, All										; convert CRLF to just LF
	loop																		; and remove completely null lines
	{
		StringReplace x,x,`n`n,`n, UseErrorLevel
		if ErrorLevel = 0	
			break
	}
	
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