syncHandoff() {
	global y, MRNstring, EpicSvcList, svcText, timenow, scr

	eventlog("Starting Handoff sync.")
	refreshCurr()																		; Get latest local currlist into memory
	Gui, main:Minimize
	res := {}
timenow := A_Now
fld := {}
fld.mrn := "1751700"
FileRead, tmp, files\eplist.clip
MRNstring := "/root/id[@mrn='" . fld.mrn . "']"
res.1 := {data:tmp}
processHandoff(res)


	/*	Check screen elements for Handoff, launch if necessary
		(this is much faster if already selected)
	*/
	loop, 5
	{
		HndOff := checkHandoff()
		if IsObject(HndOff) {
			break
		}
	}
	Progress, Off
	if !IsObject(HndOff) {
		MsgBox 0x40015, Handoff Sync, Failed to find Handoff panel.`n`nTry again?
		IfMsgBox, Retry
		{
			syncHandoff()
			return
		} else {
			Gui, main:Show
			return
		}
	}

	/*	Find matching Service List on screen
		Offer choice if no match
	*/
	Loop, % EpicSvcList.MaxIndex()
	{
		k := EpicSvcList[A_index]
		if IsObject(FindText(0,0,scr.w,scr.h,0.1,0.1,svcText[k])) {
			HndOff.Service := k
			break
		}
	}
	if (HndOff.Service="") {
		MsgBox No service found
		Gui, main:Show
		return
	}
	eventlog("Found service: " HndOff.Service)

	/*	Loop through each patient using hotkeys, update smart links,
		copy Illness Severity and Patient Summary fields to clipboard
	*/
	BlockInput, On
	loop,
	{
		timenow := A_now
		fld := readHndIllness(HndOff,done)
		if instr(done,fld.MRN) {														; break loop if we have read this record already
			Break
		}
		MRNstring := "/root/id[@mrn='" . fld.mrn . "']"
		if !IsObject(y.selectSingleNode(MRNstring)) {									; If no MRN node exists, create it.
			y.addElement("id", "root", {mrn: fld.mrn})
			y.addElement("demog", MRNstring)
			fetchGot := false
			FetchNode("diagnoses")														; Check for existing node in Archlist,
			FetchNode("notes")															; retrieve old Dx, Notes, Plan. (Status is discarded)
			FetchNode("plan")															; Otherwise, create placeholders.
			FetchNode("prov")
			FetchNode("data")
			eventlog("processHandoff " fld.mrn ((fetchGot) ? " pulled from archive":" new") ", added to active list.")
		} else {																		; Otherwise clear old demog & loc info.
			RemoveNode(MRNstring . "/demog")
			y.insertElement("demog", MRNstring . "/diagnoses")							; Insert before "diagnoses" node.
		}
		
		readHndSummary(HndOff,fld)
		res.push(fld)																	; push {MRN, Data, Summary} to RES

		SendInput, !n																	; Alt+n to move to next record
		scrcmp(HndOff.tabX,HndOff.NameY,100,15)											; detect when Name on screen changes
		
		done .= fld.MRN "`n"
	}
	BlockInput, Off
	Progress, Off

	filecheck()
	FileOpen(".currlock", "W")															; Create lock file.
	updateList(HndOff.Service,done)
	processHandoff(res)
	writeFile()
	FileDelete, .currlock

	MsgBox, 4, Print now?, % "Print list: " hndOff.Service
	IfMsgBox, Yes
	{
		PrintIt()
	}

	Gui, main:Show
	return res
}

