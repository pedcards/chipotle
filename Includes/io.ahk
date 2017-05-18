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

	yArch := new XML("archlist.xml")
	if !IsObject(yArch.selectSingleNode("/root")) {									; if yArch is empty,
		yArch.addElement("root")													; then create it.
		yArch.save("archlist.xml")													; Write out archlist
	}
	
	Progress, 30, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
	refreshCurr()																	; Get currlist, bak, or server copy
	eventlog("Valid currlist.")
	
	Progress, 80, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
	if !(isLocal) {																	; live run, download changes file from server
		ckRes := httpComm("","get")													; Check response from "get"
		
		if (ckRes=="NONE") {														; no change.xml file present
			eventlog("No change file.")
		} else if (instr(ckRes,"proxy")) {											; hospital proxy problem
			eventlog("Hospital proxy problem.")
		} else {																	; actual response, merge the blob
			eventlog("Import blob found.")
			StringReplace, ckRes, ckRes, `r`n,`n, All								; MSXML cannot handle the UNIX format when modified on server 
			StringReplace, ckRes, ckRes, `n,`r`n, All								; so convert all MS CRLF to Unix LF, then all LF back to CRLF
			z := new XML(ckRes)														; Z is the imported updates blob
			
			importNodes()															; parse Z blob
			eventlog("Import complete.")
			
			if (WriteFile()) {														; Write updated Y to currlist
				eventlog("Successful currlist update.")
				ckRes := httpComm("","unlink")											; Send command to delete update blob
				eventlog((ckRes="unlink") ? "Changefile unlinked." : "Not unlinked.")
			} else {
				eventlog("*** httpComm failed to write currlist.")
			}
		}
	}

	Progress 100, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
	Sleep 500
	Progress, off
	FileDelete, .currlock
Return
}

WriteFile() 
{
/*	This is only called during GetIt, SaveIt, ProcessCIS, and ProcessCORES
*/
	global y
	
	FileCopy, currlist.xml, currlist.bak, 1 								; make copy of good currlist
	
	Loop, 3
	{																		; try 3 times
		y.save("currlist.xml")												; to write currlist
		
		if (chk := checkXML("currlist.xml")) {								; success, break out
			break
		} else {
			eventlog("*** WriteFile unsuccessful. [" A_index "]")
			sleep 500
		}
	}
	
	if (chk) {																; successful check
		FileCopy, currlist.xml, bak/%A_Now%.bak
		return "good"
	} else {																; unsuccessful check
		progress, hide
		MsgBox Bad copy process`n`nRestoring last good copy.
		FileMove, currlist.bak, currlist.xml, 1								; then restore the last good xml
		return Error
	}
}


