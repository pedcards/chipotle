/*	QUESO - QUEry for System Operations
	formerly CHipotle Admin Interface (CHAI)
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
SetTitleMatchMode, 2
#Include includes

z := new XML("currlist.xml")
za := new XML("archlist.xml")
l_users := Object()

Gosub MainGUI

Exit

MainGUI:
{
	Gui, main:Destroy
	Gui, main:Font, s16 wBold
	Gui, main:Add, Text, y0 w150 h20 +Center, -= QUESO =-
	Gui, main:Font, wNorm s8 wItalic
	Gui, main:Add, Text, yp+30 w150 +Center, QUEry tool and`nSystem Operations
	;Gui, main:Add, Text, xp yp+14 wp hp +Center, System Operations
	Gui, main:Font, wNorm
	Gui, main:Add, Button, w150 gStatsGUI, Statistics
	Gui, main:Add, Button, wp gViewLog, View logs
	Gui, main:Add, Button, wp gUnlock, Release lock
	Gui, main:Add, Button, wp gQuery, Query archive
	Gui, main:Add, Button, wp gCleanArch, Clean archive
	Gui, main:Add, Button, wp gEnvInfo, Env Info
	Gui, main:Add, Button, wp gActiveWindow, ActiveWindowInfo
	Gui, main:Show, AutoSize, QUESO Admin
Return
}

mainGuiClose:
ExitApp

ActiveWindow:
	run, ActiveWindow.exe
return

EnvInfo:
	run, AHKenvinfo.exe
return

StatsGUI:
{
/*	Show some basic database and log stats.
	Currlist
		* Total MRN records
		* Current MRN in each team list
		* Most recent edit
	Archlist
		* Total MRN records
		* Records with empty Dx and Prov elements
	Logs
		* Most logged in
		* Most edits
	Census

*/
	;Gui, main:hide
	Loop, % (totrecs := z.selectNodes("/root/id")).length
	{
		k := totrecs.item((i:=A_Index)-1)
		t_mrn := k.getAttribute("mrn")
		t_dx := k.selectSingleNode("diagnoses").getAttribute("ed")
		t_prov := k.selectSingleNode("prov").getAttribute("ed")
		EnvSub, t_dx, %A_Now%
		EnvSub, t_prov, %A_Now%
		
		t_summ1 := 
		Loop, % (t_notes := k.selectSingleNode("notes/weekly").selectNodes("summary")).length
		{
			k1 := t_notes.item(A_Index-1)
			t_summ := k1.getAttribute("ed")
			if (t_summ > t_summ1)
				t_summ1 := t_summ
		}
		EnvSub, t_summ1, %A_Now%
		
		t_todo1 :=
		Loop, % (t_plan := k.selectSingleNode("plan/tasks").selectNodes("todo")).length
		{
			k2 := t_plan.item(A_Index-1)
			t_todo := k2.getAttribute("ed")
			if (t_todo > t_todo1)
				t_todo1 := t_todo
		}
		EnvSub, t_todo1, %A_Now%
		t_arr := [t_dx, t_prov, t_summ1, t_todo1]
		t_most :=
		for each, x in t_arr
			t_most := (t_most < x) ? x : t_most
		if (t_most > t_most1) {
			t_most1 := t_most
			t_most0 := i-1
		}
	}
	t_max := totrecs.item(t_most0)
	t_mrn := t_max.getAttribute("mrn")
	t_nam := t_max.selectSingleNode("demog/name_last").text . ", " . t_max.selectSingleNode("demog/name_first").text
	j := 0
	l_edits := 0
	Loop, % (totarch := za.selectNodes("/root/id")).length
	{
		k := totarch.item((i:=A_index)-1)
		ta_mrn := k.getAttribute("mrn")
		ta_name := k.selectSingleNode("demog/name_last").text ", " k.selectSingleNode("demog/name_first").text
		ta_dx := k.selectSingleNode("diagnoses").text
		ta_prov := k.selectSingleNode("prov").getAttribute("provCard")
		ta_notes := k.selectSingleNode("notes").text
		ta_plan := k.selectSingleNode("plan").text
		if (!ta_dx and !ta_prov and !ta_notes and !ta_plan) {
			j ++
		}
	}
	FormatTime, sessdate, A_Now, yyyyMM
	;sessdate := "201501"
	FileRead, tlog, % "logs/" sessdate ".log"
	Loop, parse, tlog, `n,`r
	{
		i := A_LoopField
		l_user := StrX(i,"[",1,1,"/",1,1)
		if !(ObjHasValue(l_users,l_user)) {
			l_users.insert(l_user)
			l_numusers ++
		}
		if i ~= "changed.$"
			l_edits ++
	}
	
	FormatTime, coresdate, % z.selectSingleNode("/root/lists/cores").getAttribute("date"), ddd MM/dd @ HH:mm
	FileGetSize, currsize, currlist.xml
	FileGetSize, archsize, archlist.xml
	MsgBox,,Statistics 
		, % "Currlist size: " currsize
		. "`nArchlist size: " archsize
		. "`nCORES data: " coresdate
		. "`nActive MRN records:`t" totrecs.length
		. "`nTotal Arch records:`t" totarch.length
		. "`nEmpty Arch records:`t" j
		. "`nUsers this month:`t" l_users.MaxIndex()-1
		. "`nEdits this month:`t" l_edits
		. "`nLast edited record:`t" t_nam " (" t_mrn ")"
