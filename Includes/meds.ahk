MedListParse(medList,bList) {								; may bake in y.ssn(//id[@mrn='" mrn "'/MAR")
	global meds1, meds2, meds0, y, MRNstring, yMarDt, medfilt_drip, medfilt_med
	tempArray = 
	medWords =
	Loop, parse, % blist, `r`n
	{
		medname := trim(StrReplace(A_LoopField,Chr(8226)," "))
		if (medname="") {
			Continue
		}
		if (medname~="Held by provider") {															; skip meds on hold
			Continue
		}
		if (medname~="Stopped \(") {																; skip recently dc meds
			Continue
		}
		if (medname~="builder|flush") {																; skip line flush
			Continue
		}
		if ObjHasValue(meds0, medName, "med") {														; skip meds on no-fly list meds0
			continue
		}
		
		if (medlist="drips") {
			medname:=RegExReplace(medName,",.*Last Rate"," gtt. Last Rate")
		}
		medName:=RegExReplace(medName,medfilt_med)													; do some string replacements
		medName:=RegExReplace(medName,medfilt_drip,"gtt.")
		medName:=RegExReplace(medName,"\(\d{1,2}/\d{1,2}\)")
		medName:=RegExReplace(medName,"i)(?<!Q|every|given)\s[0-9.]+\s(hrs|min)")
		
		if ObjHasValue(meds1, medName, "med") {														; in meds1 list (cardiac meds)
			y.addElement(medlist, yMarDt, {class: "Cardiac"}, medName)
			continue
		}
		if ObjHasValue(meds2, medName, "med") {														; in meds2 list (antiarrhythmic meds)
			y.addElement(medlist, yMarDt, {class: "Arrhythmia"}, medName)
			continue
		}
		if (medlist="abx") {																		; antibiotics meds
			y.addElement("meds", yMarDt, {class: "Abx"}
				, RegExReplace(medName,"(\d+)\s+-\s+(.*?)[\r\n]+","$2 (Day $1) "))
			continue
		}
		if (medlist="diet") {																		; diet string replacements
			diet := RegExReplace(medname,"i)(,\s+)?(Requested|Start) date\/time: .*")
			diet := RegExReplace(diet,"i)(, )?Start: \d{1,2}\/\d{2}\/\d{2} \d{1,2}:\d{2}:\d{2}")
			diet := RegExReplace(diet,"[^[:ascii:]]","~")
			StringReplace, diet, diet, Other (Nonstandard),, All
			StringReplace, diet, diet, Nonformulary Formula,, All
			StringReplace, diet, diet, % "(Formula, Nonformulary)",, All
			StringReplace, diet, diet, (Diet NPO for Procedure),, All
			StringReplace, diet, diet, (Diet Regular for Age),, All
			StringReplace, diet, diet, (Diet Modified),, All
			StringReplace, diet, diet, NPO NPO, NPO
			if (RegExMatch(diet,"Justification: (.*), Name: ([^,]*), (.*)",just)) {
				diet := just2 " (" just1 ") " just3
			}
			y.addElement(medlist, yMarDt, {class: "Diet"}, diet)
			dietStr .= diet " | "
		}
		else
			y.addElement("meds", yMarDt, {class: "Other"}, medName)									; everything else is just "meds"
	}
	if (dietStr) {																					; if dietStr generated, add for ARNP
		StringReplace, dietStr, dietStr, `r, , All
		StringReplace, dietStr, dietStr, `n, , All
		y.addElement("dietstr", yMarDt, {class: "Diet"}, dietStr)
	}
	return
}

