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
	;~ Gui, main:Add, Button, wp gCleanArch, Clean archive
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
	za := new XML("archlist.xml")
	
	;~ which := cmsgbox("FIND BLANK DX","Scan for which`ntype of blanks?","Any blank dx|Prev ed","Q")
	;~ which := instr(which,"Any") ? "mrn":"dxEd"
	which := "mrn"
	
	rep := new XML("<root/>")
	reptxt :=  ""
	repct := 0
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
		
		Progress, % 100*(idx/numnodes)
		
		if (dx_text) {																	; Skip if DX exists
			continue
		}
		if (%which%) {																	; ANY:(mrn) (always true), PREV:(dxEd) (only true if dxEd exists)
			clone := node.cloneNode(true)
			rep.selectSingleNode("/root").appendChild(clone)
			reptxt .= mrn "`n"
			repct ++
		}
	}
	progress, ,, Saving...
	rep.save("blanks.xml")
	FileDelete, blanks.txt
	FileAppend, % reptxt, blanks.txt
	progress, off
	MsgBox % "Found " repct " records"
	eventlog("Found " repct " blank records")
	
	return
}

DxRestore:
{
	za := new XML("archlist.xml")														; get fresh copy of archlist into ZA
	
	which := cmsgbox("RESTORE DIAGNOSES","","Enter MRN|Scan all blanks","Q")
	If instr(which,"MRN") {
		InputBox, bl, Search records, Enter MRN to search,,, 150 						; set BL as a single MRN
	} if instr(which,"Scan") {
		gosub BlankDx
		FileRead, bl, blanks.txt														; read blanks.txt into BL
	} if instr(which,"Close") {
		return
	}
	
	line := "`n====================`n"
	
	loop, files, archback/*																; read and reverse sort archback/* filenames
	{
		dirlist .= A_LoopFileName "`n"
	}
	Sort, dirlist, R
	
	loop, parse, bl, `n, `r
	{
		idx1 := A_Index
		mrn := A_LoopField
		znode := za.selectSingleNode("/root/id[@mrn='" mrn "']")						; ZNODE = <id[@mrn]>
		if !IsObject(znode) {
			continue																	; doesn't exist? move along
		}
		zdx := []
		zdx.dx := znode.selectSingleNode("diagnoses")									; get <diagnoses>
		zdx.ed := zdx.dx.getAttribute("ed")												; get <diagnoses[@ed]>
		
		z_pt := ptParse(mrn,za)															; get values for MRN in ZA
		progress, show
		progress, ,, % z_pt.NameL
		
		zdx.notes := 	z_pt.dxNotes													; LIVE ARCHLIST: get each <diagnosis> text values
		zdx.card := 	z_pt.dxCard
		zdx.ep :=  		z_pt.dxEP
		zdx.surg := 	z_pt.dxSurg
		zdx.prob := 	z_pt.dxProb
		zdx.misc := 	z_pt.misc
		zdx.out := "===NOTES===" zdx.notes . "`n"
			. "===CARD===" zdx.card . "`n"
			. "===EP===" zdx.ep . "`n"
			. "===SURG===" zdx.surg . "`n"
			. "===PROB===" zdx.prob . "`n"
			. "===MISC===" zdx.misc . "`n"
		
		nomatch := true
		loop, parse, dirlist, `n														; scan through dirlist filenames
		{
			fl := A_LoopField
			if (fl="") {
				break																	; reach end of list, break out
			}
			progress, show
			progress , % 100*A_index/65 ,,% fl, % idx1 ") " z_pt.NameL " (ed=" zdx.ed ")"
			
			tdx := []
			ta := new XML("archback/" fl)												; TA = next archback xml (Temp Arch)
			tnode := ta.selectSingleNode("/root/id[@mrn='" mrn "']")					; TNODE = <id[@mrn]>
			tdx.dx := tnode.selectSingleNode("diagnoses")
			tdx.ed := tdx.dx.getAttribute("ed")
			tdx.au := tdx.dx.getAttribute("au")
			if !(tdx.dx.text) {
				continue																; <diagnosis> in TA empty, move on
			}
			eventlog(mrn " Found DX in " fl)
			nomatch := false															; ELSE we have found at least one match 
			
			t_pt := ptParse(mrn,ta)
			tdx.notes := 	t_pt.dxNotes												; TEMP: get each <diagnosis> text values
			tdx.card := 	t_pt.dxCard
			tdx.ep :=  		t_pt.dxEP
			tdx.surg := 	t_pt.dxSurg
			tdx.prob := 	t_pt.dxProb
			tdx.misc := 	t_pt.misc
			tdx.out := ((tdx.notes)?"===NOTES===" tdx.notes "`n":"")
				. ((tdx.card)?"===CARD===" tdx.card "`n":"")
				. ((tdx.ep)?"===EP===" tdx.ep "`n":"")
				. ((tdx.surg)?"===SURG===" tdx.surg "`n":"")
				. ((tdx.prob)?"===PROB===" tdx.prob "`n":"")
				. ((tdx.misc)?"===MISC===" tdx.misc "`n":"")
			
			ydx := []
			y := new XML("currlist.xml")												; refresh currlist
			ynode := y.selectSingleNode("/root/id[@mrn='" mrn "']")						; YNODE = <id[@mrn]>
			ydx.dx := ynode.selectSingleNode("diagnoses")
			if (ydx.dx.text) {															; there is actually a DX in currlist
				eventlog(mrn " DX exists in currlist")
				ydx.ed := y_dx.getAttribute("ed")
				ydx.au := y_dx.getAttribute("au")
				y_pt := ptParse(mrn,y)
				ydx.notes := 	y_pt.dxNotes											; TEMP: get each <diagnosis> text values
				ydx.card := 	y_pt.dxCard
				ydx.ep :=  		y_pt.dxEP
				ydx.surg := 	y_pt.dxSurg
				ydx.prob := 	y_pt.dxProb
				ydx.misc := 	y_pt.misc
				ydx.out := ((ydx.notes)?"===NOTES===" ydx.notes "`n":"")
					. ((ydx.card)?"===CARD===" ydx.card "`n":"")
					. ((ydx.ep)?"===EP===" ydx.ep "`n":"")
					. ((ydx.surg)?"===SURG===" ydx.surg "`n":"")
					. ((ydx.prob)?"===PROB===" ydx.prob "`n":"")
					. ((ydx.misc)?"===MISC===" ydx.misc "`n":"")
			}
			progress, hide
			which := cmsgbox(idx1 ") " z_pt.NameL ", " z_pt.NameF " (BACK=" fl ")"
				, ((ydx.dx.text)
					? ydx.out . line
					: "")
				;~ . "ARCH (ed=" zdx.ed ")`n" zdx.out . line
				. tdx.out
				, ((ydx.dx.text) ? "Replace currlist|":"") . "Replace archlist|Skip this backup|Next patient"
				,"Q")
			if instr(which,"Next") {
				eventlog("Chose NEXT PATIENT")
				break																	; BREAK to next MRN
			}
			if instr(which,"Skip") {
				eventlog("Chose to SKIP this backup")
				continue																; CONTINUE to next archback list
			}
			
			; ELSE we are replacing something
			if instr(which,"archlist") {
				zdx.lst := "za"
			} else if instr(which,"currlist") {
				zdx.lst := "y"
			} else {
				continue
			}
			
			filecheck()
			FileOpen(".currlock", "W")													; Create lock file
			
			changeDx(mrn,"notes", tdx.notes, za)
			changeDx(mrn,"card", tdx.card, za)
			changeDx(mrn,"ep", tdx.ep, za)
			changeDx(mrn,"surg", tdx.surg, za)
			changeDx(mrn,"prob", tdx.prob, za)
			changeDx(mrn,"misc", tdx.misc, za)
			za.setAtt("/root/id[@mrn='" mrn "']/diagnoses", {ed:tdx.ed , au:tdx.au})
			za.save("archlist.xml")														; writeout archlist
			eventlog(mrn " DX (" tdx.ed ") replaced in archlist")
			
			if (zdx.lst="y") {
				changeDx(mrn,"notes", tdx.notes, y)
				changeDx(mrn,"card", tdx.card, y)
				changeDx(mrn,"ep", tdx.ep, y)
				changeDx(mrn,"surg", tdx.surg, y)
				changeDx(mrn,"prob", tdx.prob, y)
				changeDx(mrn,"misc", tdx.misc, y)
				y.setAtt("/root/id[@mrn='" mrn "']/diagnoses", {ed:tdx.ed , au:tdx.au})
				y.save("currlist.xml")													; if in currlist, also update that
				eventlog(mrn " DX (" tdx.ed ") replaced in currlist")
			}
			
			FileDelete, .currlock
			break																		; replacing DONE, move on to next MRN
		}
		
		if (nomatch) {																	; no DX in any archback loop, 
			changeDx(mrn,"misc","this line left intentionally blank",za)					; leave marker to prevent matching this again
			za.save("archlist.xml")
			eventlog(mrn ": Left un-blank marker.")
		}
	}
	progress, hide
	MsgBox DONE!
	return
}

ChangeDx(mrn,el,val,ByRef xml) {
	if !IsObject(xml.selectSingleNode("/root/id[@mrn='" mrn "']/diagnoses/" el)) {
		xml.addElement(el, "/root/id[@mrn='" mrn "']/diagnoses", val)
	} else {
		xml.setText("/root/id[@mrn='" mrn "']/diagnoses/" el, val)
	}
	return
}

CloneDx(mrn,ByRef dest) {
/*	Copy an entire <diagnosis> node from ta XML to the dest archlist
*/
	global ta
	
	x := ta.selectSingleNode("/root/id[@mrn='" mrn "']/diagnoses")
	
	y := dest.selectSingleNode("/root/id[@mrn='" mrn "']/diagnoses")
	y.parentNode.replaceChild(x,y)
	
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

filecheck() {
	if FileExist(".currlock") {
		err=0
		Progress, , Waiting to clear lock, File write queued...
		loop 50 {
			if (FileExist(".currlock")) {
				progress, %p%
				Sleep 100
				p += 2
			} else {
				err=1
				break
			}
		}
		if !(err) {
			progress off
			return error
		}
	} 
	progress off
	return
}

#Include xml.ahk
#Include StrX.ahk
#Include Class_LV_Colors.ahk
#Include sift3.ahk
#Include CMsgBox.ahk