checkHandoff() {
/*	Check if Handoff is running for this Patient List
	If not, start it
	Returns 
*/

/*	First stage: look for "Handoff" tab in right sidebar
		* Find section header geometry for "Illness Severity", "Patient Summary", "Action Item"
		* Find location of "Updates" (clapboard icon)
		* Calculate targets for text fields, CHIPOTLETEXT, name bar
		* Returns targets

*/
	global hndText, scr
	scale := scr.scale/100

	if (ok:=FindText(0,0,scr.w,scr.h,0.2,0.2,hndText.HandoffTab)) {
		progress, 40, Illness Severity, Finding geometry
		Ill := FindText(0,0,scr.w,scr.h,0.2,0.2,hndText.IllnessSev)
		progress, 80, Patient Summary, Finding geometry
		Summ := FindText(0,0,scr.w,scr.h,0.2,0.2,hndText.PatientSum)
		if !IsObject(Ill) {																; no Illness Severity field found
			gosub startHandoff															
			return
		}

		progress, 100, Updates, Finding geometry
		Upd := FindText(0,0,scr.w,scr.h,0.1,0.1,hndText.Updates)

		return { tabX:ok[1].x
				, IllnessY:Ill[1].y+80*scale
				, SummaryY:Summ[1].y+80*scale
				, NameY:Ill[1].y-72*scale
				, TextX:ill[1].x
				, TextY:Ill[1].y+56*scale
				, UpdateX:Upd[1].x+10
				, UpdateY:Upd[1].y+5 }
	} 
/*	Second stage: Look for Write Handoff button (single patient selected)
					or select single patient
*/
	startHandoff:
	if (ok:=FindText(0,0,1920,500,0.2,0.2,hndText.WriteHand)) {
		clickField(ok[1].x,ok[1].y)
		sleep 200
	} 

	ok:=FindText(0,0,1920,500,0.2,0.2,hndText.PatientNam)
	clickfield(ok[1].x,ok[1].y+50)
	sleep 200
	
	return
}

clickField(x,y,delay:=20) {
	MouseClick, Left, % x, % y
	sleep % delay
	MouseClick, Left, % x-5, % y+5
	sleep % delay
	return
}

getClip() {
	SendInput, ^a
	sleep 50
	SendInput, ^c
	sleep 150																			; Citrix needs time to copy to local clipboard
	return Clipboard
}

