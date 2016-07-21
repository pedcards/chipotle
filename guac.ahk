/* 	GUACAMOLE conference data browser (C)2015 TC
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetTitleMatchMode, 2
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
#Include Includes
WinClose, View Downloads - Windows Internet Explorer
LV_Colors.OnMessage()

user := A_UserName
if (user="TC") {
	netdir := A_WorkingDir "\files\Tuesday Conference"								; local files
	chipdir := ""
	isDevt := true
} else {
	netdir := "\\childrens\files\HCConference\Tuesday Conference"					; networked Conference folder
	chipdir := "\\childrens\files\HCChipotle\"										; and CHIPOTLE files
	isDevt := false
}
MsgBox, 36, GUACAMOLE, Are you launching GUACAMOLE for patient presentation?
IfMsgBox Yes
	Presenter := true
else
	Presenter := false


y := new XML(chipdir "currlist.xml")												; Get latest local currlist into memory
arch := new XML(chipdir "archlist.xml")												; Get archive.xml
datedir := Object()
mo := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
;ConfStart := "20160416132100"
ConfStart := A_Now

Gosub MainGUI																		; Draw the main GUI
SetTimer, ConfTime, 1000															; Update ConfTime every 1000 ms
WinWaitClose, GUACAMOLE Main														; wait until main GUI is closed
ExitApp

;	===========================================================================================

MainGUI:
{
	if !IsObject(dt) {
		if (isDevt) {
			dt := GetConfDate("20160329")											; use test dir. change this if want "live" handling
		} else {
			dt := GetConfDate()														; determine next conference date into array dt
		}
	}
	Gui, main:Default
	Gui, Destroy
	Gui, Font, s16 wBold
	Gui, Add, Text, y0 x20 vCTime, % "              "								; Conference real time
	Gui, Add, Text, y0 x460 vCDur, % "              "								; Conference duration (only exists for Presenter)
	Gui, Add, Text, y0 x160 w240 h20 +Center, .-= GUACAMOLE =-.
	Gui, Font, wNorm s8 wItalic
	Gui, Add, Text, yp+30 xp wp +Center, General Use Access tool for Conference Archive
	Gui, Add, Text, yp+14 xp wp +Center, Merged OnLine Elements
	Gui, Font, wBold
	Gui, Font, wNorm
	Gosub GetConfDir																; Draw the pateint grid ListView
	Gui, Add, Button, wp +Center gDateGUI, % dt.MM "/" dt.DD "/" dt.YYYY			; Date selector button
	Gui, Show, AutoSize, % "GUACAMOLE Main - " dt.MM "/" dt.DD "/" dt.YYYY			; Show GUI with seleted conference DT
Return
}

DateGUI:
{
	Gui, date:Default
	Gui, Destroy
	Gui, Add, MonthCal, vEncDt gDateChoose, % dt.YYYY dt.MM dt.DD					; Show selected date and month selector
	Gui, Show, AutoSize, Select PCC date...
	return
}

DateChoose:
{
	Gui, date:Destroy																; Close MonthCal UI
	dt := GetConfDate(EncDt)														; Reacquire DT based on value
	conflist =																		; Clear out confList
	Gosub MainGUI																	; Redraw MainGUI
	return
}

ConfTime:
{
	FormatTime, tmp, , HH:mm:ss														; Format the current time
	GuiControl, main:Text, CTime, % tmp												; Update the main GUI current time
	
	if (Presenter) {																; For presenter only,
		tt := elapsed(ConfStart,A_Now)												; Total time elapsed
		GuiControl, main:Text, CDur, % tt.hh ":" tt.mm ":" tt.ss					; Update the main GUI elapsed time
	}
return
}

elapsed(start,end) {
	start -= end, Seconds															; Seconds betwen Start and End vars
	HH := floor(-start/3600)														; Derive HH from Start elapsed secs 
	MM := floor((-start-HH*3600)/60)												; Derive MM from remainder of HH
	SS := HH*3600-MM*60-start														; Derive SS from remainder of MM
	Return {"hh":zDigit(HH), "mm":zDigit(MM), "ss":zDigit(SS)}
}

formatSec(time) {
	HH := floor(time/3600)															; Derive HH from total time (secs)
	MM := floor((time-HH*3600)/60)													; Derive MM from remainder of HH
	SS := time-HH*3600-MM*60														; Derive SS from remainder of MM
	Return {"hh":zDigit(HH), "mm":zDigit(MM), "ss":zDigit(SS)}
}

mainGuiClose:
{
	MsgBox, 36, Exit, Do you really want to quit GUACAMOLE?
	IfMsgBox No
	{
		Return
	} 
	ExitApp
}

GetConfDate(dt:="") {
; Get next conference date. If not argument, assume today
	if !(dt) {
		dt:=A_Now
	}
	FormatTime, Wday,%dt%, Wday										; Today's day of the week (Sun=1)
	if (Wday > 3) {													; if Wed-Sat, next Tue
		dt += (10-Wday), days
	} else {														; if Sun-Tue, this Tue
		dt += (3-Wday), days
	}
	conf := breakdate(dt)
	return {YYYY:conf.YYYY, MM:conf.MM, MMM:conf.MMM, DD:conf.DD}
}

GetConfDir:
{
	confDir := NetConfDir(dt.YYYY,dt.mmm,dt.dd)								; get path to conference folder based on predicted date "dt"
	SetWorkingDir % netdir "\" confDir
	if !IsObject(confList) {												; make sure confList array exists
		confList := {}
	}
	IfExist guac.xml
	{
		gXml := new XML("guac.xml")											; Open existing guac.xml
	} else {
		gXml := new XML("<root/>")											; Create new blank guac.xml if it doesn't exist
		gXml.save("guac.xml")
	}
	filelist =																; Clear out filelist string
	patnum =																; and zero out count of patient folders
	
	Progress,,,Reading conference directory
	Loop, Files, .\*, DF													; Loop through all files and directories in confDir
	{
		tmpNm := A_LoopFileName
		tmpExt := A_LoopFileExt
		if (tmpNm ~= "i)Fast Track")										; exclude Fast Track files and folders
			continue
		if (tmpExt) {														; evaluate files with extensions
			if (tmpNm ~= "i)(\~\$|(Fast Track))")							; exclude temp and "Fast Track" files
				continue
			if (tmpNm ~= "i)(?<!(Fast Track))(PCC)?.*\d{1,2}\.\d{1,2}\.\d{2,4}.*xls") {		; find XLS that matches PCC 3.29.16.xlsx
				confXls := tmpNm
			}
			continue
		}
		if !IsObject(confList[tmpNm]) {										; confList is empty
			tmpNmUP := format("{:U}",tmpNm)									; place filename in all UPPER CASE
			confList.Push(tmpNmUP)											; add it to end of confList
			confList[tmpNmUP] := {name:tmpNm,done:0,note:""}				; name=actual filename, done=no, note=cleared
		}
		if !IsObject(gXml.selectSingleNode("/root/id[@name='" tmpNmUP "']")) {
			gXml.addElement("id","root",{name: tmpNmUP})					; Add to Guac XML if not present
		}
	}
	if (confXls) {															; Read confXls if present
		Progress,,,Reading XLS file
		gosub readXls
	}
	gXml.save("guac.xml")													; Write Guac XML
	
	Gui, Font, s16
	Gui, Add, ListView, % "r" confList.length() " x20 w720 Hdr AltSubmit Grid BackgroundSilver NoSortHdr NoSort gPatDir", Name|Diagnosis|Done|Takt|Note
	Progress,,,Rendering conference list
	for key,val in confList
	{
		if (key=A_index) {
			keyNm := confList[key]											; UPPER CASE name
			keyElement := "/root/id[@name='" keyNm "']"
			keyDx := (tmp:=gXml.selectSingleNode(keyElement "/diagnosis").text) ? tmp : ""	; DIAGNOSIS, if present
			keyDone := gXml.getAtt(keyElement,"done")						; DONE flag
			keyDur := (tmp:=gXml.getAtt(keyElement,"dur")) ? formatSec(tmp) : ""	; If dur exists, get it
			keyNote := (tmp:=gXml.selectSingleNode(keyElement "/notes").text) ? tmp : ""	; NOTE, if present
			LV_Add(""
				,keyNm														; UPPER CASE name
				,keyDx														; Diagnosis
				,(keyDone) ? "x" : ""										; DONE or not
				,(keyDur) ? keyDur.MM ":" keyDur.SS : ""					; total DUR spent on this patient MM:SS
				,(keyNote) ? keyNote : "")									; note for this patient
		}
	}
	Progress, Off
	LV_ModifyCol()
	LV_ModifyCol(1,"200")
	LV_ModifyCol(2,"AutoHdr")
	LV_ModifyCol(3,"AutoHdr Center")
	LV_ModifyCol(4,"AutoHdr Center")
	LV_ModifyCol(5,"AutoHdr")
	Return
}

NetConfDir(yyyy:="",mmm:="",dd:="") {
	global netdir, datedir, mo

	if (IsObject(datedir[yyyy,mmm])) {								; YYYY\MMM already exists
		return yyyy "\" datedir[yyyy,mmm].dir "\" datedir[yyyy,mmm,dd]	; return the string for YYYY\MMM
	}
	Loop, Files, % netdir "\" yyyy "\*" , D							; Get the month dirs in YYYY
	{
		file := A_LoopFileName
		for key,obj in mo											; Compare "file" name with Mo abbrevs
		{
			if (instr(file,obj)) {									; mo MMM abbrev is in A_loopfilename
				datedir[yyyy,obj,"dir"] := file						; insert wonky name as yr[yyyy,mmm,{dir:filename}]
			}
		}
	}
	Loop, Files, % netdir "\" yyyy "\" datedir[yyyy,mmm].dir "\*" , D	; check for conf dates within that month (dir:filename)
	{
		file := A_LoopFileName
		if (regexmatch(file,"\d{1,2}\.\d{1,2}\.\d{1,2}")) {			; sometimes named "6.19.15"
			d0 := zdigit(strX(file,".",1,1,".",1,1))
			datedir[yyyy,mmm,d0] := file
		} else if (RegExMatch(file,"\w\s\d{1,2}")){					; sometimes named "Jun 19" or "June 19"
			d0 := zdigit(strX(file," ",1,1,"",1,0))
			datedir[yyyy,mmm,d0] := file
		} else if (regexmatch(file,"\b\d{1,2}\b")) {				; sometimes just named "19"
			d0 := zdigit(file)
			datedir[yyyy,mmm,d0] := file
		}															; inserts dir name into datedir[yyyy,mmm,dd]
	}
return yyyy "\" datedir[yyyy,mmm].dir "\" datedir[yyyy,mmm,dd]		; returns path to that date's conference 
}

ReadXls:
{
	tmpDT:=gXml.selectSingleNode("/root/done").text					; last time ReadXLS run
	FileGetTime, tmpDiff, % confXls									; get XLS modified time
	tmpDiff -= tmpDT												; Compare XLS-XML time diff
	if (tmpDiff < 0) {												; XLS older, do not repeat
		return
	}
	FileCopy % confXls, guac.xlsx, 1								; Create a copy of the active XLS file 
	oWorkbook := ComObjGet(netDir "\" confDir "\guac.xlsx")			; Open the copy in memory (this is a one-way street)
	colArr := ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q"] ;array of column letters
	xls_hdr := Object()
	xls_cel := Object()
	Loop 
	{
		RowNum := A_Index																; Loop through rows in RowNum
		chk := oWorkbook.Sheets(1).Range("A" RowNum).value								; Get value in first column (e.g. A1..A10)
		if (RowNum=1) {																	; First row is just last file update
			upDate := chk
			continue
		}
		if !(chk)																		; if empty, then end of file or bad file
			break
		Loop
		{	
			ColNum := A_Index															; Iterate through columns
			if (colnum>maxcol)															; Extend maxcol (largest col) when we have passed the old max
				maxcol:=colnum
			cel := oWorkbook.Sheets(1).Range(colArr[ColNum] RowNum).value				; Get value of colNum rowNum (e.g. C4)
			if ((cel="") && (colnum=maxcol))											; Find max column
				break
			if (rownum=2) {																; Row 2 is headers
				; Patient name / MRN / Cardiologist / Diagnosis / conference prep / scheduling notes / presented / deferred / imaging needed / ICU LOS / Total LOS / Surgeons / time
				if instr(cel,"Patient name") {											; Fix some header names
					cel:="Name"
				}
				if instr(cel,"Conference prep") {
					cel:="Prep"
				}
				if instr(cel,"scheduling notes") {
					cel:="Notes"
				}
				if instr(cel,"imaging needed") {
					cel:="Imaging"
				}
				xls_hdr[ColNum] := trim(cel)											; Add cel to headers xls_hdr[]
			} else {
				xls_cel[ColNum] := cel													; Otherwise add value to xls_cel[]
			}
		}
		xls_mrn := Round(xls_cel[ObjHasValue(xls_hdr,"MRN")])							; Get value in xls_hdr MRN column 
		xls_name := xls_cel[ObjHasValue(xls_hdr,"Name")]								; Get name from xls_hdr Name column
		if !(xls_mrn)																	; Empty MRN, move on
			continue
		xls_nameL := strX(xls_name,"",1,1,",",1,1)
		StringUpper, xls_nameUP, xls_nameL												; Name in upper case
		xls_id := "/root/id[@name='" xls_nameUP "']"									; Element string for id[@name]
		
		if !IsObject(gXml.selectSingleNode(xls_id)) {									; Add new element if not present
			gXml.addElement("id","root",{name:xls_nameUP})
		}
		gXml.setAtt(xls_id,{mrn:xls_mrn})
		if !IsObject(gXml.selectSingleNode(xls_id "/name_full")) {						; Add full name if not present
			gXml.addElement("name_full",xls_id,xls_name)
		}
		if !IsObject(gXml.selectSingleNode(xls_id "/diagnosis")) {
			gXml.addElement("diagnosis",xls_id,xls_cel[ObjHasValue(xls_hdr,"Diagnosis")]) ; Add diagnostics and Diagnosis
		}
		if !IsObject(gXml.selectSingleNode(xls_id "/prep")) {
			gXml.addElement("prep",xls_id,xls_cel[ObjHasValue(xls_hdr,"Prep")])
		}
		if !IsObject(gXml.selectSingleNode(xls_id "/notes")) {
			gXml.addElement("notes",xls_id,xls_cel[ObjHasValue(xls_hdr,"Notes")])
		}
	}
	if !IsObject(gXml.selectSingleNode("/root/done")) {
		gXml.addElement("done","/root",A_Now)											; Add <done> element when has been scanned to prevent future scans
	} else {
		gXml.setText("/root/done",A_now)												; Set <done> value to now
	}
	oExcel := oWorkbook.Application														; close workbook
	oExcel.quit
	Return
}

PatDir:
{
	if !(A_GuiEvent = "DoubleClick")								; Only respond to double-click in GetConfDir listview
		return
	if WinExist("[Guac] Patient:") {								; if another PatL window still open, close it and all associated windows
		Gosub PatLGuiClose
	}
	gXml := new XML("guac.xml")										; refresh gXml from guac.xml

	Gui, Main:Submit, NoHide										; use Submit to update variables
	PatName := confList[A_EventInfo]								; get PatName from confList pointer from A_EventInfo; could we just get the first column?
	PatTime := A_Now												; timer start
	PatTime += -gXml.getAtt("/root/id[@name='" patName "']","dur"), Seconds		; add to previous cumulative dur time from gXml
	filepath := netdir "\" confdir "\" PatName						; PatName is name of folder
	filePmax = 														; clear max file field length
	fileNmax =														; clear max filename length
	filelist =														; clear out filelist
	filenum =														; clear total valid files
	pt = 															; clear patient text from Chipotle
	
	Loop, Files, % filepath "\*" , F													; read only files in patDir filepath
	{
		name := A_LoopFileName
		if (name~="i)(\~\$|Thumbs.db)") {												; exclude ~$ temp and thumbs.db files
			continue
		}
		pdoc := (name~="i)PCC(\snote)?.*\.doc") ? filepath "\" name : ""				; match "*PCC*.doc*", pdoc is complete filepath to doc, else ""
		filelist .= (name) ? name "|" : ""												; if exists, append name to listbox "filelist"
		filenum ++																		; increment filenum (total files added)
		fileNmax := (StrLen(name)>fileNmax) ? StrLen(name) : fileNmax					; Increase max filename length
	}
	
	patLBw := (fileNmax>32) ? (fileNmax-32)*12+360 : 360								; listbox width has min 360px, adds 12px for each char over 32		*** could probably consolidate this ***
	
	if !(filelist) {																	; empty filelist string
		MsgBox No files
		Gui, main:Show																	; redisplay main GUI
		return
	}
	
	gXmlPt := gXml.selectSingleNode("/root/id[@name='" patName "']")					; gXml node for PATIENT NAME
	patMRN := gXmlPt.getAttribute("mrn")												; MRN from gXmlPt node
	
	Gui, PatL:Default
	Gui, Destroy
	Gui, Font, s16
	Gui, Add, ListBox, % "r" filenum " section w" patLBw " vPatFile gPatFileGet", % filelist
	Gui, Font, s12
	Gui, Add, Button, wP Disabled vplMRNbut, No MRN found								; default MRN button to Disabled
	Gui, Add, Button, wP gPatFileGet , Open all...
	Gui, Font, s8
	if (patMRN) {																		; MRN found in gXML
		pt := checkChip(patMRN)															; check Chipotle currlist (#1) and archlist (#2) for MRN, returns in obj pt
		GuiControl, , plMRNbut, % patMRN												; change plMRNbut button to MRN
	}
	if IsObject(pt) {																	; pt obj has values if exists in either currlist or archlist
		GuiControl, , plMRNbut, CHIPOTLE data											; change plMRNbut button to indicate Chipotle data present
		Gui, Add, Text, ys x+m r20 w300 wrap vplChipNote, % ""
			. "CHIPOTLE data (from " niceDate(pt.dxEd) ")`n" 							; generate CHIPOTLE data string for sidebar
			. ((pt.dxCard)  ? "Diagnoses:`n" pt.dxCard "`n`n" : "")
			. ((pt.dxSurg)  ? "Surgeries/Caths:`n" pt.dxSurg "`n`n" : "")
			. ((pt.dxEP)    ? "EP issues:`n" pt.dxEP "`n`n" : "")
			. ((pt.dxProb)  ? "Problems:`n" pt.dxProb "`n`n" : "")
			. ((pt.dxNotes) ? "Notes:`n" pt.dxNotes : "")
	}
	Gui, Show, w800 AutoSize, % "[Guac] Patient: " PatName
	
	Gosub PatConsole																	; launch PatConsole for patient clock, "Close All", "Open file", etc.
	SetTimer, PatCxTimer, 1000															; start clock for PatCxTimer

	if IsObject(pt) {																	; pt obj had values, added CHIPOTLE data sidebar
		return																			; finish
	}
	if (patMRN) {																		; still have MRN but done
		return																			; finish
	}
	
;	TODO: This could be an IF/ELSE clause
;	TODO: the plMRNbut + checkChip() could be a final common section
	IfExist %doc%																		; no known MRN but doc exists
	{
		GuiControl, , plMRNbut, Scanning...												; change plMRNbut button to indicate scanning
		ptmp := parsePatDoc(pdoc)														; populate pdoc obj as array of document section text blocks
		gXmlPt.setAttribute("mrn",ptmp.MRN)												; add found MRN to gXML
		gXml.save("guac.xml")															; save the changes to gXML
		gosub PatDir																	; redraw entire patDir GUI
	}
	return
}

PatLGuiClose:
{
	SetTimer, PatCxTimer, Off															; cancel PatCxTimer
	Gui, PatCx:Destroy																	; destroy PatCx GUI
	
	Progress, 100, Progress, Closing files, % patName
	Loop, Files, % filepath "\*" , F													; Loop through files in pat directory "filepath"
	{
		tmpNm := A_LoopFileName
		tmpExt := A_LoopFileExt
		StringReplace , tmpNm, tmpNm, .%tmpExt%											; convert tmpNm without ext
		WinClose, %tmpNm%																; close it
	}
	Gui, PatL:Destroy																	; destroy PatList GUI
	if (Presenter) {																	; update Takt time for Presenter only
		PatTime -= A_Now, Seconds														; time diff for time patient data opened
		gXml.setAtt("/root/id[@name='" patName "']",{dur:-PatTime})						; update gXML with new total dur
		gXml.save("guac.xml")															; save gXML
	}
	Progress, Off
	gosub MainGUI																		; all patient GUI's closed, reopen main GUI
Return
}

PatConsole:
{
	if !(Presenter)																		; only display console in Presenter mode
		return
	SysGet, scr, Monitor																; get display port info into "scr"
	Gui, PatCx:Default
	Gui, Destroy
	Gui, +ToolWindow +AlwaysOnTop -SysMenu												; small title bar, delete system menu and icons
	Gui, Add, Text, vPatCxT, % "                 "										; PatCx time
	Gui, Font, s6
	Gui, Add, Button, xP+50 yP gPatCxSel, Select File									; show file selector
	Gui, Add, Button, xP yP+18 gPatLGuiClose, Close all									; close GUI and all opened patient files
	Gui, Show, % "x" scrRight-200 " y10 AutoSize", % PatName
	return
}

PatCxTimer:
{
	tt := elapsed(PatTime,A_Now)														; get elapsed time between PatTime and A_Now
	GuiControl, PatCx:Text, PatCxT, % tt.mm ":" tt.ss									; update PatCx time display
	if (tt.mm >= 10) {
		Gui, PatCx:Color, Red															; change bkgd RED if over 10 mins
	} else if (tt.mm >= 8) {
		Gui, PatCx:Color, Yellow														; otherwise change bkgd YEL if over 8 mins
	}
	return
}

PatCxSel:
{
	WinActivate % "[Guac] Patient:"														; bring back PatL GUI
	return
}

PatFileGet:
{
	Gui, PatL:Submit, NoHide
	if (A_GuiEvent = "DoubleClick") {													; double-click on line, just pass the line data
		files := PatFile
	} else if (A_GuiControl = "Open all...") {											; clicked "Open all..." button
		files := trim(filelist,"|")														; trim "|" from end
		If (filenum>4) {
			MsgBox, 52, % "Lots of files (" filenum ")", Really open all of these files?
			IfMsgBox, Yes
				tmp = true
			if !(tmp)																	; necessary as dialog can be Yes, No, or close
				return
		}
	} else {
		return
	}
	confList[PatName].done := true														; set confList bit DONE for this patient
	gXml.selectSingleNode("/root/id[@name='" PatName "']").setAttribute("done",1)		; set done bit in gXML
	gXml.save("guac.xml")																; save gXML
	
	Loop, parse, files, |																; iterate through files in folder
	{
		patloopfile := A_LoopField														; file name
		patdirfile := filepath "\" PatloopFile											; path + file name
		Run, %patDirFile%																; open by Windows default method
	}
Return
}

parsePatDoc(doc) {
	txt := ComObjGet(doc).Range.Text													; select all text in doc
	return fieldvals(txt)																; return obj with doc sections from fieldvals
}

checkChip(mrn) {
/*	Checks currlist and archlist for MRN
	if exists, parses mrn and returns ptParse array
*/
	global y, arch
	if IsObject(y.selectSingleNode("//id[@mrn='" mrn "']")) {							; present in currlist?
		return ptParse(mrn,y)
	} else if IsObject(arch.selectSingleNode("//id[@mrn='" mrn "']")) {					; check the archives
		return ptParse(mrn,arch)
	} 
	
	return Error
}

