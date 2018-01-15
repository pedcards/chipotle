/*	QUESO - QUEry for System Operations
	formerly CHipotle Admin Interface (CHAI)
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
SetTitleMatchMode, 2
#Include includes
user := A_UserName
FormatTime, sessdate, A_Now, yyyyMM

eventlog("Started QUESO.")
z := new XML("currlist.xml")
za := new XML("archlist.xml")
l_users := Object()

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
	;~ Gui, main:Add, Button, wp gBlankDX, Find Dx Blanks
	Gui, main:Add, Button, wp gDxRestore, Restore Dx
	;~ Gui, main:Add, Button, wp gRegionalCensus, Regional Census
	Gui, main:Add, Button, wp gEnvInfo, Env Info
	Gui, main:Add, Button, wp gActiveWindow, ActiveWindowInfo
	Gui, main:Show, AutoSize, QUESO Admin
Return
}

mainGuiClose:
{
	eventlog("Exit QUESO.")
	ExitApp
}

ActiveWindow:
	eventlog("Show active window info.")
	run, ActiveWindow.exe
return

EnvInfo:
	eventlog("Show envt info.")
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
	
	eventlog("[Stats] Edits this month: " l_edits)
	eventlog("[Stats] Users this month: " l_users.MaxIndex()-1)
	eventlog("[Stats] Empty Arch records: " j)
	eventlog("[Stats] Total Arch records: " totarch.length)
	eventlog("[Stats] Active MRN records: " totrecs.length)
	eventlog("[Stats] CORES data: " coresdate)
	eventlog("[Stats] Archlist size: " archsize)
	eventlog("[Stats] Currlist size: " currsize)
Return
}

ViewLog:
{
	eventlog("Log viewer.")
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
			LV_ModifyCol()
			LV_ModifyCol(1, "Autohdr")
			LV_ModifyCol(2, "Autohdr")
			LV_ModifyCol(3, "Autohdr")
		}
	}
	Progress, off
	gui, VL:show, AutoSize
Return
}

Unlock:
{
	eventlog("Release .currlock")
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
	eventlog("Query button")
	Gui, main:Hide
	InputBox, q, Search..., Enter provider search string
	eventlog("Search term: '" q "'.")
	;~ q := "rugge"
	qres := 
	
	Loop, % (totarch := za.selectNodes("/root/id/prov")).length
	{
		k := totarch.item(A_index-1)
		pc := k.getAttribute("provCard")
		if (pc~="i)" . q ) {
			id := k.parentNode
			mrn := id.getAttribute("mrn")
			ed_pc := k.getAttribute("ed")
			ed_dx := id.selectSingleNode("diagnoses").getAttribute("ed")
			eddt := (ed_pc > ed_dx) ? ed_pc : ed_dx
			qres .= mrn ", " eddt "`r`n"
		}
	}
	if (qres) {
		eventlog(RegExReplace(qres,"`r`n"," || "))
		qres .= "`r`nResults copied to CLIPBOARD, can be pasted into another program."
		Clipboard := qres
		MsgBox % qres
	}
	Gui, main:Show
	return
}

CleanArch:
{
	eventlog("Clean archives.")
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
	eventlog(j " records removed from arch.")
	MsgBox % j " records removed."
	za.save("archlist.xml")
	Return
}

RegionalCensus:
{
	loc := ["Cards","CSR","TXP"]
	Loop, Files, logs\*.xml																; Loop through each census.xml file
	{
		fname := A_LoopFileFullPath
		FileGetTime, fdate_m, %fname%, M												; Get modified
		FileGetTime, fdate_c, %fname%, C												; and created dates
		cens := new XML(fname)
		loop, % (c0 := cens.selectNodes("/root/census")).Length							; Loop through each <census day> node
		{
			cNode := c0.item(A_index-1)
			cDay := cNode.getAttribute("day")
			
			c_CRD := cNode.selectSingleNode("Cards")									; Check for presence of census data
			c_CSR := cNode.selectSingleNode("CSR")
			c_TXP := cNode.selectSingleNode("TXP")
			if !(IsObject(c_CRD) && IsObject(c_CSR)) {									; Must have at least CRD and CSR
				continue																; otherwise skip this node
			}
			progress, , % cDay, % fname
			c1 := "/root/census[@day='" cDay "']"
			if !IsObject(cNode.selectSingleNode("regional")) {
				cens.addElement("regional",c1)
			}
				
			for key,list in loc {														; Run through each list
				clTot := (cList := cNode.selectNodes(list "/mrn")).length 
				loop, % clTot {															; Gather MRN elements
					progress, % 100*A_index/clTot
					MRN := cList.item(A_Index-1).text									; Get MRN
					MRNstring := "/root/id[@mrn='" MRN "']"
					clProv := za.selectSingleNode(MRNstring "/prov").getAttribute("provCard")
					tmpTG := tmpCrd := ""
					
					tmpCrd := checkCrd(clProv)											; tmpCrd gets provCard (spell checked)
					plFuzz := 100*tmpCrd.fuzz											; fuzz score for tmpCrd
					if (clProv="") {													; no cardiologist
						tmpCrd.group := "Other"											; group is "Other"
					} else if (clProv~="i)Central WA|Schmer|Sallaam|Salaam|Toews") {
						tmpCrd.group := "Central WA"
					} else if (clProv~="SCH|Transplant|Heart Failure|Tx|SV team") {		; unclaimed Tx and Cards patients
						tmpCrd.group := "SCH"											; place in SCH group
					} else if (plFuzz < 20) {											; Close match found (< 0.20)
						clProv := tmpCrd.best											; take the close match
					} else {															; Screw it, no good match (> 0.20)
						tmpCrd.group := "Other"
					}
					
					tmpCrd.group := RegExReplace(tmpCrd.group," ","_")
					c2 := c1 "/regional/" tmpCrd.group
					if !IsObject(cens.selectSingleNode(c2)) {							; Make sure <day/regional/group> exists
						cens.addElement(tmpCrd.group,c1 "/regional")
					}
					
					if !IsObject(cens.selectSingleNode(c2 "/mrn[text()='" MRN "']")) {		; Add unique MRN[@crd] to regional group
						cens.addElement("mrn",c2, MRN)
						cens.selectSingleNode(c2 "/mrn[text()='" MRN "']").setAttribute("crd",clProv)
					}
				}
			}
			Loop, % (rlist := cens.selectNodes(c1 "/regional/*")).length {				; Loop through each regional group node
				rnode := rlist.item(A_index-1)
				rnode.setAttribute("tot",rnode.selectNodes("mrn").length)				; Set attr "tot"
			}
		}
		cens.save(fname)
		FileSetTime, fDate_m, %fname%, M
	}
	progress, off
Return	
}

regionalCensus(location) {
/*	Generate counts for regional cardiologists in census XML
*/
	global y, cens, c1, censdate
	tmpTG := tmpCrd := ""
	cGrps := {}
	if !IsObject(cens.selectSingleNode(c1 "/regional")) {
		cens.addElement("regional", c1)
	}
	
	Loop, % (plist := y.selectNodes("/root/lists/" . location . "/mrn")).length {		; loop through location MRN's into plist
		kMRN := plist.item(i:=A_Index-1).text											; text item in lists/location/mrn
		;~ pl := ptParse(kMRN)																; fill pl with ptParse
		clProv := pl.provCard															; get CRD provider into clProv
		tmpCrd := checkCrd(clProv)														; tmpCrd gets provCard (spell checked)
		plFuzz := 100*tmpCrd.fuzz														; fuzz score for tmpCrd
		if (clProv="") {																; no cardiologist
			tmpCrd.group := "Other"														; group is "Other"
		} else if (clProv~="SCH|Transplant|Heart Failure|Tx|SV team") {					; unclaimed Tx and Cards patients
			tmpCrd.group := "SCH"														; place in SCH group
		} else if (plFuzz < 20) {														; Close match found (< 0.20)
			clProv := tmpCrd.best														; take the close match
		} else {																		; Screw it, no good match (> 0.20)
			tmpCrd.group := "Other"
		}
		
		tmpCrd.group := RegExReplace(tmpCrd.group," ","_")
		c2 := c1 "/regional/" tmpCrd.group
		if !IsObject(cens.selectSingleNode(c2)) {										; Make sure <day/regional/group> exists
			cens.addElement(tmpCrd.group,c1 "/regional")
		}
		
		if !IsObject(cens.selectSingleNode(c2 "/mrn[text()='" kMRN "']")) {				; Add unique MRN[@crd] to regional group
			cens.addElement("mrn",c2, kMRN)
			cens.selectSingleNode(c2 "/mrn[text()='" kMRN "']").setAttribute("crd",clProv)
		}
		;~ cens.viewXML()
	}
	
	Loop, % (rlist := cens.selectNodes(c1 "/regional/*")).length {						; Loop through each regional group node
		rnode := rlist.item(A_index-1)
		rnode.setAttribute("tot",rnode.selectNodes("mrn").length)						; Set attr "tot"
	}
	
	Return
}