readHndIllness(ByRef HndOff, ByRef done) {
/*	Read the Illness Severity field
	Click twice (not double click) to ensure we are in field
*/
	progress, % A_index*10,% " ",% " "
	clickField(HndOff.tabX,HndOff.IllnessY,100)
	updateSmartLinks(HndOff.UpdateX,HndOff.UpdateY)

	Clipboard :=
	fld := []
	loop, 5																				; get 3 attempts to capture clipboard
	{
		progress,,% "Attempt " A_Index
		clickField(HndOff.tabX,HndOff.IllnessY,50)
		clp := getClip()
		if (clp="") {
			clickField(HndOff.tabX,HndOff.IllnessY)
			Continue
		} 
		if (clp="`r`n") {																; field is truly blank
			MsgBox 0x40021, Novel patient?, Insert CHIPOTLE smart text?`n, 3
			IfMsgBox Cancel
			{
				Break
			}
			clickField(HndOff.tabX,HndOff.IllnessY)
			SendInput, .chipotle{enter}													; type dot phrase to insert
			sleep 300
			ScrCmp(HndOff.TextX,HndOff.TextY,100,10)									; detect when text expands
			Continue
		}
		fld.MRN := strX(clp,"[MRN] ",1,6," [DOB]",0,6)									; clip changed from baseline
		fld.Data := clp
		progress,,,% fld.MRN
		break
	}
	if instr(done,fld.MRN) {															; break loop if we have read this record already
		return fld
	}

	return fld
}

readHndSummary(ByRef HndOff, ByRef fld) {
/*	Read the Patient Summary field
	Click twice (not double click) to ensure we are in field
*/
	global y, MRNstring, timenow

	card := y.selectSingleNode(MRNstring "/diagnoses/card")
	c_txt := card.Text
	c_dt := card.getAttribute("ed")
	epic := y.selectSingleNode(MRNstring "/diagnoses/summ")
	e_txt := epic.Text
	e_dt := epic.getAttribute("ed")

	Clipboard :=
	clickField(HndOff.tabX,HndOff.SummaryY)												; now grab the Patient Summary field 
	loop, 3
	{
		clickField(HndOff.tabX,HndOff.SummaryY,50)
		clp := getClip()
		if (clp="") {																	; nothing populated, try again
			clickField(HndOff.tabX,HndOff.SummaryY)
			Continue
		} 
		; Patient Summary is empty
		if (clp="`r`n") {
			if (c_txt="") {																; - if Card empty as well, then exit
				break
			} 
			Clipboard := c_txt															; - Card is present
			clickField(HndOff.tabX,HndOff.SummaryY)
			sleep 50
			SendInput, ^a
			sleep 50
			SendInput, ^v																; paste c_txt into Patient Summary
			ReplacePatNode(MRNstring "/diagnoses","summ",clp)
			y.selectSingleNode(MRNstring "/diagnoses/summ").setAttribute("ed",timenow)
			card.setAttribute("ed",timenow)
			eventlog(fld.mrn " Card diagnoses added to Handoff.")
			Break
		}
		clp := trim(clp,"`r`n ")
		clp := StrReplace(clp, "`r`n", "`n")
		; Patient Summary is not empty, but Diagnoses/Card is empty
		if (c_txt="") {
			ReplacePatNode(MRNstring "/diagnoses","card",clp)
			y.selectSingleNode(MRNstring "/diagnoses/card").setAttribute("ed",timenow)
			ReplacePatNode(MRNstring "/diagnoses","summ",clp)
			y.selectSingleNode(MRNstring "/diagnoses/summ").setAttribute("ed",timenow)
			eventlog(fld.mrn " Handoff summary added to Chipotle.")
			Break
		}
		; Patient Summary not empty, and Diagnoses/Card not empty
		if (c_txt=clp) {																; no changes, exit
			Break
		}
		if ((clp = e_txt) && (c_dt != e_dt)) {											; CARD changed but Epic unchanged
			Clipboard := c_txt															; most recent edit on Chipotle
			clickField(HndOff.tabX,HndOff.SummaryY)
			sleep 50
			SendInput, ^a
			sleep 50
			SendInput, ^v
			ReplacePatNode(MRNstring "/diagnoses","summ",c_txt)
			y.selectSingleNode(MRNstring "/diagnoses/summ").setAttribute("ed",c_dt)
			eventlog(fld.mrn " Card diagnoses changed, updated to Handoff.")
			Break
		}
		if (clp != e_txt) 					 {											; CLIP changed but CARD unchanged
			ReplacePatNode(MRNstring "/diagnoses","card",clp)							; must assume Epic change more recent
			y.selectSingleNode(MRNstring "/diagnoses/card").setAttribute("ed",timenow)
			ReplacePatNode(MRNstring "/diagnoses","summ",clp)
			y.selectSingleNode(MRNstring "/diagnoses/summ").setAttribute("ed",timenow)
			eventlog(fld.mrn " Handoff changed, updated to Chipotle.")
			Break
		}
		eventlog(fld.mrn " did not match rules.")
	}
	Return
}

updateSmartLinks(x,y) {
/*	Updates smart links by sending ctrl+F11 to the active window
	Arguments (x,y) are pixel coords to monitor change in Update icon
*/
	SendInput, !r
	sleep 100
	loop,
	{
		PixelGetColor, col, % x , % y
		; progress,,,% col
		if (col="0xFFFFFF") {
			break
		}
	}
	return
}

updateList(service,done) {
	global y, loc, location, locString, timenow

	location := Service
	locString := loc[location,"name"]

	RemoveNode("/root/lists/" . location)												; Clear existing /root/lists for this location
	y.addElement(location, "/root/lists", {date: timenow})								; Refresh this list
	Loop, Parse, done, `n, `r
	{
		k := A_LoopField
		if (k="") {
			Break
		}
		y.addElement("mrn", "/root/lists/" location, k)
	}
	
	; listsort(location)
	writefile()
	Gosub UpdateMainGui
	eventlog(location " list updated.")

	Return
}

processHandoff(ByRef epic) {
	global y, yArch
		, mrnstring, timenow, yMarDt
		, cicudocs, txpdocs
		, loc, location, locString
		, cis_list
	
	loop, % epic.MaxIndex()
	{
		clp := epic[A_Index].Data
		top := strX(clp,"",0,1,"<Data>",0,9)
		t1 := StregX(top,"--CHIPOTLE Sign Out ",0,1,"--",1)
		; Date := t1.YYYY t1.MM t1.DD t1.hr t1.min 
		nn:=1
		fld := []
		Loop
		{
			k := stregx(top,"\[\w+\]",nn,0," \[|\R+",1,nn)
			RegExMatch(k, "O)\[(.*)\] (.*)",match)
			if (match.value(1)="") {
				break
			}
			fld[match.value(1)] := Trim(match.value(2))
		}
		fld.time := t1
		fld.admit := parseDate(fld.admit).YMD
		fld.unit := (fld.room~="FA\.6.*-C")
			? "CICU-F6"
		: (fld.room~="FA\.6.*-P")
			? "PICU-F6"
		: (fld.room~="FA\.5.*-P")
			? "PICU-F5"
		: (fld.room~="RC\.6.*")
			? "SUR-RC6"
		: (fld.room~="RB\.6.*")
			? "SUR-RB6"
		: (fld.room~="RA\.6.*")
			? "NICU-R6"
		: (fld.room~="FA\.5.*-N")
			? "NICU-F5"
		: (fld.room~="FA\.3.*")
			? "PULM-F3"
		: fld.unit

		datatxt := parseTag(clp,"Data")
		vstxt := parseTag(datatxt,"vs")
		vs_bp := parseData(vstxt,"(BP)\s+(.*?)[\s\R]")
		vs_p := parseData(vstxt,"(Pulse)\s+(.*?)[\s\R]")
		vs_wt := parseData(vstxt,"(Wt).*?(\d.*)")
		vs_spo2 := parseData(vstxt,"(SpO2).*?(\d+)")
		vs_bsa := parseData(vstxt,"(BSA)\s+(.*?)\s")
		vs_sbp := maxMin(parseData(vstxt,"(Systolic).*?(Min.*?Max.*?)\s"))
		vs_dbp := maxMin(parseData(vstxt,"(Diastolic).*?(Min.*?Max.*?)\s"))
		vs_tmax := parseData(vstxt,"(Temp).*?Max:(.*?)\s")
		vs_wtchg := parseData(vstxt,"(Weight change):\s+(.*)")

		iotxt := parseTag(datatxt,"io")
		io_in := parseData(iotxt,"(In):\s(.*)")
		io_out := parseData(iotxt,"(Out):\s(.*)")

		ventTxt := trim(parseTag(datatxt,"vent"),"`r`n")

		labstxt := parseTag(clp,"Labs")
		abgtxt := parseData(labstxt,"(Art) pH.*?:\s+(.*)")
		cbctxt := parseData(labstxt,"(CBC) -\s+(.*)")
		ekgtxt := parseTag(labstxt,"ekg")
		
		medstxt := parseTag(clp,"Medications")
		meds_drips := stregx(medstxt,"\[DRIPS\]",1,1,"\[SCHEDULED\]",1)
		meds_sched := stregx(medstxt,"\[SCHEDULED\]",1,1,"\[PRN\]",1)
		meds_prn := stregx(medstxt,"\[PRN\]",1,1,"\[DIET\]",1)
		meds_diet := stregx(medstxt "<<<","\[DIET\]",1,1,"<<<",1)
		
		careteam := parseTag(clp,"Team")

		; Fill with demographic data
		MRNstring := "/root/id[@mrn='" . fld.mrn . "']"
		y.addElement("name_last", MRNstring . "/demog", fld.name_L)
		y.addElement("name_first", MRNstring . "/demog", fld.name_F)
		y.addElement("data", MRNstring . "/demog", {date: timenow})
		y.addElement("sex", MRNstring . "/demog/data", fld.sex)
		y.addElement("dob", MRNstring . "/demog/data", fld.dob)
		y.addElement("age", MRNstring . "/demog/data", fld.age)
		y.addElement("service", MRNstring . "/demog/data", fld.service)
		y.addElement("attg", MRNstring . "/demog/data", fld.attg)
		y.addElement("admit", MRNstring . "/demog/data", parseDate(fld.admit).YMD)
		y.addElement("unit", MRNstring . "/demog/data", fld.unit)
		y.addElement("room", MRNstring . "/demog/data", fld.room)
		
		; Capture each encounter
		if !IsObject(y.selectSingleNode(MRNstring "/prov/enc[@adm='" parseDate(fld.admit).YMD "']")) {
			y.addElement("enc", MRNstring "/prov", {adm:parseDate(fld.admit).ymd, attg:fld.attg, svc:fld.service})
		}

		; Remove the old Info nodes
		Loop % (infos := y.selectNodes(MRNstring "/info")).length
		{
			tmpdt := infos.Item(A_index-1).getAttribute("date")
			tmpTD := tmpdt
			tmpTD -= A_now, Days
			if ((tmpTD < -7) or (substr(tmpdt,1,8) = substr(A_now,1,8))) {				; remove old nodes or replace info/mar from today.
				RemoveNode(MRNstring "/info[@date='" tmpdt "']")
				continue
			}
			if (tmpTD < 1) {															; remove old info/hx and info/notes from nodes older than 1 day.
				RemoveNode(MRNstring "/info[@date='" tmpdt "']/hx")
				RemoveNode(MRNstring "/info[@date='" tmpdt "']/notes")
			}
		}
		; Remove old MAR except for this run.
		Loop % (infos := y.selectNodes(MRNstring "/MAR")).length
		{
			tmpdt := infos.Item(A_Index-1).getAttribute("date")
			if (tmpdt!=timenow) {
				RemoveNode(MRNstring "/MAR[@date='" tmpdt "']")
			}
		}
	
		y.addElement("info", MRNstring, {date: timenow})								; Create a new /info node
		yInfoDt := MRNstring . "/info[@date='" timenow "']"
			; y.addElement("wt", yInfoDt, fld.Wt)
			; y.addElement("allergies", yInfoDt, CORES.Alls)
			; y.addElement("code", yInfoDt, CORES.Code)
			; y.addElement("team", yInfoDt, CORES.Team)
			y.addElement("vs", yInfoDt)
				y.addElement("wt",   yInfoDt "/vs", {change:vs_wtchg}, vs_wt)
				y.addElement("bsa",  yInfoDt "/vs", vs_bsa)
				y.addElement("temp", yInfoDt "/vs", vs_tmax)
				y.addElement("p",    yInfoDt "/vs", vs_p)
				y.addElement("bp",   yInfoDt "/vs", vs_sbp "/" vs_dbp)
				y.addElement("spo2", yInfoDt "/vs", vs_spo2)
			y.addElement("vent", yInfoDt)
				y.addElement("vent", yInfoDt "/vent", ventTxt)
			y.addElement("io", yInfoDt )
				y.addElement("in",   yInfoDt "/io", io_in)
				y.addElement("out",  yInfoDt "/io", io_out)
				; y.addElement("ct",  yInfoDt "/io", CORES.ioCT)
				; y.addElement("net", yInfoDt "/io", CORES.ioNet)
				; y.addElement("uop", yInfoDt "/io", CORES.ioUOP)
			y.addElement("labs", yInfoDt )
				y.addElement("abg",  yInfoDt "/labs", abgtxt)
				y.addElement("cbc",  yInfoDt "/labs", cbctxt)
			y.addElement("studies", yInfoDt)
				y.addElement("ekg",  yInfoDt "/studies", ekgtxt)
		
		if !isobject(y.selectSingleNode(MRNstring "/MAR")) {
			y.addElement("MAR", MRNstring)											; Create a new /MAR node
		}
		y.selectSingleNode(MRNstring "/MAR").setAttribute("date", timenow)			; Change date to now
		if !(y.selectNodes(MRNstring "/MAR/*").length) {							; Populate only if empty
			yMarDt := MRNstring "/MAR[@date='" timenow "']"
			MedListParse("drips",meds_drips)
			MedListParse("meds",meds_sched)
			MedListParse("prn",meds_prn)
			MedListParse("diet",meds_diet)
		}
	writeOut("/root","id[@mrn='" . fld.mrn . "']")
	}
	Return
}

parseTag(txt,tag) {
/*	Read text between <tag>
	Returns text excluding tags
*/
	bs := "<" tag ">"
	es := "</" tag ">"
	x := stregx(txt,bs,1,1,es,1)
	return x
}

parseData(clp,set) {
/*	Scans for values in CLP using regex in SET
	Returns var1=label var2=field
*/
	RegExMatch(clp, "\R+" set, var)
	return var2
}

maxMin(txt) {
	txt := RegExReplace(txt, " |:|Min|Max")
	txt := StrReplace(txt, ",", "-")
	return txt
}

fmtMean(str) {
/*	from string " 78-140 124 "
 *	returns "78-140 (124)"
 */
str := trim(str," `t`r`n")
str := RegExReplace(str,"-[\s]+","-")
str := RegExReplace(str,"/[\s]+","/")
str := RegExReplace(str," ([^ ](.*))"," ($1)")

return str
}

ioVal(blk,str) {
/*	from IO block "blk"
 *	retrieve "str v1 v2 v3"
 *	where v1,v2,v3 = today,yesterday,2d ago
 *	or "str= val"
 *	return VAL
 */
ln := trim(stregX(blk,"^" str,1,0,"\R",1))
RegExMatch(ln,"\s([\d.-]+)\s*([\d.-]+)?\s*([\d.-]+)?",v)
return {v1:v1,v2:v2,v3:v3}
}

processSensis(txt) {
	Loop, files, .\files\data_in\sensis\*.HIS, F
	{
		FileRead, txt, % A_LoopFileFullPath
		
		readHIS(txt)
	}
}

readHIS(txt) {
	pipe := chr(0xB3)
	y := new XML("<root/>")

	Loop, parse, txt, `n, `r
	{
		i := A_LoopField
		if (i~="^Group:") {																; Line starts with "Group:"
			grp := 																		; Clear grp
			grp := strX(i,"Group:",1,6,"",0)											; Get new grp
			y.addElement("group","root",{name:grp})										; Create new <group> node
			grpStr := "/root/group[@name='" grp "']"
			continue
		} else if (i~="^Fields:") {														; Line starts with "Fields:"
			fields := []																; Clear fields array
			fld := trim(strX(i,"Fields:",1,7,"",0),pipe)								; Get new fld
			fields := StrSplit(fld,pipe)												; Create fields array
			continue
		} else if (i~=pipe) {															; Any other line containing pipe char is a result line
			values := []																; Clear values array
			val := trim(i,pipe)															; Get new val
			values := StrSplit(val,pipe)												; Create values array
			y.addElement("result",grpStr)												; Create new <result> node
			loop, % fields.length()														; Scan through each fields[] element
			{
				x := A_Index
				yv := y.createElement(fields[x])										; Get each fields[x] name
				yt := y.createTextNode(values[x])										; Get corresponding values[x] result
				y.selectSingleNode(grpStr).lastChild.appendChild(yv).appendChild(yt)	; To last <result>, append <field>value</field>
			}
		}
	}
	return y
}
