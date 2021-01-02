global epicWin
global fText={}
fText.WriteHand  := "|<>*186$68.000000000003k7U00000001w3w00000000TUz000000007sDkkkkAk031w3wACA0A00sD0S1bXC73UC1U30Nsbxtw3Uw1s6PNnAn0sT0z0iqMnAEDrsDkDDaAry3xz7w3ltXBz0sTvz0QQMnA0C7zzk776AnC3Vw3w1VlXCT0sT0z000003U07kDk00000001w3w00000000T0z000000007kDk00000002"
fText.HandoffTab := "|<>*193$64.00000000000w1s00000007sDk0000000TUz00000001y3w1UM0001bs7k61U000670C0M60000MM0s1UMQ1kDXk7k73XwzXyTUT0Ty8nbAty3w1ks3ARlbwTk61Xwlr6Tzz0M6Tn7QNzzw1UNXARlbs7k61aQlnCTUT0M6Dn77ty1w000800A7s7k0000000TUT00000001y1w000000000000000000U"
fText.IllnessSev := "|<>*191$99.000000000000000001VU00000000000004CQ000000001k0001lnU00000001z0000CCQ00000000Ts0001lnU00000007U0000CCQNs3kDVw0s07VUllnXzUz3wTU7U3yQ7CCQTyDwzbw0S0TtlllnXlnVr0s03w73iCCCQQCTyw7U07szxlllnXVnzXsT00D7zbQCCQQCw0DVw00xs0vVlnXVnU0S3k03b07QCCQQCQ01kC00Qs0T1lnXVnzbSvk7zbr3sCCQQCDwzbw0zsTsS0lVX0kT3sT03w1w1k00000000000000004"
fText.PatientSum := "|<>*185$97.00000C0000000000Dw00670000600z007z00700000301zU03nk03U00001U1w001ks03k00001s0s000sQTXyMDkzlz0Q0MCQCTtzADwTwzUD0A7C70CS6C7CCD03s63bz0T737zb3300z31nz1zXVXznVVU07lUty1xlklk1kkk00wkQs0kssMs0sMM00CMCQ0sQQAQ0QAA007C7C0CSC6D6C6707Dbjb07z7n3z733s3zVznU1vVtUz31Uw0zUys0000000000000001"
fText.PatientNam := "|<>*212$71.000000000001z001U0000k83z00X00001ks6701a000M3VkA6030000k7XUMATDMyDnkDb7ktzSnyTrUTCTzmCNaAla0rQnz0QnQtXA1bs60Dtazn6M37nw0NnBk6Ak6DiM1naNXANUADQk1zCnyMnUMSTU3yTXslb0kMw000000000004"
fText.ActionItem := "|<>*189$71.0000000000000000000000000000000000000000000000000000600000010000C0000007000kM00000QT001U000000sy0030000001ny0TTn0y3D03bQ3yzb7y7z07CsDxyCTyDy0CssQ0kQsQQC0Rllk1UtkMsQ0vznU31r0tks1rzb063i1n1k3jzC0A7Q363U7EDC0MCQCA70CUCTswQzwMC0R0QTlwszkkQ0s0MT1tUS1Uk0k00000000000000000000000000000000000000000000001"
fText.Updates    := "|<>*166$21.yQvwtrznjzyBzzlzzyQtlrCQC001k00C001k00C001k00C001k00TzzzU"



F12::
{
	if (ok:=FindText(0,0,1920,500,0.2,0.2,fText.HandoffTab)) {
		HO_x := ok[1].x
		progress, 20, Illness Severity, Finding geometry
		fldIll := FindText(0,0,1920,1024,0.2,0.2,fText.IllnessSev)
		progress, 40, Patient Summary, Finding geometry
		fldSum := FindText(0,0,1920,1024,0.2,0.2,fText.PatientSum)
		progress, 80, Action Item, Finding geometry
		fldAct := FindText(0,0,1920,1024,0.2,0.2,fText.ActionItem)
		progress, 100, Updates, Finding geometry
		fldAct := FindText(0,0,1920,1024,0.1,0.1,fText.Updates)

		hoIll_y := fldIll[1].y+100
		hoSum_y := fldSum[1].y+100
		hoName_y := fldIll[1].y-100
		progress, hide
	} else {
		MsgBox Not here!
		ExitApp
	}

	t0 := A_TickCount
	epicWin := WinExist("Hyperspace")
	loop,
	{
		tt0 := A_TickCount
		progress, % A_index*10,% " ",% " "
		clickField(HO_x,hoIll_y)
		updateField(fldAct[1].x,fldAct[1].y)

		Clipboard :=
		c0 := Clipboard
		loop, 3
		{
			progress,,% "Attempt " A_Index
			clp := getClip()
			if (clp=c0) {																; clip unchanged from baseline
				Continue																; do it again
			}
			else {
				fld := readClip(clp)
				progress,,,% fld.Name " " fld.Time
				break
			} 
		}

 		if (clp="`r`n") {
			MsgBox 0x40024, Novel patient?, Insert CHIPOTLE smart text?`n
			IfMsgBox Yes, {
				clickField(HO_x,hoIll_y)
				SendInput, .chip{enter}
				sleep 500
				ScrCmp(HO_x-180,hoIll_y-30,100,10)
				continue
			} 
		}

 		if instr(txt,fld.MRN) {
			break
		}
		txt .= fld.MRN " " (A_TickCount-tt0)/1000 "`n"
		lastMRN := fld.MRN
		
		; clp := getClip()
		; readClip(clp)
		; sleep 200

		SendInput, !n
		scrcmp(1445,235,100,15)
	}

	MsgBox, % "T=" (A_TickCount-t0)/1000 "`n`n" txt
}

ExitApp

clickField(x,y,delay:=20) {
	WinActivate, ahk_id %epicWin%
	sleep % delay
	MouseMove, x,y, 0
	sleep % delay
	MouseClick, L, x, y

	return
}

getClip() {
	SendInput, ^a
	sleep 50
	SendInput, ^c
	sleep 200
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

updateField(x,y) {
	SendInput, ^{F11}
	sleep 100
	loop,
	{
		PixelGetColor, col, X, Y
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
