#Include xml.ahk
y := new XML("currlist.xml")
x := new XML("<root/>")
x.selectSingleNode("root").appendChild(y.selectSingleNode("/root/lists").cloneNode(true))
loop, % (yaN := y.selectNodes("/root/id")).length {
	mrn := yaN.item(i:=A_Index-1).getAttribute("mrn")
	mrnstring := "/root/id[@mrn='" mrn "']"
	yNode := y.selectSingleNode(mrnstring)
	x.addElement("id","/root", {mrn:mrn})
	xNode := x.selectSingleNode(mrnstring)
	
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
	if IsObject(clone := yNode.selectSingleNode(node).cloneNode(true))
		xNode.appendChild(clone)
	test[node] := xNode.selectSingleNode(node).text
}
