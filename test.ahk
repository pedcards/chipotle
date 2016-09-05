;~ whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")						; initialize http request in object whr
	;~ whr.Open("GET"														; set the http verb to GET file "change"
		;~ ,"https://depts.washington.edu/pedcards/change/direct.php?test=true&do=get"
		;~ , true)
	;~ whr.Send()															; SEND the command to the address
	;~ whr.WaitForResponse()
;~ ckUrl := whr.ResponseText												; the http response

;~ MsgBox % ckUrl

#include includes/strx.ahk

nodepath := "weekly/notes"

path1 := strX(nodePath, "",1,0, "/",1,1)
path2 := strX(nodePath, "/",1,1, "",1,0)

MsgBox,, % nodepath, % path1 "`n" path2
