PM_chk := "Main GUI"
gosub main

WinWaitClose, Main GUI
ExitApp


Main:
{
	Gui, PmGui:Destroy
	Gui, PmGui:Default
	Gui, Add, Text, Center, Pacemaker Settings
	Gui, Add, Text, Center, % (pmDate.MM) ? pmDate.MM "/" pmDate.DD "/" pmDate.YYYY " @ " pmDate.HH ":" pmDate.min ":" pmDate.sec : ""
	Gui, Add, Text, Section, MODE
	Gui, Add, Text, xm yp+22, LRL
	Gui, Add, Text, xm yp+22, URL
	Gui, Add, Edit, ys-2 w40 vPmSet_mode, % PmSet.mode
	Gui, Add, Edit, yp+22 w40 vPmSet_LRL, % PmSet.LRL
	Gui, Add, Edit, yp+22 w40 vPmSet_URL, % PmSet.URL
	
	Gui, Add, Text, xm+120 ys, AVI
	Gui, Add, Text, xp yp+22, PVARP
	Gui, Add, Edit, ys-2 w40 vPmSet_AVI, % PmSet.AVI
	Gui, Add, Edit, yp+22 w40 vPmSet_PVARP, % PmSet.PVARP
	
	Gui, add, text, xm yp+60 w210 h1 0x7  ;Horizontal Line > Black
	
	Gui, Font, Bold
	Gui, Add, Text, xm yp+22, Tested
	Gui, Add, Text, xm+120 yp, Programmed
	
	Gui, Font, Normal
	Gui, Add, Text, Section xm yp+22, Ap (mA)
	Gui, Add, Text, xm yp+22, As (mV)
	Gui, Add, Text, xm yp+22, Vp (mA)
	Gui, Add, Text, xm yp+22, Vs (mV)
	Gui, Add, Edit, ys-2 w40 vPmSet_ApThr, % PmSet.ApThr
	Gui, Add, Edit, yp+22 w40 vPmSet_AsThr, % PmSet.AsThr
	Gui, Add, Edit, yp+22 w40 vPmSet_VpThr, % PmSet.VpThr
	Gui, Add, Edit, yp+22 w40 vPmSet_VsThr, % PmSet.VsThr

	Gui, Add, Text, xm+120 ys, Ap (mA)
	Gui, Add, Text, xp yp+22, As (mV)
	Gui, Add, Text, xp yp+22, Vp (mA)
	Gui, Add, Text, xp yp+22, Vs (mV)
	Gui, Add, Edit, ys-2 w40 vPmSet_Ap, % PmSet.Ap
	Gui, Add, Edit, yp+22 w40 vPmSet_As, % PmSet.As
	Gui, Add, Edit, yp+22 w40 vPmSet_Vp, % PmSet.Vp
	Gui, Add, Edit, yp+22 w40 vPmSet_Vs, % PmSet.Vs

	Gui, Add, Edit, xm yp+30 w210 r2 vPmSet_notes, % PmSet.notes
	Gui, Add, Button, xm w210 Center , Save values

	Gui, -MinimizeBox -MaximizeBox
	Gui, Show, AutoSize, % PM_chk
	return
}

#Include includes\strx.ahk
