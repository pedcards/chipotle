whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")						; initialize http request in object whr
	whr.Open("GET"														; set the http verb to GET file "change"
		,"https://depts.washington.edu/pedcards/change/direct.php?do=get"
		, true)
	whr.Send()															; SEND the command to the address
	whr.WaitForResponse()
ckUrl := whr.ResponseText												; the http response

MsgBox % ckUrl