SaveIt:
{
	eventlog("Starting save...")
	vSaveIt:=true																		; inform GetIt that run from SaveIt, changes progress window
	gosub GetIt																			; refresh latest y and yarch from local and server
	vSaveIt:=																			; clear bit
	
	filecheck()																			; file in use, delay until .currlock cleared
	FileOpen(".currlock", "W")															; Create lock file.

	Progress, b w300, Processing...
	
	; Save all MRN, Dx, Notes, ToDo, etc in arch.xml
	yaNum := y.selectNodes("/root/id").length
	Loop, % (yaN := y.selectNodes("/root/id")).length {									; Loop through each ID/MRN in Currlist
		k := yaN.item(A_Index-1)
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
		if (A_index/10 == Round(A_index/10)) {
			Progress, % 80*(A_Index/yaNum), % dialogVals[Rand(dialogVals.MaxIndex())] "..." 
		}
		
		errList:=false																	; for counting hits in lists
		
		Loop, % (yaList := y.selectNodes("/root/lists/*/mrn")).length {					; Compare each MRN in active lists
			yaItem := yaList.item(A_index-1)
			yaName := yaItem.parentNode.nodeName
			if (yaName~="cores") {														; Skip scanning CORES, so only counts MRN in actual lists
				continue
			}
			yaMRN := yaItem.text														; MRNs in /root/lists
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

	Progress, 90, % dialogVals[Rand(dialogVals.MaxIndex())] "..."
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
		eventlog("SURGCNTR removed.")
	}
	
	y.save("currlist.xml")
	FileCopy, currlist.xml, % "bak/" A_now ".bak"
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
		Run pscp.exe -sftp -i chipotle-pr.ppk -p logs/%sessdate%.log pedcards@homer.u.washington.edu:public_html/%servfold%/logs/%sessdate%.log,, Min
		WinWaitClose ahk_id %consWin%
		eventlog("CHIPS server updated.")
	}
	
	bdir :=
	Loop, files, bak/*.bak
	{
		bdir .= A_LoopFileTimeCreated "`t" A_LoopFileName "`n"
	}
	Sort, bdir, R
	Loop, parse, bdir, `n
	{
		if (A_index < 11)																; skip the 10 most recent .bak files
			continue
		k := "bak/" strX(A_LoopField,"`t",1,1,"",0)										; Get filename between TAB and NL
		FileDelete, %k%																	; Delete
	}
	
	FileDelete, .currlock
	eventlog("Save successful.")
	Progress, 100, Done!
	;Sleep, 1000

Return
}

saveCensus:
{
/*	Called when grab Cards, CSR, or TXP
	Skip this if census has already been created today.
	Creates <census date='20160415'>, for each full list, and <census/cons> for the parsed consults.
	TXP divided into Ward, ICU, and Cons
*/
	FormatTime, censDate, A_Now, yyyyMMdd
	censDT := breakDate(censDate)
	censY := censDT.YYYY
	censM := censDT.MM
	censD := censDT.DD
	censFile := "logs/" censY censM ".xml"										; Read or create the censDate.xml file
	if (fileexist(censFile)) {
		cens := new XML(censFile)
	} else {
		cens := new XML("<root/>")
	}
	
	if !IsObject(cens.selectSingleNode(c1 := "/root/census[@day='" censD "']")) {	; Create date element and placeholders
		cens.addElement("census", "/root", {day: censD})
		cens.addElement("Cards", c1)
		cens.addElement("CSR", c1)
		cens.addElement("TXP", c1)
		cens.addElement("Cons", c1)
		cens.addElement("Ward", c1 "/Cons")
		cens.addElement("ICU",  c1 "/Cons")
	}
	
	if (cens.selectSingleNode(c1 "/" location).getAttribute("date"))			; if this location already done, then skip
		return
	
	; Clone service locations from Y to Cens
	; and set attr tot for number of <mrn> elements contained
	cens.selectSingleNode(c1).replaceChild(y.selectSingleNode("/root/lists/" location).cloneNode(location="Cards" ? true : false), cens.selectSingleNode(c1 "/" location))
	cens.selectSingleNode(c1 "/" location).setAttribute("tot",cens.selectNodes(c1 "/" location "/mrn").length)
	
	if (location="TXP") {
		loop % (c2:=y.selectNodes("/root/id/status[@txp='on']")).length {		; find all patients with status TXP
			cMRN := c2.item(i:=A_Index-1).parentNode.getAttribute("mrn")
			cUnit := y.selectSingleNode("/root/id[@mrn='" cMRN "']/demog/data/unit").text
			cSvc := y.selectSingleNode("/root/id[@mrn='" cMRN "']/demog/data/service").text
			if !(cSvc~="Cardi") {
				cUnit := "Cons"													; don't count HF consults toward
			}
			if !IsObject(cens.selectSingleNode(c1 "/TXP/" cUnit)) {				; create TXP/unit in Cens
				cens.addElement(cUnit, c1 "/TXP")
			}
			cens.addElement("mrn", c1 "/TXP/" cUnit, cMRN)						; add MRN to TXP/unit
		}
		cens.selectSingleNode(c1 "/TXP").setAttribute("tot",cens.selectNodes(c1 "/TXP//mrn").length)
		cens.selectSingleNode(c1 "/TXP/CICU-F6").setAttribute("tot",cens.selectNodes(c1 "/TXP/CICU-F6/mrn").length)
		cens.selectSingleNode(c1 "/TXP/" loc_Surg).setAttribute("tot",cens.selectNodes(c1 "/TXP/" loc_Surg "/mrn").length)
	}
	
	; When run the Cards list, count CONSULT vs CRD patients in WARD
	if (location="Cards") {
		Loop % (c3:=y.selectNodes("/root/lists/Ward/mrn")).length {				; Scan all MRN in WARD
			cMRN := c3.item(A_Index-1).text
			cSvc := y.selectSingleNode("/root/id[@mrn='" cMRN "']/demog/data/service").text
			if (cSvc~="Cardi") {												; Service contains "Cardi" (e.g. "*ology", "*ac Surgery")
				continue														; skip it
			}
			cens.addElement("mrn", c1 "/Cons/Ward", cMRN)						; Add remainder to Consult list
		}
		cens.selectSingleNode(c1 "/Cons/Ward").setAttribute("tot",cens.selectNodes(c1 "/Cons/Ward/mrn").length)
	}
	; When run CSR list, separate CICU vs ARNP, count CONSULT vs (CSR|CRD|CICU) patients in ICUCons
	if (location="CSR") {
		cNP := cCSR := 0
		Loop % (c3:=y.selectNodes("/root/lists/CSR/mrn")).length {				; Scan all MRN in CSR
			cMRN := c3.item(A_Index-1).text
			cUnit := y.selectSingleNode("/root/id[@mrn='" cMRN "']/demog/data/unit").text
			if !IsObject(cens.selectSingleNode(c1 "/CSR/" cUnit)) {				; create CSR/unit in Cens if doesn't exist
				cens.addElement(cUnit, c1 "/CSR")
			}
			if (cUnit~=loc_Surg) {												; Unit contains "SUR-R4" (e.g. "SUR-R4", not "SURGCNTR")
				cens.addElement("mrn", c1 "/CSR/" loc_surg, cMRN)				; Add to CSR/SUR-R4
			} else {
				cens.addElement("mrn", c1 "/CSR/CICU-F6", cMRN)				; Add all else (incl SURGCNTR) to CSR/CICU-F6
			}
		}
		cens.selectSingleNode(c1 "/CSR").setAttribute("tot",cens.selectNodes(c1 "/CSR//mrn").length)
		cens.selectSingleNode(c1 "/CSR/" loc_Surg).setAttribute("tot",cens.selectNodes(c1 "/CSR/" loc_Surg "/mrn").length)
		cens.selectSingleNode(c1 "/CSR/CICU-F6" ).setAttribute("tot",cens.selectNodes(c1 "/CSR/CICU-F6/mrn").length)
		
		Loop % (c3:=y.selectNodes("/root/lists/ICUCons/mrn")).length {			; Scan all MRN in ICUCons
			cMRN := c3.item(A_Index-1).text
			cSvc := y.selectSingleNode("/root/id[@mrn='" cMRN "']/demog/data/service").text
			if (cSvc="") {
				continue														; Skip if patient discharged (no service)
			}
			if (cSvc~="Cardi") {
				continue														; Skip if Service contains "Cardi" (e.g. "*ology", "*ac Surgery")
			}
			cens.addElement("mrn", c1 "/Cons/ICU", cMRN)						; The remainder go to Consult list
		}
		cens.selectSingleNode(c1 "/Cons/ICU").setAttribute("tot",cens.selectNodes(c1 "/Cons/ICU/mrn").length)
	}
	
	eventlog("CENSUS '" location "' updated.")
	cens.save(censFile)															; save the censDate.xml file
	
	censCrd := cens.selectSingleNode(c1 "/Cards")								; get nodes of service locations
	censCSR := cens.selectSingleNode(c1 "/CSR")
	censTxp := cens.selectSingleNode(c1 "/TXP")
	
	; When Cens tot exists for all (CRD,CSR,TXP)
	; add tot numbers to census.csv
	if ((totCRD:=censCrd.getAttribute("tot")) and (totCSR:=censCSR.getAttribute("tot")) and (totTXP:=censTxp.getAttribute("tot"))) {
		totTxCICU := censTxp.selectSingleNode("CICU-F6").getAttribute("tot")
		totTxWard := censTxp.selectSingleNode(loc_Surg).getAttribute("tot")
		totConsWard := cens.selectSingleNode(c1 "/Cons/Ward").getAttribute("tot")
		totConsICU  := cens.selectSingleNode(c1 "/Cons/ICU").getAttribute("tot")
		totCsrWard := censCSR.selectSingleNode(loc_Surg).getAttribute("tot")
		totCsrICU  := censCSR.selectSingleNode("CICU-F6").getAttribute("tot")
		FileAppend, % censM "/" censD "/" censY "," totCRD "," totCSR "," totTxCICU "," totTxWard "," totConsWard "," totConsICU "," totCsrWard "`n" , logs/census.csv
		eventlog("Daily census updated.")
	}
	
	; On Fri (or Sat) perform Forecast (and Qgenda) update
	if (A_WDay > 5) {
		gosub readForecast
	}
	return
}

