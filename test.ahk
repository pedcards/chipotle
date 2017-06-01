doc := []
x := "T Chan"
y := z := 100

if !instr(x,",") {
	crd := RegExReplace(x,"(\w.*\w) (\w.*)","$2, $1")
}
Loop, Read, outdocs.csv
{
	;~ LineNum := A_Index
	Loop, parse, A_LoopReadLine, CSV
	{
		doc[A_Index] := A_LoopField
	}
	if !instr(doc[4],"@") {
		continue
	}
	y := fuzzysearch(x,doc[1])*100
	if (y=0) {
		best := doc[1]
		MsgBox here
		break
	}
	if (y<z) {
		z := y
		best := doc[1]
	}
}
MsgBox % best

#Include includes/sift3.ahk
