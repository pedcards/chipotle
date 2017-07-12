FileRead, txt, .\files\data_in\sensis\SensisExportExample.HIS
StringReplace, txt, txt, `r`n, `n, All
n := 1
pipe := chr(0xB3)
y := new XML("test.xml")
y.addElement("root")

Loop, parse, txt, `n, `r
{
	i := A_LoopField
	if (i~="^Group:") {
		grp := 
		grp := strX(i,"Group:",1,6,"",0)
		y.addElement("group","root",{name:grp})
		continue
	} else if (i~="^Fields:") {
		fields := []
		fld := trim(strX(i,"Fields:",1,7,"",0),pipe)
		fields := StrSplit(fld,pipe)
		continue
	} else if (i~=pipe) {
		str :=
		values := []
		val := trim(i,pipe)
		values := StrSplit(val,pipe)
		y.addElement("result","/root/group[@name='" grp "']")
		loop, % fields.length()
		{
			x := A_Index
			yv := y.createElement(fields[x])
			yt := y.createTextNode(values[x])
			y.selectSingleNode("/root/group[@name='" grp "']").lastChild.appendChild(yv).appendChild(yt)
		}
	}
}
y.viewXML()
ExitApp

#Include Includes
#Include strX.ahk
#Include stregX.ahk
#Include xml.ahk
