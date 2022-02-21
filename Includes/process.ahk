syncHandoff(restart:="") {
/*	The main loop for syncing between CHIPOTLE and Handoff
	Must be run from either PC or VDI so Epic window is visible to CHIPOTLE
	Cannot be run directly from Citrix (sister process does not "see" other Citrix windows)

*/
	global y, MRNstring, EpicSvcList, svcText, timenow, scr, gdi, EscActive

	if !(restart="Y") {
		MsgBox 0x31, Handoff Sync
			, % "Ready to start Handoff Sync?`n`n`n"
			. "This will take 1-2 minutes.`n`n"
			. "Do not touch your mouse or keyboard during the process.`n`n"
			. "[ctrl-esc] to cancel during sync."
		IfMsgBox OK, {
			
		} Else {
			return
		}
	}
	eventlog("Starting Handoff sync.")
	refreshCurr()																		; Get latest local currlist into memory
	Gui, main:Minimize
	res := {}

	/*	Find Epic instance
	*/
	if !(winEpic := WinExist("Hyperspace.*Production")) {
		MsgBox NO EPIC WINDOW!
		eventlog("No Epic window found.")
		Gui, main:Show
		Return
	}
	scr.winEpic := winEpic
	WinActivate ahk_id %winEpic%
	gdi_init()																			; create GDI canvas
	escActive := true


	/*	Check screen elements for Handoff, launch if necessary
		(this is much faster if already selected)
	*/
	loop, 5
	{
		HndOff := checkHandoff(winEpic)													; Check if Handoff running
		if IsObject(HndOff) {															; and find key UI coords
			break
		}
	}
	if !IsObject(HndOff) {
		MsgBox 0x40015, Handoff Sync, Failed to find Handoff panel.`n`nTry again?
		IfMsgBox, Retry
		{
			syncHandoff("Y")
			return
		} else {
			Progress, Off
			Gui, main:Show
			return
		}
	}
	/*	Make sure Illness Severity and Patient Summary sections are open
	*/
	Illness:=FindHndSection("IllnessSev",1)
	Summ:=FindHndSection("PatientSum",1)

	Progress, % "y" Illness.HeadY, Finding Geometry`n
		, `nSyncing Handoff...`n`nDo not touch mouse or keyboard!`n`n[ctrl-esc] to cancel`n
		, Handoff Sync

	/*	Find matching Service List on screen
		Offer choice if no match
	*/
	Progress,,Finding service
	Loop, % EpicSvcList.MaxIndex()
	{
		k := EpicSvcList[A_index]
		if IsObject(FindText(okx,oky,0,0,scr.W,scr.H,0.0,0.0,svcText[k])) {
			HndOff.Service := k
			HndOff.ServiceX := okx
			HndOff.ServiceY := oky-16
			break
		}
	}
	if (HndOff.Service="") {
		MsgBox No service found
		Gui, main:Show
		return
	}
	eventlog("Found service: " HndOff.Service)
	/*	Check if only 1 patient
	*/
	if FindText(okx,oky,0,0,scr.W,scr.H,0.0,0.0,svcText["JustOne"]) {
		HndOff.JustOne := true 
	}

	/*	Loop through each patient using hotkeys, update smart links,
		copy Illness Severity and Patient Summary fields to clipboard
	*/
	BlockInput, On
	loop,
	{
		/*	Populate fld with data from .CHIPOTLETEXT from Illness Severity 
		*/
		Progress,,Record %A_Index%
		; sleep 200																		; might need to sleep if selecting patients for deletion
		snap := Gdip_BitmapFromScreen(hndOff.PanelX+12 "|" hndOff.RoomY "|90|18")
		snap64 := Gdip_EncodeBitmapTo64string(snap,"png")
		Gdip_DisposeImage(snap)
		if (A_index=1) {
			snap0 := snap64																; base64 of first room number
		} else if (snap64=snap0) {
			Break																		; jump out when  reach first bitmap again
		} 

		timenow := A_now
		fld := readHndIllness(HndOff,done)
		if (fld="UNABLE") {																; Unable to edit Handoff error
			WinActivate % "ahk_id " scr.winEpic
			clickButton(HndOff.tabX,HndOff.tabY)
			SendInput, !n																; Alt+n to move to next record
			scrcmp(HndOff.tabX-100,HndOff.NameY,100,15)									; detect when Name on screen changes
			Continue
		}
		if (fld="MULTIPLE") {															; Multiple patients got selected somehow
			WinActivate % "ahk_id " scr.winEpic
			clickButton(HndOff.tabX,HndOff.tabY)
			SendInput, !n																
			scrcmp(HndOff.tabX-100,HndOff.NameY,100,15)									
			syncHandoff("Y")															; restart the cycl
			Return
		}
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
		
		/*	Update DIAGNOSIS field with Patient Summary
		*/
		WinActivate % "ahk_id " scr.winEpic
		readHndSummary(HndOff,fld)
		res.push(fld)																	; push {MRN, Data, Summary} to RES

		done .= fld.MRN "`n"
		
		/*	If only 1 patient
		*/
		if (hndOff.JustOne=true) {
			break
		}

		/*	Move to next patient
			Wait until name field changes with scrcmp() 
		*/
		WinActivate % "ahk_id " scr.winEpic
		Illness:=FindHndSection("IllnessSev")
		clickButton(Illness.EditX,Illness.EditY+20)
		SendInput, !n																	; Alt+n to move to next record
		scrcmp(Illness.EditX,HndOff.NameY,100,15)										; detect when Name on screen changes
		
		sleep 100
	}
	BlockInput, Off
	Progress, Off
	escActive := false

	filecheck()
	updateList(HndOff.Service,done)
	processHandoff(res)
	Progress,,% " ", Writing file...
	writeFile()
	Progress, Off

	MsgBox, 4, Print now?, % "Print list: " hndOff.Service
	IfMsgBox, Yes
	{
		PrintIt()
	}

	Gui, main:Show
	return res
}

