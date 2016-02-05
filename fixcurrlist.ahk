#Include includes/xml.ahk
y := new XML("currlist.xml")
x := new XML("<root/>")
x.selectSingleNode("root").appendChild(y.selectSingleNode("/root/lists").cloneNode(true))
loop, % (yaN := y.selectNodes("/root/id")).length {
	mrn := yaN.item(i:=A_Index-1).getAttribute("mrn")
	mrnstring := "/root/id[@mrn='" mrn "']"
	yNode := y.selectSingleNode(mrnstring)
	x.addElement("id","/root", {mrn:mrn})
	xNode := x.selectSingleNode(mrnstring)
	
	;fixnode("call/tasks")							; Don't really care about the arg, just to remind me what it does now.
	
	copynode("demog")
	copynode("diagnoses")
	copynode("prov")
	copynode("status")
	copynode("notes")
	copynode("plan")
	copynode("info")
	copynode("MAR")
}
FileDelete newcurr.xml
x.save("newcurr.xml")
ExitApp

copynode(node) {
	global
	progress,,%node%,%mrn%
	loop, % (nodes := yNode.selectNodes(node)).length {
		if IsObject(clone := nodes.item(A_Index-1).cloneNode(true))
			xNode.appendChild(clone)
	}
}

fixnode(name) {
	global
	if IsObject(clone := y.selectSingleNode(mrnstring "/plan/call").cloneNode(true)) {
		progress,,%node%,%mrn%
		if !IsObject(y.selectSingleNode(mrnstring "/plan/tasks"))
			y.addElement("tasks", mrnstring "/plan")
		y.selectSingleNode(mrnstring "/plan/tasks").appendChild(clone)
		q:=y.selectSingleNode(mrnstring "/plan/call")
		q.parentNode.removeChild(q)
		yNode := y.selectSingleNode(mrnstring)
	}
}
