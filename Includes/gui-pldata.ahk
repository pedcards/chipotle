plDataList:
{
;~ MsgBox Coming soon!
;~ Return
	Gui, plistG:Hide
	Gui, dlist:Destroy
	Gui, dlist:Add, Button, x10 y360 w200 h30 gplDataEdit, Add study...
	Gui, dlist:Add, Tab2, x10 y10 w800 h340 vDataTab, Recent||Echo|ECG|CXR|Cath|GXT|CMR
	Gui, dlist:Default
	plData("Recent")
	plData("Echo")
	plData("ECG")
	plData("CXR")
	plData("Cath")
	plData("GXT")
	plData("CMR")
	if (plDataTab) {
		GuiControl, dlist:Choose, DataTab, |%plDataTab%
		plDataTab:=
	}
	Gui, dlist:Show, AutoSize, % pl_nameL " study matrix"
Return
}

plDataEdit:
{
	;Agn := A_EventInfo
	Agc := A_GuiControl
	Gui, dlist:ListView, %Agc%
	Agn := LV_GetNext(0)
	GuiControlGet, plDataType, , DataTab
	if (plDataType="Recent")
		return
	tmpTS := "", tmpD := "DateIdx", tmp := ""
	if (substr(Agc,1,6)=="DataLV") {
		if (Agn=0)
			return
		LV_GetText(tmpTS,Agn,1)								; Date created index
		LV_GetText(tmpD,Agn,2)								; Study date
		LV_GetText(tmp,Agn,4)								; Results
	}
	formW:=700, formR:=5, formtype:="D"
	gosub plForm

	if (formDel) {
		MsgBox, 20, Confirm, Delete this %plDataType%?
		IfMsgBox Yes 
		{
			if !IsObject(pl_mrnstring "/trash") {
				y.addElement("trash", pl_mrnstring)
				WriteOut(pl_mrnstring, "trash")
			}
			delmrnstr := pl_mrnstring "/data/" plDataType "/study[@created='" formTS "']"
			y.selectSingleNode(delmrnstr).setAttribute("del", A_Now)
			y.selectSingleNode(delmrnstr).setAttribute("au", user)
			locnode := y.selectSingleNode(delmrnstr)
			y.selectSingleNode(pl_mrnstring "/data/" plDataType).removeChild(locnode)
			WriteOut(pl_mrnstring, "data")
			y.selectSingleNode(pl_mrnstring "/trash").appendChild(locnode.cloneNode(true))
			WriteOut(pl_mrnstring, "trash")
			eventlog(mrn " " plDataType " " tmpD " deleted.")
			plDataTab:=plDataType
			gosub plDataList
		}
		Return
	}

	if !(formedit=true) {
		return
	}
	if !(formsave=true) {
		return
	}
	if !IsObject(y.selectSingleNode(pl_mrnstring "/data")) {
		y.addElement("data", pl_mrnstring)
		WriteOut(pl_mrnstring, "data")
	}
	if !IsObject(y.selectSingleNode(pl_mrnstring "/data/" plDataType)) {
		y.addElement(plDataType, pl_mrnstring "/data")
		WriteOut(pl_mrnstring "/data", plDataType)
	}
	if (formnew) {
		y.addElement("study", pl_mrnstring "/data/" plDataType, {date:formDT, created:formTS}, formTxt)
	} else {
		y.selectSingleNode(pl_mrnstring "/data/" plDataType "/study[@created='" formTS "']").childNodes[0].nodevalue := formTxt
		y.selectSingleNode(pl_mrnstring "/data/" plDataType "/study[@created='" formTS "']").setAttribute("date", formDT)
	}
	y.selectSingleNode(pl_mrnstring "/data/" plDataType "/study[@created='" formTS "']").setAttribute("ed", A_Now)
	y.selectSingleNode(pl_mrnstring "/data/" plDataType "/study[@created='" formTS "']").setAttribute("au", user)
	WriteOut(pl_mrnstring, "data")
	eventlog(mrn " data list updated.")
	plDataTab:=plDataType
	gosub plDataList
Return
}

plData(Dtype) {
	global
	local plDlist, plData, plDataIdx, plDataDate, plDataDisp, plDataItem
	Gui, dlist:Tab, %Dtype%
	Gui, dlist:Add, ListView, -Multi Grid NoSortHdr w780 h300 vDataLV%Dtype% gplDataEdit, DateCr|DateIdx|Date|Result
	If (Dtype="Recent")
		Dtype:="*"

	Loop, % (plDlist := y.selectNodes(pl_mrnstring "/data/" Dtype "/study")).length {
		plData := plDlist.item(A_index-1)
		plDataIdx := plData.getAttribute("created")
		plDataDate := plData.getAttribute("date")
		plDataDisp := substr(plDataDate,5,2) . "/" . substr(plDataDate,7,2) . "/" . substr(plDataDate,1,4)
		plDataItem := plData.text
		LV_Add("", plDataIdx, plDataDate, plDataDisp, plDataItem)
	}
	LV_ModifyCol(1, 0)
	LV_ModifyCol(2, "0 Sort")
	LV_ModifyCol(3, "AutoHdr")
	if (Dtype="*")
		LV_ModifyCol(2, "0 SortDesc")
}