checkHandoff(win) {
/*	Check if Handoff is running for this Patient List
	If not, start it and make sure Illness Severity and Patient Summary sections are open
*/

	global hndText, scr
	scale := scr.scale/100
	rtside := 0.5*scr.w

/*	look for "Handoff" tab in right sidebar
	* Open text sections
	* On success, return Handoff tabX, and Patient nameY values
*/
	WinActivate ahk_id %win%
	
	if (FindText(okx,oky,rtside,0,scr.w,scr.h,0.0,0.0,hndText.ArrowLt)) {				; Right panel is collapsed
		WinActivate ahk_id %win%
		clickButton(okX,okY)
		sleep 100
		return
	} else {
		FindText(panelX,panelY,rtside,0,scr.w,scr.h,0.0,0.0,hndText.ArrowRt)			; Right panel X
	}
	if (FindText(okx,oky,0,0,scr.w,scr.h,0.0,0.0,hndText.ArrowDn)) {					; Bottom panel is opened
		WinActivate ahk_id %win%
		clickButton(okX,okY)
		sleep 100
		return
	}
	if (FindText(okx,oky,rtside,0,scr.w,scr.h,0.0,0.0,hndText.NoPatient)) {				; Finds "No Patient Handoff" error
		WinActivate ahk_id %win%
		clickButton(ok[1].X,ok[1].Y)
		SendInput, !n																	; Alt+n to move to next record
		sleep 100
		return
	}
	
	if (ok:=FindText(okx,oky,rtside,0,scr.w,scr.h,0.0,0.0,hndText.HandoffTab)) {
		return { tabX:ok[1].x															; x.coord of Handoff sidetab
				, tabY:ok[1].y															; y.coord of Handoff sidetab
				, panelX:panelX
				, NameY:ok[1].y+round(36*scale)											; y.coord of Handoff Patient Name
				, roomY:ok[1].y+round(54*scale)											; y.coord of Handoff room number
				, null:""}
	} 
/*	Look for Write Handoff button (single patient selected)
	or select single patient
*/
	if (wrH:=FindText(okx,oky,0,0,rtside,500,0.0,0.0,hndText.WriteHand)) {
		WinActivate ahk_id %win%
		clickButton(wrH[1].x,wrH[1].y)
		sleep 500
	} 

	if (room:=FindText(okx,oky,0,0,rtside,500,0.2,0.2,hndText.RoomBed)) {
		WinActivate ahk_id %win%
		clickButton(room[1].x,room[1].y+50)
		sleep 500
	}
	
	return
}

