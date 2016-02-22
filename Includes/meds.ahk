MedListParse(medList,bList) {								; may bake in y.ssn(//id[@mrn='" mrn "'/MAR")
	global meds1, meds2, meds0, y, MRNstring, yMarDt, medfilt_drip, medfilt_med
	tempArray = 
	medWords =
	StringReplace, bList, bList, •%A_space%, ``, ALL
	StringSplit, tempArray, bList, ``
	Loop, %tempArray0%
	{
		if (StrLen(medName:=tempArray%A_Index%)<3)													; Discard essentially blank lines
			continue
		medName:=RegExReplace(medName,medfilt_med)
		medName:=RegExReplace(medName,medfilt_drip,"gtt.")
		if ObjHasValue(meds1, medName, "med") {
			y.addElement(medlist, yMarDt, {class: "Cardiac"}, medName)
			continue
		}
		if ObjHasValue(meds2, medName, "med") {
			y.addElement(medlist, yMarDt, {class: "Arrhythmia"}, medName)
			continue
		}
		if ObjHasValue(meds0, medName, "med") {
			continue
		}
		else
			y.addElement(medlist, yMarDt, {class: "Other"}, medName)
	}
}

