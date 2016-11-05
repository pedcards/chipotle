	dirlist :=
	Loop, logs\*.*
	{
		dirlist .= A_LoopFileTimeCreated "`t" A_LoopFileName "`n"
	}
	sort, dirlist, R
	
	loop, parse, dirlist, `n
	{
		;~ StringSplit, name, A_LoopField, `t
		name := instr(A_LoopField, A_tab, 0)
		MsgBox % name
	}
	
