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
	confdir := "files/Tuesday Conference"
}

mo := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
FormatTime, currdate, A_Now, yyyy``MM``MMM``MMMM``dd``dddd
StringSplit, currdate, currdate, ``

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
	Gui, main:Destroy
	Gui, main:Font, s16 wBold
	Gui, main:Add, Text, y0 w250 h20 +Center, .-= GUACAMOLE =-.
	Gui, main:Font, wNorm s8 wItalic
	Gui, main:Add, Text, yp+30 wp +Center, General Use Access tool for Conference
	Gui, main:Add, Text, xp yp+14 wp hp +Center, System Operations
	Gui, main:Font, wNorm
;	Gui, main:Add, Button, w150 gStatsGUI, Statistics
;	Gui, main:Add, Button, wp gViewLog, View logs
;	Gui, main:Add, Button, wp gUnlock, Release lock
	Gui, main:Add, Button, wp, % currdate1 " " currdate2
	Gui, main:Add, Button, wp, % isAdmin
;	Gui, main:Add, Button, wp gEnvInfo, Env Info
;	Gui, main:Add, Button, wp gActiveWindow, ActiveWindowInfo
	Gui, main:Show, AutoSize, GUACAMOLE Main
Return
}

mainGuiClose:
ExitApp






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