processCIS(clip) {
	global y, yArch
		, mrnstring, timenow
		, cicudocs, txpdocs
		, loc, location, locString
		, cis_list
	filecheck()
	refreshCurr()																		; Get latest local currlist into memory
	
	cis_list := readCisCol()															; Parse clip into cols
	tmp:=matchCisList()																	; Score cis_list vs all available lists
	MsgBox, 3, % "Confirm " loc[tmp.list,"name"] ;" = " tmp.score
	 , % """" loc[tmp.list,"name"] """ list detected`n"
	 . ((tmp.score < 50) ? "but low match score (" tmp.score "%)`n`n" : "`n")
	 . "Yes = Update this list`n"
	 . "No = Select different list`n"
	 . "Cancel = Oops. Didn't mean to do that`n"
	IfMsgBox, Yes
	{
		location:=tmp.list																; Set location= best match list
		locString := loc[location,"name"]												; Set locString for display
		eventlog("Accepted " location)
		Gosub UpdateMainGui
	} 
	IfMsgBox, No 
	{
		eventlog("Clicked NO.")
		Gosub QueryList																	; Better ask
		WinWaitClose, CIS List
		if !(locString) {						; Avoids error if exit QueryList
			eventlog("Exit QueryList.")
			return								; without choice.
		}
		eventlog("Selected " location)
		tmp.score := (tmp[location] > 0) ? tmp[location] : 0							; Set score to score for selected list
	}
	IfMsgBox, Cancel 
	{																	; Oops. Don't process!
		locString := ""
		eventlog("Cancelled selection.")
		return
	}
	
	FileOpen(".currlock", "W")															; Create lock file.
	RemoveNode("/root/lists/" . location)												; Clear existing /root/lists for this location
	y.addElement(location, "/root/lists", {date: timenow})								; Refresh this list
	for k,v in cis_list
	{
		y.addElement("mrn", "/root/lists/" location, v)
	}
	
	listsort(location)
	writefile()
	eventlog(location " list updated.")
	FileDelete, .currlock
		
	MsgBox, 4, Print now?, Print list: %locString%
	IfMsgBox, Yes
	{
		PrintIt()
	}
Return
	
	
}

