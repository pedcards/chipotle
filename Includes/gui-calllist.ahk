CallList:
{
	Gui, tList:Hide
	Gui, cList:Destroy
	if (location="")
		location := substr(A_GuiControl,2)
	locString := loc[location,"name"]
	tmpTG := tmpCrd := ""
	cGrps := {}
	
; First pass: scan patient list into arrays
	Loop, % (plist := y.selectNodes("/root/lists/" . location . "/mrn")).length {
		kMRN := plist.item(i:=A_Index-1).text
		pl := ptParse(kMRN)
		clProv := pl.provCard
		if (plCall := pl.callN)
			plCall -= substr(A_Now,1,8), Days
		tmpCrd := checkCrd(clProv)
		plFuzz := 100*tmpCrd.fuzz
		if (clProv="") {												; no cardiologist
			tmpCrd.group := "Other"
		} else if (plFuzz < 5) {										; Near perfect match found (< 0.05)
			clProv := tmpCrd.best
		} else if (plFuzz < 20) {										; less than perfect match (0.05-0.20)
			MsgBox, 262436, % "Primary cardiologist (" pl.nameL ")"
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
		} else {														; Screw it, no good match (> 0.20)
			tmpCrd.group := "Other"
		}
;		MsgBox,,% kMRN " " pl.nameL ", " pl.nameF, % "Prov: " clProv "`nGroup: " tmpCrd.group
		
		if !ObjHasKey(cGrps,tmpCrd.group) {
			cGrps.Insert(tmpCrd.group)
			cGrps[tmpCrd.group] := {count:0}
		}
		cGrps[tmpCrd.group,"count"] +=1
		cGrps[tmpCrd.group].Insert("" kMRN "")
		cGrps[tmpCrd.group,kMRN] := {name:pl.nameL ", " pl.nameF , prov:clProv , last:pl.callL , next:pl.callN}
	}
	
; Second pass: identify groups with patients, and generate tabs
	cGrpList := ""
	for k,val in cGrps													; index groups by number of items
	{																	; then sort in descending order
		tmp := "000" . cGrps[val,"count"]
		cGrpList .= substr(tmp,-2) . val "`n"
	}
	sort, cGrpList, R U
	
	Loop, parse, cGrpList, `n											; generate tab names based on this list
	{
		k := substr(A_LoopField,4)
		if !(k)
			break
		if (k="Other")
			continue
		tmpTG .= k "|"
	}
	tmpTG .= "Other|TO CALL"
	tmpTgW := 600
	k := 0
	Gui, cList:Add, Tab2, Buttons -Wrap w%tmpTgW% h440 vCallLV, % tmpTG

; Third pass: fill each tab LV with the previously found patients
	Gui, cList:Default
	Gui, cList:Show, Autosize, % location " Call List"
	Gui, cList:Tab, TO CALL												; Make sure TO CALL tab exists before filling names
	Gui, cList:Add, ListView
		, % "-Multi Grid NoSortHdr x10 y35 w" tmpTgW " h440 gplCallCard v" outGrpV["TO CALL"] " hwnd" outGrpV["TO CALL"]
		, % "MRN|Name|Cardiologist|Group"

	tmpG := tmpV := ""
	loop, parse, tmpTG, |
	{
		tmpG := A_LoopField
		tmpV := outGrpV[tmpG]
		if (tmpG="TO CALL")
			continue
		Gui, cList:Tab, % tmpG
		Gui, cList:Add, ListView
			, % "-Multi Grid NoSortHdr x10 y35 w" tmpTgW " h440 gplCallCard v" tmpV " hwnd" tmpV
			, % "MRN|Name|Cardiologist|" ((tmpG="TO CALL") ? "Group" : "Last|Next")
		LV_Colors.Attach(%tmpV%,1,1,1)
		
		for k2,kMRN in cGrps[tmpG]
		{
			plG := cGrps[tmpG,kMRN]
			if (plG.name="")
				continue
			if (plCall := plG.next)
				plCall -= substr(A_Now,1,8), Days
			Gui, cList:Listview, % outGrpV[tmpG]
			LV_add(""
				, kMRN
				, plG.name
				, plG.prov
				, ((plG.last) ? niceDate(plG.last) : "---")
				, ((plG.next) ? niceDate(plG.next) : "---"))
			RowNum := LV_GetCount()
			if !(plG.next) {
				LV_Colors.Row(%tmpV%, RowNum, 0xCCCCCC)
			} else if (plCall<2) {
				LV_Colors.Row(%tmpV%, RowNum, 0xFF0000)
			} else if (plCall<4) {
				LV_Colors.Row(%tmpV%, RowNum, 0xFFFF00)
			}
			LV_ModifyCol()
			LV_ModifyCol(1, "Autohdr")
			LV_ModifyCol(2, "Autohdr")
			LV_ModifyCol(3, "Autohdr")
			LV_ModifyCol(3, "Sort")
			LV_ModifyCol(4, "Autohdr")
			LV_ModifyCol(5, "Autohdr")
			if ((plG.next) and (plCall<2)) {
				Gui, cList:Listview, % outGrpV["TO CALL"]
				LV_Add(""
				, kMRN
				, plG.name
				, plG.prov
				, tmpG)
				LV_ModifyCol(1, "Autohdr")
				LV_ModifyCol(2, "Autohdr")
				LV_ModifyCol(3, "Autohdr")
				LV_ModifyCol(3, "Sort")
			}
		}
	}

	GuiControl, ChooseString, CallLV, TO CALL
	sleep 100
	if (grTab) {												; tabs redrawn, return to last used tab
		GuiControl, ChooseString, CallLV, % grTab
	}
	
	return
}

