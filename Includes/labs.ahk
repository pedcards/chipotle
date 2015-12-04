parseLabs(block) {
	global y, MRNstring, timenow
	yLabDt := MRNstring "/info[@date='" timenow "']/labs"
	while (block) {																	; iterate through each section of the lab block
		labsec := labGetSection(block)
		labs := labSecType(labsec.res)
		if (labs.type="CBC") {
			y.addElement("CBC", yLabDt, {old:labsec.old, new:labsec.new})
				y.addElement("legend", yLabDt "/CBC", labsec.date)
				y.addElement("WBC", yLabDt "/CBC", labs.wbc)
				y.addElement("Hgb", yLabDt "/CBC", labs.hgb)
				y.addElement("Hct", yLabDt "/CBC", labs.hct)
				y.addElement("Plt", yLabDt "/CBC", labs.plt)
				y.addElement("rest", yLabDt "/CBC", labs.rest)
		}
		if (labs.type="Lytes") {
			y.addElement("Lytes", yLabDt, {old:labsec.old, new:labsec.new})
				y.addElement("legend", yLabDt "/Lytes", labsec.date)
				y.addElement("Na", yLabDt "/Lytes", labs.na)
				y.addElement("K", yLabDt "/Lytes", labs.k)
				y.addElement("HCO3", yLabDt "/Lytes", labs.HCO3)
				y.addElement("Cl", yLabDt "/Lytes", labs.Cl)
				y.addElement("BUN", yLabDt "/Lytes", labs.BUN)
				y.addElement("Cr", yLabDt "/Lytes", labs.Cr)
				y.addElement("Glu", yLabDt "/Lytes", labs.glu)
				(labs.ABG) ? y.addElement("ABG", yLabDt "/Lytes", labs.ABG) : ""
				(labs.iCA) ? y.addElement("iCA", yLabDt "/Lytes", labs.iCA) : ""
				(labs.ALT) ? y.addElement("ALT", yLabDt "/Lytes", labs.ALT) : ""
				(labs.AST) ? y.addElement("AST", yLabDt "/Lytes", labs.AST) : ""
				(labs.PTT) ? y.addElement("PTT", yLabDt "/Lytes", labs.PTT) : ""
				(labs.INR) ? y.addElement("INR", yLabDt "/Lytes", labs.INR) : ""
				(labs.Alb) ? y.addElement("Alb", yLabDt "/Lytes", labs.Alb) : ""
				(labs.Lac) ? y.addElement("Lac", yLabDt "/Lytes", labs.Lac) : ""
				(labs.CRP) ? y.addElement("CRP", yLabDt "/Lytes", labs.CRP) : ""
				(labs.ESR) ? y.addElement("ESR", yLabDt "/Lytes", labs.ESR) : ""
				(labs.DBil) ? y.addElement("DBil", yLabDt "/Lytes", labs.DBil) : ""
				(labs.IBil) ? y.addElement("IBil", yLabDt "/Lytes", labs.IBil) : ""
				y.addElement("rest", yLabDt "/Lytes", labs.rest)
		}
		if (labs.type="Other") {
			y.addElement("Other", yLabDt, {old:labsec.old, new:labsec.new}, labsec.date)
				y.addElement("rest", yLabDt "/Other", labs.rest)
		}
	}
	return
}

labGetSection(byref block) {
/*	Separates block by date-delineated next section
	Returns result.date (date block), result.res (text block to next section)
	and truncated block byRef.
	Next iteration will keep truncating until no more block
*/
	str = \d{1,2}\/\d{1,2}\s\d{2}:\d{2}
	sepOld := "(\(\))=" str
	sepNew := "(\[\])=" str
	sep := "(\(\)|\[\])=" str 
	sepLine := "(" sep ".*)+.*\R"
	from := RegExMatch(block,"O)"sepline,match1)
	to := RegExMatch(block,"O)"sepline,match2,match1.len())
	
	blockDate := match1.value()
	RegExMatch(blockDate,"O)"sepOld,dateOld)
	RegExMatch(blockDate,"O)"sepNew,dateNew)
	
	blockNext := match2.value()
	blockRes := strX(block,blockDate,from,match1.len(),blockNext,1,match2.len(),n)
	block := substr(block,n)
	return {date:trim(blockDate," `t`r`n"), old:labDate(dateOld.value), new:labDate(dateNew.value), res:trim(blockRes," `t`r`n")}
}

labDate(str) {
	dateForm = \d{2}\/\d{2}\s\d{2}:\d{2}
	strDate := RegExMatch(str,"O)"dateForm,res)
	v := res.value()
	if !v
		return Error
	StringReplace, v, v, %A_Space%,, All
	StringReplace, v, v, /,, All
	StringReplace, v, v, :,, All
	FormatTime, yr, %A_now%, yyyy
	v := yr . v
return v
}