readCISCol(location:="") {
	global y, yArch, mrnstring, clip, timenow, cicudocs, txpdocs, fetchgot
	clip_elem := Object()						; initialize the arrays
	scan_elem := Object()
	clip_array := Object()
	list := object()
	colTmp := {"FIN":0, "MRN":0, "Sex":0, "Age":0, "Adm":0, "DOB":0, "Days":0, "Room":0, "Unit":0, "Locn":0, "Attg":0, "Name":0, "Svc":0}

; First pass: parse fields into arrays and field types
	colIdx := colTmp.Clone()
	Loop, parse, clip, `n, `r%A_Tab%%A_Space%									; Scan entire clip
	{
		clip_num := A_Index														; "Row" number
		clip_full := A_LoopField												; Entire row
		If (clip_full) break
		Loop, parse, clip_full, %A_Tab%											; Scan tab-delimited columns
		{
			i:=A_LoopField														; Get each cell val
			j:=fieldType(i)														; Returns key index if matches key regex
			clip_elem[clip_num,A_Index] := i									; Place each element into an array
			scan_elem[clip_num,A_Index] := j									; parallel array with best guess field type
		}
	}
; Second pass: scan through each column (length determined by first row)
	loop, % scan_elem[1].MaxIndex()
	{
		scan_col := A_Index
		colval := colTmp.Clone()
		Loop, % scan_elem.MaxIndex()											; read each row
		{
			colval[scan_elem[A_Index,scan_col]] ++								; increment counter for found type
		}
		bestcol := 0
		bestK := ""
		for k,v in colval														; scan each type
		{
			if (v>bestcol) {
				bestcol := v													; find highest matching column
				bestK := k
			}
		}
		if !(colIdx[bestk]) and ((bestCol/scan_elem.MaxIndex()) > 0.6) {		; store best column for each type
			colIdx[bestK] := scan_col
		}
	}
	if !(colIdx["Locn"]) {													; No Location column
		if !(colIdx["Unit"]) {												; Check for Unit
			eventlog("*** Missing 'Nurse Unit' column.")
			colErr .= "Nurse Unit`n"
		}
		if !(colIdx["Room"]) {												; and Room columns
			eventlog("*** Missing 'Room' column.")
			colErr .= "Room`n"
		}
	}
; Third pass: parse array elements according to identified field types
	filecheck()
	FileOpen(".currlock", "W")															; Create lock file.

	Loop, % (maxclip:=clip_elem.MaxIndex())
	{
		clip_num := A_Index	
		CIS_mrn := clip_elem[clip_num,colIdx["MRN"]]				; MRN
			MRNstring := "/root/id[@mrn='" . CIS_mrn . "']"
		if (CIS_mrn = "") {											; skip if null
			continue
		}
		CIS_name := clip_elem[clip_num,colIdx["Name"]]
			CIS_name := RegExReplace(CIS_name,"'","``")
			CIS_name_last := Trim(StrX(CIS_name, ,0,0, ", ",1,2))		; Last name
			CIS_name_first := Trim(StrX(CIS_name, ", ",0,2, " ",1,0))	; First name
		if (colIdx["Locn"]) {
			CIS_loc := clip_elem[clip_num,colIdx["Locn"]]
			CIS_loc_unit := StrX(CIS_loc, ,0,0, " ",1,1)			; Unit
			CIS_loc_room := StrX(CIS_loc, " ",1,1, " ",1,0)			; Room number
		} else {
			CIS_loc_room := clip_elem[clip_num,colIdx["Room"]]		; No Location column
			CIS_loc_unit := clip_elem[clip_num,colIdx["Unit"]]		; Get Room and Unit separately
		}
		CIS_attg := clip_elem[clip_num,colIdx["Attg"]]					; Attending
			StrX(CIS_attg,",",1,2," ",1,2,n )							; Get ATTG last,first name
			CIS_attg := substr(CIS_attg,1,n)
		CIS_adm_full := clip_elem[clip_num,colIdx["Adm"]]				; Admit date/time
			i := parseDate(StrX(CIS_adm_full, ,0,0, " ",1,0))
			CIS_admit := i.YYYY . i.MM . i.DD
		CIS_sex := clip_elem[clip_num,colIdx["Sex"]]					; Sex
		CIS_age := clip_elem[clip_num,colIdx["Age"]]					; Age
		CIS_svc := clip_elem[clip_num,colIdx["Svc"]]					; Service
		CIS_dob := clip_elem[clip_num,colIdx["DOB"]]					; DOB
		;															Now fix some issues we have with CIS labelling
		if (ObjHasValue(cicuDocs,CIS_attg) and !(RegExMatch(CIS_svc,"i)(Cardiology)|(Cardiac Surgery)|(Cardiac Transplant)"))) {
			CIS_svc := "Cardiac Surgery"
		}
		if (CIS_name_last="ZTEST")
			continue
		if !IsObject(y.selectSingleNode(MRNstring)) {				; If no MRN node exists, create it.
			y.addElement("id", "root", {mrn: CIS_mrn})
			y.addElement("demog", MRNstring)
			fetchGot := false
			FetchNode("diagnoses")									; Check for existing node in Archlist,
			FetchNode("notes")										; retrieve old Dx, Notes, Plan. (Status is discarded)
			FetchNode("plan")										; Otherwise, create placeholders.
			FetchNode("prov")
			FetchNode("data")
			eventlog("processCIS " CIS_mrn ((fetchGot) ? " pulled from archive":" new") ", added to active list.")
		} else {													; Otherwise clear old demog & loc info.
			RemoveNode(MRNstring . "/demog")
			y.insertElement("demog", MRNstring . "/diagnoses")		; Insert before "diagnoses" node.
		}
		; Fill with data from CIS list.
		y.addElement("name_last", MRNstring . "/demog", CIS_name_last)
		y.addElement("name_first", MRNstring . "/demog", CIS_name_first)
		y.addElement("data", MRNstring . "/demog", {date: timenow})
		y.addElement("sex", MRNstring . "/demog/data", CIS_sex)
		y.addElement("dob", MRNstring . "/demog/data", CIS_dob)
		y.addElement("age", MRNstring . "/demog/data", CIS_age)
		y.addElement("service", MRNstring . "/demog/data", CIS_svc)
		y.addElement("attg", MRNstring . "/demog/data", CIS_attg)
		y.addElement("admit", MRNstring . "/demog/data", CIS_adm_full)
		y.addElement("unit", MRNstring . "/demog/data", CIS_loc_unit)
		y.addElement("room", MRNstring . "/demog/data", CIS_loc_room)
		
		; Capture each encounter
		if !IsObject(y.selectSingleNode(MRNstring "/prov/enc[@adm='" CIS_admit "']")) {
			y.addElement("enc", MRNstring "/prov", {adm:CIS_admit, attg:CIS_attg, svc:CIS_svc})
		}
		
		; Auto label Transplant patients admitted by Txp attg
		if !IsObject(y.selectSingleNode(MRNstring "/status")) {							; If no status, add it.
			y.addElement("status", MRNstring)
		}
		if (ObjHasValue(txpDocs,CIS_attg)) {											; If matches TxpDocs list
			y.selectSingleNode(MRNstring "/status").setAttribute("txp", "on")			; Set status flag.
		}
		
		list.push(CIS_mrn)											; add MRN to list
		
		; Add Cardiology/SURGCNTR patients to SURGCNTR list, these are cath patients, will fall off when discharged?
		if (CIS_svc="Cardiology" and CIS_loc_unit="SURGCNTR") {
			SurgCntrPath := "/root/lists/SURGCNTR"
			if !IsObject(y.selectSingleNode(SurgCntrPath)) {
				y.addElement("SURGCNTR","/root/lists", {date:timenow})
			}
			if !IsObject(y.selectSingleNode(SurgCntrPath "/mrn[text()='" CIS_mrn "']")) {
				y.addElement("mrn", SurgCntrPath, CIS_mrn)
			}
		}
	}
	filedelete, .currlock
	progress off
	if (colErr) {
		MsgBox,,Columns Error, % "This list is missing the following columns:`n`n" colErr "`nPlease repair CIS settings."
	}
	return list
}

