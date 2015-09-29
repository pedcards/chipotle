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
if (InStr(A_WorkingDir,"AutoHotkey")) {
	confdir := "files\Tuesday Conference"
} else {
	confdir := "\\chmc16\Cardio\Conference\Tuesday Conference"
}

;conf := Object()
;mo := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

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
	dt := GetConfDate()
	confdate := dt.YYYY "\" dt.MMM "\" dt.DD
	Gui, main:Default
	Gui, Destroy
	Gui, Font, s16 wBold
	Gui, Add, Text, y0 w250 h20 +Center, .-= GUACAMOLE =-.
	Gui, Font, wNorm s8 wItalic
	Gui, Add, Text, yp+30 wp +Center, General Use Access tool for Conference Archive
	Gui, Add, Text, xp yp+14 wp hp +Center, Merged OnLine Encounters
	Gui, Font, wNorm
	Gui, Add, Button, wp gGetConfDir, % confdate
	Gui, Add, Button, wp, Date browser
	Gui, Add, Button, wp, Search archive
	Gui, Show, AutoSize, GUACAMOLE Main
Return
}

mainGuiClose:
ExitApp

GetConfDir:
{
	dt := GetConfDate()
	filelist =
	confdate := dt.YYYY "\" dt.MMM "\" dt.DD
	Loop, %confdir%\%confdate%\* , 2	
	{
		filelist .= A_LoopFileName "|"
	}
	Gui, ConfL:Default
	Gui, Destroy
	Gui, Font, s16
	Gui, Add, ListBox, vPatName gPatData, %filelist%
	Gui, Show, AutoSize, % "Conference " dt.MM "/" dt.DD "/" dt.YYYY
	Return
}

PatData:
{
	if !(A_GuiEvent = "DoubleClick")
		return
	Gui, ConfL:Submit
;	Gui, ConfL:Hide
	filelist =
	filenum =
	Loop, %confdir%\%confdate%\%patname%\*, 1
	{
		filelist .= (A_LoopFileName) ? A_LoopFileName "|" : ""
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
	Gui, Show, AutoSize, % "Patient " PatName
	return
}

PatFileGet:
{
	Gui, PatL:Submit
Return
}

GetConfDate(dt:="") {
/*	Get next conference date. If not argument, assume today
*/
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

breakDate(x) {
; Disassembles 201502150831 into Yr=2015 Mo=02 Da=15 Hr=08 Min=31 Sec=00
	D_Yr := substr(x,1,4)
	D_Mo := substr(x,5,2)
	D_Da := substr(x,7,2)
	D_Hr := substr(x,9,2)
	D_Min := substr(x,11,2)
	D_Sec := substr(x,13,2)
	FormatTime, D_day, x, ddd
	FormatTime, D_Mon, x, MMM
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

#Include xml.ahk
#Include StrX.ahk
#Include Class_LV_Colors.ahk
#Include sift3.ahk
#Include CMsgBox.ahk