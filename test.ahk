fileread, str, bak\20161114091131.bak
badstr := "~~"
if (pos:=RegExMatch(str,badstr)) {
	RegExMatch(str,"O)</\w+\s*[\^>]*>",post,pos)
	per := instr(str,"<id",,pos-strlen(str))
	RegExMatch(str,"O)<\w+((\s+\w+(\s*=\s*(?:"".*?""|'.*?'|[\^'"">\s]+))?)+\s*|\s*)/?>",pre,per)
	MsgBox % "Illegal chars detected at position " pos ".`n" post.value "`n" pre.value
	
	;~ str := RegExReplace(str,"[^[:ascii:]]","~")
}

ExitApp

#Include includes\strx.ahk
