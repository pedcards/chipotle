global epicWin
global fText:={}, svcText:={}, EpicSvcList:=[]
/*	Strings for FindText
	Stick these in INI
 */
fText.WriteHand  := "|<>*186$68.000000000003k7U00000001w3w00000000TUz000000007sDkkkkAk031w3wACA0A00sD0S1bXC73UC1U30Nsbxtw3Uw1s6PNnAn0sT0z0iqMnAEDrsDkDDaAry3xz7w3ltXBz0sTvz0QQMnA0C7zzk776AnC3Vw3w1VlXCT0sT0z000003U07kDk00000001w3w00000000T0z000000007kDk00000002"
fText.HandoffTab := "|<>*193$64.00000000000w1s00000007sDk0000000TUz00000001y3w1UM0001bs7k61U000670C0M60000MM0s1UMQ1kDXk7k73XwzXyTUT0Ty8nbAty3w1ks3ARlbwTk61Xwlr6Tzz0M6Tn7QNzzw1UNXARlbs7k61aQlnCTUT0M6Dn77ty1w000800A7s7k0000000TUT00000001y1w000000000000000000U"
fText.IllnessSev := "|<>*191$99.000000000000000001VU00000000000004CQ000000001k0001lnU00000001z0000CCQ00000000Ts0001lnU00000007U0000CCQNs3kDVw0s07VUllnXzUz3wTU7U3yQ7CCQTyDwzbw0S0TtlllnXlnVr0s03w73iCCCQQCTyw7U07szxlllnXVnzXsT00D7zbQCCQQCw0DVw00xs0vVlnXVnU0S3k03b07QCCQQCQ01kC00Qs0T1lnXVnzbSvk7zbr3sCCQQCDwzbw0zsTsS0lVX0kT3sT03w1w1k00000000000000004"
fText.PatientSum := "|<>*185$97.00000C0000000000Dw00670000600z007z00700000301zU03nk03U00001U1w001ks03k00001s0s000sQTXyMDkzlz0Q0MCQCTtzADwTwzUD0A7C70CS6C7CCD03s63bz0T737zb3300z31nz1zXVXznVVU07lUty1xlklk1kkk00wkQs0kssMs0sMM00CMCQ0sQQAQ0QAA007C7C0CSC6D6C6707Dbjb07z7n3z733s3zVznU1vVtUz31Uw0zUys0000000000000001"
fText.PatientNam := "|<>*212$71.000000000001z001U0000k83z00X00001ks6701a000M3VkA6030000k7XUMATDMyDnkDb7ktzSnyTrUTCTzmCNaAla0rQnz0QnQtXA1bs60Dtazn6M37nw0NnBk6Ak6DiM1naNXANUADQk1zCnyMnUMSTU3yTXslb0kMw000000000004"
fText.ActionItem := "|<>*189$71.0000000000000000000000000000000000000000000000000000600000010000C0000007000kM00000QT001U000000sy0030000001ny0TTn0y3D03bQ3yzb7y7z07CsDxyCTyDy0CssQ0kQsQQC0Rllk1UtkMsQ0vznU31r0tks1rzb063i1n1k3jzC0A7Q363U7EDC0MCQCA70CUCTswQzwMC0R0QTlwszkkQ0s0MT1tUS1Uk0k00000000000000000000000000000000000000000000001"
fText.Updates    := "|<>*166$21.yQvwtrznjzyBzzlzzyQtlrCQC001k00C001k00C001k00C001k00TzzzU"

svcText.EPteam := "|<>*193$71.00000000000000000000000000000000000000000000000000000000000DwTk0zw00000Tszk1zs00000k1Vk0A000001U31U0M00000306300k3sDkzq0A601UDsTlzjsMQ030sk1XXTstk061Uk3b2k1z00A71VzC5U3U00MDzDCQ/06000kTwQQsK0A001Us0ktkg0M0030k1VnVM0k0061kX7b2zlU00A1z7zC4zU00000s300000000000000000000000000000000000000000000000001"
svcText.ICUcons := "|<>*197$101.00000000000000000k3wM1063y00000001UTsk70QTw000000031k1UC0ls8000000067030Q1X000000000AA060s7C01y3z1yQ6Ms0A1kAM07y7z7wsQlU0M3Usk0ACCCA1ktX00k71XU0kCQAM3Vn601UC3701UQsQs73aA030QAC030tksyC7AQ060sMA061nVkSQCMM0C1lkQ0A3b3UQsQks0A330M0Q6C70NktUsAQCC0wAQQQCMlnn0zkTkM0TsTksQz1zW0T0D0k0D0C00Ew1m000003U00000000000000060000000000000000000000000002"
svcText.Wardcons := "|<>*193$101.00000000000000000000000030000000030M6000060M7s000061kA0000A0kzk0000C3Us0000M33U00000Q7VU0000k6C000000MT33wDlzUQM03w7w2kyC7wT7z0lk0DwDwBVgQ0MsQC1X00sMQQvaQk1lUkQ7601UMkNnAtUTX1UMAA070lUnaMr3r630ksM0C1X1XDli66A61VUs0Q3630D3sQAMA330k0s6A60S3ksMkQCA1k0kQMA0w7VllUswM1kNlkkNUsD1zX0ztU1zVz1UnU080k00Q300Q0s0010000000060000000000000000800000002"
EpicSvcList := ["EPteam","ICUcons","Wardcons"]


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
	if (ok:=FindText(0,0,1920,500,0.2,0.2,fText.HandoffTab)) {
		progress, 40, Illness Severity, Finding geometry
		Ill := FindText(0,0,1920,1024,0.2,0.2,fText.IllnessSev)
		progress, 80, Patient Summary, Finding geometry
		Summ := FindText(0,0,1920,1024,0.2,0.2,fText.PatientSum)
		if !IsObject(Ill) {																; no Illness Severity field found
			gosub startHandoff															
			return
		}

		progress, 100, Updates, Finding geometry
		Upd := FindText(0,0,1920,1024,0.1,0.1,fText.Updates)

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
	if (ok:=FindText(0,0,1920,500,0.2,0.2,fText.WriteHand)) {
		clickField(ok[1].x,ok[1].y)
		sleep 200
	} 

	ok:=FindText(0,0,1920,500,0.2,0.2,fText.PatientNam)
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