matchCisList() {
	global y, cis_list, loc
	arr := object()
	for key,grp in loc																	; key=num, grp=listname
	{
		if !strlen(grp) {
			continue
		}
		comp := object()																; clear comp(arison) array
		loop % (cur := y.selectNodes("/root/lists/" grp "/mrn")).length
		{
			comp.push(cur.item(A_index-1).text)											; add all <val/mrn> to comp
		}
		totC := comp.Length()															; totC= total MRN in comp
		totL := cis_list.Length()														; totL= total MRN in cis_list
		
		hit := miss := left := perc := 0												; fresh scores for each list
		for k,mrn in cis_list															; run through new cis_list
		{
			if (i:=objHasValue(comp,mrn)) {												; if present in comp list,
				hit += 1																; score hit
				comp.RemoveAt(i)														; remove from comp
			} else {
				miss += 1																; debit from this list
			}
		}
		
		left := totC-hit																; debit unmatched in comp
		
		;~ perc := round((100+100*(2*hit-(miss+left))/(totC+totL))/2,2)					; percent match
		perc := round((200+100*((hit/totC)-(miss/totL)-(left/totC)))/3,2)				; new percent match score
		arr[grp] := perc																; save score for each group
		
		if (perc>best) {																; remember best perc score and list group
			best := perc
			res := grp
		}
		list := "L" totL " C" totC "  ||  " 
		. "H" hit " M" miss " L" round(left) "  ||  " 
		. perc "% " grp
		eventlog(list)
	}
	arr.list := res																		; add best group
	arr.score := best																	; and best score to arr[]
	eventlog("Predicts " res " (" best ").")
	
	return arr
}

