GetIt:
{
	; ==================															; temporarily delete this when testing to avoid delays.
	;FileDelete, .currlock
	; ==================
	filecheck()																		; delay loop if .currlock set (currlist write in process)
	FileOpen(".currlock", "W")														; Create lock file.
	if !(vSaveIt=true)																; not launched from SaveIt:
		Progress, b w300, Reading data..., % "- = C H I P O T L E = -`nversion " vers "`n"
			;. "`n`nNow with " rand(20,99) "% less E. coli!"									; This could be a space for a random message
	else
		Progress, b w300, Consolidating data..., 
	Progress, 20																	; launched from SaveIt, no CHIPOTLE header

	FileCopy, currlist.xml, templist.xml, 1											; create templist copy from currlist
	if !(isLocal) {																	; live run, download changes file from server
		/*	Can accept do verbs "get", "root", "save"
		*/
		ckRes := httpComm("get")
		
		if (ckRes=="NONE") {														; no change.xml file present
			; nothing here
			MsgBox No change file.
		} else if (instr(ckRes,"proxy")) {											; hospital proxy problem
			MsgBox Hospital proxy problem.
		} else {																	; actual response
			; merge blob
			ckXML := new XML(ckRes)
		}
	}
	FileGetTime, currtime, currlist.xml												; modified date for currlist.xml

	Progress, 60, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
	
	;~ z := new XML("templist.xml")													; load templist into XML object Z -- UNNECESSARY if templist is untouched
	Progress,, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
	/*																				This would be the place to check integrity of templist.xml
	*/
	checkXML(z)
	
	;~ if !(FileExist("currlist.xml")) {												; no currlist exists (really?) -- this would only occur if no local currlist
		;~ z.save("currlist.xml")														; create currlist from object Z
	;~ }
	FileCopy, currlist.xml, oldlist.xml, 1											; Backup currlist to oldlist.
	;~ x := new XML("currlist.xml")													; Load currlist into working X.
	
	;~ x.save("currlist.xml")																; save X to currlist
	y := new XML("currlist.xml")														; load this fresh currlist.XML into Y
	Progress 80, % dialogVals[Rand(dialogVals.MaxIndex())] "..."


	yArch := new XML("archlist.xml")
	if !IsObject(yArch.selectSingleNode("/root")) {										; if yArch is empty,
		yArch.addElement("root")														; then create it.
		yArch.save("archlist.xml")															; Write out archlist
	}
	
	Sleep 500
	Progress, off
	FileDelete, .currlock
Return
}

SaveIt:
{
	vSaveIt:=true																		; inform GetIt that run from SaveIt, changes progress window
	gosub GetIt																			; recheck the server side currlist.xml
	vSaveIt:=																			; clear bit
	
	filecheck()																			; file in use, delay until .currlock cleared
	FileOpen(".currlock", "W")															; Create lock file.

	Progress, b w300, Processing...
	y := new XML("currlist.xml")														; Load freshest copy of Currlist
	yArch := new XML("archlist.xml")													; and ArchList
	
	; Save all MRN, Dx, Notes, ToDo, etc in arch.xml
	yaNum := y.selectNodes("/root/id").length
	Loop, % (yaN := y.selectNodes("/root/id")).length {									; Loop through each ID/MRN in Currlist
		k := yaN.item((i:=A_Index)-1)
		kMRN := k.getAttribute("mrn")
		if !IsObject(yaMRN:=yArch.selectSingleNode("/root/id[@mrn='" kMRN "']")) {		; If ID MRN node does not exist in Archlist, 
			yArch.addElement("id","root", {mrn: kMRN})									; then create it 
			yArch.addElement("demog","/root/id[@mrn='" kMRN "']")						; along with the placeholder children 
			yArch.addElement("diagnoses","/root/id[@mrn='" kMRN "']") 
			yArch.addElement("notes","/root/id[@mrn='" kMRN "']") 
			yArch.addElement("plan","/root/id[@mrn='" kMRN "']") 
			eventlog(kMRN " added to archlist.") 
		}
		ArchiveNode("demog")															; clone nodes to arch if not already done 
		ArchiveNode("diagnoses") 
		ArchiveNode("prov") 
		ArchiveNode("notes") 
		ArchiveNode("plan") 
		Progress, % 80*(i/yaNum), % dialogVals[Rand(dialogVals.MaxIndex())] "..." 
		
		errList:=false																		; for counting hits in lists
		
		Loop, % (yaList := y.selectNodes("/root/lists/*/mrn")).length {					; Compare each MRN against the list of
			yaMRN := yaList.item((j:=A_Index)-1).text									; MRNs in /root/lists
			if (kMRN == yaMRN) {														; If MRN matches in any list, then move on
				errList:=true
				break																	; break out of list search loop
			}
		}
		if !(errList) {																	; If did not match any list, archive the ID/MRN
			ArchiveNode("notes",1)														; ArchiveNode(node,1) to archive this node by today's date
			ArchiveNode("plan",1)
			errtext .= "* " . k.selectSingleNode("demog/name_first").text . " " . k.selectSingleNode("demog/name_last").text . "`n"
			RemoveNode("/root/id[@mrn='" kMRN "']")										; ID node is archived, remove it from Y.
			eventlog(kMRN " removed from active lists.")
		}
	}

	Progress, 80, Saving updates...
	yArch.save("archlist.xml")															; Writeout archlist
	if !(errList) {																		; dialog to show if there were any hits
		Progress, hide
		MsgBox, 48
			, Database cleaning
			, % "The following patient records no longer appear `non any CIS census and have been removed `nfrom the active list:`n`n" . errtext
		Progress, 85
	}
	; =================================================
	if IsObject(y.selectSingleNode("/root/lists/SURGCNTR")) {
		RemoveNode("/root/lists/SURGCNTR")
		MsgBox SURGCNTR removed.
	}
	
	y.save("currlist.xml")
	eventlog("Currlist cleaned up.")
	
	if !(isLocal) {																		; for live data, send to server
		Run pscp.exe -sftp -i chipotle-pr.ppk -p currlist.xml pedcards@homer.u.washington.edu:public_html/%servfold%/currlist.xml,, Min
		sleep 500																		; CIS VM needs longer delay than 200ms to recognize window
		ConsWin := WinExist("ahk_class ConsoleWindowClass")								; get window ID
		IfWinExist ahk_id %consWin% 
		{
			ControlSend,, {y}{Enter}, ahk_id %consWin%									; blindly send {y}{enter} string to console
			Progress,, Console %consWin% found											; to get past save keys query
		}
		WinWaitClose ahk_id %consWin%
		Run pscp.exe -sftp -i chipotle-pr.ppk -p logs/%sessdate%.log pedcards@homer.u.washington.edu:public_html/%servfold%/logs/%sessdate%.log,, Min
	}

	FileDelete, .currlock
	eventlog("CHIPS server updated.")
	Progress, 100, Done!
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
	if (A_WDay > 5) {
		gosub readForecast
	}
	return
}

httpComm(do) {
	; consider two parameters?
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")							; initialize http request in object whr
		whr.Open("GET"															; set the http verb to GET file "change"
			, "https://depts.washington.edu/pedcards/change/direct.php?do=" . do
			, true)
		whr.Send()																; SEND the command to the address
		whr.WaitForResponse()	
	return whr.ResponseText													; the http response
}

checkXML(xml) {
/*	Simple integrity check to see if XML stream ends with </root>
 */
	Loop, Parse, xml
	{
		lastline := A_LoopField
	}
	if instr(lastline,"</root>") {
		return "good"
	} else {
		return "bad"
	}
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

