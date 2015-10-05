/* 	GUACAMOLE conference data browser (C)2015 TC
*/

/*	Todo lists: 
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetTitleMatchMode, 2
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
WinClose, View Downloads - Windows Internet Explorer
LV_Colors.OnMessage()

gosub ReadIni
user := A_UserName
isAdmin := ObjHasValue(admins,user)
;~ if (InStr(A_WorkingDir,"-AutoHotkey")) {
if (user="TC") {
	netdir := A_WorkingDir "\files\Tuesday Conference"
} else {
	netdir := "\\chmc16\Cardio\Conference\Tuesday Conference"
}

datedir := Object()
mo := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

y := new XML("currlist.xml")												; Get latest local currlist into memory
arch := new XML("archlist.xml")												; Get archive.xml

Gosub MainGUI
WinWaitClose, GUACAMOLE Main
ExitApp

;	===========================================================================================
ReadIni:
{
admins:=[]
cicuUsers:=[]
arnpUsers:=[]
txpDocs:=[]
csrDocs:=[]
cicuDocs:=[]
loc:=Object()
CIS_cols:=[]
CIS_colvals:=[]
dialogVals:=[]
teamSort:=[]
meds1:=[]
meds2:=[]
Forecast_svc:=[]
Forecast_val:=[]

	Loop, Read, chipotle.ini
	{
		i:=A_LoopReadLine
		if (i="")
			continue
		if (substr(i,1,1)="[") {
			sec:=strX(i,"[",1,1,"]",1,1)
			continue
		}
		if (k := RegExMatch(i,"[\s\t];")) {
			i := trim(substr(i,1,k))
		}
		if (sec="ADMINS") {
			admins.Insert(i)
		}
		if (sec="CICU") {
			cicuUsers.Insert(i)
		}
		if (sec="ARNP") {
			arnpUsers.Insert(i)
		}
		if (sec="TXPDOCS") {
			txpDocs.Insert(i)
		}
		if (sec="CSRDOCS") {
			csrDocs.Insert(i)
		}
		if (sec="CICUDOCS") {
			cicuDocs.Insert(i)
		}
		if (sec="LOCATIONS") {
			splitIni(i,c1,c2)
			StringLower, c3, c1
			loc.Insert(c1)
			loc[c1] := {name:c2, datevar:"GUI" c3 "TXT"}
		}
		if (sec="CIS_strings") {
			splitIni(i,c1,c2)
			%c1% := c2
		}
		if (sec="Dialog_Str") {
			dialogVals.Insert(i)
		}
		if (sec="CIS_cols") {
			splitIni(i,c1,c2)
			CIS_cols.Insert(c1)
			CIS_colvals.Insert(c2)
		}
		if (sec="CORES_struc") {
			splitIni(i,c1,c2)
			%c1% := c2
		}
		if (sec="Team sort") {
			teamSort.Insert(i)
		}
		if (sec="MEDS1") {
			meds1.Insert(i)
		}
		if (sec="MEDS2") {
			meds2.Insert(i)
		}
		if (sec="Forecast") {
			splitIni(i,c1,c2)
			Forecast_svc.Insert(c1)
			Forecast_val.Insert(c2)
		}
	}
Return
}

splitIni(x, ByRef y, ByRef z) {
	y := trim(substr(x,1,(k := instr(x, "="))), " `t=")
	z := trim(substr(x,k), " `t=""")
	return
}

MainGUI:
{
	dt := GetConfDate()									; determine next conference date into array dt
	Gui, main:Default
	Gui, Destroy
	Gui, Font, s16 wBold
	Gui, Add, Text, y0 w250 h20 +Center, .-= GUACAMOLE =-.
	Gui, Font, wNorm s8 wItalic
	Gui, Add, Text, yp+30 wp +Center, General Use Access tool for Conference Archive
	Gui, Add, Text, xp yp+14 wp hp +Center, Merged OnLine Elements
	Gui, Font, wNorm
	Gui, Add, Button, wp gGetConfDir, % dt.MMM " " dt.DD
	Gui, Add, Button, wp Disabled, Date browser
	Gui, Add, Button, wp Disabled, AHK %A_AhkVersion%
	Gui, Show, AutoSize, GUACAMOLE Main
Return
}

mainGuiClose:
ExitApp

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
	confDir := NetConfDir(dt.YYYY,dt.mmm,dt.dd)
	filelist =
	Loop, % netdir "\" confDir "\*" , 2
	{
		filelist .= A_LoopFileName "|"
	}
	Gui, ConfL:Default
	Gui, Destroy
	Gui, Font, s16
	Gui, Add, ListBox, vPatName gPatDir, %filelist%
	Gui, Show, AutoSize, % "Conference " dt.MM "/" dt.DD "/" dt.YYYY
	Return
}

NetConfDir(yyyy:="",mmm:="",dd:="") {
	global netdir, mo, datedir
	if (IsObject(datedir[yyyy,mmm])) {
		return yyyy "\" datedir[yyyy,mmm].dir "\" datedir[yyyy,mmm,dd]
	}
	Loop, % netdir "\" yyyy "\*" , 2								; Get the month dirs in YYYY
	{
		file := A_LoopFileName
		for key,obj in mo											; Compare "file" name with Mo abbrevs
		{
			if (instr(file,obj)) {									; mo MMM abbrev is in A_loopfilename
				datedir[yyyy,obj,"dir"] := file						; insert wonky name as yr[yyyy,mmm,{dir:filename}]
			}
		}
	}
	Loop, % netdir "\" yyyy "\" datedir[yyyy,mmm].dir "\*" , 2		; check for conf dates within that month (dir:filename)
	{
		file := A_LoopFileName
		if (regexmatch(file,"\d{1,2}\.\d{1,2}\.\d{1,2}")) {			; sometimes named "6.19.15"
			dd := zdigit(strX(file,".",1,1,".",1,1))
			datedir[yyyy,mmm,dd] := file
		} else if (RegExMatch(file,"\w\s\d{1,2}")){					; sometimes named "Jun 19" or "June 19"
			dd := zdigit(strX(file," ",1,1,"",1,0))
			datedir[yyyy,mmm,dd] := file
		} else if (regexmatch(file,"\b\d{1,2}\b")) {				; sometimes just named "19"
			dd := zdigit(file)
			datedir[yyyy,mmm,dd] := file
		}															; inserts dir name into datedir[yyyy,mmm,dd]
	}
return yyyy "\" datedir[yyyy,mmm].dir "\" datedir[yyyy,mmm,dd]		; returns path to that date's conference 
}

PatDir:
{
	if !(A_GuiEvent = "DoubleClick")
		return
	Gui, ConfL:Submit
	filelist =
	filenum =
	Loop, % netdir "\" confdir "\" PatName "\*" , 1
	{
		name := A_LoopFileName
		filelist .= (name) ? name "|" : ""
		filenum ++
	}
	if !(filelist) {
		MsgBox No files
		return
	}
	Gui, PatL:Default
	Gui, Destroy
	Gui, Font, s16
	Gui, Add, ListBox, r%filenum% vPatFile gPatFileGet,%filelist%
	Gui, Font, s12
	Gui, Add, Button, wP, Open all...
	Gui, Show, AutoSize, % "Patient: " PatName
	return
}

PatFileGet:
{
	if !(A_GuiEvent = "DoubleClick")
		return
	Gui, PatL:Submit
		
	SplitPath, PatFile, , , PatFileExt
	patdirfile := netdir "\" confdir "\" PatName "\" PatFile
	filetxt =
	if ((instr(patFileExt,"doc")) and (instr(PatFile,"PCC note"))) {
		;~ MsgBox, 262404, Parse file, Harvest info?
		;~ IfMsgBox, Yes
		if (patfile)								
		{
			pt := parsePatDoc(patDirFile)
			checkChip(pt)
			MsgBox % arch
			;~ lbl := "mrn"
			;~ MsgBox,, % lbl, % "'" tx[lbl] "'"
		} else {
		}
	} else {
		Run, %patDirFile%
	}
Return
}

parsePatDoc(doc) {
	;~ IfNotExist %doc% {
		;~ return Error
	;~ }
	SplitPath, doc, docName, docDir, docExt, docNoExt
	Progress,,% docNoExt, Reading...
	txt := ComObjGet(doc).Range.Text
	Progress, hide
	return fieldvals(txt)
}

checkChip(pt) {
	global y, arch
	mrn := "1431528"
	if IsObject(y.selectSingleNode("//id[@mrn='" mrn "']")) {			; present in any active list?
		;getPatXml
	} else if IsObject(arch.selectSingleNode("//id[@mrn='" mrn "']")) {			; check the archives
		MsgBox Archive list
	} else {
		MsgBox Not on any list
	}
	
	;lbl := "cardiologist"
	;MsgBox,, % lbl, % "'" pt[lbl] "'"
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
	;global fields
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

#Include xml.ahk
#Include StrX.ahk
#Include Class_LV_Colors.ahk
#Include sift3.ahk
#Include CMsgBox.ahk