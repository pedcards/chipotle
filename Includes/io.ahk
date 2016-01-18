GetIt:
{
	; ==================
	;FileDelete, .currlock
	; ==================
	filecheck()
	FileOpen(".currlock", "W")													; Create lock file.
	if !(vSaveIt=true)
		Progress, b w300, Reading data..., % "- = C H I P O T L E = -`nversion " vers
	else
		Progress, b w300, Consolidating data..., 
	Progress, 20
	
	if (isLocal) {
		FileCopy, currlist.xml, templist.xml
	} else {
		Run pscp.exe -sftp -i chipotle-pr.ppk -p pedcards@homer.u.washington.edu:public_html/%servfold%/currlist.xml templist.xml,, Min
		sleep 500
		ConsWin := WinExist("ahk_class ConsoleWindowClass")
		IfWinExist ahk_id %consWin% 
		{
			ControlSend,, {y}{Enter}, ahk_id %consWin%
			;Progress,, Console %consWin% found
			Progress,, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
		}
		WinWaitClose ahk_id %consWin%
	}
	Progress, 60, % dialogVals[Rand(dialogVals.MaxIndex())] "..."

	FileRead, templist, templist.xml					; the downloaded list.
		StringReplace, templist, templist, `r`n,, All	; AHK XML cannot handle the UNIX format when modified on server.
		StringReplace, templist, templist, `n,, All	
	z := new XML(templist)								; convert templist into XML object Z
	Progress,, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
	

	if !(FileExist("currlist.xml")) {
		z.save("currlist.xml")
	}
	FileDelete, oldlist.xml
	FileCopy, currlist.xml, oldlist.xml										; Backup currlist to oldlist.
	x := new XML("currlist.xml")											; Load currlist into working X.
	
;	 Get last dates
/*	 Cycle through lists
	 	Server lists are always old data. Currlist can be newer than the server.
		Copy Citrix copy for latest.
*/
	Loop, % (zList := z.selectNodes("/root/lists/*")).length {
		k := zList.item((i:=A_Index)-1).nodeName
		if !IsObject(x.selectSingleNode("/root/lists/" k)) {						; list does not exist on current XML
			x.addElement(k,"/root/lists")									; create a blank
		}
		locPath := x.selectSingleNode("/root/lists")
		locNode := locPath.selectSingleNode(k)
		locDate := locNode.getAttribute("date")
		remPath := z.selectSingleNode("/root/lists")
		remNode := remPath.selectSingleNode(k)
		remDate := remNode.getAttribute("date")
		if (remDate<locDate) {								; local edit is newer.
			continue
		} 
		if (remDate>locDate) {								; remote is newer than local.
			clone := remnode.cloneNode(true)
			locPath.replaceChild(clone,locNode)
		}
	}
	Progress,, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
	
	
/*	 Cycle through ID@MRN's
		<demog> - never modified. local info always newest.
		<info> - from CORES. never modified on server.
		<mar> - from CORES. never modified on server.
		<status> - can be updated.
		<diagnoses> - (notes, card, ep, surg, prob, prov) can be updated on either side.
		<notes/weekly> - (summary) updated on either side.
		<notes/progress> - (note) updated on either side.
		<plan/tasks> - (todo) updated on either side.
*/
	Loop, % (zID := z.selectNodes("/root/id")).length {				; Loop through each MRN in tempList
		k := zID.item((i:=A_Index)-1)
		kMRN := k.getAttribute("mrn")
		kMRNstring := "/root/id[@mrn='" kMRN "']"
		
		if !IsObject(x.selectSingleNode(kMRNstring)) {									; No MRN in X but exists in Z?
			clone := z.selectSingleNode(kMRNstring).cloneNode(true)
			x.selectSingleNode("/root").appendChild(clone)						; Copy entire MRN node from Z to X
			continue															; and move on.
		}
		; Check <status>
		compareDates(kMRNstring,"status")
		; Check <diagnoses>
		compareDates(kMRNstring,"diagnoses")
		
		compareDates(kMRNstring,"prov")
		if !IsObject(x.selectSingleNode(kMRNstring "/prov")) {
			x.addElement("prov", kMRNstring)
		}
		if IsObject(x.selectSingleNode(kMRNstring "/diagnoses/prov")) {
			clone := x.selectSingleNode(kMRNstring "/diagnoses/prov").cloneNode(true)
			x.selectSingleNode(kMRNstring).replaceChild(clone,x.selectSingleNode(kMRNstring "/prov"))
			x.selectSingleNode(kMRNstring "/diagnoses").removeChild(x.selectSingleNode(kMRNstring "/diagnoses/prov"))
		}
		
		; Check <trash>
		Loop % (zTrash := k.selectNodes("trash/*")).length { ; Loop through trash items.
			zTr := zTrash.item(A_Index-1)
			zTrCr := zTr.getAttribute("created")
			xTr := x.selectSingleNode(kMRNstring "/trash/*[@created='" zTrCr "']")
			if IsObject(xTr) and (zTr.text = xTr.text) {			; if exists in trash, skip to next
				continue
			} 
			if !IsObject(x.selectSingleNode(kMRNstring "/trash")) {		; make sure that <trash> exists
				x.addElement("trash", kMRNstring)
			}															; then copy the clone into <trash>
			clone := zTr.cloneNode(true)
			x.selectSingleNode(kMRNstring "/trash").appendChild(clone)
		}
		
		; Check <notes/weekly>
		Loop, % (zNotes := k.selectNodes("notes/weekly/summary")).length {	; Loop through each /root/id@MRN/notes/weekly/summary note.
			zWN := zNotes.item(A_Index-1)
			zWND := zWN.getAttribute("created")
			if IsObject(x.selectSingleNode(kMRNstring "/trash/summary[@created='" zWND "']"))
				continue
			Else
				compareDates(kMRNstring "/notes/weekly","summary[@created='" zWND "']")
		}
		; Check <notes/progress>
		
		; Check <plan/done>
		Loop, % (zTasks := k.selectNodes("plan/done/todo")).length {	; Loop through each /root/id@MRN/plan/done/todo.
			zTD := zTasks.item(A_Index-1)
			zWND := zTD.getAttribute("created")
			if IsObject(x.selectSingleNode(kMRNstring "/trash/todo[@created='" zWND "']"))
				continue
			else
				compareDates(kMRNstring "/plan/done","todo[@created='" zWND "']")
		}
		; Check <plan/tasks>
		Loop, % (zTasks := k.selectNodes("plan/tasks/todo")).length {	; Loop through each /root/id@MRN/plan/tasks/todo.
			zTD := zTasks.item(A_Index-1)
			zWND := zTD.getAttribute("created")
			if IsObject(x.selectSingleNode(kMRNstring "/trash/todo[@created='" zWND "']")) or IsObject(x.selectSingleNode(kMRNstring "/plan/done/todo[@created='" zWND "']"))
				continue
				; skip if index exists in completed or deleted.
			else
				compareDates(kMRNstring "/plan/tasks","todo[@created='" zWND "']")
		}
	}
	x.save("currlist.xml")
	y := new XML("currlist.xml")							; open fresh currlist.XML into Y
	;~ while (str := loc[i:=A_Index]) {						; get the dates for each of the lists
		;~ loc[str,"date"] := y.getAtt("/root/lists/" . str, "date")
	;~ }
	;~ DateCORES := y.getAtt("/root/lists/cores", "date")
	Progress 80, % dialogVals[Rand(dialogVals.MaxIndex())] "..."


	yArch := new XML("archlist.xml")
	if !IsObject(yArch.selectSingleNode("/root")) {			; if yArch is empty,
		yArch.addElement("root")					; then create it.
	}
	
	Loop, % (yN := y.selectNodes("/root/id")).length {				; Loop through each MRN in Currlist
		k := yN.item((i:=A_Index)-1)
		kMRN := k.getAttribute("mrn")
		if !IsObject(yaMRN:=yArch.selectSingleNode("/root/id[@mrn='" kMRN "']")) {		; If ID MRN node does not exist in Archlist,
			yArch.addElement("id","root", {mrn: kMRN})							; then create it
			yArch.addElement("demog","/root/id[@mrn='" kMRN "']")				; along with the placeholder children
			yArch.addElement("diagnoses","/root/id[@mrn='" kMRN "']")
			yArch.addElement("notes","/root/id[@mrn='" kMRN "']")
			yArch.addElement("plan","/root/id[@mrn='" kMRN "']")
			eventlog(kMRN " added to archlist.")
		}
		ArchiveNode("demog")
		ArchiveNode("diagnoses")
		ArchiveNode("prov")
		ArchiveNode("notes")
		ArchiveNode("plan")
	}
	Progress, 100, % dialogVals[Rand(dialogVals.MaxIndex())] "..."

	yArch.save("archlist.xml")											; Write out
	Sleep 500
	Progress, off
	FileDelete, .currlock
Return
}

SaveIt:
{
	vSaveIt:=true
	gosub GetIt														; recheck the server side currlist.xml
	vSaveIt:=
	
	filecheck()
	FileOpen(".currlock", "W")													; Create lock file.

	Progress, b w300, Processing...
	y := new XML("currlist.xml")									; Load freshest copy of Currlist
	yArch := new XML("archlist.xml")
	; Save all MRN, Dx, Notes, ToDo, etc in arch.xml
	Loop, % (yaN := y.selectNodes("/root/id")).length {				; Loop through each MRN in Currlist
		k := yaN.item((i:=A_Index)-1)
		kMRN := k.getAttribute("mrn")
		errnum=0
		Loop, % (yaList := y.selectNodes("/root/lists/*/mrn")).length {		; Compare each MRN against the list of
			yaMRN := yaList.item((j:=A_Index)-1).text						; MRNs in /root/lists
			if (kMRN == yaMRN) {											; If a hit, then move on
				errnum+=1
				continue
			}
		}
		if !(errnum) {								; If did not match, delete the ID/MRN
			yaMRN := yArch.selectSingleNode("/root/id[@mrn='" kMRN "']")					; Find equivalent MRN node in Archlist previously written in SaveIt.
			ArchiveNode("demog")
			ArchiveNode("diagnoses")
			ArchiveNode("prov")
			ArchiveNode("notes",1)						; ArchiveNode(node,1) to archive this node by today's date
			ArchiveNode("plan",1)
			errtext := errtext . "* " . k.selectSingleNode("demog/name_first").text . " " . k.selectSingleNode("demog/name_last").text . "`n"
			RemoveNode("/root/id[@mrn='" kMRN "']")
			eventlog(kMRN " removed from active lists.")
		}
	}

	Progress, 80, Compressing nodes...
	yArch.save("archlist.xml")						; Writeout
	if !(errnum) {
		Progress, hide
		MsgBox, 48
			, Database cleaning
			, % "The following patient records no longer appear `non any CIS census and have been removed `nfrom the active list:`n`n" . errtext
		Progress, 85
	}
	; =================================================
	y.save("currlist.xml")
	eventlog("Currlist cleaned up.")
	
	if !(isLocal) {
		Run pscp.exe -sftp -i chipotle-pr.ppk -p currlist.xml pedcards@homer.u.washington.edu:public_html/%servfold%/currlist.xml,, Min
		sleep 500																; CIS VM needs longer delay than 200ms to recognize window
		ConsWin := WinExist("ahk_class ConsoleWindowClass")
		IfWinExist ahk_id %consWin% 
		{
			ControlSend,, {y}{Enter}, ahk_id %consWin%
			Progress,, Console %consWin% found
		}
		WinWaitClose ahk_id %consWin%
		Run pscp.exe -sftp -i chipotle-pr.ppk -p logs/%sessdate%.log pedcards@homer.u.washington.edu:public_html/%servfold%/logs/%sessdate%.log,, Min
	}

	FileDelete, .currlock
	eventlog("CHIPS server updated.")
	Progress, 100, Saving updates...
	;Sleep, 1000

