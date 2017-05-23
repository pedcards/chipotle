CallList:
{
	Gui, tList:Hide
	Gui, cList:Destroy															; destroy any previous cList
	if (location="")
		location := substr(A_GuiControl,2)
	locString := loc[location,"name"]											; get location into locString
	tmpTG := tmpCrd := ""
	cGrps := {}
	
; First pass: scan patient list into arrays
	Loop, % (plist := y.selectNodes("/root/lists/" . location . "/mrn")).length {		; loop through location MRN's into plist
		kMRN := plist.item(i:=A_Index-1).text									; text item in lists/location/mrn
		pl := ptParse(kMRN)														; fill pl with ptParse
		clProv := pl.provCard													; get CRD provider into clProv
		if (plCall := pl.callN)													; check if next call date set
			plCall -= substr(A_Now,1,8), Days									; and calculate days to next due call
		tmpCrd := checkCrd(clProv)												; tmpCrd gets provCard (spell checked)
		plFuzz := 100*tmpCrd.fuzz												; fuzz score for tmpCrd
		if (clProv="") {														; no cardiologist
			tmpCrd.group := "Other"												; group is "Other"
		} else if (clProv~="SCH|Transplant|Heart Failure|Tx") {					; unclaimed Tx and Cards patients
			tmpCrd.group := "SCH"												; place in SCH group
		} else if (plFuzz < 5) {												; Near perfect match found (< 0.05)
			clProv := tmpCrd.best												; take the close match
		} else if (plFuzz < 20) {												; less than perfect match (0.05-0.20)
			MsgBox, 262436, % "Primary cardiologist (" pl.nameL ")"				; verify name
				, % "Stored value: " clProv "`n"
				. "Correlation: " 1-tmpCrd.fuzz "`n`n"
				. "Did you mean: " tmpCrd.best "?`n`n`n"
				. "YES = use """ tmpCrd.best """`n`n"
				. "NO = keep """ clProv """"
			IfMsgBox, Yes
				clProv := tmpCrd.best
			else {
				tmpCrd.group := "Other"
			}
		} else {																; Screw it, no good match (> 0.20)
			tmpCrd.group := "Other"
		}
;		MsgBox,,% kMRN " " pl.nameL ", " pl.nameF, % "Prov: " clProv "`nGroup: " tmpCrd.group
		
		if !ObjHasKey(cGrps,tmpCrd.group) {										; tmpCrd.group not already added
			cGrps.Insert(tmpCrd.group)											; insert it into cGrps
			cGrps[tmpCrd.group] := {count:0}									; add count element
		}
		cGrps[tmpCrd.group,"count"] +=1											; increment count element
		cGrps[tmpCrd.group].Insert("" kMRN "")									; insert MRN from lists/location
		cGrps[tmpCrd.group,kMRN] := {name:pl.nameL ", " pl.nameF 				; insert name, prov, last, next as subelements 
			, prov:clProv , last:pl.callL , next:pl.callN}
	}
	
; Second pass: identify groups with patients, and generate tabs
	cGrpList := ""
	for k,val in cGrps															; index groups by number of items
	{																			; then sort in descending order
		tmp := "000" . cGrps[val,"count"]
		cGrpList .= substr(tmp,-2) . val "`n"
	}
	sort, cGrpList, R U
	
	Loop, parse, cGrpList, `n													; generate tab names based on this list
	{
		k := substr(A_LoopField,4)
		if !(k)																	; break when reach the end
			break
		if (k="Other")															; skip "Other" since it starts the list
			continue
		tmpTG .= k "|"
	}
	tmpTG .= "Other|TO CALL"
	tmpTgW := 600
	k := 0
	Gui, cList:Add, Tab2, Buttons -Wrap w%tmpTgW% h440 vCallLV, % tmpTG			; add Tab bar with var CallLV

; Third pass: fill each tab LV with the previously found patients
	Gui, cList:Default
	Gui, cList:Show, Autosize, % location " Call List"							; show the GUI
	Gui, cList:Tab, TO CALL														; Make sure TO CALL tab exists before filling names
	Gui, cList:Add, ListView													; add LV for "TO CALL" with var and hwnd 
		, % "-Multi Grid NoSortHdr x10 y35 w" tmpTgW " h440 gplCallCard v" outGrpV["TO CALL"] " hwnd" outGrpV["TO CALL"]
		, % "MRN|Name|Cardiologist|Group"

	tmpG := tmpV := ""
	loop, parse, tmpTG, |														; parse the tmpTG list we just made
	{
		tmpG := A_LoopField														; tmpG is the tab name
		tmpV := outGrpV[tmpG]													; tmpV is the var and hwnd from outGrpV[tmpG]
		if (tmpG="TO CALL")														; skip "TO CALL"
			continue
		Gui, cList:Tab, % tmpG													; select tab named tmpG
		Gui, cList:Add, ListView												; add LV for each tmpG with var and hwnd from tmpV
			, % "-Multi Grid NoSortHdr x10 y35 w" tmpTgW " h440 gplCallCard v" tmpV " hwnd" tmpV
			, % "MRN|Name|Cardiologist|" ((tmpG="TO CALL") ? "Group" : "Last|Next")
		LV_Colors.Attach(%tmpV%,1,1,1)											; attach a color to the LV
		
		for k2,kMRN in cGrps[tmpG]												; parse the MRN elements in each cGrps[tmpG]
		{
			plG := cGrps[tmpG,kMRN]												; plG is the element of the MRN object
			if (plG.name="")													; skip blanks
				continue
			if (plCall := plG.next)												; next call date exists
				plCall -= substr(A_Now,1,8), Days								; calc days to next call due
			Gui, cList:Listview, % outGrpV[tmpG]								; select the LV associated with this Tab
			LV_add(""															; add a row with MRN, name, CRD, last, and next
				, kMRN
				, plG.name
				, plG.prov
				, ((plG.last) ? niceDate(plG.last) : "---")
				, ((plG.next) ? niceDate(plG.next) : "---"))
			RowNum := LV_GetCount()												; RowNum is the currently added row
			if !(plG.next) {													; no due date, set gray
				LV_Colors.Row(%tmpV%, RowNum, 0xCCCCCC)
			} else if (plCall<2) {												; due in 1 day, set red
				LV_Colors.Row(%tmpV%, RowNum, 0xFF0000)
			} else if (plCall<4) {												; due in 2-3 days, set yellow
				LV_Colors.Row(%tmpV%, RowNum, 0xFFFF00)
			}
			LV_ModifyCol()
			LV_ModifyCol(1, "Autohdr")
			LV_ModifyCol(2, "Autohdr")
			LV_ModifyCol(3, "Autohdr")
			LV_ModifyCol(3, "Sort")
			LV_ModifyCol(4, "Autohdr")
			LV_ModifyCol(5, "Autohdr")
			if ((plG.next) and (plCall<2)) {									; due in 1 day
				Gui, cList:Listview, % outGrpV["TO CALL"]						; select "TO CALL" LV
				LV_Add(""														; add to the LV
				, kMRN
				, plG.name
				, plG.prov
				, tmpG)
				LV_ModifyCol(1, "Autohdr")
				LV_ModifyCol(2, "Autohdr")
				LV_ModifyCol(3, "Autohdr")
				LV_ModifyCol(3, "Sort")
			}
		}																		; /LOOP parsing MRNs
	}																			; /LOOP parsing tmpTG

	GuiControl, ChooseString, CallLV, TO CALL									; select "TO CALL"
	sleep 100
	if (grTab) {												; tabs redrawn, return to last used tab
		GuiControl, ChooseString, CallLV, % grTab
	}
	
	return
}

