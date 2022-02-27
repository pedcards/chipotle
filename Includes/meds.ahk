MedListParse(bList) {								; may bake in y.ssn(//id[@mrn='" mrn "'/MAR")
	global meds1, meds2, meds0, y, MRNstring, yMarDt
	meds_abx := stregx(blist,"\[ABX\]",1,1,"\[CONTINUOUS\]",1)
	meds_all := stregx(blist ">>>","\[CONTINUOUS\]",1,1,"\[DIET\]",1)

	tempArray = 
	medWords =
	Loop, parse, % meds_all, `r`n
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
		Name:=RegExReplace(Name,"\b\(?[0-9\-\.]+ (mg|mEq)/([0-9\.]+ )?mL\)?")
		Name:=RegExReplace(Name,"i)injection|nasal/buccal")
		Name:=RegExReplace(Name,"i)(\(pediatric\))? suppository")
		Name:=RegExReplace(Name,"i)dextrose [0-9\.]+ .*?with sodium chloride [0-9\.]+ mEq ")
		Name:=RegExReplace(Name,"i)oral (suspension|solution|liquid)")
		Name:=RegExReplace(Name,"i)chewable .*?tablet")
		Name:=RegExReplace(Name,"i)suppository|pill|packet|tablet|capsule|lozenge|suspension")
		Name:=RegExReplace(Name,"i)(HFA|MDI) .*?inhaler")
		Name:=RegExReplace(Name,"i)bolus from pump","bolus")
		Name:=RegExReplace(Name,Dose)

		Dose:=RegExReplace(Dose,".*? \(Dosing Weight\)")

		Route:=RegExReplace(Route,"i)Oral","PO")
		Route:=RegExReplace(Route,"i)Intravenous","IV")
		Route:=RegExReplace(Route,"i)Rectal","PR")
		Route:=RegExReplace(Route,"i)Intramuscular","IM")
		Route:=RegExReplace(Route,"i)Subcutaneous","SQ")
		Route:=RegExReplace(Route,"i)Per (G|J|D|NG|ND|NJ) tube","P$1T")
		Route:=RegExReplace(Route,"i)(PO|NG|ND|NJ) or (PO|NG|ND|NJ)( tube)?","$1/$2")

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
			tag := "meds"
		}

		/*	Determine medclass: Cardiac, Arrhythmia, Other, etc.
		*/
		medclass := "Other"																			; default medclass is Other
		medfw := strX(Name,"",0,1," ",1,1)															; get first word of med name
		if ObjHasValue(meds1, "i)" Name, "med") {													; in meds1 list (cardiac meds)
			medclass:="Cardiac"
		}
		if ObjHasValue(meds2, "i)" Name, "med") {													; in meds2 list (antiarrhythmic meds)
			medclass:="Arrhythmia"
		}
		if InStr(meds_abx,medfw) {																	; antibiotics meds
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

dietListParse(txt) {
	global y, yMarDt

	dstr:="(\d{2}\/\d{2}\/\d{2})\s+\d{4}"
	ptr:=1
	Loop,
	{
		if !(pos1:=RegExMatch(txt,dstr,dmatch,ptr)) {									; search for "mm/dd/yy hhmm" beginning at ptr
			break
		}
		val:=trim(stregX(txt,dmatch,pos1,1,dstr "(?!\t)",1,ptr),"`r`n`t ")				; get string to next matching mm/dd/yy
		ptr++																			; advance ptr+1 to avoid rematch

		source := trim(stregX(val,"",1,1,"(Until discontinued|\R+)",1),"`r`n`t ")
		route := trim(stregX(val,"^Route\s+",1,1,"(\R|\Z)",1),"`r`n`t ")
		freq := trim(stregX(val,"^Frequency\s+",1,1,"(\R|\Z)",1),"`r`n`t ")
		volume := trim(stregX(val,"^Volume.*?:\s+",1,1,"(\R|\Z)",1),"`r`n`t ")
		dur := trim(stregX(val,"^Duration.*?:\s+",1,1,"(\R|\Z)",1),"`r`n`t ")
		cals := trim(stregX(val,"^Final Calories:\s+",1,1,"(\R|\Z)",1),"`r`n`t ")

		str1 := source . strQ(cals," (###)")
				. strQ(route freq,", ") strQ (volume,"### mL") strQ(route," ###") strQ(freq," ###") strQ(dur," over ###")

		y.addElement("diet", yMarDt, {class: "Diet"}, str1 )
		dietStr .= str1 " | "
	}
	if (dietStr) {																					; if dietStr generated, add for ARNP
		dietStr := trim(dietStr,"| `r`n")
		y.addElement("dietstr", yMarDt, {class: "Diet"}, dietStr)
	}
	Return
}
