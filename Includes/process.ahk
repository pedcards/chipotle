processCIS:										;*** Parse CIS patient list
{
	filecheck()
	FileOpen(".currlock", "W")													; Create lock file.
	y := new XML("currlist.xml")												; Get latest local currlist into memory
	RemoveNode("/root/lists/" . location)
	y.addElement(location, "/root/lists", {date: timenow})
	rtfList :=
	colTmp := {"FIN":0, "MRN":0, "Sex":0, "Age":0, "Adm":0, "DOB":0, "Days":0, "Room":0, "Svc":0, "Attg":0, "Name":0}

; First pass: parse fields into arrays and field types
	colIdx := colTmp.Clone()
	Loop, parse, clip, `n, `r%A_Tab%%A_Space%
	{
		clip_num := A_Index
		clip_full := A_LoopField
		If (clip_full) break
		Loop, parse, clip_full, %A_Tab%
		{
			i:=A_LoopField
			j:=fieldType(i)
			clip_elem[clip_num,A_Index] := i									; Place each element into an array, 
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
; Third pass: parse array elements according to identified field types
	Loop, % clip_elem.MaxIndex()
	{
		clip_num := A_Index	
		CIS_mrn := clip_elem[clip_num,colIdx["MRN"]]				; MRN
			MRNstring := "/root/id[@mrn='" . CIS_mrn . "']"
		if (CIS_mrn = "") {											; skip if null
			continue
		}
		CIS_name := clip_elem[clip_num,colIdx["Name"]]
			CIS_name_last := Trim(StrX(CIS_name, ,0,0, ", ",1,2))		; Last name
			CIS_name_first := Trim(StrX(CIS_name, ", ",0,2, " ",1,0))	; First name
		CIS_loc := clip_elem[clip_num,colIdx["Room"]]
			CIS_loc_unit := StrX(CIS_loc, ,0,0, " ",1,1)				; Unit
			CIS_loc_room := StrX(CIS_loc, " ",1,1, " ",1,0)				; Room number
			if (CIS_loc_room="") {
				CIS_loc_room := CIS_loc_unit
				CIS_loc_unit := ((CIS_loc_unit ~= "FA\.6\.2\d{2}\b") 
					? "CICU-F6"
					: ((CIS_loc_unit ~= "RC\.6\.\d{3}\b")
						? "SUR-R6" 
						: ""))
			}
		CIS_attg := clip_elem[clip_num,colIdx["Attg"]]					; Attending
			StrX(CIS_attg,",",1,2," ",1,2,n )							; Get ATTG last,first name
			CIS_attg := substr(CIS_attg,1,n)
		CIS_adm_full := clip_elem[clip_num,colIdx["Adm"]]				; Admit date/time
			CIS_admit := StrX(CIS_adm_full, ,0,0, " ",1,0)
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
			FetchNode("diagnoses")									; Check for existing node in Archlist,
			FetchNode("notes")										; retrieve old Dx, Notes, Plan. (Status is discarded)
			FetchNode("plan")										; Otherwise, create placeholders.
			FetchNode("prov")
			if (archDxDate := y.selectSingleNode(MRNstring "/diagnoses").getattribute("date")) {				; Dx node fetched from archlist
				if (archDxNotes := y.selectSingleNode(MRNstring "/diagnoses/notes").text) {						; DxNotes has text
					y.setText(MRNstring "/diagnoses/notes", "[[" niceDate(archDxDate) ": " archDxNotes "]]")	; Denote with [[date]]
				}
			}
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
		y.addElement("mrn", "/root/lists/" . location, CIS_mrn)
		
		; Auto label Transplant patients admitted by Txp attg
		if !IsObject(y.selectSingleNode(MRNstring "/status")) {							; If no status, add it.
			y.addElement("status", MRNstring)
		}
		if (ObjHasValue(txpDocs,CIS_attg)) {											; If matches TxpDocs list
			y.selectSingleNode(MRNstring "/status").setAttribute("txp", "on")			; Set status flag.
		}
		if (location="TXP" and ((CIS_svc="Cardiology") or (CIS_svc="Cardiac Surgery"))) {	; If on TXP list AND on CRD or CSR
			y.selectSingleNode(MRNstring "/status").setAttribute("txp", "on")				; Set status flag.
		}
		
		; Add Cardiology/SURGCNTR patients to SURGCNTR list, these are cath patients, will fall off when discharged?
;		if (location="Cards" and CIS_sex="Female") {
		if (location="Cards" and CIS_loc_unit="SURGCNTR") {
			SurgCntrPath := "/root/lists/SURGCNTR"
			if !IsObject(y.selectSingleNode(SurgCntrPath)) {
				y.addElement("SURGCNTR","/root/lists", {date:timenow})
			}
			if !IsObject(y.selectSingleNode(SurgCntrPath "/mrn[text()='" CIS_mrn "']")) {
				y.addElement("mrn", SurgCntrPath, CIS_mrn)
			}
		}
	}
	listsort(location)
	y.save("currlist.xml")
	eventlog(location " list updated.")
	FileDelete, .currlock
		
	MsgBox, 4, Print now?, Print list: %locString%
	IfMsgBox, Yes
	{
		gosub PrintIt
	}
Return
}

processCORES: 										;*** Parse CORES Rounding/Handoff Report
{
	filecheck()
	FileOpen(".currlock", "W")													; Create lock file.
	y := new XML("currlist.xml")												; load freshest currlist into memory

	Progress, b,, Scanning...
	RemoveNode("/root/lists/cores")
	y.addElement("cores", "/root/lists", {date: timenow})

	GuiControl, Main:Text, GUIcoresTXT, %timenow%
	GuiControl, Main:Text, GUIcoresChk, ***
	Gui, Main:Submit, NoHide
	N:=1, n0:=0, n1:=0
	
	While clip {
		ptBlock := StrX( clip, "Patient Information" ,N,19, "Patient Information" ,1,20, N )
		if instr(ptBlock,"CORES Rounding") {
			ptBlock := StrX( ptBlock, "",1,1, "CORES Rounding" ,1,15)
		}
		if instr(ptBlock,"Contacts 1`r") {
			ptBlock := StrX( ptBlock, "",1,1, "Contacts 1" ,1,11)
		}
		if (ptBlock = "") {
			break   ; end of clip reached
		} else {
		NN = 1
		Cores_Demo := strX(ptBlock, "",1,0, "DOB:",1,0,NN)
		CORES_Loc := trim(StrX(Cores_Demo, "",1,0, "`r",1,1))
		CORES_MRNx := trim(RegExMatch(Cores_Demo,"\d{6,7}",CORES_MRN))
		CORES_Name := trim(StrX(Cores_Demo,CORES_Loc,1,StrLen(CORES_Loc),CORES_MRNx,1,8)," `t`r`n")
			CORES_name_last := Trim(StrX(CORES_name, ,0,0, ", ",1,2))			
			CORES_name_first := Trim(StrX(CORES_name, ", ",0,2, " ",1,0))	
		Progress,,, % CORES_name_last ", " CORES_name_first
		CORES_DCW := StrX( ptBlock, "DCW: " ,1,5, "`r" ,1,1, NN )				; skip to Line 5
		CORES_Alls := StrX( ptBlock, "Allergy: " ,1,9, "`r" ,1,1, NN )			; Line 6
		CORES_Code := StrX( ptBlock, "Code Status: " ,1,13, "`r" ,1,1, NN )		; Line 7

		CORES_HX =
		CORES_HX := StRegX( ptBlock, "`r",NN,2, "Medications.*(DRIPS|SCH MEDS)",1,NN)
			StringReplace, CORES_hx, CORES_hx, •%A_space%, *%A_Space%, ALL
			StringReplace, CORES_hx, CORES_hx, `r`n, <br>, ALL
			StringReplace, CORES_hx, CORES_hx, Medical History, <hr><b><i>Medical History</i></b>
			StringReplace, CORES_hx, CORES_hx, ID Statement, <hr><b><i>ID Statement</i></b>
			StringReplace, CORES_hx, CORES_hx, Active Issues, <hr><b><i>Active Issues</i></b>
			StringReplace, CORES_hx, CORES_hx, Social Hx, <hr><b><i>Social Hx</i></b>
			StringReplace, CORES_hx, CORES_hx, Action Items - To Dos, <hr><b><i>Action Items - To Dos</i></b>
		CORES_Diet := substr(cores_hx,RegExMatch(cores_hx,"m)Diet.*\*"))
			StringReplace, CORES_Diet, CORES_Diet, Diet *, *
			StringReplace, CORES_Diet, CORES_Diet, <br>, `r`n, ALL
			;~ CORES_DietStr := CORES_Diet
			StringReplace, CORES_Diet, CORES_Diet, *%A_Space%, •%A_space%, ALL
		
		CORES_MedBlock = 
		CORES_MedBlock := StrX( ptBlock, "Medications" ,NN,11, "Vitals" ,1,7, NN )
		CORES_Drips := StrX( CORES_MedBlock, "DRIPS`r" ,1,6, "SCH MEDS" ,1,9 )
		CORES_Meds := StrX( CORES_MedBlock, "SCH MEDS`r" ,1,9, "PRN" ,1,4 )
		CORES_PRN := StrX( CORES_MedBlock, "PRN`r" ,1,4, "" ,0,0 )
		
		CORES_vsBlock := StrX( ptBlock, "Vitals" ,NN,6, "Ins/Outs" ,1,8, NN ) ; ...,1,8, NN)
			CORES_vsWt := StrX( CORES_vsBlock, "Meas Wt:",0,8, "`r`n" ,1,2, NNN)
				if (instr(CORES_vsWt,"No current data available")) {
					CORES_vsWt := "n/a"
				}
			CORES_vsTmp := RTrim(StrX( CORES_vsBlock, "`r`nT ",NNN,4, "HR " ,1,3, NNN), " M")
			CORES_vsHR := StrX(StrX( CORES_vsBlock, "HR ",NNN,3, "RR", 1,3, NNN),"",0,0,"MHR",1,3)
			CORES_vsRR := StrX( CORES_vsBlock, "RR",NNN,3, "`r`n", 1,1, NNN)
			CORES_vsNBP := StrX( CORES_vsBlock, "NIBP",NNN,5, "`r`n", 1,1, NNN)
			CORES_vsVent := StrX( CORES_vsBlock, "`r`n",NNN-2,1, "SpO2",1,4, NNN)
			CORES_vsSat := StrX( CORES_vsBlock, "SpO2",NNN,5, "`r`n",1,1, NNN)
			CORES_vsPain := StrX( CORES_vsBlock, "`r`n" ,NNN-1 ,1, "",1,1, NNN)
		CORES_IOBlock := StrX( ptBlock, "Ins/Outs" ,NN,8, "Labs (72 Hrs)" ,1,14, NN)
			CORES_ioIn := StrX( CORES_IOBlock, "In=",1,4, "`r`n",1,1)
			CORES_ioEnt := StrX( CORES_IOBlock, "Gastric/Enteral=",1,17, "`r`n",1,1)
			CORES_ioPO := StrX( CORES_IOBlock, "Oral=",1,6, "`r`n",1,1)
			CORES_ioOut := StrX( CORES_IOBlock, "Out=",1,5, "`r`n",1,1)
			CORES_ioCT := StrX( CORES_IOBlock, "Chest Tube=",1,11, "`r`n",1,1)
			CORES_ioNet := StrX( CORES_IOBlock, "IO Net=",1,8, "`r`n",1,1)
			CORES_ioUOP := StrX( CORES_IOBlock, "UOP=",1,5, "`r`n",1,1)
		CORES_LabsBlock := strx(ptblock, "Labs (72 Hrs) / Studies",1,23, "",0,0)
			CORES_Labs := trim(StRegX( CORES_LabsBlock, "" ,1,1, "\`n(Studies|Notes)",1))
			CORES_Studies := trim(StrX( CORES_LabsBlock, "`nStudies",1,8, "`nNotes",1,6))
			CORES_Notes := trim(StrX( CORES_LabsBlock, "`nNotes",1,6, "",0,0))
		
		n0 += 1
		; List parsed, now place in XML(y)
		y.addElement("mrn", "/root/lists/cores", CORES_mrn)
		MRNstring := "/root/id[@mrn='" . CORES_mrn . "']"
		if !IsObject(y.selectSingleNode(MRNstring)) {		; If no arch record, create it.
			y.addElement("id", "root", {mrn: CORES_mrn})
			y.addElement("demog", MRNstring)
				y.addElement("name_last", MRNstring . "/demog", CORES_name_last)	
				y.addElement("name_first", MRNstring . "/demog", CORES_name_first)	; would keep since name could change
			y.addElement("diagnoses", MRNstring)
			y.addElement("notes", MRNstring)
			y.addElement("plan", MRNstring)
			n1 += 1
		}
		; Remove the old Info nodes
		Loop % (infos := y.selectNodes(MRNstring "/info")).length
		{
			tmpdt := infos.Item(A_index-1).getAttribute("date")
			tmpTD := tmpdt
			tmpTD -= A_now, Days
			if ((tmpTD < -7) or (substr(tmpdt,1,8) = substr(A_now,1,8))) {			; remove old nodes or replace info/mar from today.
			;if (tmpTD < -7)  {														; remove old nodes.
				RemoveNode(MRNstring "/info[@date='" tmpdt "']")
				continue
			}
			if (tmpTD < 1) {														; remove old info/hx and info/notes from nodes older than 1 day.
				RemoveNode(MRNstring "/info[@date='" tmpdt "']/hx")
				RemoveNode(MRNstring "/info[@date='" tmpdt "']/notes")
			}
		}
		Loop % (infos := y.selectNodes(MRNstring "/MAR")).length					; remove old MAR except for this run.
		{
			tmpdt := infos.Item(A_Index-1).getAttribute("date")
			if (tmpdt!=timenow) {
				RemoveNode(MRNstring "/MAR[@date='" tmpdt "']")
			}
		}
	
		y.addElement("info", MRNstring, {date: timenow})	; Create a new /info node
		yInfoDt := MRNstring . "/info[@date='" timenow "']"
			y.addElement("dcw", yInfoDt, CORES_DCW)
			y.addElement("allergies", yInfoDt, CORES_Alls)
			y.addElement("code", yInfoDt, CORES_Code)
			if !(y.selectSingleNode(yInfoDt "/hx").text)
				y.addElement("hx", yInfoDt, CORES_HX)
			y.addElement("vs", yInfoDt)
				y.addElement("wt", yInfoDt "/vs", StrX(CORES_vsWt,,1,1,"kg",1,2,NN))
				if (tmp:=StrX(CORES_vsWt,"(",NN,2,")",1,1))
					y.selectSingleNode(yInfoDt "/vs/wt").setAttribute("change", tmp)
				y.addElement("temp", yInfoDt "/vs", CORES_vsTmp)
				y.addElement("hr",   yInfoDt "/vs", CORES_vsHR)
				y.addElement("rr",   yInfoDt "/vs", CORES_vsRR)
				y.addElement("bp",   yInfoDt "/vs", CORES_vsNBP)
				y.addElement("spo2", yInfoDt "/vs", CORES_vsSat)
				y.addElement("pain", yInfoDt "/vs", CORES_vsPain)
			y.addElement("io", yInfoDt )
				y.addElement("in",  yInfoDt "/io", CORES_ioIn)
				y.addElement("ent", yInfoDt "/io", CORES_ioEnt)
				y.addElement("po",  yInfoDt "/io", CORES_ioPO)
				y.addElement("out", yInfoDt "/io", CORES_ioOut)
				y.addElement("ct",  yInfoDt "/io", CORES_ioCT)
				y.addElement("net", yInfoDt "/io", CORES_ioNet)
				y.addElement("uop", yInfoDt "/io", CORES_ioUOP)
			y.addElement("labs", yInfoDt )
				parseLabs(CORES_Labs)
			y.addElement("studies", yInfoDt , CORES_Studies)
			y.addElement("notes", yInfoDt , CORES_Notes)
		if !isobject(y.selectSingleNode(MRNstring "/MAR"))
			y.addElement("MAR", MRNstring)											; Create a new /MAR node
		y.selectSingleNode(MRNstring "/MAR").setAttribute("date", timenow)			; Change date to now
		if !(y.selectNodes(MRNstring "/MAR/*").length) {							; Populate only if empty
			yMarDt := MRNstring "/MAR[@date='" timenow "']"
				MedListParse("drips",CORES_Drips)
				MedListParse("meds",CORES_Meds)
				MedListParse("prn",CORES_PRN)
				MedListParse("diet",CORES_Diet)
			}
		}
	}
	Progress off
	y.save("currlist.xml")
	eventlog("CORES data updated.")
	FileDelete, .currlock
	Return
}

