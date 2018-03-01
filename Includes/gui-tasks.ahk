plTasksList:
{
	Gui, tlist:Destroy
	Gui, tlist:Add, Listview, -Multi AltSubmit Checked Grid NoSortHdr W780 gplTaskEdit vTaskLV hwndHLV, Task Date|Item|DateIdx|Created|Done
	LV_Colors.Attach(HLV,1,0,0)
	Gui, tlist:Default
	gosub plTaskGrid
	
	GuiControl, tlist:Move, TaskLV, % "H" tlvH
	Gui, tlist:Add, Button, % "w780 x10 y" tlvH+10 " gplTaskEdit", ADD A TASK...
	Gui, tlist:Show, % "W800 H" tlvH+35 , % pl_nameL " - Tasks"
	GuiControl, tlist:+Redraw, %HLV%
	Gui, plistG:Hide
Return	
}

plTaskGrid:
{
	pTct := 1
	i:=0
	if IsObject(plTodo := y.selectSingleNode(pl_mrnstring "/plan/call")) {
		plTodoD := plTodo.getAttribute("next")
		plTodoCk := plTodoD
		EnvSub, plTodoCk, A_Now, D
		if (plTodoCk<1) {
			plTodoDate := substr(plTodoD,5,2) "/" substr(plTodoD,7,2)
			LV_Add("", plTodoDate, "Call Dr. " pl.provCard, plTodoD, "call")
			LV_Colors.Row(HLV, 1, 0xFF0000)
			pTct += 1
		}
	}
	Loop, % (plTodos := y.selectNodes(pl_mrnstring "/plan/tasks/todo")).length {
		plTodo := plTodos.item(A_Index-1)
		plTodoD := plTodo.getAttribute("due")
		plTodoDate := substr(plTodoD,5,2) . "/" . substr(plTodoD,7,2)
		plTodoCreated := plTodo.getAttribute("created")
		plTodoDone := plTodo.getAttribute("done")
		LV_Add("", plTodoDate, plTodo.text, plTodoD, plTodoCreated, plTodoDone)
		plTodoCk := plTodoD
		EnvSub, plTodoCk , A_Now, D
		if (plTodoCk<3) {
			LV_Colors.Row(HLV, pTct, 0xFFFF00)
		}
		if (plTodoCk<1) {
			LV_Colors.Row(HLV, pTct, 0xFF0000)
		}
		pTct += 1
	}
	Loop, % (plTodos := y.selectNodes(pl_mrnstring "/plan/done/todo")).length {
		plTodo := plTodos.item(A_Index-1)
		plTodoD := plTodo.getAttribute("due")
		plTodoDate := substr(plTodoD,5,2) . "/" . substr(plTodoD,7,2)
		plTodoCreated := plTodo.getAttribute("created")
		plTodoDone := plTodo.getAttribute("done")
		LV_Add("Check", plTodoDate, plTodo.text, plTodoD, plTodoCreated, plTodoDone)
		LV_Colors.Row(HLV, pTct, 0xC0C0C0)
		pTct += 1
	}
	;LV_ModifyCol()
	LV_ModifyCol(1, "AutoHdr")
	LV_ModifyCol(2,680)
	LV_ModifyCol(3, "0 Sort")
	LV_ModifyCol(4, 0)
	LV_ModifyCol(5, "0 Sort")
	pTct+=1
	if pTct>25
		pTct:=25
	if pTct<4
		pTct:=4
	tlvH := (pTct)*21
}