checkCrd(x) {
/*	Compares pl_ProvCard vs array of cardiologists
	x = name
	returns array[match score, best match, best match group]
*/
	global Docs
	fuzz := 1
	for rowidx,row in Docs
	{
		for colidx,item in row
		{
			res := fuzzysearch(x,item)
			if (res<fuzz) {
				fuzz := res
				best:=item
				group:=rowidx
			}
		}
	}
	return {"fuzz":fuzz,"best":best,"group":group}
}

BlankDx: 
{
/*	Scan through arch records for empty dx
	Ignore records with no dx [@ed] attr (never had a dx)
*/
	rep := new XML("<root/>")
	reptxt :=  ""
	numnodes := (nodes := za.selectNodes("/root/id")).length
	loop, % numnodes
	{
		idx := A_index
		node := nodes.item(idx-1)
		mrn := node.getattribute("mrn")
		name := node.selectSingleNode("demog")
			name_L := name.selectSingleNode("name_last").text
			name_F := name.selectSingleNode("name_first").text
		dx := node.selectSingleNode("diagnoses")
			dxEd := dx.getAttribute("ed")
			dxAu := dx.getAttribute("au")
		dx_text := dx.text
			;~ dx_notes := dx.selectSingleNode("notes").text
			;~ dx_card := dx.selectSingleNode("card").text
			;~ dx_ep := dx.selectSingleNode("ep").text
			;~ dx_surg := dx.selectSingleNode("surg").text
			;~ dx_prob := dx.selectSingleNode("prob").text
			;~ dx_misc := dx.selectSingleNode("misc").text
		Progress, % 100*(idx/numnodes)
		if ((dxEd) && !(dx_text)) {
			clone := node.cloneNode(true)
			rep.selectSingleNode("/root").appendChild(clone)
			reptxt .= substr(dxEd,5,2) "/" substr(dxEd,7,2) "/" substr(dxEd,1,4) "`n"
		}
	}
	progress, ,, Saving...
	rep.save("blanks.xml")
	FileDelete, blanks.txt
	FileAppend, % reptxt, blanks.txt
	progress, off
	
	return
}

