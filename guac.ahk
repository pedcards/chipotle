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
	;Gui, Add, Text, yp+30 wp +Center, % "Conference " dt.MM "/" dt.DD "/" dt.YYYY
	Gui, Font, wNorm
	Gosub GetConfDir																; Draw the pateint grid ListView
	Gui, Show, AutoSize, % "GUACAMOLE Main - " dt.MM "/" dt.DD "/" dt.YYYY			; Show GUI with seleted conference DT
Return
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
	
	Loop, Files, .\*, DF													; Loop through all files and directories in confDir
	{
		tmpNm := A_LoopFileName
		tmpExt := A_LoopFileExt
		if (tmpExt) {														; evaluate files with extensions
			if (tmpNm ~= "i)(\~\$|(Fast Track))")							; exclude "Fast Track" files
				continue
			if (tmpNm ~= "i)(PCC)?\s*\d{1,2}\.\d{1,2}\.\d{2,4}.*xls") {		; find XLS that matches PCC 3.29.16.xlsx
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
		gosub readXls
	}
	gXml.save("guac.xml")													; Write Guac XML
	
	Gui, Font, s16
	Gui, Add, ListView, % "r" confList.length() " x20 w540 Hdr AltSubmit Grid BackgroundSilver NoSortHdr NoSort gPatDir", Name|Done|Takt|Note
	for key,val in confList
	{
		if (key=A_index) {
			keyNm := confList[key]											; UPPER CASE name
			keyElement := "/root/id[@name='" keyNm "']"
			keyDone := gXml.getAtt(keyElement,"done")						; DONE flag
			keyDur := (tmp:=gXml.getAtt(keyElement,"dur")) ? formatSec(tmp) : ""	; If dur exists, get it
			keyNote := (tmp:=gXml.selectSingleNode(keyElement "/notes").text) ? tmp : ""	; NOTE, if present
			LV_Add(""
				,keyNm														; UPPER CASE name
				,(keyDone) ? "x" : ""										; DONE or not
				,(keyDur) ? keyDur.MM ":" keyDur.SS : ""					; total DUR spent on this patient MM:SS
				,(keyNote) ? keyNote : "")									; note for this patient
		}
	}
	LV_ModifyCol()
	LV_ModifyCol(1,"200")
	LV_ModifyCol(2,"AutoHdr Center")
	LV_ModifyCol(3,"AutoHdr Center")
	LV_ModifyCol(4,"AutoHdr")
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
	oWorkbook := ComObjGet(netDir "\" confDir "\guac.xlsx")
	colArr := ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q"] ;array of column letters
	xls_hdr := Object()
	xls_cel := Object()
	Loop 
	{
		RowNum := A_Index																; Loop through rows
		chk := oWorkbook.Sheets(1).Range("A" RowNum).value
		if (RowNum=1) {																	; First row is just last file update
			upDate := chk
			continue
		}
		if !(chk)																		; if empty, then bad file
			break
		Loop
		{	
			ColNum := A_Index															; Iterate through columns
			if (colnum>maxcol)
				maxcol:=colnum
			cel := oWorkbook.Sheets(1).Range(colArr[ColNum] RowNum).value
			if ((cel="") && (colnum=maxcol))											; Find max column
				break
			if (rownum=2) {																; Fix some column names
				; Patient name / MRN / Cardiologist / Diagnosis / conference prep / scheduling notes / presented / deferred / imaging needed / ICU LOS / Total LOS / Surgeons / time
				if instr(cel,"Patient name") {
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
				xls_hdr[ColNum] := trim(cel)
			} else {
				xls_cel[ColNum] := cel
			}
		}
		xls_mrn := Round(xls_cel[ObjHasValue(xls_hdr,"MRN")])
		xls_name := xls_cel[ObjHasValue(xls_hdr,"Name")]
		if !(xls_mrn)
			continue
		xls_nameL := strX(xls_name,"",1,1,",",1,1)
		StringUpper, xls_nameUP, xls_nameL
		xls_id := "/root/id[@name='" xls_nameUP "']"
		
		if !IsObject(gXml.selectSingleNode(xls_id)) {
			gXml.addElement("id","root",{name:xls_nameUP})
		}
		gXml.setAtt(xls_id,{mrn:xls_mrn})
		if !IsObject(gXml.selectSingleNode(xls_id "/name_full")) {
			gXml.addElement("name_full",xls_id,xls_name)
		}
		if !IsObject(gXml.selectSingleNode(xls_id "/diagnosis")) {
			gXml.addElement("diagnosis",xls_id,xls_cel[ObjHasValue(xls_hdr,"Diagnosis")])
		}
		if !IsObject(gXml.selectSingleNode(xls_id "/prep")) {
			gXml.addElement("prep",xls_id,xls_cel[ObjHasValue(xls_hdr,"Prep")])
		}
		if !IsObject(gXml.selectSingleNode(xls_id "/notes")) {
			gXml.addElement("notes",xls_id,xls_cel[ObjHasValue(xls_hdr,"Notes")])
		}
	}
	if !IsObject(gXml.selectSingleNode("/root/done")) {
		gXml.addElement("done","/root",A_Now)												; Add <done> element when has been scanned to prevent future scans
	} else {
		gXml.setText("/root/done",A_now)
	}
	oExcel := oWorkbook.Application
	oExcel.quit
	Return
}

PatDir:
{
	if !(A_GuiEvent = "DoubleClick")
		return
	if WinExist("[Guac] Patient:") {								; if a window still open, close it.
		Gosub PatLGuiClose
	}
	gXml := new XML("guac.xml")										; refresh guac.xml

	Gui, Main:Submit, NoHide
	PatName := confList[A_EventInfo]
	PatTime := A_Now
	PatTime += -gXml.getAtt("/root/id[@name='" patName "']","dur"), Seconds
	filepath := netdir "\" confdir "\" PatName
	filePmax = 
	fileNmax =
	filelist =
	filenum =
	pdoc =
	pt = 
	Loop, % filepath "\*" , 1
	{
		name := A_LoopFileName
		if (name~="(\~\$|Thumbs.db)") {
			continue
		}
		if (RegExMatch(name,"i)PCC(\snote)?.*\.doc")) {
			pdoc := filepath "\" name
		}
		filelist .= (name) ? name "|" : ""
		filenum ++
		filePmax := StrLen(name)
		if (filePmax>fileNmax) {														; Get longest filename
			fileNmax := filePmax
		}
	}
	patLBw := (fileNmax>32) ? (fileNmax-32)*12+360 : 360
	if !(filelist) {
		MsgBox No files
		Gui, main:Show
		return
	}
	gXmlPt := gXml.selectSingleNode("/root/id[@name='" patName "']")
	patMRN := gXmlPt.getAttribute("mrn")
	Gui, PatL:Default
	Gui, Destroy
	Gui, Font, s16
	Gui, Add, ListBox, % "r" filenum " section w" patLBw " vPatFile gPatFileGet", % filelist
	Gui, Font, s12
	Gui, Add, Button, wP Disabled vplMRNbut, No MRN found
	Gui, Add, Button, wP gPatFileGet , Open all...
	Gui, Font, s8
	if (patMRN) {
		pt := checkChip(patMRN)
		GuiControl, , plMRNbut, % patMRN
	}
	if IsObject(pt) {
		tmp := 	"CHIPOTLE data (from " niceDate(pt.dxEd) ")`n" 
			. ((pt.dxCard)  ? "Diagnoses:`n" pt.dxCard "`n`n" : "")
			. ((pt.dxSurg)  ? "Surgeries/Caths:`n" pt.dxSurg "`n`n" : "")
			. ((pt.dxEP)    ? "EP issues:`n" pt.dxEP "`n`n" : "")
			. ((pt.dxProb)  ? "Problems:`n" pt.dxProb "`n`n" : "")
			. ((pt.dxNotes) ? "Notes:`n" pt.dxNotes : "")
		GuiControl, , plMRNbut, CHIPOTLE data
		Gui, Add, Text, ys x+m r20 w300 wrap vplChipNote, % tmp
	}
	Gui, Show, w800 AutoSize, % "[Guac] Patient: " PatName
	
	Gosub PatConsole
	SetTimer, PatCxTimer, 1000

	if IsObject(pt) {
		return
	}
	if !(patMRN) {
		GuiControl, , plMRNbut, Scanning...
		pdoc := parsePatDoc(pdoc)
		gXmlPt.setAttribute("mrn",pdoc.MRN)
		gXml.save("guac.xml")
		GuiControl, , plMRNbut, % pdoc.MRN
		pt := checkChip(pdoc.MRN)
		gosub PatDir
	}
	return
}

PatLGuiClose:
{
	SetTimer, PatCxTimer, Off
	Gui, PatCx:Destroy
	
	Loop, % filepath "\*" , 1
	{
		tmpNm := A_LoopFileName
		tmpExt := A_LoopFileExt
		StringReplace , tmpNm, tmpNm, .%tmpExt%
		WinClose, %tmpNm%
	}
	Gui, PatL:Destroy
	if (Presenter) {																	; update Takt time for Presenter only
		PatTime -= A_Now, Seconds
		gXml.setAtt("/root/id[@name='" patName "']",{dur:-PatTime})
		gXml.save("guac.xml")
	}
	gosub MainGUI
Return
}

PatConsole:
{
	if !(Presenter)
		return
	SysGet, scr, Monitor
	Gui, PatCx:Default
	Gui, Destroy
	Gui, +ToolWindow +AlwaysOnTop -SysMenu
	Gui, Add, Text, vPatCxT, % "                 "
	Gui, Font, s6
	Gui, Add, Button, xP+50 yP gPatCxSel, Select File
	Gui, Add, Button, xP yP+18 gPatLGuiClose, Close all
	Gui, Show, % "x" scrRight-200 " y10 AutoSize", % PatName
	return
}

PatCxTimer:
{
	tt := elapsed(PatTime,A_Now)
	GuiControl, PatCx:Text, PatCxT, % tt.mm ":" tt.ss
	if (tt.mm >= 10) {
		Gui, PatCx:Color, Red
	} else if (tt.mm >= 8) {
		Gui, PatCx:Color, Yellow
	}
	return
}

PatCxSel:
{
	WinActivate % "[Guac] Patient:"
	return
}

PatFileGet:
{
	Gui, PatL:Submit, NoHide
	if (A_GuiEvent = "DoubleClick") {
		files := PatFile
	} else if (A_GuiControl = "Open all...") {
		files := trim(filelist,"|")
		If (filenum>4) {
			MsgBox, 52, % "Lots of files (" filenum ")", Really open all of these files?
			IfMsgBox, Yes
				tmp = true
			if !(tmp) 
				return
		}
	} else {
		return
	}
	confList[PatName].done := true
	gXml.selectSingleNode("/root/id[@name='" PatName "']").setAttribute("done",1)
	gXml.save("guac.xml")
	Loop, parse, files, |
	{
		patloopfile := A_LoopField
		patdirfile := filepath "\" PatloopFile
		Run, %patDirFile%
	}
Return
}

parsePatDoc(doc) {
	;~ IfNotExist %doc% {
		;~ return Error
	;~ }
	;SplitPath, doc, docName, docDir, docExt, docNoExt
	;Progress,,% docNoExt, Reading...
	txt := ComObjGet(doc).Range.Text
	;Progress, hide
	return fieldvals(txt)
}

checkChip(mrn) {
/*	Checks currlist and archlist for MRN
	if exists, returns in array pt
*/
	global y, arch
	if IsObject(y.selectSingleNode("//id[@mrn='" mrn "']")) {			; present in any active list?
		return pt := ptParse(mrn,y)
	} else if IsObject(arch.selectSingleNode("//id[@mrn='" mrn "']")) {			; check the archives
		return pt := ptParse(mrn,arch)
	} else {
		;MsgBox Not on any list
	}
	return pt
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
	for k, i in fields
	{
		j := fields[k+1]
		m := trim(stRegX(x,i,n,1,j,1,n)," `r`n`t")
		lbl := RegExReplace(trim(cleanColon(i)," `r`n`t#"),"\\[\w()]")
		if (lbl="MR") {
			m := LTrim(RegExReplace(m,"\-"),"0")
			lbl := "MRN"
		}
		if (lbl="HEART CENTER CARE COORDINATION NOTE") {
			StringLower, m, m, T
			out.nameL := strX(m,,1,0, ",",1,1)
			lbl := "nameF"
			m := strX(m,",",1,2, " ",1,1)
		}
		if (lbl="CARDIOLOGIST") {
			m := strX(m,"",1,1,", ",1,2)
			m := SubStr(m,1,1) ". " strX(m," ",0,1,"",0,1)
		}
		out[lbl] := m
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
	n := InStr(txt,":")
	txt:=strX(txt,"",1,1,":",1,1)
	txt = %txt%
	return txt
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