Return
}

saveCensus:
{
	FormatTime, censDate, A_Now, yyyyMMdd
	censDT := breakDate(censDate)
	censY := censDT.YYYY
	censM := censDT.MM
	censD := censDT.DD
	censFile := "logs/" censY censM ".xml"
	if (fileexist(censFile)) {
		cens := new XML(censFile)
	} else {
		cens := new XML("<root/>")
	}
	
	if !IsObject(cens.selectSingleNode(c1 := "/root/census[@day='" censD "']")) {
		cens.addElement("census", "/root", {day: censD})
		cens.addElement("Cards", c1)
		cens.addElement("CSR", c1)
		cens.addElement("TXP", c1)
	}
	
	if (cens.selectSingleNode(c1 "/" location).getAttribute("date"))	; if already done, then skip
		return
	
	cens.selectSingleNode(c1).replaceChild(y.selectSingleNode("/root/lists/" location).cloneNode(location="TXP" ? false : true), cens.selectSingleNode(c1 "/" location))
	cens.selectSingleNode(c1 "/" location).setAttribute("tot",cens.selectNodes(c1 "/" location "/mrn").length)
	if (location="TXP") {
		loop % (c2:=y.selectNodes("/root/id/status[@txp='on']")).length {
			cMRN := c2.item(i:=A_Index-1).parentNode.getAttribute("mrn")
			cUnit := y.selectSingleNode("/root/id[@mrn='" cMRN "']/demog/data/unit").text
			if !IsObject(cens.selectSingleNode(c1 "/TXP/" cUnit)) {
				cens.addElement(cUnit, c1 "/TXP")
			}
			cens.addElement("mrn", c1 "/TXP/" cUnit, cMRN)
		}
		cens.selectSingleNode(c1 "/TXP").setAttribute("tot",totTXP:=cens.selectNodes(c1 "/TXP//mrn").length)
		cens.selectSingleNode(c1 "/TXP/CICU").setAttribute("tot",totTxCICU:=cens.selectNodes(c1 "/TXP/CICU/mrn").length)
		cens.selectSingleNode(c1 "/TXP/SUR-R6").setAttribute("tot",totTxWard:=cens.selectNodes(c1 "/TXP/SUR-R6/mrn").length)
	}
	
	eventlog("CENSUS '" location "' updated.")
	cens.save(censFile)
	censCrd := cens.selectSingleNode(c1 "/Cards")
	censCSR := cens.selectSingleNode(c1 "/CSR")
	censTxp := cens.selectSingleNode(c1 "/TXP")
		
	if ((totCRD:=censCrd.getAttribute("tot")) and (totCSR:=censCSR.getAttribute("tot")) and (totTXP:=censTxp.getAttribute("tot"))) {
		totTxCICU := cens.selectSingleNode(c1 "/TXP/CICU").getAttribute("tot")
		totTxWard := cens.selectSingleNode(c1 "/TXP/SUR-R6").getAttribute("tot")
		FileAppend, % censM "/" censD "/" censY "," totCRD "," totCSR "," totTxCICU "," totTxWard "`n" , logs/census.csv
		eventlog("Daily census updated.")
	}
	return
}

