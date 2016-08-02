PatListGUIcc:
{
	pl_demo := ""
		. "DOB: " pl_DOB 
		. "   Age: " (instr(pl_Age,"month")?RegExReplace(pl_Age,"i)month","mo"):instr(pl_Age,"year")?RegExReplace(pl_Age,"i)year","yr"):pl_Age) 
		. "   Sex: " substr(pl_Sex,1,1) "`n`n"
		. pl_Unit " :: " pl_Room "`n"
		. pl_Svc "`n"
		. "Admitted: " pl_Admit
	pl_infoDT := breakdate(pl_info.getAttribute("date"))
	winFW := win.wX
	Gui, plistG:Destroy
	Gui, plistG:Default
	Gui, -DPIScale
	Gui, Font, Bold
	Gui, Add, GroupBox, % "x"win.bor " y"win.bor " w"win.boxH " h"win.demo_h, % pl_NameL . ", " . pl_NameF "  ---  " MRN
	Gui, Add, GroupBox, % "x"win.bor+win.boxH+win.boxQ+win.bor " y"win.bor " w"win.boxQ-win.bor " h"win.demo_h
	Gui, Add, GroupBox, % "x"win.bor+win.boxH " y"win.bor " w"win.boxQ " h"win.demo_h/2+4
	Gui, Add, GroupBox, % "xP yP+"win.demo_h/2-4 " wP hP"
	Gui, Font, Normal
	Gui, Add, Text, % "x"win.bor+10 " y"win.bor+20, % pl_demo
	Gui, Add, Text, % "x"win.bor+win.boxH+10 " y"win.bor+10 " w"win.boxQ-14 , % "CRD: " pl_ProvCard "`n" ((pl_ProvSchCard) ? "CRD(SCH): " pl_ProvSchCard : "")
	Gui, Add, Text, % "xP yP+"win.demo_h/2-4 " wP", % "CSR: " pl_provCSR
	y0 := win.bor+win.demo_h+win.bor
	for key,val in ccFields {
		x0 := win.bor
		w0 := win.boxF
		h0 := win.field_H
		box1 := "x"x0 " y"y0 " w"w0 " h"h0
		edVar := "cc"val
		edVal := pl_ccSys.selectSingleNode(val).text
		if (edVar = "ccFEN") {
			edVal := plDiet(edVal)
		}
		edit1 := "x"x0+3 " y"y0+12 " w"w0-5 " h"h0-16 " -VScroll gplInputNote v"edVar
		Gui, Font, Bold
		Gui, Add, GroupBox, % box1, % RegExReplace(val,"_","/")
		Gui, Font, Normal
		Gui, Add, Edit, % edit1, % edVal
		y0 += h0
	}
	Gui, Add, Button, % "x"win.bor " w"win.boxQ-20 " h"win.rh*2.5 " gPlSumm", Weekly Summary
	Gui, Add, Button, % "xP+"win.boxQ " yP w"win.boxQ-20 " h"win.rh*2.5 " gPlTasksList", Tasks/Todo
	Gui, Add, Button, % "xP+"win.boxQ " yP w"win.boxQ-20 " h"win.rh*2.5 " gplMar", Medications
	Gui, Add, Button, % "x"win.bor+win.boxF " yP w"win.boxQ-20 " h"win.rh*2.5,Hello >'o'<
	Gui, Add, Button, % "x"win.bor " w"win.boxQ-20 " h"win.rh*2.5 " gplHealthMaint", Health Maintenance
	Gui, Add, Button, % "xP+"win.boxQ " yP w"win.boxQ-20 " h"win.rh*2.5 " Disabled", Cath Plan
	Gui, Add, Button, % "xP+"win.boxQ " yP w"win.boxQ-20 " h"win.rh*2.5 " gplDCinject", Discharge note injector
	Gui, Add, Button, % "x"win.bor+win.boxF " yP w"win.boxQ-20 " h"win.rh*2.5 " gplSave", SAVE
	Gui, Show, % "w"winFw " h"win.wY, % "CON CARNE - " pl_nameL

	tmpDarr := Object()
	tmpDt := "DX|"
	Loop % (yInfo:=y.selectNodes("//id[@mrn='" MRN "']/info")).length
	{
		yInfoDt := yInfo.Item(A_index-1).getAttribute("date")
		tmpD := breakdate(yInfoDt)
		tmpDarr[tmpD.MM "/" tmpD.DD] := yInfoDt
		tmpDt .= tmpD.MM "/" tmpD.DD "|"
		tmpCt := A_Index
	}
	Gui, Add, Tab2, % "x"win.bor+win.boxF+win.bor " y"win.bor " w"win.rCol-win.bor " h"win.demo_H+win.cont_H-win.bor " -Wrap Choose"tmpCt+1, % tmpDt
	loop, parse, tmpDt, |
	{
		tmpG := A_LoopField
		tmpB := A_index
		pl_info := y.selectSingleNode("//id[@mrn='" MRN "']/info[@date='" tmpDarr[tmpG] "']")
		Gui, Tab, %tmpB%
		Gui, Add, Text, % "x"win.bor+win.boxF+win.bor*2 " y"win.bor+3*win.bor " w"win.rCol-3*win.bor-14 " -Wrap vccDataVS"tmpB, % ccData(pl_info,"VS")
		GuiControlGet, tmpPos, Pos, ccDataVS%tmpB%
		Gui, Add, Text, % "x"tmpPosX " yp+"tmpPosH " wP-10"
			ccData(pl_info,"labs")
	}
	w0 := win.rCol-3*win.bor
	Gui, Tab, Dx
	Gui, Add, Text, % "w" w0, Diagnoses && problems
	Gui, Add, Edit, % "w" w0 " h48 vpl_dxCard gplInputNote", %pl_dxCard%
	Gui, Add, Text
	Gui, Add, Text, % "w" w0 " ", EP diagnoses/problems
	Gui, Add, Edit, % "w" w0 " h48 vpl_dxEP gplInputNote", %pl_dxEP%
	Gui, Add, Text
	Gui, Add, Text, % "w" w0 " ", Surgeries/Caths/Interventions
	Gui, Add, Edit, % "w" w0 " h48 vpl_dxSurg gplInputNote", %pl_dxSurg%
	Gui, Add, Text
	Gui, Add, Text, % "w" w0 " ", Problems
	Gui, Add, Edit, % "w" w0 " h48 vpl_dxProb gplInputNote", %pl_dxProb%
	Gui, Add, Text
	Gui, Add, Text, % "w" w0 " ", Quick notes
	Gui, Add, Edit, % "w" w0 " h48 vpl_dxNotes gplInputNote", %pl_dxNotes%
	Gui, Add, Text
	Gui, Add, Text, % "w" w0 " ", Misc notes
	Gui, Add, Edit, % "w" w0 " h40 gplInputNote vpl_misc", %pl_misc%
	return
}

