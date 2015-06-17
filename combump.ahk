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

user := A_UserName
if (user="tchun1") {
	ahk_path := "O:\PApps\PortableApps\AutoHotkey"
} else {
	ahk_path := "C:\Program Files (x86)\AutoHotkey\Compiler"
}
ahk2exe_loc := ahk_path "\Ahk2Exe.exe"
ahk2exe_mpr := ahk_path "\mpress.exe"

fileIn := "chipotle.ahk"
fileIco := "pepper32.ico"

FileRead, txt, %fileIn%

RegExMatch(txt,"Oi)vers := "".*""",vers) 
versOld := strX(vers.value,"""",1,1,"""",1,1)
InputBox, versNew, Change version string, % "Previous version: " versOld,,,,,,,,% versOld
versNewStr := "vers := """ versNew """"
if ErrorLevel {
	MsgBox Cancelled
	ExitApp
}
;FileDelete chipotle.tmp.bak
FileMove, %fileIn%, chipotle.tmp.bak, 1


txtOut := RegExReplace(txt,vers.value,versNewStr,,1)
FileDelete chipotle.tmp
FileAppend, %txtOut%, chipotle.tmp

fileOut := "chipotle-" versNew "-" A_Now ".exe" 
RunWait, %ahk2exe_loc% /in "chipotle.tmp" /out "chipotle.exe" /icon %fileIco% /mpress 1
FileCopy, chipotle.exe, %fileOut%
FileMove, chipotle.tmp, chipotle.ahk, 1

if (user="tchun1") {
	netDir := "\\chmc16\Cardio\Inpatient List\chipotle\"
	netFile := """" netDir "chipotle.exe"""
	netOld := """" netDir "chipotle." versOld ".exe"""
	netIni := """" netDir "chipotle.ini"""
	FileMove, %netFile%, %netOld%
	FileCopy, chipotle.exe, %netFile%, 1
	FileCopy, chipotle.ini, %netIni%, 1
}

#Include strx.ahk