FindHndSection(sect,open:="") {
/*	Find Handoff section
	sect - Section name from hndText.sect
	open - 1=click open closed section
	returns coords of upper L corner of section header, upper edge of edit box, null if fails
*/
	global hndText, scr

	rtside := 0.5*scr.w

	secHeader := FindText(okx,oky,rtside,0,scr.w,scr.h,0.0,0.0,hndText[sect])
	if !IsObject(secHeader) {															; no section header found (e.g. Illness Severity)
		if FindText(okx,oky,rtside,0,scr.w,scr.y,0.0,0.0,hndText.Unable) {				; Unable to edit Handoff message
			return "UNABLE"
		} else 
		if FindText(okx,oky,rtside,0,scr.w,scr.y,0.0,0.0,hndText.Multiple) {			; Multiple patients selected message
			return "MULTIPLE"
		} else {
			Return
		}
	}

	togDN := FindText(okx,oky,secHeader[1].x,secHeader[1][2],scr.w,secHeader[1][2]+secHeader[1][4],0.0,0.0,hndText.ToggleDN)
	if (open && togDN) {
		clickButton(secHeader[1].x,secHeader[1].y)
		sleep 100
		FindHndSection(sect,1)
	}
	togUP := FindText(okx,oky,secHeader[1].x,secHeader[1][2],scr.w,secHeader[1][2]+secHeader[1][4],0.0,0.0,hndText.ToggleUP)
	secToggle := (togUP ? "UP" 
		: togDN ? "DN"
		: "")
	loop, 3
	{
		secEdit := FindText(okx,oky,secHeader[1][1]-20,secHeader[1][2],secHeader[1][1]+200,secHeader[1][2]+200,0.1,0.1,hndText.EditBox)
		if (secEdit) {
			break
		}
	}

	return  { HeadX:secHeader.1.1
			, HeadY:secHeader.1.2
			, EditX:secEdit.1.1+secEdit.1.3
			, EditY:secEdit.1.2+secEdit.1.4
			, toggle:secToggle
			, null:"" }
}

clickField(x,y) {
/*	Click on text field with given coordinates (x,y)
	Click a second time with offset coords to ensure we are in the box
	*ver = (true,false) verify the text box is active
*/
	global hndText
	delay := 100

	Loop, 8
	{
		MouseClick, Left, % x, % y
		MouseClick, Left, % x+10, % y+10
		
		if (FindText(okx,oky,x,y-100,x+100,y+100,0.0,0.0,hndText.ActiveBox)) {
			ver:=True
		}
		if (ver) {
			break
		}
	}
	return
}

clickButton(x,y) {
	delay := 100
	MouseClick, Left, % x, % y
	Return
}

getClip(k) {
	str := "^" k
	SendInput, ^a
	SendInput, % str
	sleep 150																			; Citrix needs time to copy to local clipboard
	return Clipboard
}

