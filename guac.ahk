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
;ConfStart := "20160416132100"
ConfStart := A_Now

Gosub MainGUI
SetTimer, ConfTime, 1000
SetTimer, ConfDur, 1000
WinWaitClose, GUACAMOLE Main
ExitApp

;	===========================================================================================

MainGUI:
{
	if !IsObject(dt) {
		;dt := GetConfDate()									; determine next conference date into array dt
		dt := GetConfDate("20160329")									; determine next conference date into array dt
	}
	Gui, main:Default
	Gui, Destroy
	Gui, Font, s16 wBold
	Gui, Add, Text, y0 x10 vCTime, % "              "
	Gui, Add, Text, y0 x460 vCDur, % "              "
	Gui, Add, Text, y0 x160 w240 h20 +Center, .-= GUACAMOLE =-.
	Gui, Font, wNorm s8 wItalic
	Gui, Add, Text, yp+30 xp wp +Center, General Use Access tool for Conference Archive
	Gui, Add, Text, yp+14 xp wp +Center, Merged OnLine Elements
	Gui, Font, wBold
	;Gui, Add, Text, yp+30 wp +Center, % "Conference " dt.MM "/" dt.DD "/" dt.YYYY
	Gui, Font, wNorm
	Gosub GetConfDir
	Gui, Show, AutoSize, % "GUACAMOLE Main - " dt.MM "/" dt.DD "/" dt.YYYY
Return
}

ConfTime:
{
	FormatTime, tmp, , HH:mm:ss
	GuiControl, main:Text, CTime, % tmp
	return
}

ConfDur:
{
	tt := elapsed(ConfStart)
	GuiControl, main:Text, CDur, % tt.hh ":" tt.mm ":" tt.ss
	Return
}

elapsed(start) {
	start -= A_Now, Seconds
	HH := floor(-start/3600)
	MM := floor((-start-HH*3600)/60)
	SS := HH*3600-MM*60-start
	Return {"hh":zDigit(HH), "mm":zDigit(MM), "ss":zDigit(SS)}
}

mainGuiClose:
{
	MsgBox, 36, Exit, Do you really want to leave GUACAMOLE?`n`nWHY???
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
		Gosub GetGuacXml
	} else {
		gXml := new XML("<root/>")
		gXml.save("guac.xml")
	}
	filelist =
	patnum =
	Loop, Files, .\*, DF
	{
		tmpNm := A_LoopFileName
		tmpExt := A_LoopFileExt
		if (tmpExt) {														; evaluate files with extensions
			if (tmpNm ~= "i)(\~\$|(Fast Track))")									; exclude "Fast Track" files
				continue
			if (tmpNm ~= "i)(PCC)?\s*\d{1,2}\.\d{1,2}\.\d{2,4}.*xls") {		; find XLS that matches 3.29.16.xlsx
				confXls := tmpNm
			}
			continue
		}
		if !IsObject(confList[tmpNm]) {
			confList.Push(tmpNm)
			confList[tmpNm] := {name:tmpNm,done:0,note:""}
		}
		if !IsObject(gXml.selectSingleNode("/root/id[@name='" tmpNm "']")) {
			gXml.addElement("id","root",{name: tmpNm})
		}
	}
	gXml.save("guac.xml")
	Gui, Font, s16
	Gui, Add, ListView, % "r" confList.length() " x20 w540 Hdr AltSubmit Grid BackgroundSilver NoSortHdr NoSort gPatDir", Name|Done|Takt|Note
	for key,val in confList
	{
		if (key=A_index) {
			;LV_Add("",confList[key],(confList[val].done) ? "x" : "",confList[val].note)
			LV_Add("",confList[key],(gXml.selectSingleNode("/root/id[@name='" confList[key] "']").getAttribute("done")) ? "x" : "",confList[val].note)
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

GetGuacXml:
{
	gXml := new XML("guac.xml")
	
	Return
}

PatDir:
{
	;MsgBox % A_GuiEvent
	if (ErrorLevel~="[Cc]") {
		tmp := A_EventInfo
		confList[confList[tmp]].done := 1-confList[confList[tmp]].done
		;MsgBox % confList[confList[tmp]].done "`n" !(confList[confList[tmp]].done)
	}
	if !(A_GuiEvent = "DoubleClick")
		return
	Gui, Main:Submit, NoHide
	PatName := confList[A_EventInfo]
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
		Gui, main:Show
		return
	}
	gXmlPt := gXml.selectSingleNode("/root/id[@name='" patName "']")
	patMRN := gXmlPt.getAttribute("mrn")
	Gui, PatL:Default
	Gui, Destroy
	Gui, Font, s16
	Gui, Add, ListBox, r%filenum% section w400 vPatFile gPatFileGet,%filelist%
	Gui, Font, s12
	Gui, Add, Button, wP Disabled vplMRNbut gChipInfo, No MRN found
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
	Gui, Show, w800 AutoSize, % "Patient: " PatName

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
	Loop, % filepath "\*" , 1
	{
		tmpNm := A_LoopFileName
		tmpExt := A_LoopFileExt
		StringReplace , tmpNm, tmpNm, .%tmpExt%
		WinClose, %tmpNm%
	}
	Gui, PatL:Destroy
	gosub MainGUI
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