ccData(pl,sec) {
	if (sec="VS") {
		x := pl.selectSingleNode("vs")
			if (i:=x.selectSingleNode("wt")) {
				txt .= "Wt:`t" i.text ((j:=i.getAttribute("change")) ? " is "j : "")
			}
			if (i:=x.selectSingleNode("temp")) {
				txt .= "`nTemp:`t" vsMean(i.text) 
			}
			if (i:=x.selectSingleNode("hr")) {
				txt .= "`nHR:`t" vsMean(i.text)
			}
			if (i:=x.selectSingleNode("rr")) {
				txt .= "`nRR:`t" vsMean(i.text)
			}
			if (i:=x.selectSingleNode("bp")) {
				txt .= "`nBP:`t" vsMean(i.text)
			}
			if (i:=x.selectSingleNode("spo2")) {
				txt .= "`nspO2:`t" vsMean(i.text)
			}
			if (i:=x.selectSingleNode("pain")) {
				txt .= "`nPain:`t" vsMean(i.text)
			}
		if (x := pl.selectSingleNode("io")) {
			txt .= "`n"
		}
			if (i:=x.selectSingleNode("in")) {
				txt .= "`nIn:`t" i.text ((j:=x.selectSingleNode("po").text) ? " (" j " PO)" : "")
			}
			if (i:=x.selectSingleNode("out")) {
				txt .= "`nOut:`t" i.text
			}
			if (i:=x.selectSingleNode("ct")) {
				txt .= "`nCT:`t" i.text
			}
			if (i:=x.selectSingleNode("net")) {
				txt .= "`nNet:`t" i.text
			}
			if (i:=x.selectSingleNode("uop")) {
				txt .= "`nUOP:`t" i.text
			}
		return txt
	} 
	if (sec="labs") {
		global plistG, win
		x := pl.selectSingleNode("labs")
		if (i:=x.selectSingleNode("CBC")) {
			Hgb:=i.selectSingleNode("Hgb").text
			Hct:=i.selectSingleNode("Hct").text
			WBC:=i.selectSingleNode("WBC").text 
			Plt:=i.selectSingleNode("Plt").text 
			;txtln := (strlen(Hgb)>strlen(Hct)) ? strlen(Hgb) : strlen(Hct)
			txtln := compStr(Hgb,Hct)
			Gui, Add, Text,wP, % "CBC`t" i.selectSingleNode("legend").text
			Gui, Add, Text, Center Section wP, % Hgb "`n>" substr("————————————————————————————————————————",1,txtln.ln) "<`n" Hct
			Gui, Add, Text,% "xS+" (win.rCol/2)-txtln.px-ln(strlen(WBC))*10 " yS", % "`n" WBC
			Gui, Add, Text,% "xS+" (win.rCol/2)+(txtln.px/2) " yS", % "`n" Plt
			Gui, Add, Text,xS, % "`t" cleanwhitespace(i.selectSingleNode("rest").text)
		} 
		if (i:=x.selectSingleNode("Lytes")) {
			Gui, Add, Text,% "w" win.rCol-win.bor-20, % "Lytes`t" i.selectSingleNode("legend").text
			Na:=i.selectSingleNode("Na").text 
			K:=i.selectSingleNode("K").text 
			HCO3:=i.selectSingleNode("HCO3").text 
			Cl:=i.selectSingleNode("Cl").text 
			BUN:=i.selectSingleNode("BUN").text 
			Cr:=i.selectSingleNode("Cr").text 
			Glu:=i.selectSingleNode("Glu").text
			ch1 := compStr(Na,K)
			ch2 := compStr(HCO3,Cl)
			ch3 := compStr(BUN,Cr)
			Gui, Add, Text, % "Center Section", % "`t" Na "`n`n`t" K
			Gui, Add, Text, % "Center xS+"ch1.px+10 " yS", % HCO3 "`n`n" Cl
			Gui, Add, Text, % "Center xS+"ch1.px+ch2.px " yS", % Bun "`n`n" Cr
			Gui, Add, Text, xS yS+14, % "`t" substr("————————————————————————————————————————",1,ch1.ln) 
			Gui, Add, Text, % "xS+"ch1.px " yS+14", % substr("————————————————————————————————————————",1,ch2.ln+4) 
			Gui, Add, Text, % "xS+"ch1.px+ch2.px-20 " yS+14", % substr("————————————————————————————————————————",1,ch3.ln+2) "<    " Glu
			Gui, Add, Text, % "xS+"ch1.px " yS", % "|`n|`n|"
			Gui, Add, Text, % "xS+"ch1.px+ch2.px-20 " yS", % "|`n|`n|`n"
			if (ABG:=i.selectSingleNode("ABG").text) {
				Gui, Add, text, xS, % trim(ABG)
			}
			if (iCA:=i.selectSingleNode("iCA").text) {
				Gui, Add, text, xS, % iCA
			}
			if ((ALT:=i.selectSingleNode("ALT").text) or (AST:=i.selectSingleNode("AST").text)){
				Gui, Add, text, xS, % ALT "`t" ALT
			}
			if ((PTT:=i.selectSingleNode("PTT").text) or (INR:=i.selectSingleNode("INR").text)) {
				Gui, Add, text, xS, % PTT "`t" INR
			}
			if (Alb:=i.selectSingleNode("Alb").text) {
				Gui, Add, text, xS, % Alb
			}
			if (Lac:=i.selectSingleNode("Lac").text) {
				Gui, Add, text, xS, % Lac
			}
			if (CRP:=i.selectSingleNode("CRP").text) {
				Gui, Add, text, xS, % CRP
			}
			if (ESR:=i.selectSingleNode("ESR").text) {
				Gui, Add, text, xS, % ESR
			}
			if ((DBil:=i.selectSingleNode("DBil").text) or (IBil:=i.selectSingleNode("IBil").text)) {
				Gui, Add, text, xS, % DBil "`t" IBil
			}
			if (rest:=i.selectSingleNode("rest").text) {
				Gui, Add, text, % "+Wrap xS w" win.rCol-win.bor-20, % cleanwhitespace(rest)
			}
		}
	}
	return txt
}