eventlog(event) {
	global user, sessdate
	comp := A_ComputerName
	FormatTime, now, A_Now, yyyy.MM.dd.HH:mm:ss
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

WriteOut(path,node) {
/* 
	Prevents concurrent writing of y.MRN data. If someone is saving data (.currlock exists), script will wait
	approx 6 secs and check every 50 msec whether the lock file is removed. When available it creates clones the y.MRN
	node, loads a fresh currlist into Z (latest update), replaces the z.MRN node with the cloned y.MRN node,
	saves it, then reloads this currlist into Y.
*/
	global y
	filecheck()
	FileOpen(".currlock", "W")													; Create lock file.
	locPath := y.selectSingleNode(path)
	locNode := locPath.selectSingleNode(node)
	clone := locNode.cloneNode(true)											; make copy of y.node

	z := new XML("currlist.xml")												; open most recent existing currlist.XML into temp Z
	if !IsObject(z.selectSingleNode(path "/" node)) {
		If instr(node,"id[@mrn") {
			z.addElement("id","root",{mrn: strX(node,"='",1,2,"']",1,2)})
		} else {
			z.addElement(node,path)
		}
	}
	zPath := z.selectSingleNode(path)											; find same "node" in z
	zNode := zPath.selectSingleNode(node)
	zPath.replaceChild(clone,zNode)												; replace existing zNode with node clone

	z.save("currlist.xml")														; write z into currlist
	y := new XML("currlist.xml")												; reload currlist into y
	FileDelete, .currlock														; release lock file.
}

filecheck() {
	if FileExist(".currlock") {
		err=0
		Progress, , Waiting to clear lock, File write queued...
		loop 50 {
			if (FileExist(".currlock")) {
				progress, %p%
				Sleep 50
				p += 1
			} else {
				err=1
				break
			}
		}
		if !(err) {
			;~ Progress off
			;~ MsgBox This file appears to be locked.
			FileDelete, .currlock
			;~ ExitApp
		}
	} 
	progress off
}

