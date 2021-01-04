global epicWin
global hndText:={}, svcText:={}, EpicSvcList:=[]
/*	Strings for FindText
	Stick these in INI
 */



F12::
{
	res := syncHandoff()
}

syncHandoff() {
	res := {}
	t0 := A_TickCount
	epicWin := WinExist("Hyperspace")

	loop, 4																				; Iterate until Handoff editor launched
	{																					; this is much faster if you select manually
		HndOff := checkHandoff()
		if IsObject(HndOff) {
			break
		}
	}
	if !IsObject(HndOff) {
		msgbox fail
		return
	}

	Loop, % EpicSvcList.MaxIndex()														; Find matching Service List on screen
	{
		k := EpicSvcList[A_index]
		if IsObject(FindText(0,0,1920,500,0,0,svcText[k])) {
			HndOff.Service := k
		}
	}
	if (HndOff.Service="") {															; no match, will need to choose
		MsgBox No service found
		return
	}

	loop,																				; Loop through each patient in list
	{
		tt0 := A_TickCount
		progress, % A_index*10,% " ",% " "
		clickField(HndOff.tabX,HndOff.IllnessY)
		updateSmartLinks(HndOff.UpdateX,HndOff.UpdateY)

		Clipboard :=
		c0 := Clipboard
		fld := []
		loop, 3																			; get 3 attempts to capture clipboard
		{
			progress,,% "Attempt " A_Index
			clp := getClip()
			if (clp!=c0) {
				fld.MRN := strX(clp,"[MRN] ",1,6," [DOB]",0,6)							; clip changed from baseline
				; fld := readClip(clp)
				fld.Data := clp
				progress,,,% fld.MRN
				break
			}
		}
 		if (clp="`r`n") {																; field is truly blank
			MsgBox 0x40024, Novel patient?, Insert CHIPOTLE smart text?`n
			IfMsgBox Yes, {
				clickField(HndOff.tabX,HndOff.IllnessY)
				SendInput, .chipotle{enter}												; type dot phrase to insert
				sleep 300
				ScrCmp(HndOff.TextX,HndOff.TextY,100,10)								; detect when text expands
				continue
			} 
		}

 		if instr(txt,fld.MRN) {															; break loop if we have read this record already
			break
		}

		clickField(HndOff.tabX,HndOff.SummaryY)											; now grab the Patient Summary field 
		Clipboard :=
		c0 := Clipboard
		loop, 3
		{
			clp := getClip()
			if (clp!=c0) {
				fld.Summary := clp
				break
			}
		}

		txt .= fld.MRN " " (A_TickCount-tt0)/1000 "`n"
		lastMRN := fld.MRN

		res.push(fld)																	; push {MRN, Data, Summary} to RES

		SendInput, !n																	; Alt+n to move to next record
		scrcmp(HndOff.tabX,HndOff.NameY,100,15)											; detect when Name on screen changes
	}

	MsgBox,,% HndOff.Service, % "T=" (A_TickCount-t0)/1000 "`n`n" txt
	return res
}

ExitApp

checkHandoff() {
/*	Check if Handoff is running for this Patient List
	If not, start it
	Returns 
*/

/*	First stage: look for "Handoff" tab in right sidebar
		* Find section header geometry for "Illness Severity", "Patient Summary", "Action Item"
		* Find location of "Updates" (clapboard icon)
		* Calculate targets for text fields, CHIPOTLETEXT, name bar
		* Returns targets

*/
	if (ok:=FindText(0,0,1920,500,0.2,0.2,hndText.HandoffTab)) {
		progress, 40, Illness Severity, Finding geometry
		Ill := FindText(0,0,1920,1024,0.2,0.2,hndText.IllnessSev)
		progress, 80, Patient Summary, Finding geometry
		Summ := FindText(0,0,1920,1024,0.2,0.2,hndText.PatientSum)
		if !IsObject(Ill) {																; no Illness Severity field found
			gosub startHandoff															
			return
		}

		progress, 100, Updates, Finding geometry
		Upd := FindText(0,0,1920,1024,0.1,0.1,hndText.Updates)

		progress, hide
		return { tabX:ok[1].x
				, IllnessY:Ill[1].y+100
				, SummaryY:Summ[1].y+100
				, NameY:Ill[1].y-100
				, TextX:ok[1].x-180
				, TextY:Ill[1].y+70
				, UpdateX:Upd[1].x 
				, UpdateY:Upd[1].y+2 }
	} 
/*	Second stage: Look for Write Handoff button (single patient selected)
					or select single patient
*/
	startHandoff:
	if (ok:=FindText(0,0,1920,500,0.2,0.2,hndText.WriteHand)) {
		clickField(ok[1].x,ok[1].y)
		sleep 200
	} 

	ok:=FindText(0,0,1920,500,0.2,0.2,hndText.PatientNam)
	clickfield(ok[1].x,ok[1].y+50)
	sleep 200
	
	return
}

clickField(x,y,delay:=0) {
	WinActivate, ahk_id %epicWin%
	sleep % delay
	MouseClick, L, % x, % y
	sleep % delay
	return
}

getClip() {
	SendInput, ^a
	sleep 50
	SendInput, ^c
	sleep 200																			; Citrix needs time to copy to local clipboard
	return Clipboard
}

readClip(byref clp) {
	top := SubStr(clp, 1, 256)
	t1 := StregX(top,"--CHIPOTLE Sign Out ",0,1,"--",1)
	n:=1
	fld := []
	Loop
	{
		k := stregx(top,"\[\w+\]",n,0," \[|\R+",1,n)
		RegExMatch(k, "O)\[(.*)\] (.*)",match)
		if (match.value(1)="") {
			break
		}
		fld[match.value(1)] := match.value(2)
	}
	fld.time := t1
	vs := stregx(clp,"<VITALS>",1,1,"</VITALS>",1)


	return fld
}

updateSmartLinks(x,y) {
/*	Updates smart links by sending ctrl+F11 to the active window
	Arguments (x,y) are pixel coords to monitor change in Update icon
*/
	SendInput, ^{F11}
	sleep 100
	loop,
	{
		PixelGetColor, col, % x , % y
		; progress,,,% col
		if (col="0xFFFFFF") {
			break
		}
	}
	return
}

#Include Includes
#Include strX.ahk
#Include stregX.ahk
#Include xml.ahk
#Include FindText.ahk
#Include ScrCmp.ahk