plHealthMaint:
{
	hmtList := ["Nbs1:NBS#1 sent","Nbs2:NBS#2 sent","Baer:BAER passed","Oph:Ophtho","Gt:GT teaching","Seat:Car seat"
				, "Pcp:PCP","Crd:Cardiology","Ndv:Neurodev","OTPT:OT/PT/Speech"
				, "Synagis:Synagis candidate","Imms:Immunications","DC:Discharge plan","CPR:CPR"]
	hmtCol := 120
	hmtW := 250
	Gui, hMaint:Default
	Gui, Destroy
	for key,val in hmtList {
		opt := strX(val,,0,0,":",1,1)
		res := strX(val,":",1,1,"",1,1)
		chk := y.selectSingleNode(pl_mrnstring "/ccHMT/" opt).getAttribute("set")
		txt := y.selectSingleNode(pl_mrnstring "/ccHMT/" opt).text
		Gui, Add, Checkbox, % "x"win.bor " Checked"((chk)?"1":"0") " vhMT"opt , % res
		Gui, Add, Edit, % "x"hmtCol " yP-4 w"hmtW " vhMT"opt "Txt", % txt
	}
	Gui, Show, AutoSize, Health Maintenance
	return
}
hMaintGuiClose:
{
	Gui, hMaint:Submit
	if !IsObject(y.selectSingleNode(pl_mrnstring "/ccHMT")) {
		y.addElement("ccHMT", pl_mrnstring)
	}
	FormatTime, editdate, A_Now, yyyyMMddHHmmss
	y.setAtt(pl_mrnstring "/ccHMT", {ed: editdate},{au: user})

	for key,val in hmtList {
		opt := strX(val,,0,0,":",1,1)
		res := strX(val,":",1,1,"",1,1)
		if !IsObject(y.selectSingleNode(pl_mrnstring "/ccHMT/" opt)) {
			y.addElement(opt, pl_mrnstring "/ccHMT")
		}
		yHMT := y.selectSingleNode(pl_mrnstring "/ccHMT/" opt)
		ySet := yHMT.getAttribute("set")
		yRes := yHMT.text
		if !(hMT%opt%=ySet) {
			yHMT.setAttribute("set",hMT%opt%)
			eventlog(mrn " Health Maint " opt " changed.")
			yHMTchg = true
		}
		if !(hMT%opt%Txt=yRes) {
			y.setText(pl_mrnstring "/ccHMT/" opt,hMT%opt%Txt)
			eventlog(mrn " Health Maint " opt " info changed.")
			yHMTchg = true
		}
	}
	if (yHMTchg) {
		WriteOut(pl_mrnstring,"ccHMT")
		yHMTchg = false
	}
	return
}

