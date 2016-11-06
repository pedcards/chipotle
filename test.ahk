	dirlist :=
	Loop, logs\*.*
	{
		dirlist .= A_LoopFileTimeCreated "`t" A_LoopFileName "`n"
	}
	sort, dirlist, R
	
	loop, parse, dirlist, `n
	{
		name := strX(A_LoopField, "`t",1,1, "",0)
		MsgBox % "'" name "'"
	}
	

ExitApp
#Include includes\strx.ahk