DxRestore:
{
	loop, files, archback/*
	{
		dirlist .= A_LoopFileName "`n"
	}
	Sort, dirlist, R
	
	InputBox, mrn, Search records, Enter MRN to search,,, 150
	node := za.selectSingleNode("/root/id[@mrn='" mrn "']")
	pt := ptParse(mrn,za)
	
	loop, % (nodes := node.selectNodes("archive/dc")).length
	{
		enc := nodes.item(A_index-1)
		dc := enc.getAttribute("date")
		;~ MsgBox % dc
	}
	loop, parse, dirlist, `n
	{
		fl := A_LoopField
		if (fl="") {
			break
		}
		progress, ,, % fl
		ta := new XML("archback/" fl)
		tnode := ta.selectSingleNode("/root/id[@mrn='" mrn "']")
		t_dx := tnode.selectSingleNode("diagnoses")
		t_dx_ed := t_dx.getAttribute("ed")
		if !(t_dx.text) {
			continue
		}
		t_dx_notes := t_dx.selectSingleNode("notes").text
		t_dx_card := t_dx.selectSingleNode("card").text
		t_dx_ep := t_dx.selectSingleNode("ep").text
		t_dx_surg := t_dx.selectSingleNode("surg").text
		t_dx_prob := t_dx.selectSingleNode("prob").text
		t_dx_misc := t_dx.selectSingleNode("misc").text
		
		progress, hide
		MsgBox,, % t_dx_ed, % t_dx.text
	}
	progress, hide
	MsgBox % pt.NameL
	return
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

eventlog(event) {
	global user, sessdate
	comp := A_ComputerName
	FormatTime, now, A_Now, yyyy.MM.dd||HH:mm:ss
	name := "logs/" . sessdate . ".log"
	txt := now " [" user "/" comp "] " event "`n"
	filePrepend(txt,name)
;	FileAppend, % timenow " ["  user "/" comp "] " event "`n", % "logs/" . sessdate . ".log"
}

FilePrepend( Text, Filename ) { 
/*	from haichen http://www.autohotkey.com/board/topic/80342-fileprependa-insert-text-at-begin-of-file-ansi-text/?p=510640
*/
    file:= FileOpen(Filename, "rw")
    text .= File.Read()
    file.pos:=0
    File.Write(text)
    File.Close()
}

#Include xml.ahk
#Include StrX.ahk
#Include Class_LV_Colors.ahk
#Include sift3.ahk