httpComm(url:="",verb:="") {
	; consider two parameters?
	global servFold
	if (url="") {
		url := "https://depts.washington.edu/pedcards/change/direct.php?" 
				. ((servFold="testlist") ? "test=true&" : "") 
				. "do=" . verb
	}
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")							; initialize http request in object whr
		whr.Open("GET"															; set the http verb to GET file "change"
			, url
			, true)
		whr.Send()																; SEND the command to the address
		whr.WaitForResponse()													; and wait for
	return whr.ResponseText														; the http response
}

parseJSON(txt) {
	out := {}
	Loop																		; Go until we say STOP
	{
		ind := A_index															; INDex number for whole array
		ele := strX(txt,"{",n,1, "}",1,1, n)									; Find next ELEment {"label":"value"}
		if (n > strlen(txt)) {
			break																; STOP when we reach the end
		}
		sub := StrSplit(ele,",")												; Array of SUBelements for this ELEment
		Loop, % sub.MaxIndex()
		{
			StringSplit, key, % sub[A_Index] , : , `"							; Split each SUB into label (key1) and value (key2)
			out[ind,key1] := key2												; Add to the array
		}
	}
	return out
}

checkXML(xml) {
/*	Simple integrity check for XML files.
	Reads XML file into string, checks if string ends with </root>
	If success, returns obj. If not, returns error.
 */
	FileRead, str, % xml	
	Loop, parse, str, `n, `r
	{
		test := A_LoopField
		if !(test) {
			continue
		}
		lastline := test
	}
	if instr(lastline,"</root>") {
		if (pos:=RegExMatch(str,"[^[:ascii:]]")) {
			per := instr(str,"<id",,pos-strlen(str))
			RegExMatch(str,"O)<\w+((\s+\w+(\s*=\s*(?:"".*?""|'.*?'|[\^'"">\s]+))?)+\s*|\s*)/?>",pre,per)
			RegExMatch(str,"O)</\w+\s*[\^>]*>",post,pos)
			eventlog("Illegal chars detected in " xml " in " pre.value "/" post.value ".")
			str := RegExReplace(str,"[^[:ascii:]]","~")
		}
		return str
	} else {
		return error 
	}
}

importNodes() {
	global y, z, zNode, zClone													; access to Y (currlist) and Z (update blob)
	
	loop, % (ck:=z.selectNodes("//node")).length
	{
		zPath := ck.item(A_index-1)												; zPath is each <node>
		zNode := zPath.childNodes.item(0)										; zNode is child to clone
		zClone := zNode.cloneNode(true)											; clone the changed node
		
		zMRN := zPath.getAttribute("MRN")										; get the MRN, 
		zType := zPath.getAttribute("type")										; element type, e.g. diagnoses, prov, status, todo, summary
		zChange := zPath.getAttribute("change")									; and changed flags (add, del, done, undo)
		
		compareDates(zMRN,zType,zChange)
	}
	
	return
}
	
compareDates(zMRN, zType, zChange:="") {
	global y, z, zNode, zClone
	nodePath := {"todo":"plan/tasks"													; array to map nodetype:idpath for import node
				,"summary":"notes/weekly"
				,"stat":"status"
				,"dx":"diagnoses"
				,"prov":"prov"
				,"pmtemp":"pacing"
				,"pmperm":"diagnoses/device"}
	
	if !IsObject(yID := y.selectSingleNode("//id[@mrn='" zMRN "']")) {					; Missing MRN will only happen if ID has been archived since last server sync
		return																			; so skip to next index
	}
	
	znAu := zNode.getAttribute("au")													; author of change
	znEd := zNode.getAttribute("ed")													; last edit date/time
	znCreated := zNode.getAttribute("created")											; creation date/time (for notes and tasks)
	znDate := zNode.getAttribute("date")												; target date (for notes and tasks)
	;MsgBox % "`n`n`n`n`n`n" zType "`n" zMRN "`n" znED "`n" zClone.getAttribute("ed") "`nISOBJ " IsObject(zClone) 
	
	mrnStr := "//id[@mrn='" zMRN "']"
	PathStr := mrnStr "/" nodePath[zType]												; string to full path
	NodeStr := zType . ((znCreated) ? "[@created='" znCreated "']" : "")				; string to zType with created attr if present in zNode
	
	; todo tasks and notes can be deleted.
	; if @del=true, element has been moved to <trash> on server
	; check if this item is already in trash: "/trash/*[@created=' created ']" exists and text of both is equal
	; if not, move node to trash
	
	if (zChange="del") {																; move existing plan/task/todo or notes/weekly/summary to trash
		makeNodes(zMRN,"trash")															; create trash node if not present
		y.selectSingleNode(mrnStr "/trash").appendChild(zClone)							; create item in trash
		removeNode(pathStr "/" nodeStr)													; remove item from plan/task/todo or notes/weekly/summary
		eventlog(zMRN " <--DEL::" zType "::" znCreated "::" znAu "::" znEd )
		return
	} else if (zChange="done") {														; mark plan/task/todo as done; move to plan/done/todo
		makeNodes(zMRN,"plan/done")														; plan/task already exists, make sure plan/done exists
		y.selectSingleNode(mrnStr "/plan/done").appendChild(zClone)
		removeNode(pathStr "/" nodeStr)
		eventlog(zMRN " <--DONE::" zType "::" znCreated "::" znAu "::" znEd )
		return
	} else if (zChange="undo") {														; move from plan/done/todo to plan/task/todo
		MsgBox % pathStr "/" nodeStr
		y.selectSingleNode(pathStr).appendChild(zClone)
		removeNode(mrnStr "/plan/done/" nodeStr)
		eventlog(zMRN " <--UNCHK::" zType "::" znCreated "::" znAu "::" znEd )
		return
	} else if (zChange="add") {															; new <plan/tasks/todo> or <notes/weekly/summary>
		makeNodes(zMRN,nodePath[zType])													; ensure that path to <plan/tasks> or <notes/weekly> exist in Y
		yPath := yID.selectSingleNode(nodePath[zType])									; the parent node
		yPath.appendChild(zClone)
		eventlog(zMRN " <--ADD::" zType "::" znCreated "::" znAu "::" znEd )
		return
	} else if (zChange="edit") {
		yPath := yID.selectSingleNode(nodePath[zType])									; edit existing <plan/tasks> or <notes/weekly>
		yPath.replaceChild(zClone,yPath.selectSingleNode(nodeStr))
		eventlog(zMRN " <--CHG::" zType "::" znCreated "::" znAu "::" znEd )
		return
	} else if (zChange="mod") {															; adds/mods node in zType
		makeNodes(zMRN,nodePath[zType])
		yPath := yID.selectSingleNode(nodePath[zType])
		yPath.parentNode.replaceChild(zClone,yPath)
		eventlog(zMRN " <--CHG::" zType "::" znAu "::" znEd )
		return
	}
	; remaining instances are diagnosis, status, prov
	yPath := yID
	yNode := yPath.selectSingleNode(nodePath[zType])									; get the local node
	ynEd := yNode.getAttribute("ed")													; last edit time
	
	if (znEd>ynEd) {																	; as long as remote node ed is more recent
		yPath.replaceChild(zClone,yNode)												; make the clone
		eventlog(zMRN " <--CHG::" zType "::" znAu "::" znEd )
	} else {
		eventlog(zMRN " X--BLK::" zType ((znCreated) ? "::" znCreated : "") "::" znAu "::" znEd " not newer.")
	}
	
	return
}

makeNodes(MRN,path) {
/*	Checks Y for presence of the node in path
 *	Creates path as needed
 */
	global y
	mrnPath :=  "//id[@mrn='" MRN "']"
	if IsObject(yNode := y.selectSingleNode(mrnPath "/" path)) {						; path exists, return
		return
	}
	loop, parse, path, /
	{
		step := A_LoopField																; each next level of path
		
		if IsObject(y.selectSingleNode(mrnPath "/" step)) {								; this level exists,
			mrnPath .= "/" step															; add to mrnPath string
			continue																	; and move to next level
		}
		y.addElement(step, mrnPath)														; does not exist, add this element
		mrnPath .= "/" step																; add to mrnPath string and move to next
	}
	return
}

ArchiveNode(node,i:=0) {
	global y, yArch, kMRN											; Initialize global variables
	MRN := "/root/id[@mrn='" kMRN "']"
	x := y.selectSingleNode(MRN "/" node)							; Get "node" from k (y.id[mrn])
	if !IsObject(x) {
		;MsgBox Fail
		return
	}
	if !IsObject(yArch.selectSingleNode(MRN "/" node))					; if no node exists,
		yArch.addElement(node,MRN)										; create it.
	arcX := yArch.selectSingleNode(MRN "/" node)						; get the node, whether existant or new
	
	clone := x.cloneNode(true)											; make a copy
	yArch.selectSingleNode(MRN).replaceChild(clone,arcX)				; replace arcX with the clone.
	
	if ((node="demog") and (yArch.selectSingleNode(MRN "/demog/data"))){
		yArch.selectSingleNode(MRN "/demog").removeChild(yArch.selectSingleNode(MRN "/demog/data"))
	}
	
	if (i=1)	{														; create <id/archive/discharge[date=now]>
		if !IsObject(yArch.selectSingleNode(MRN "/archive")) {
			yArch.addElement("archive",MRN)
		}
		FormatTime, dcdate, A_Now, yyyyMMdd
		yArch.addElement("dc",MRN "/archive", {date: dcdate})
		yArch.selectSingleNode(MRN "/archive/dc[@date='" dcdate "']").appendChild(clone)
	}																	; move element here
	return
}

FetchNode(node) {
	global
	local x, clone
	if IsObject(yArch.selectSingleNode(MRNstring "/" node)) {		; Node arch exists
		x := yArch.selectSingleNode(MRNstring "/" node)
		clone := x.cloneNode(true)
		y.selectSingleNode(MRNstring).appendChild(clone)			; using appendChild as no Child exists yet.
	} else {
		y.addElement(node, MRNstring)								; If no node arch exists, create placeholder
	}
}

RemoveNode(node) {
	global
	local q
	q := y.selectSingleNode(node)
	q.parentNode.removeChild(q)
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

refreshCurr(lock:="") {
/*	Refresh Y in memory with currlist.xml to reflect changes from other users.
	If invalid XML, try to read the most recent .bak file in reverse chron order.
	If all .bak files fail, get last saved server copy.
	If lock="", filecheck()/currlock is handled from outside this function.
	If lock=1, will handle the filecheck()/currlock within this call.
*/
	global y
	if (lock) {
		filecheck()
		FileOpen(".currlock", "W")												; Create lock file
	}
	if (z:=checkXML("currlist.xml")) {											; Valid XML
		y := new XML(z)														; <== Is this valid?
		if (lock) 
			FileDelete, .currlock													; Clear the file lock
		return																	; Return with refreshed Y
	}
	
	eventlog("*** Failed to read currlist. Attempting backup restore.")
	dirlist :=
	Loop, files, bak\*.bak
	{
		dirlist .= A_LoopFileTimeCreated "`t" A_LoopFileName "`n"				; build up dirlist with Created time `t Filename
	}
	Sort, dirlist, R															; Sort in reverse chron order
	Loop, parse, dirlist, `n
	{
		name := strX(A_LoopField,"`t",1,1,"",0)									; Get filename between TAB and NL
		if (z:=checkXML("bak\" name)) {											; Is valid XML
			y := new XML(z)														; Replace Y with Z
			eventlog("Successful restore from " name)
			FileCopy, bak\%name%, currlist.xml, 1								; Replace currlist.xml with good copy
			if (lock)
				FileDelete, .currlock											; Clear file lock
			return
		} else {
			FileDelete, bak\%name%												; Delete the bad bak file
		}
	}
	
	eventlog("** Failed to restore backup. Attempting to download server backup.")
	sz := httpComm("","full")														; call download of FULL list from server, not just changes
	FileDelete, templist.xml
	FileAppend, %sz%, templist.xml												; write out as templist
	if (z:=checkXML("templist.xml")) {
		y := new XML(z)															; Replace Y with Z
		eventlog("Successful restore from server.")
		filecopy, templist.xml, currlist.xml, 1									; copy templist to currlist
		if (lock)
			FileDelete, .currlock													; clear file lock
		return
	}
	
	eventlog("*** Failed to restore from server.")									; All attempts fail. Something bad has happened.
	httpComm("","err999")															; Pushover message of utter failure
	FileDelete, .currlock
	MsgBox, 16, CRITICAL ERROR, Unable to read currlist. `n`nExiting.
	ExitApp
}

repairXML(ByRef y, ByRef z) {
/*	Attempt to repair broken XML file.
	"Y" = broken XML, "Z" = last good bak version
	Get X chars from broken tail for polymerase annealing.
	Search for "<id mrn=" backwards from broken tail, get the MRN string.
	Search for same "tail" within the same ID MRN in Z.
	Copy the remainder of Z from that point.
	Attach to broken tail of Y.
*/

	; Cool idea, but will this really be relevant if we have a constant supply of good bak files?
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
	
	if (ck:=checkXML("currlist.xml")) {											; Valid XML
		z := new XML(ck)
	} else {
		eventlog("*** WriteOut failed to read currlist.")
		dirlist :=
		Loop, files, bak\*.bak
		{
			dirlist .= A_LoopFileTimeCreated "`t" A_LoopFileName "`n"			; build up dirlist with Created time `t Filename
		}
		Sort, dirlist, R														; Sort in reverse chron order
		Loop, parse, dirlist, `n
		{
			name := strX(A_LoopField,"`t",1,1,"",0)								; Get filename between TAB and NL
			if (ck:=checkXML("bak\" name)) {									; Is valid XML
				z := new XML(ck)												; Replace Y with Z
				eventlog("WriteOut restore Z from " name)
				FileCopy, bak\%name%, currlist.xml, 1							; Replace currlist.xml with good copy
				break
			} else {
				FileDelete, bak\%name%											; Delete the bad bak file
			}
		}											
	}																			; temp Z will be most recent good currlist
	
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
	FileCopy, currlist.xml, % "bak/" A_now ".bak"								; create a backup for each writeout
	FileGetSize, currSize, currlist.xml, k
	if (currSize > 500) {
		notify("err200")
	}
	y := z																		; make Y match Z, don't need a file op
	FileDelete, .currlock														; release lock file.
	return
}

notify(verb) {
/*	if ".notify" not set, notify Admin
*/
	if !FileExist(".notify") {
		httpComm("","err200")
	}
	FileOpen(".notify","W")
	return
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