processCORES(clip) {
	global y, yArch
		, GUIcoresTXT, GUIcoresChk, timenow
		, CORES_Pt, CORES_Pg, CORES_end
		, yMarDT, MRNstring, fetchgot
	filecheck()
	refreshCurr()
	
	FileOpen(".currlock", "W")															; Create lock file.
	RemoveNode("/root/lists/cores")														; clear out <lists/cores>
	y.addElement("cores", "/root/lists", {date: timenow})								; create new dated <lists/cores>
	
	GuiControl, Main:Text, GUIcoresTXT, %timenow%										
	GuiControl, Main:Text, GUIcoresChk, ***
	Gui, Main:Submit, NoHide
	N:=1, n0:=0, n1:=0
	StringReplace, clip, clip, % cores_pt, % cores_pt, UseErrorLevel
	totPt := ErrorLevel
	
	while (clip) {																		; parse through CLIP
		ptBlock := stregX(clip															; get each "Patient Information" block
			, CORES_Pt,N,1																; N = position in CLIP
			, CORES_Pt "|" CORES_Pg "|" CORES_end,1,N)									; match to next pt, next page, or end
		if (ptBlock = "") {
			break															 			; end of clip reached
		}
		
		NN := 1																			; NN = position in ptBlock
		cores := []																		; Reset CORES obj
		
		cores.demog := stregX(ptBlock,"",1,0,"DOB:",1)									; DEMOGRAPHICS block
		cores.loc := stregX(cores.demog,"",1,0,"\R+",0,NN)
		cores.name := stregX(cores.demog,"",NN,0,"\R+",0,NN)
			cores.name_last := Trim(StrX(cores.name,"",0,0, ",",1,1))
			cores.name_first := Trim(StrX(cores.name,",",1,1, "",0))
		RegExMatch(cores.demog,"\d{6,7}",tmp,NN)
		cores.mrn := tmp
		Progress, % 100*(n0+1)/totPt, % cores.name, % CORES.mrn
		
		cores.DCW := stregX(ptBlock,"DCW: ",1,1,"\R",1,NN)								; skip to line 5
		cores.Alls := stregX(ptBlock,"Allergy: ",1,1,"\R",1,NN)							; line 6
		cores.Code := stregX(ptBlock,"Code Status: ",1,1,"\R",1,NN)						; line 7
		
		cores.Hx := stregX(ptBlock,"",NN,0,"Medications.*(DRIPS|SCH MEDS)",1,NN)
			;~ cores.Hx := RegExReplace(cores.Hx,"* ","* ")								; was breaking gitkraken
		cores.Diet := stregX(cores.Hx "<<<","^\s*Diet *",1,1,"<<<",1)
			cores.Diet := RegExReplace(cores.Diet,"Diet \*","*")
		
		cores.MedBlock := stregX(ptBlock,"Medications",NN,1,"Vitals",1,NN) "<<<"
			cores.Drips := stregX(cores.MedBlock,"Drips\R",1,1,"SCH MEDS|PRN|ANTIBIOTICS|<<<",1)
			cores.Meds := stregX(cores.MedBlock,"SCH MEDS\R",1,1,"SCH MEDS|PRN|ANTIBIOTICS|<<<",1)
			cores.PRN := stregX(cores.MedBlock,"PRN\R",1,1,"SCH MEDS|PRN|ANTIBIOTICS|<<<",1)
			cores.Abx := stregX(cores.MedBlock,"ANTIBIOTICS\R",1,1,"SCH MEDS|PRN|ANTIBIOTICS|<<<",1)
		
		cores.vs := stregX(ptBlock,"Vitals",NN,1,"Ins/Outs",1,NN)
			cores.vsWt := trim(stregX(cores.vs,"Meas Wt:",1,1,"\R",0,NNN)," `r`n")
			cores.vsWt := !instr(cores.vsWt,"No current data available") ?: "n/a"
			cores.vsTmp := fmtMean(stregX(cores.vs,"^T ",NNN,1,"HR ",1,NNN))
			cores.vsHR := fmtMean(stregX(cores.vs,"HR ",NNN,1,"MHR",1,NNN))
			cores.vsRR := fmtMean(stregX(cores.vs,"RR ",NNN,1,"\R",1,NNN))
			cores.vsNBP := fmtMean(stregX(cores.vs,"NI?BP ",NNN,1,"\R",1,NNN))
			cores.vsVent := stregX(cores.vs,"",NNN,0,"SpO2",1,NNN)
			cores.vsSat := fmtMean(stregX(cores.vs,"SpO2",NNN,1,"\R",1,NNN))
			cores.vsPain := fmtMean(stregX(cores.vs,"Pain Score",NNN,1,"\R",1,NNN))
		cores.io := stregX(ptBlock,"Ins/Outs",NN,1,"Labs \(72 Hrs\)",1,NN)
			cores.ioIntake := ioVal(cores.io,"Intake").v2
			cores.ioOutput := ioVal(cores.io,"Output").v2
			cores.ioCT := ioVal(cores.io,"Chst Tube").v2
			cores.ioUOP := ioVal(cores.io,"UOP").v1
			cores.ioNet := ioVal(cores.io,"IO Net").v1
		cores.labsBlock := stregX(ptBlock ">>>","Labs (.*)? / Studies",NN,1,">>>",1,NN)
			cores.labs := trim(stregX(cores.labsBlock,"",1,1,"^(Studies|Notes)",1))
			cores.studies := trim(stregX(cores.labsBlock ">>>","^Studies",1,1,"^(Notes|>>>)",1))
			cores.notes := RegExReplace(trim(stregX(cores.labsBlock ">>>","^Notes",1,1,">>>",1)),"[^[:ascii:]]","~")
			
		n0 += 1																			; n0 = number of CORES pts processed
		; List parsed, now place in XML(y)
		y.addElement("mrn", "/root/lists/cores", CORES.mrn)								; add MRN to <lists/cores>
		MRNstring := "/root/id[@mrn='" . CORES.mrn . "']"
		if !IsObject(y.selectSingleNode(MRNstring)) {									; If no <id@mrn> record in Y, create it.
			y.addElement("id", "root", {mrn: CORES.mrn})
			y.addElement("demog", MRNstring)
				y.addElement("name_last", MRNstring . "/demog", CORES.name_last)	
				y.addElement("name_first", MRNstring . "/demog", CORES.name_first)		; would keep since name could change
			fetchGot := false
			FetchNode("diagnoses")														; Check for existing node in Archlist,
			FetchNode("notes")															; retrieve old Dx, Notes, Plan. (Status is discarded)
			FetchNode("plan")															; Otherwise, create placeholders.
			FetchNode("prov")
			FetchNode("data")
			eventlog("processCORES " CORES.mrn ((fetchGot) ? " pulled from archive":" new") ", added to active list.")
			n1 += 1																		; n1 = number of new CORES pts added
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
			y.addElement("dcw", yInfoDt, CORES.DCW)
			y.addElement("allergies", yInfoDt, CORES.Alls)
			y.addElement("code", yInfoDt, CORES.Code)
			if !(y.selectSingleNode(yInfoDt "/hx").text) {
				y.addElement("hx", yInfoDt, "CORES hx")									; CORES_HX
			}
			y.addElement("vs", yInfoDt)
				y.addElement("wt", yInfoDt "/vs", StrX(CORES.vsWt,,1,1,"kg",1,2,NN))
				if (tmp:=StrX(CORES.vsWt,"(",NN,2,")",1,1)) {
					y.selectSingleNode(yInfoDt "/vs/wt").setAttribute("change", tmp)
				}
				y.addElement("temp", yInfoDt "/vs", CORES.vsTmp)
				y.addElement("hr",   yInfoDt "/vs", CORES.vsHR)
				y.addElement("rr",   yInfoDt "/vs", CORES.vsRR)
				y.addElement("bp",   yInfoDt "/vs", CORES.vsNBP)
				y.addElement("spo2", yInfoDt "/vs", CORES.vsSat)
				y.addElement("pain", yInfoDt "/vs", CORES.vsPain)
			y.addElement("io", yInfoDt )
				y.addElement("in",  yInfoDt "/io", CORES.ioIntake)
				y.addElement("out", yInfoDt "/io", CORES.ioOutput)
				y.addElement("ct",  yInfoDt "/io", CORES.ioCT)
				y.addElement("net", yInfoDt "/io", CORES.ioNet)
				y.addElement("uop", yInfoDt "/io", CORES.ioUOP)
			y.addElement("labs", yInfoDt )
				parseLabs(CORES.Labs)
			y.addElement("studies", yInfoDt , CORES.Studies)
			y.addElement("notes", yInfoDt , CORES.Notes)
		if !isobject(y.selectSingleNode(MRNstring "/MAR")) {
			y.addElement("MAR", MRNstring)											; Create a new /MAR node
		}
		y.selectSingleNode(MRNstring "/MAR").setAttribute("date", timenow)			; Change date to now
		if !(y.selectNodes(MRNstring "/MAR/*").length) {							; Populate only if empty
			yMarDt := MRNstring "/MAR[@date='" timenow "']"
				MedListParse("drips",cores.Drips)
				MedListParse("meds",cores.Meds)
				MedListParse("prn",CORES.PRN)
				MedListParse("abx",cores.Abx)
				MedListParse("diet",CORES.Diet)
		}
	}																				; end WHILE
	writeFile()
	eventlog("CORES data updated.")
	FileDelete, .currlock
	
	Progress off
	MsgBox,,CORES data update, % n0 " total records read.`n" n1 " new records added."
	
return	
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