plTaskEdit:
{
	Ag:=A_GuiEvent
	plEl := errorlevel
	LV_GetText(tmpTS, A_EventInfo,4)
	If (Ag=="I") {
		if !IsObject(y.selectSingleNode(pl_mrnstring "/plan/done")) {
			y.addElement("done", pl_mrnstring "/plan")
			WriteOut(pl_mrnstring "/plan", "done")
		}
		If (plEl=="C") {									; checkbox selected
			if !IsObject(locnode := y.selectSingleNode(pl_mrnstring "/plan/tasks/todo[@created='" tmpTS "']"))
				Return
			locnode.setAttribute("done", A_now)
			locnode.setAttribute("au", user)
			clone := locnode.cloneNode(true)
			y.selectSingleNode(pl_mrnstring "/plan/done").appendChild(clone)
			y.selectSingleNode(pl_mrnstring "/plan/tasks").removeChild(locnode)
			WriteOut(pl_mrnstring, "plan")
			gosub plTasksList
		}
		Else If (plEl=="c") {								; checkbox deselected
			if !IsObject(locnode := y.selectSingleNode(pl_mrnstring "/plan/done/todo[@created='" tmpTS "']"))
				return
			locnode.setAttribute("done", "")
			locnode.setAttribute("au", user)
			clone := locnode.cloneNode(true)
			y.selectSingleNode(pl_mrnstring "/plan/tasks").appendChild(clone)
			y.selectSingleNode(pl_mrnstring "/plan/done").removeChild(locnode)
			WriteOut(pl_mrnstring, "plan")
			gosub plTasksList
		}
	}
	if (tmpTS="call") {
		plProv := pl_provCard
		plName := pl_nameL
		gosub plCallCard
		return
	}
	Agn:=LV_GetNext(0)
	if !(A_GuiControl=="ADD A TASK...") and (!(Ag=="DoubleClick") or (Agn=0))
			Return
	LV_GetText(tmpDate, Agn,1)					; displayed date
	LV_GetText(tmp, Agn,2)						; text
	LV_GetText(tmpD, Agn,3)						; full date (for indexing)
	LV_GetText(tmpTS, Agn,4)					; created date (necessary for tasks)
	LV_GetText(tmpDone, Agn,5)					; done date
	if (Agn and tmpDone) {
		MsgBox Cannot modify completed task.
		return
	}
	formW:=700, formR:=5, formtype:="T"
	gosub plForm
	;gosub plTasksList

	if (formDel) {
		MsgBox, 20, Confirm, Delete this task?
		IfMsgBox Yes 
		{
			if !IsObject(pl_mrnstring "/trash") {
				y.addElement("trash", pl_mrnstring)
				WriteOut(pl_mrnstring, "trash")
			}
			delmrnstr := pl_mrnstring "/plan/tasks/todo[@created='" formTS "']"
			y.selectSingleNode(delmrnstr).setAttribute("del", A_Now)
			y.selectSingleNode(delmrnstr).setAttribute("au", user)
			locnode := y.selectSingleNode(delmrnstr)
			y.selectSingleNode(pl_mrnstring "/plan/tasks").removeChild(locnode)
			WriteOut(pl_mrnstring, "plan")
			y.selectSingleNode(pl_mrnstring "/trash").appendChild(locnode.cloneNode(true))
			WriteOut(pl_mrnstring, "trash")
			eventlog(mrn " todo " tmpD " deleted.")
			gosub plTasksList
		}
		GuiControl, +Redraw, %HLV%
		Return
	}

	if !(formedit=true) {
		return
	}
	if !(formsave=true) {
		return
	}
	if !IsObject(y.selectSingleNode(pl_mrnstring "/plan")) {
		y.addElement("plan", pl_mrnstring)
		WriteOut(pl_mrnstring, "plan")
	}
	if !IsObject(y.selectSingleNode(pl_mrnstring "/plan/tasks")) {
		y.addElement("tasks", pl_mrnstring "/plan")
		WriteOut(pl_mrnstring "/plan", "tasks")
	}
	if (formnew) {
		y.addElement("todo", pl_mrnstring "/plan/tasks", {due:formDT, created:formTS}, formTxt)
	} else {
		y.selectSingleNode(pl_mrnstring "/plan/tasks/todo[@created='" formTS "']").childNodes[0].nodevalue := formTxt
		y.selectSingleNode(pl_mrnstring "/plan/tasks/todo[@created='" formTS "']").setAttribute("due", formDT)
	}
	y.selectSingleNode(pl_mrnstring "/plan/tasks/todo[@created='" formTS "']").setAttribute("ed", A_Now)
	y.selectSingleNode(pl_mrnstring "/plan/tasks/todo[@created='" formTS "']").setAttribute("au", user)
	WriteOut(pl_mrnstring "/plan","tasks")
	eventlog(mrn " todo list updated.")
	gosub plTasksList
Return
}

tListGuiClose:
	Gui, tlist:Destroy
	Gui, plistG:Restore
	Return

TeamTaskPt:
{
	LV_GetText(mrn, A_EventInfo, 3)
	Gui, ttask:Destroy
	Gosub PatListGet
Return	
}

