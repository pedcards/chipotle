FileRead, txt, .\files\data_in\sensis\SensisExportExample.HIS
StringReplace, txt, txt, `r`n, `n, All
n := 1
pipe := chr(0xB3)

Loop, parse, txt, `n, `r
{
	i := A_LoopField
	if (i~="^Group:") {
		grp := 
		grp := strX(i,"Group:",1,6,"",0)
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
		loop, % fields.length()
		{
			x := A_Index
			str .= fields[x] ": " values[x] "`n"
		}
		MsgBox,,% grp, % str
	}
}
ExitApp

#Include Includes
#Include strX.ahk
#Include stregX.ahk
#Include xml.ahk