breakDate(x) {
; Disassembles 201502150831 into Yr=2015 Mo=02 Da=15 Hr=08 Min=31 Sec=00
	D_Yr := substr(x,1,4)
	D_Mo := substr(x,5,2)
	D_Da := substr(x,7,2)
	D_Hr := substr(x,9,2)
	D_Min := substr(x,11,2)
	D_Sec := substr(x,13,2)
	FormatTime, D_day, %x%, ddd
	FormatTime, D_Mon, %x%, MMM
	return {"YYYY":D_Yr, "MM":D_Mo, "MMM":D_Mon, "DD":D_Da, "ddd":D_day
		, "HH":D_Hr, "min":D_Min, "sec":D_sec}
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
ObjHasValue(aObj, aValue, rx:="") {
; modified from http://www.autohotkey.com/board/topic/84006-ahk-l-containshasvalue-method/	
    for key, val in aObj
		if (rx="RX") {																	; argument 3 is "RX" 
			if (aValue ~= val) {														; does RegExMatch
				return, key, Errorlevel := 0
			}
		} else {
			if (val = aValue) {															; otherwise just string match
				return, key, ErrorLevel := 0
			}
		}
    return, false, errorlevel := 1														; fails match, return err
}

fieldvals(x) {
/*	Matches field values and results. Gets text between FIELDS[k] to FIELDS[k+1]. Excess whitespace removed. Returns results as array.
	x	= input text
*/
	fields := ["Result Title:","Performed By:","HEART CENTER CARE COORDINATION NOTE","DOB:","MR #:","AGE:"
		,"PRESENTING CARDIOLOGIST:","\bCARDIOLOGIST:","SURGEON\(s\):","PRIMARY CARE PHYSICIAN:","REQUEST FOR:","DIAGNOSIS:"
		,"PURPOSE OF PRESENTATION:","CLINICAL HISTORY:","HISTORY \(SURGICAL AND INTERVENTIONS\):","OPERATIVE REPORTS:"
		,"BRIEF FINDINGS \(see below for further detail\)"
		,"\bECG","\bCXR","\bECHO","\bMRI","\bCT","\bCath/Angio","\bEP","\bExercise","\bHolter","\bOp Note"
		,"Other Studies / Details:"]
	out := object()
	for k, i in fields																	; k = index, i = field string
	{
		j := fields[k+1]																; j = next index
		m := trim(stRegX(x,i,n,1,j,1,n)," `r`n`t")									; m = string within, trimmed of extraneous characters
		lbl := RegExReplace(trim(cleanColon(i)," `r`n`t#"),"\\[\w()]")					; lbl = string up to ":"
		if (lbl="MR") {
			m := LTrim(RegExReplace(m,"\-"),"0")										; normalize MRN field name
			lbl := "MRN"
		}
		if (lbl="HEART CENTER CARE COORDINATION NOTE") {								; *** this will break if there is an addendum ***
			StringLower, m, m, T
			out.nameL := strX(m,,1,0, ",",1,1)											; nameL = string to ","
			lbl := "nameF"
			m := strX(m,",",1,2, " ",1,1)												; nameF = string "," to " "			*** can probably change to CONTINUE ***
		}
		if (lbl="CARDIOLOGIST") {
			m := strX(m,"",1,1,", ",1,2)												; take name up to ", "
			m := SubStr(m,1,1) ". " strX(m," ",0,1,"",0,1)								; first initial ". " last name
		}
		out[lbl] := m																	; set object value
	}
	return out
}

stRegX(h,BS="",BO=1,BT=0, ES="",ET=0, ByRef N="") {
/*	modified version: searches from BS to "   "
	h = Haystack
	BS = beginning string
	BO = beginning offset
	BT = beginning trim, TRUE or FALSE
	ES = ending string
	ET = ending trim, TRUE or FALSE
	N = variable for next offset
*/
	;BS .= "(.*?)\s{3}"
	rem:="[OPimsxADJUXPSC(\`n)(\`r)(\`a)]+\)"
	pos0 := RegExMatch(h,((BS~=rem)?"Oim"BS:"Oim)"BS),bPat,((BO<1)?1:BO))
	pos1 := RegExMatch(h,((ES~=rem)?"Oim"ES:"Oim)"ES),ePat,pos0+bPat.len)
	N := pos1+((ET)?0:(ePat.len))
	return substr(h,pos0+((BT)?(bPat.len):0),N-pos0-bPat.len)
}

cleancolon(ByRef txt) {
	n := InStr(txt,":")																	; extraneous var?
	txt:=strX(txt,"",1,1,":",1,1)														; get string up to ":"
	txt = %txt%																			; trim space from result
	return txt
}

cleanspace(ByRef txt) {
	StringReplace txt,txt,`n,%A_Space%, All												; replace "`n" with space, create long string from block
	StringReplace txt,txt,%A_Space%.%A_Space%,.%A_Space%, All							; replace any instance of " . " with ". "
	loop
	{
		StringReplace txt,txt,%A_Space%%A_Space%,%A_Space%, UseErrorLevel				; replace all "  " with " "
		if ErrorLevel = 0																; continue until no more instances
			break
	}
	return txt
}

PtParse(mrn,ByRef y) {
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
		, "dxEd":y.getAtt(mrnstring "/diagnoses", "ed")
		, "dxCard":pl.selectSingleNode("diagnoses/card").text
		, "dxEP":pl.selectSingleNode("diagnoses/ep").text
		, "dxSurg":pl.selectSingleNode("diagnoses/surg").text
		, "dxNotes":pl.selectSingleNode("diagnoses/notes").text
		, "dxProb":pl.selectSingleNode("diagnoses/prob").text
		, "misc":pl.selectSingleNode("diagnoses/misc").text
		, "statCons":(pl.selectSingleNode("status").getAttribute("cons") == "on")
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
		, "ProvCSR":y.getAtt(mrnstring "/prov","CSR")
		, "ProvEP":y.getAtt(mrnstring "/prov","provEP")
		, "ProvPCP":y.getAtt(mrnstring "/prov","provPCP")
		, "statPM":(pl.selectSingleNode("prov").getAttribute("pm") == "on")
		, "statMil":(pl.selectSingleNode("prov").getAttribute("mil") == "on")
		, "statTxp":(pl.selectSingleNode("prov").getAttribute("txp") == "on")}
}


#Include xml.ahk
#Include StrX.ahk
#Include Class_LV_Colors.ahk
#Include sift3.ahk
#Include CMsgBox.ahk