/*	Compile bump - compiles 
	- get old version num
	- ask for new version num
	- replace version string
	- compile "chipotle-VER-DATETIME.exe"
	- delete old chipotle.exe
	- copy chipotle-VER-DATETIME.exe to chipotle.exe
	- if on network, copy new chipotle.exe to shared folder
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

Progress, 20, Finding files..., COMBUMP
user := A_UserName
ahk_path := ((user="tchun1") ? "O:\PApps\PortableApps" : "C:\Program Files") . "\AutoHotkey\Compiler"
ahk2exe_loc := ahk_path "\Ahk2Exe.exe"
ahk2exe_mpr := ahk_path "\mpress.exe"

fileIn := "chipotle.ahk"
fileIco := "pepper32.ico"

Progress, 40, Reading chipotle.ahk, COMBUMP
FileRead, txt, %fileIn%

RegExMatch(txt,"Oi)vers := "".*""",vers) 
versOld := strX(vers.value,"""",1,1,"""",1,1)
Progress, hide
InputBox, versNew, Change version string, % "Previous version: " versOld,,,,,,,,% versOld
Progress, show
versNewStr := "vers := """ versNew """"
if ErrorLevel {
	MsgBox Cancelled
	ExitApp
}
Progress, 60, Moving files..., COMBUMP
;FileDelete chipotle.tmp.bak
FileMove, %fileIn%, chipotle.tmp.bak, 1


txtOut := RegExReplace(txt,vers.value,versNewStr,,1)
FileDelete chipotle.tmp
FileAppend, %txtOut%, chipotle.tmp

Progress, 80, Compiling new version..., COMBUMP
fileOut := "chipotle-" versNew "-" A_Now ".exe" 
RunWait, %ahk2exe_loc% /in "chipotle.tmp" /out "chipotle.exe" /icon %fileIco% /mpress 1
FileCopy, chipotle.exe, %fileOut%, 1
FileMove, chipotle.ini, chipotle.ini, 1
FileMove, chipotle.tmp, chipotle.ahk, 1

Progress, 100, Finishing..., COMBUMP
Progress, off
MsgBox % "Compiled and bumped to version " versNew

ExitApp

StrX( H,  BS="",BO=0,BT=1,   ES="",EO=0,ET=1,  ByRef N="" ) { ;    | by Skan | 19-Nov-2009
Return SubStr(H,P:=(((Z:=StrLen(ES))+(X:=StrLen(H))+StrLen(BS)-Z-X)?((T:=InStr(H,BS,0,((BO
<0)?(1):(BO))))?(T+BT):(X+1)):(1)),(N:=P+((Z)?((T:=InStr(H,ES,0,((EO)?(P+1):(0))))?(T-P+Z
+(0-ET)):(X+P)):(X)))-P) ; v1.0-196c 21-Nov-2009 www.autohotkey.com/forum/topic51354.html
}