labSecType(block) {
	global y, MRNstring
	x := Object()
	topsec := strX(block,,1,0,"`r`n`r`n",1,2,n)
	loop, parse, topsec, `n
	{
		row := A_Index
		k := RegExReplace(trim(A_LoopField),"\s+"," ")
		StringSplit, el, k, %A_Space%
		loop, %el0%																		; generate fingerprint
		{
			sub := el%A_Index%
			if (sub ~= "\d{1,3}\.\d{1,3}") {											; decimals
				fing .= "D"
				x[row,A_Index] := sub
			}
			else if (sub ~= "\d{1,3}") {												; whole numbers
				fing .= "W"
				x[row,A_Index] := sub
			}
		}
		fing .= "N"																		; end line
	}
	botsec := SubStr(block,n)
	if (RegExMatch(botsec,"O)[67]\.\d+\s\/\s\d+\s\/\s\d+\s.*",abg)) {
		botsec := RegExReplace(botsec,"[67]\.\d{1,2}\s\/\s\d+\s\/\s\d+\s.*","")
	}
	if (RegExMatch(botsec,"O)(ICa\:)(.*)\d{1,2}",iCA)) {
		botsec := RegExReplace(botsec,"(ICa\:)(.*)\d{1,2}","")
	}
	if (RegExMatch(botsec,"O)ALT\s(.*)\d{2,4}",ALT)) {
		botsec := RegExReplace(botsec,"ALT\s(.*)\d{2,4}","")
	}
	if (RegExMatch(botsec,"O)AST\s(.*)\d{2,4}",AST)) {
		botsec := RegExReplace(botsec,"AST\s(.*)\d{2,4}","")
	}
	if (RegExMatch(botsec,"O)PTT\s>?\d{2,3}",PTT)) {
		botsec := RegExReplace(botsec,"PTT\s>?\d{2,3}","")
	}
	if (RegExMatch(botsec,"O)Pt.INR\s[<>0-9\.]+",INR)) {
		botsec := RegExReplace(botsec,"Pt.INR\s[<>0-9.]+","")
	}
	if (RegExMatch(botsec,"O)Alb\s[<>0-9\.]+",Alb)) {
		botsec := RegExReplace(botsec,"Alb\s[<>0-9.]+","")
	}
	if (RegExMatch(botsec,"O)Lac\s[<>0-9\.]+",Lac)) {
		botsec := RegExReplace(botsec,"Lac\s[<>0-9.]+","")
	}
	if (RegExMatch(botsec,"O)CRP\s[<>0-9\.]+.*",CRP)) {
		botsec := RegExReplace(botsec,"CRP\s[<>0-9.]+.*","")
	}
	if (RegExMatch(botsec,"O)ESR\s[<>0-9\.]+.*",ESR)) {
		botsec := RegExReplace(botsec,"ESR\s[<>0-9.]+.*","")
	}
	if (RegExMatch(botsec,"O)D Bili\s[<>0-9.]+.*",DBil)) {
		botsec := RegExReplace(botsec,"D Bili\s[<>0-9\.]+.*","")
	}
	if (RegExMatch(botsec,"O)I Bili\s[<>0-9.]+.*",IBil)) {
		botsec := RegExReplace(botsec,"I Bili\s[<>0-9\.]+.*","")
	}
	;~ if (RegExMatch(botsec,"O)^\s*\W+\s*\[?[0-9.]+\]?\s*?$")) {
		;~ botsec := RegExReplace(botsec,"^\s*\W+\s*\[?[0-9.]+\]?\s*?$","")
	;~ }
	
	if (fing ~= "WW.?NDW.?N") {
		return {type:"Lytes", Na:x[1,1], HCO3:x[1,2], BUN:x[1,3], K:x[2,1], Cl:x[2,2], Cr:x[2,3], Glu:x[3,1]
			, ABG:abg.value(), iCA:iCA.value(), ALT:ALT.value(), AST:AST.value(), PTT:PTT.value(), INR:INR.value()
			, Alb:Alb.value(), Lac:Lac.value(), CRP:CRP.value(), ESR:ESR.value(),DBil:DBil.value(), IBil:IBil.value()
			, rest:botsec}
	} else if (fing ~= "DDNDNWN") {
		return {type:"CBC", WBC:x[1,1], Hgb:x[1,2], Hct:x[2,1], Plt:x[3,1], rest:botsec}
	} else {
		return {type:"Other", rest:block}
	}
}