Return
}

ViewLog:
{
	FormatTime, sessdate, A_Now, yyyyMM
	FileRead, tlog, % "logs/" sessdate ".log"
	l_users := {}
	l_numusers :=
	l_tabs :=
	Progress,h80,,Scanning users
	Loop, parse, tlog, `n,`r
	{
		i := A_LoopField
		l_date := StrX(i,"",1,0,"[",1,1)
		l_user := StrX(i,"[",1,1,"/",1,1)
		l_log := StrX(i,"]",1,1,"",0,0)
		if !(ObjHasValue(l_users,l_user)) {
			l_users.insert(l_user)
			l_users[l_user] := []
			l_tabs .= l_user . "|"
		} 
		l_users[l_user].insert(i)
	}
	l_max := l_users.MaxIndex()
	gui, VL:Destroy
	gui, VL:add, Tab2, w800 -Wrap vLogLV hwndLogH, % l_tabs
	for k,v in l_users
	{
		tmpHwnd := "Hwnd" . k
		gui, VL:Tab, % v
		gui, VL:add, ListView, % "-Multi Grid NoSortHdr x10 y30 w800 h400 vUsr" k " hwndtmpHwnd" k, Date|Time|Entry
		gui, VL:default
		Progress, % 100*k/l_max,, % v
		for kk,vv in l_users[v]
		{
			l_dt := StrX(vv,"",1,0,"[",1,1)
			l_time := substr(l_dt,12)
			l_date := substr(l_dt,1,10)
			l_log := StrX(vv,"]",1,1,"",0,0)
			gui, VL:ListView, % v
			LV_Add(""
				, l_date
				, l_time
				, l_log)
			Progress,, % l_date
		}
		LV_ModifyCol()
		LV_ModifyCol(1, "Autohdr")
		LV_ModifyCol(2, "Autohdr")
		LV_ModifyCol(3, "Autohdr")
	}
	Progress, off
	gui, VL:show, AutoSize
Return
}

Unlock:
{
	If FileExist(".currlock") {
		FileGetTime, x, .currlock
		EnvSub, x, A_Now, s
		y := -x/60
		z := substr("0" . round(60*(y+ceil(x/60))), -1)
		MsgBox,52,Unlock, % "Lock file is " floor(y) ":" z " minutes old.`n`nDelete file?"
		IfMsgBox, Yes
		{
			FileDelete, .currlock
		}
	} else {
		MsgBox,48,Unlock, No lock file exists!
	}
	Return
}

Query:
{
	Gui, main:Hide
	;~ InputBox, q, Search..., Search for "Ruggerie"
	q := "rugge"
	Loop, % (totarch := z.selectNodes("/root/id/prov")).length
	{
		k := totarch.item(A_index-1)
		pc := k.getAttribute("provCard")
		if (pc~="i)" . q ) {
			MsgBox % pc
		}
	}
	Gui, main:Show
	return
}

CleanArch:
{
	
	j := 0
	l_edits := 0
	Loop, % (totarch := za.selectNodes("/root/id")).length
	{
		k := totarch.item((i:=A_index)-1)
		ta_mrn := k.getAttribute("mrn")
		ta_name := k.selectSingleNode("demog/name_last").text ", " k.selectSingleNode("demog/name_first").text
		ta_dx := k.selectSingleNode("diagnoses").text									; Dx fields
		ta_prov := k.selectSingleNode("prov").getAttribute("provCard")					; Provider attr
		ta_notes := k.selectSingleNode("notes").text									; Current summary notes
		ta_plan := k.selectSingleNode("plan").text										; Current todo items
		ta_arc := k.selectSingleNode("archive")										; Archived dc/plan and dc/notes
		if (!ta_dx and !ta_prov and !ta_notes and !ta_plan and !ta_arc.text) {
			j ++
			RemoveNode("/root/id[@mrn='" ta_mrn "']", za)
		} else {
			loop, % (archRecs := ta_arc.selectNodes("*")).length
			{
				kk := archRecs.item((ii:=A_Index)-1)
				if (!kk.text) {
					q := kk
					q.parentNode.removeChild(q)
				}
			}
			Loop, % (archDx := k.selectNodes("diagnoses/*[not(text())]")).length
			{
				kk := archDx.item((ii:=A_Index)-1)
				q := kk
				q.parentNode.removeChild(q)
			}
		}
	}
	MsgBox % j " records removed."
	za.save("archlist.xml")
	Return
}

ObjHasValue(aObj, aValue) {
; From http://www.autohotkey.com/board/topic/84006-ahk-l-containshasvalue-method/	
    for key, val in aObj
        if(val = aValue)
            return, true, ErrorLevel := 0
    return, false, errorlevel := 1
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

RemoveNode(node,ByRef y) {
	q := y.selectSingleNode(node)
	q.parentNode.removeChild(q)
}

#Include xml.ahk
#Include StrX.ahk
#Include Class_LV_Colors.ahk
