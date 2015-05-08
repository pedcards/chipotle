file = %A_ScriptDir%\Sign-out.docx
WordDoc := ComObjGet(file).range.text
MsgBox % WordDoc
