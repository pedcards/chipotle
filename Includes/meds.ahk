MedListParse(bList) {								; may bake in y.ssn(//id[@mrn='" mrn "'/MAR")
	global meds1, meds2, meds0, y, MRNstring, yMarDt
	tempArray = 
	medWords =
	Loop, parse, % blist, `r`n
	{
		medline := trim(StrReplace(A_LoopField,Chr(8226)," "))
		medline := RegExReplace(medline,"(\d),(\d{3})","$1$2")
		
		if (medline="") {
			Continue
		}
		if (medline~="Held by provider") {															; skip meds on hold
			Continue
		}
		if (medline~="Current Facility-Administered") {												; skip section header
			Continue
		}
		if (medline~="i)discontinued|stopped|canceled") {											; skip recently dc meds
			Continue
		}
		if ObjHasValue(meds0, medline, "med") {														; skip meds on no-fly list meds0
			continue
		}
		
		/*	Parse line and do string replacements
		*/
		tab := StrSplit(medline, ", ")
			Name := tab[1]
			Dose := tab[2]
			Route := tab[3]
			Sched := tab[4]
		Name:=RegExReplace(Name,"i) in (sodium chloride|lactated|dextrose|sterile water).*?mL\)?( infusion)?")
		Name:=RegExReplace(Name,"^(.*?)( \d.*? )(infusion|drops|injection)","$1")
		Name:=RegExReplace(Name,"\b\(?[0-9\-\.]+ mg/mL\)?")
		Name:=RegExReplace(Name,"i)injection|oral solution|nasal/buccal")
		Name:=RegExReplace(Name,Dose)
		Dose:=RegExReplace(Dose,".*? \(Dosing Weight\)")
		Route:=RegExReplace(Route,"Intravenous","IV")
		Sched:=RegExReplace(Sched,"Continuous","gtt.")
		Sched:=RegExReplace(Sched,"Every","Q")
		Sched:=RegExReplace(Sched,"2 times a day","BID")
		Sched:=RegExReplace(Sched,"3 times a day","TID")
		Sched:=RegExReplace(Sched,"4 times a day","QID")
		
		/*	Determine tag: drips, med, or prn
		*/
		if (medline~="i)\d\s+(mg|mcg|unit|units|milli-units)\/kg\/(sec|min|hr)") {
			tag := "drips"
			Name := RegExReplace(Name,"^(.*?)( \d.*?)$","$1")
			RegExMatch(medline,"(Last Rate:.*?)$",lastrate)
			Sched .= strQ(lastrate," (" RegExReplace(lastrate,"Last Rate:.*?, ") ")")
		} 
		else if (medline~="PRN") {
			tag := "prn"
		}
		else {
			tag := "med"
		}

		/*	Determine medclass: Cardiac, Arrhythmia, Other, etc.
		*/
		medclass := "Other"																			; default medclass is Other
		if ObjHasValue(meds1, "i)" Name, "med") {													; in meds1 list (cardiac meds)
			medclass:="Cardiac"
		}
		if ObjHasValue(meds2, "i)" Name, "med") {													; in meds2 list (antiarrhythmic meds)
			medclass:="Arrhythmia"
		}
		if (medlist="abx") {																		; antibiotics meds
			medclass:="Abx"
			; y.addElement("meds", yMarDt, {class: "Abx"}
			; 	, RegExReplace(medName,"(\d+)\s+-\s+(.*?)[\r\n]+","$2 (Day $1) "))
		}
		
		/*	Write MAR element
		*/
		medName := Name strQ(Dose," ###") strQ(Route," ###") strQ(Sched," ###")
		y.addElement(tag, yMarDt, {class: medclass}, cleanSpace(medName))
	}
	return
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
			y.addElement(medlist, yMarDt, {class: medclass}, cleanSpace(medName))									; everything else is just "meds"
	}
	if (dietStr) {																					; if dietStr generated, add for ARNP
		StringReplace, dietStr, dietStr, `r, , All
		StringReplace, dietStr, dietStr, `n, , All
		y.addElement("dietstr", yMarDt, {class: "Diet"}, dietStr)
	}
	return
}

