/*	Fetch settings and arrays from .ini file
	admins[]
	cicuUsers[]
	arnpUsers[]
	txpDocs[]
	csrDocs[]
	locations = loc variable NAMES and STRINGS displayed
	CIS_strings = variables for CIS and CORES window recognition
	CORES_struc = strings for recognizing CORES structure
	CIS_cols = key="value" pairs of RegEx search strings to define column field values, in order of scan
	Forecast = strings for recognizing Electronic Forecast fields
*/

getIni:
{
	admins:=readIni("admins")
	coordUsers:=readIni("coordUsers")
	cicuUsers:=readIni("cicuUsers")
	arnpUsers:=readIni("arnpUsers")
	pharmUsers:=readIni("pharmUsers")

	txpDocs:=readIni("txpDocs")
	csrDocs:=readIni("csrDocs")
	cicuDocs:=readIni("cicuDocs")

	dialogVals:=readIni("dialogVals")
	teamSort:=readIni("teamSort")
	ccFields:=readIni("ccFields")
	bpdFields:=readIni("bpdFields")

	meds1:=readIni("meds1")
	meds2:=readIni("meds2")
	meds3:=readIni("meds3")
	meds4:=readIni("meds4")
	meds0:=readIni("meds0")
	readIni("med_filt")

	hndText:=readIni("hndText" . scr.Scale)
	svcText:=readIni("svcText" . scr.Scale)
	EpicSvcList:=readIni("EpicSvcList")

	pathprd:=readIni("pathPRD")
	pathdev:=readIni("pathDEV")

	loc := {}
	readIni("Hosp_Loc")
	loc_str:=readIni("loc_str")
	loop, % loc_str.MaxIndex()
	{
		splitIni(loc_str[A_index],c1,c2)
		loc.push(c1)
		loc[c1]:={name:}
		loc[c1] := {name:c2, datevar:"GUI" format("{:l}",c1) "TXT"}
	}
	
Return
}

readIni(section) {
/*	Reads a set of variables
	[section]					==	 		var1 := res1, var2 := res2
	var1=res1
	var2=res2
	
	[array]						==			array := ["ccc","bbb","aaa"]
	=ccc
	=bbb
	=aaa
	
	[objet]						==	 		objet := {aaa:10,bbb:27,ccc:31}
	aaa:10
	bbb:27
	ccc:31
*/
	global
	local x, i, key, val
		, i_res := object()
		, i_type := []
		, i_lines := []
	i_type.var := i_type.obj := i_type.arr := false
	IniRead,x,chipotle.ini,%section%
	Loop, parse, x, `n,`r																; analyze section struction
	{
		i := A_LoopField
		if (i~="(?<!"")[=]")															; find = not preceded by "
		{
			if (i ~= "^=") {															; starts with "=" is an array list
				i_type.arr := true
			} else {																	; "aaa=123" is a var declaration
				i_type.var := true
			}
		} else																			; does not contain a quoted =
		{
			if (i~="(?<!"")[:]") {														; find : not preceded by " is an object
				i_type.obj := true
			} else {																	; contains neither = nor : can be an array list
				i_type.arr := true
			}
		}
	}
	if ((i_type.obj) + (i_type.arr) + (i_type.var)) > 1 {								; too many types, return error
		return error
	}
	Loop, parse, x, `n,`r																; now loop through lines
	{
		i := A_LoopField
		if (i_type.var) {
			key := strX(i,"",1,0,"=",1,1)
			val := strX(i,"=",1,1,"",0)
			%key% := trim(val,"""")
		}
		if (i_type.obj) {
			key := strX(i,"",1,0,":",1,1)
			val := strX(i,":",1,1,"",0)
			i_res[key] := trim(val,"""")
		}
		if (i_type.arr) {
			i := RegExReplace(i,"^=")													; remove preceding =
			i_res.push(trim(i,""""))
		}
	}
	return i_res
}

splitIni(x, ByRef y, ByRef z) {
	y := trim(substr(x,1,(k := instr(x, "="))), " `t=")
	z := trim(substr(x,k), " `t=""")
	return
}

makeLoc(vars*) {
	global loc
	res := []
	for index,var in vars {
		res.Push(var)
		res[var] := loc[var]
	}
	return res
}