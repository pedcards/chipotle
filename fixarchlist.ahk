#Include xml.ahk
test:=["demog","diagnoses","prov","notes","plan"]
y := new XML("archlist.xml")
x := new XML()
x.addElement("root")
loop, % (yaN := y.selectNodes("/root/id")).length {
	mrn := yaN.item(i:=A_Index-1).getAttribute("mrn")
	mrnstring := "/root/id[@mrn='" mrn "']"
	yNode := y.selectSingleNode(mrnstring)
	
	x.addElement("id","/root", {mrn:mrn})
	xNode := x.selectSingleNode(mrnstring)
	
	copynode("demog")
	copynode("diagnoses")
	if IsObject(xNode.selectSingleNode("diagnoses/prov")) {
		clone := xNode.selectSingleNode("diagnoses/prov").cloneNode(true)
		xNode.appendChild(clone)
		xNode.selectSingleNode("diagnoses").removeChild(xNode.selectSingleNode("diagnoses/prov"))
	} else {
		copynode("prov")
	}
	copynode("notes")
	copynode("plan")
	if (!test["demog"] and !test["diagnoses"] and !test["prov"] and !test["notes"] and !test["plan"]) {
		;MsgBox %MRN% empty!
		x.selectSingleNode("/root").removeChild(x.selectSingleNode(mrnstring))
	}
}
FileDelete newarch.xml
x.save("newarch.xml")
ExitApp

copynode(node) {
	global
	progress,,%node%,%mrn%
	x.addElement(node,mrnstring)
	if IsObject(clone := yNode.selectSingleNode(node).cloneNode(true))
		xNode.replaceChild(clone,xNode.selectSingleNode(node))
	test[node] := xNode.selectSingleNode(node).text
}
