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
vers := "1.7.9.2"
user := A_UserName
FormatTime, sessdate, A_Now, yyyyMM

gosub ReadIni
scr:=screenDims()
win:=winDim(scr)

servfold := "patlist"
if (ObjHasValue(admins,user)) {
	isAdmin := true
	if (InStr(A_WorkingDir,"Ahk")) {
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
		coresType := StrX(clipCkCORES,"CORES",1,0,"REPORT v3.0",1,0,N)
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
	;FileSelectFile , clipname,, %A_ScriptDir%, Select file:, AHK clip files (*.clip)
	clipname := "cores0301rhr.clip"
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
				stork_hdr[ColNum] := cel
			} else {
				stork_cel[ColNum] := cel
			}
		}
		stork_mrn := Round(stork_cel[ObjHasValue(stork_hdr,"Mother SCH")])
		if !(stork_mrn)
			continue
		stork_names := stork_cel[ObjHasValue(stork_hdr,"Names")]
			if (pos2:=instr(stork_names,",",,,2)) {												; A second "," means baby name present
				lastname := RegExMatch(stork_names,"(?<=\s)\w+,",,instr(stork_names,",",,,1))
;				MsgBox % "`n`n`n`n`n`n`n" lastname " - " pos2
			}


	y.addElement("id","/root/lists/stork",{mrn:stork_mrn})
	}
	Progress, Hide

	oExcel := oWorkbook.Application
	oExcel.quit

	MsgBox Stork List updated.
	Writeout("/root/lists","stork")
	Eventlog("Stork List updated.")
Return
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
		if (tmpDt < -21) {																		; save call schedule for 3 weeks (for TRRIQ)
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
	
	SurR6Path := "/root/lists/SurR6"											; Clear old Sur-R6 list
	if IsObject(y.selectSingleNode(SurR6Path)) {
		removeNode(SurR6Path)
	}
	y.addElement("SurR6","/root/lists", {date:timenow})
	
	Loop, % (c1:=y.selectNodes("/root/lists/CSR/mrn")).length {					; Select CSR patients on SUR-R6
		c1mrn := c1.item(A_Index-1).text
		c1str := "/root/id[@mrn='" c1mrn "']"
		c1loc := y.selectSingleNode(c1str "/demog/data/unit").text
		if (c1loc="SUR-R6") {
			y.addElement("mrn",SurR6Path,c1mrn)
			WriteOut("/root/lists","SurR6")
		}
	}
	
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
	global CIS_cols, CIS_colvals
	for k in CIS_cols
	{
		if (x ~= CIS_colvals[k]) {
			return CIS_cols[k]
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