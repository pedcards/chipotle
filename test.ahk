FileRead, txt, .\files\data_in\sensis\SensisExportExample.HIS
StringReplace, txt, txt, `r`n, `n, All
n := 1

Loop
{
	i := strx(txt,"Group:",n,0,"`n`n",1,0,n)
	grp := strX(i,"Group:",1,6,"`n",1,1)
	fld := strX(i,"Fields:",1,7,"`n",1,1,nn)
	val := strX(i,"`n",nn-1,1,"",0)
	;~ MsgBox  % "Grp: " grp "`n"
			;~ . "Fld: " fld "`n"
			;~ . "Val: " val "`n"
	fld := trim(fld,"³")
	val := trim(val,"³")
	StringSplit, ele, fld, % "³"
	StringSplit, res, val, % "³"
	loop, % ele0
	{
		idx := A_Index
		MsgBox,,% grp "[" idx "/" ele0 "]", % ele%idx% "`n" res%idx%
	}
}
ExitApp

#Include Includes
#Include strX.ahk
#Include stregX.ahk
#Include xml.ahk