readHndIllness(ByRef HndOff, ByRef done) {
/*	Read the Illness Severity field
	Click twice (not double click) to ensure we are in field
*/
	global scr
	WinActivate % "ahk_id " scr.winEpic
	Illness:=FindHndSection("IllnessSev",1)
	if !IsObject(Illness) {																; no object, return error string
		return Illness
	}

	Clipboard :=
	fld := []
	loop, 5																				; get 5 attempts to capture clipboard
	{
		progress, % 20*A_Index
		WinActivate % "ahk_id " scr.winEpic
		clickField(Illness.EditX+100, Illness.EditY+16)
		clp := getClip("x")
		if (clp="") {
			sleep 50
			Continue
		} 
		if (clp="`r`n") {																; field is truly blank
			WinActivate % "ahk_id " scr.winEpic
			clickField(Illness.EditX+100, Illness.EditY+16)
			SendInput, .chipotletext{enter}												; type dot phrase to insert
			clipbdWait(Illness.EditX-50, Illness.EditY)									; Wait for Clipbd icon after text expansion
			clipsent := true
			Continue
		} 
		if !(clipsent) {
			if instr(clp,"--CHIPOTLE Sign Out") {
				continue
			} else {
				clp0 := trim(clp,"`r`n")
				Continue
			}
		}
		WinActivate % "ahk_id " scr.winEpic
		clickfield(Illness.EditX+100, Illness.EditY+16)
		if (clp0) {
			Clipboard := clp0
			; sleep 150
			getClip("v")
			SendInput, {Right}
		} else {
			SendInput, {del}
		}
		fld.MRN := strX(clp,"[MRN] ",1,6," [DOB]",0,6)									; clip changed from baseline
		fld.Data := clp
		progress,,% "Found " fld.MRN
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

	y.diagnoses/summ = Epic patient summary with timestamp
	y.diagnoses/card = Chipotle diagnoses with timestamp
*/
	global y, MRNstring, timenow, scr
	
	card := y.selectSingleNode(MRNstring "/diagnoses/card")
	c_txt := card.Text																	; Text from diagnoses/card
	c_dt := card.getAttribute("ed")														; last saved DT
	epic := y.selectSingleNode(MRNstring "/diagnoses/summ")
	e_txt := epic.Text																	; Text from last Patient Summary
	e_dt := epic.getAttribute("ed")														; last saved DT

	WinActivate % "ahk_id " scr.winEpic
	summ := FindHndSection("PatientSum",1)
	Clipboard :=
	loop, 7
	{
		WinActivate % "ahk_id " scr.winEpic
		clickField(summ.EditX,summ.EditY+20)											; grab the Patient Summary field
		clp := getClip("c")
		SendInput, {Right}
		if (clp="") {																	; nothing populated, try again
			sleep 50
			Continue
		} 

		/*	Patient Summary is empty
		*/
		if (clp="`r`n") {
			if (c_txt="") {																; - if Card empty as well, then exit
				break
			} 
			Clipboard := c_txt															; - Card is present
			summReplace(summ)
			ReplacePatNode(MRNstring "/diagnoses","summ",clp)
			y.selectSingleNode(MRNstring "/diagnoses/summ").setAttribute("ed",timenow)
			card.setAttribute("ed",timenow)
			eventlog(fld.mrn " Card diagnoses added to Handoff.")
			Break
		}

		/*	Patient Summary is not empty
		*/
 		clp := trim(clp,"`r`n ")
		clp := StrReplace(clp, "`r`n", "`n")
		charsub := false
		
		; Check for illegal characters
		if instr(clp,chr(160)) {
			clp := StrReplace(clp,chr(160)," ")
			charsub := true
		}

		; ... Diagnoses/Card is empty
		if (c_txt="") {
			ReplacePatNode(MRNstring "/diagnoses","card",clp)
			y.selectSingleNode(MRNstring "/diagnoses/card").setAttribute("ed",timenow)
			ReplacePatNode(MRNstring "/diagnoses","summ",clp)
			y.selectSingleNode(MRNstring "/diagnoses/summ").setAttribute("ed",timenow)
			eventlog(fld.mrn " Handoff summary added to Chipotle.")

			if (charsub) {
				clipboard := clp														; replace Summary with fixed chars
				summReplace(summ)
				eventlog(fld.mrn " Summary replaced charsub")
			}

			Break
		}

		; ... Diagnoses/Card not empty
		if (c_txt=clp) {																; no changes, exit
			Break
		}

		if ((clp = e_txt) && (c_dt != e_dt)) {											; CARD changed but Epic unchanged
			Clipboard := c_txt															; most recent edit on Chipotle
			summReplace(summ)
			ReplacePatNode(MRNstring "/diagnoses","summ",c_txt)
			y.selectSingleNode(MRNstring "/diagnoses/summ").setAttribute("ed",c_dt)
			eventlog(fld.mrn " Card diagnoses changed, updated to Handoff.")

			if (charsub) {
				clipboard := clp														; replace Summary with fixed chars
				summReplace(summ)
				eventlog(fld.mrn " Summary replaced charsub")
			}

			Break
		}

		if (clp != e_txt) {					 											; CLIP changed but CARD unchanged
			ReplacePatNode(MRNstring "/diagnoses","card",clp)							; must assume Epic change more recent
			y.selectSingleNode(MRNstring "/diagnoses/card").setAttribute("ed",timenow)
			ReplacePatNode(MRNstring "/diagnoses","summ",clp)
			y.selectSingleNode(MRNstring "/diagnoses/summ").setAttribute("ed",timenow)
			eventlog(fld.mrn " Handoff changed, updated to Chipotle.")

			if (charsub) {
				clipboard := clp														; replace Summary with fixed chars
				summReplace(summ)
				eventlog(fld.mrn " Summary replaced charsub")
			}

			Break
		}
		eventlog(fld.mrn " did not match rules.")
	}
	Return
}

summReplace(ByRef summ) {
/*	Replace Patient Summary with clipboard
*/
	global scr

	WinActivate % "ahk_id " scr.winEpic
	clickField(summ.EditX,summ.EditY)
	getClip("v")
	SendInput, {Right}
	Return
}

clipbdWait(x,y,x2,h) {
/*	Search for clipboard from (x,y) to (x+100,y+100)
*/
	global hndText
	timeout:=7
	tick:=50
	t1 := A_TickCount+1000*timeout

	While, (A_tickcount < t1)
	{
		if IsObject(ok:=FindText(okx,oky,x,y,x2,y+h,0.0,0.0,hndText.Clipbd)) {
			Return
		}
		Sleep, % tick
	}
	Return
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
		, cis_list, unitloc
	
	totalIndex := epic.MaxIndex()
	loop, % totalIndex
	{
		Progress, % 100*A_Index/totalIndex,, % epic[A_Index].MRN
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
		loop, % unitloc.Length()
		{
			unitrx := StrSplit(unitloc[A_Index],":")
			if (fld.room~=unitrx[1]) {
				fld.unit := unitrx[2]
				Break
			}
		}

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
		ekgtxt := strX(parseTag(labstxt,"ekg"),"Narrative`r`n",1,9,"",0,1)
		echotxt := parseTag(labstxt,"echo")
			echotmp := parseDate(stregX(echotxt,"Study Date:",1,1,"Sex:",1))
			echodt := echotmp.YMD echotmp.hr echotmp.min echotmp.sec
			echosumm := stregX(echotxt
				,"Exam Location:",1,0
				,"(Segmental Cardiotype,|Systemic Veins:|Pulmonary Veins:|Atria:|Mitral Valve:|Tricuspid Valve:)",1)
		
		medstxt := parseTag(clp,"Medications")
		meds_drips := stregx(medstxt,"\[DRIPS\]",1,1,"\[SCHEDULED\]",1)
		meds_sched := stregx(medstxt,"\[SCHEDULED\]",1,1,"\[PRN\]",1)
		meds_prn := stregx(medstxt,"\[PRN\]",1,1,"\[DIET\]",1)
		meds_diet := stregx(medstxt "<<<","\[DIET\]",1,1,"<<<",1)
		
		careteam := parseTag(clp,"Team")

		; Fill with demographic data
		MRNstring := "/root/id[@mrn='" . fld.mrn . "']"
		y.addElement("name_last", MRNstring . "/demog", format("{:U}",fld.name_L))
		y.addElement("name_first", MRNstring . "/demog", format("{:U}",fld.name_F))
		y.addElement("data", MRNstring . "/demog", {date: timenow})
		y.addElement("sex", MRNstring . "/demog/data", format("{:T}",fld.sex))
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
				y.addElement("echo", yInfoDt "/studies", {date:echodt}, echosumm)
		
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

;Create a canvas using GDI+. Values in global var gdi.
gdi_init() {
	global gdi, scr

	gdi := []
	If !(gdi.pToken := Gdip_Startup())
	{
		MsgBox "Gdiplus failed to start. Please ensure you have gdiplus on your system"
		ExitApp
	}
	Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
	Gui, 1: Show, NA
	gdi.hwnd1 := WinExist()																; window handle
	gdi.hbm := CreateDIBSection(scr.w, scr.h)											; gdi bitmap
	gdi.hdc := CreateCompatibleDC()														; device context
	gdi.obm := SelectObject(gdi.hdc, gdi.hbm)											; select bitmap
	gdi.G := Gdip_GraphicsFromHDC(gdi.hdc)												; pointer to graphics
	Gdip_SetSmoothingMode(gdi.G, 4)														; smoothing mode to antialias=4 

	return
}

;Clear the canvas created. Shutdown Gdip.
gdi_clear() {
	global gdi

	SelectObject(gdi.hdc, gdi.obm)
	DeleteObject(gdi.hbm)
	DeleteDC(gdi.hdc)
	Gdip_DeleteGraphics(gdi.G)

	Gui, 1:destroy
	Gdip_Shutdown(gdi.pToken)
	
	Return
}

draw_crosshair(x,y,r:=20,type:="") {
	global gdi, scr
	
	pPen := Gdip_CreatePen(0xffff0000, 1)
	Gdip_DrawLine(gdi.G, pPen, x-1,y-1,x+1,y+1)
	Gdip_DrawLine(gdi.G, pPen, x-1,y+1,x+1,y-1)

	if (type="X") {
		Gdip_DrawLine(gdi.G, pPen, x-r,y-r,x-10,y-10)
		Gdip_DrawLine(gdi.G, pPen, x-r,y+r,x-10,y+10)
		Gdip_DrawLine(gdi.G, pPen, x+r,y-r,x+10,y-10)
		Gdip_DrawLine(gdi.G, pPen, x+r,y+r,x+10,y+10)
	} else {
		Gdip_DrawLine(gdi.G, pPen, x,y-r,x,y-10)
		Gdip_DrawLine(gdi.G, pPen, x,y+r,x,y+10)
		Gdip_DrawLine(gdi.G, pPen, x-r,y,x-10,y)
		Gdip_DrawLine(gdi.G, pPen, x+r,y,x+10,y)
	}

	Gdip_DeletePen(pPen)
	UpdateLayeredWindow(gdi.hwnd1, gdi.hdc, 0,0, scr.w, scr.h)

	return
}

draw_box(x,y,w,h) {
	global gdi, scr
	
	pPen := Gdip_CreatePen(0xffff0000, 1)
	Gdip_DrawRectangle(gdi.G,pPen,x,y,w,h)
	Gdip_DeletePen(pPen)
	UpdateLayeredWindow(gdi.hwnd1, gdi.hdc, 0,0, scr.w, scr.h)

	Return
}

Gdip_EncodeBitmapTo64string(pBitmap, ext, Quality=75) {
/*	Taken from https://github.com/iseahound/Vis2/
*/
	if Ext not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
		return -1
	Extension := "." Ext

	DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
	VarSetCapacity(ci, nSize)
	DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, Ptr, &ci)
	if !(nCount && nSize)
	return -2



	Loop, %nCount%
	{
			sString := StrGet(NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize), "UTF-16")
			if !InStr(sString, "*" Extension)
				continue

			pCodec := &ci+idx
			break
	}


	if !pCodec
		return -3

	if (Quality != 75)
	{
		Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
		if Extension in .JPG,.JPEG,.JPE,.JFIF
		{
				DllCall("gdiplus\GdipGetEncoderParameterListSize", Ptr, pBitmap, Ptr, pCodec, "uint*", nSize)
				VarSetCapacity(EncoderParameters, nSize, 0)
				DllCall("gdiplus\GdipGetEncoderParameterList", Ptr, pBitmap, Ptr, pCodec, "uint", nSize, Ptr, &EncoderParameters)
				Loop, % NumGet(EncoderParameters, "UInt")
				{
				elem := (24+(A_PtrSize ? A_PtrSize : 4))*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
				if (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)
				{
						p := elem+&EncoderParameters-pad-4
						NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20, "UInt")), "UInt")
						break
				}
				}
		}
	}

	DllCall("ole32\CreateStreamOnHGlobal", "ptr",0, "int",true, "ptr*",pStream)
	DllCall("gdiplus\GdipSaveImageToStream", "ptr",pBitmap, "ptr",pStream, "ptr",pCodec, "uint",p ? p : 0)

	DllCall("ole32\GetHGlobalFromStream", "ptr",pStream, "uint*",hData)
	pData := DllCall("GlobalLock", "ptr",hData, "uptr")
	nSize := DllCall("GlobalSize", "uint",pData)

	VarSetCapacity(Bin, nSize, 0)
	DllCall("RtlMoveMemory", "ptr",&Bin , "ptr",pData , "uint",nSize)
	DllCall("GlobalUnlock", "ptr",hData)
	DllCall(NumGet(NumGet(pStream + 0, 0, "uptr") + (A_PtrSize * 2), 0, "uptr"), "ptr",pStream)
	DllCall("GlobalFree", "ptr",hData)
	
	DllCall("Crypt32.dll\CryptBinaryToString", "ptr",&Bin, "uint",nSize, "uint",0x01, "ptr",0, "uint*",base64Length)
	VarSetCapacity(base64, base64Length*2, 0)
	DllCall("Crypt32.dll\CryptBinaryToString", "ptr",&Bin, "uint",nSize, "uint",0x01, "ptr",&base64, "uint*",base64Length)
	Bin := ""
	VarSetCapacity(Bin, 0)
	VarSetCapacity(base64, -1)

	return base64
}

