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
	netdir := A_WorkingDir "\files\Tuesday Conference"
	chipdir := ""
} else {
	netdir := "\\chmc16\Cardio\Conference\Tuesday Conference"
	chipdir := "\\childrens\files\HCChipotle\"
}

y := new XML(chipdir "currlist.xml")												; Get latest local currlist into memory
arch := new XML(chipdir "archlist.xml")												; Get archive.xml
datedir := Object()
mo := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

Gosub MainGUI
WinWaitClose, GUACAMOLE Main
ExitApp

;	===========================================================================================

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
	patnum =
	Loop, % netdir "\" confDir "\*" , 2
	{
		filelist .= A_LoopFileName "|"
		patnum ++
	}
	Gui, main:Minimize
	Gui, ConfL:Default
	Gui, Destroy
	Gui, Font, s16
	Gui, Add, ListBox, % ((patnum) ? "r" patNum : "") " vPatName gPatDir", %filelist%
	Gui, Show, AutoSize, % "Conference " dt.MM "/" dt.DD "/" dt.YYYY
	Return
}

confLGuiClose:
	Gui, ConfL:Destroy
	Gui, main:Show
return

NetConfDir(yyyy:="",mmm:="",dd:="") {
	global netdir, datedir, mo

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

PatDir:
{
	if !(A_GuiEvent = "DoubleClick")
		return
	Gui, ConfL:Submit
	filepath := netdir "\" confdir "\" PatName
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
	}
	if !(filelist) {
		MsgBox No files
		Gui, ConfL:Show
		return
	}
	Gui, PatL:Default
	Gui, Destroy
	Gui, Font, s16
	Gui, Add, ListBox, r%filenum% w400 vPatFile gPatFileGet,%filelist%
	Gui, Font, s12
	Gui, Add, Button, wP Disabled vplMRNbut gChipInfo, No MRN found
	Gui, Add, Button, wP gPatFileGet , Open all...
	Gui, Show, AutoSize, % "Patient: " PatName
	if (pdoc) {
		pdoc := parsePatDoc(pdoc)
		GuiControl, , plMRNbut, % pdoc.MRN
		pt := checkChip(pdoc.MRN)
	}
	if IsObject(pt) {
		GuiControl, , plMRNbut, CHIPOTLE data
		GuiControl, Enable, plMRNbut
	}
	return
}

PatLGuiClose:
	Gui, PatL:Destroy
	Gui, ConfL:Show
Return

ChipInfo:
{
	MsgBox,,% "CHIPOTLE notes - " pt.nameL ", " pt.nameF, % ""
	. "Diagnoses:`n" pt.dxCard "`n`n"
	. "Surgeries/Caths:`n" pt.dxSurg "`n`n"
	. "EP issues:`n" pt.dxEP "`n`n"
	. "Problems:`n" pt.dxProb "`n`n"
	. "Notes: " ((pt.dxNotes) ? "(from " niceDate(pt.dxEd) ")`n" pt.dxNotes : "")
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