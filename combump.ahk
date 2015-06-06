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

ahk2exe_loc := "O:\PApps\PortableApps\AutoHotkey\Ahk2Exe.exe"
ahk2exe_mpr := "O:\PApps\PortableApps\AutoHotkey\mpress.exe"

fileIn := "chipotle.ahk"
fileOut := "chipotle.exe"
iconIn := "pepper32.ico"
splitpath, fileIn,,,,fileNam

MsgBox % fileIn "`n" fileNam

#Include strx.ahk