vsMean(ByRef txt) {
	StringReplace, txt, txt, -%A_Space%, - , All
	StringReplace, txt, txt, /%A_Space%, / , All
	mean := strx(txt, " ",0,1, "",0,0)
	range := substr(txt,1,0-strlen(mean))
	StringReplace, range, range, - , %A_Space%-%A_Space%, All
	return range ((mean) ? "(" mean ")" : "")
}

compStr(a,b) {
	lnA := strlen(a)
	lnB := strlen(b)
	max := (lnA>lnB) ? a : b
	maxln := strlen(max)
	maxPx := log(maxln)*100
	return {max:max,ln:maxln,px:maxPx}
}

CountLines(Text)
	{ 
 	 StringReplace, Text, Text, `n, `n, UseErrorLevel
	 Return ErrorLevel + 1
	}

plDCinject:
{
	Gui, gDCinj:Destroy
	Gui, gDCinj:Default
	Gui, +AlwaysOnTop
	Gui, Add, Text, 
		, % "Select the item you want,`n"
		. "then paste (Ctrl-V) it where you want."
	Gui, Add, Button, w200 gInjSumm, Summaries
	Gui, Add, Button, w200 gInjUpd, Updates
	Gui, Add, Button, w200 gInjLabs, Labs
	Gui, Show, , Note Injector
	return
}

DCinjGuiClose:
{
	Gui, gDCinj:Destroy
	return
}

InjSumm:
{
	tmp := GetNotes(mrn,"weekly")
	Gui, gDCinj:Hide
	if (tmp) {
		Clipboard := tmp
		MsgBox Text has been copied to clipboard.`nPaste (Ctrl-V) where you want.
	} else {
		MsgBox No notes found!
	}
	Gui, gDCinj:Show
	return
}

InjUpd:
{
	tmp := GetNotes(mrn,"updates")
	Gui, gDCinj:Hide
	if (tmp) {
		Clipboard := tmp
		MsgBox Text has been copied to clipboard.`nPaste (Ctrl-V) where you want.
	} else {
		MsgBox No notes found!
	}
	Gui, gDCinj:Show
	return
}

InjLabs:
{
	tmpD := BreakDate(A_Now)
	dcLabs := y.selectSingleNode("//id[@mrn='" MRN "']/info[@date='" tmpDarr[tmpD.MM "/" tmpD.DD] "']/labs")
	dcDate := dcLabs.getAttribute("date")
	Gui, gDCinj:Hide
	if !IsObject(dcLabs) {
		MsgBox,,% dcDate, No labs!
		Gui, gDCinj:Show
		return
	}
	
	if (i:=dcLabs.selectSingleNode("CBC")) {
		Loop, % (j:=i.selectNodes("*")).length {
			k := j.item(A_Index-1)
			node := k.nodeName
			nodeTxt := k.text
			MsgBox,,% node, % nodeTxt
		}
	}
	if (i:=dcLabs.selectSingleNode("Lytes")) {
		Loop, % (j:=i.selectNodes("*")).length {
			k := j.item(A_Index-1)
			node := k.nodeName
			nodeTxt := k.text
			MsgBox,,% node, % nodeTxt
		}
	}
		
	Gui, gDCinj:Show
	return
}