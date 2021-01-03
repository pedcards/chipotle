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

ReadIni:
{
admins:=[]
coordUsers:=[]
cicuUsers:=[]
arnpUsers:=[]
pharmUsers:=[]
txpDocs:=[]
csrDocs:=[]
cicuDocs:=[]
loc:=Object()
CIS_colRx:=[]
dialogVals:=[]
teamSort:=[]
ccFields:=[]
bpdFields:=[]
meds1:=[]
meds2:=[]
meds3:=[]
meds4:=[]
meds0:=[]
medfilt:=[]

	Loop, Read, chipotle.ini
	{
		i:=A_LoopReadLine
		if (i="")
			continue
		if (substr(i,1,1)="[") {
			sec:=strX(i,"[",1,1,"]",1,1)
			continue
		}
		if (k := RegExMatch(i,"[\s\t];")) {
			i := trim(substr(i,1,k))
		}
		if (sec="ADMINS") {
			admins.Insert(i)
		}
		if (sec="COORD") {
			coordUsers.Insert(i)
		}
		if (sec="CICU") {
			cicuUsers.Insert(i)
		}
		if (sec="ARNP") {
			arnpUsers.Insert(i)
		}
		if (sec="PHARM") {
			pharmUsers.Insert(i)
		}
		if (sec="BPD") {
			bpdUsers.Insert(i)
		}
		if (sec="TXPDOCS") {
			txpDocs.Insert(i)
		}
		if (sec="CSRDOCS") {
			csrDocs.Insert(i)
		}
		if (sec="CICUDOCS") {
			cicuDocs.Insert(i)
		}
		if (sec="LOCATIONS") {
			splitIni(i,c1,c2)
			StringLower, c3, c1
			loc.Insert(c1)
			loc[c1] := {name:c2, datevar:"GUI" c3 "TXT"}
		}
		if (sec="Hosp_Loc") {
			splitIni(i,c1,c2)
			%c1% := c2
		}
		if (sec="CIS_strings") {
			splitIni(i,c1,c2)
			%c1% := c2
		}
		if (sec="Dialog_Str") {
			dialogVals.Insert(i)
		}
		if (sec="CIS_cols") {
			splitIni(i,c1,c2)
			CIS_colRx[c1] := c2
		}
		if (sec="CORES_struc") {
			splitIni(i,c1,c2)
			%c1% := c2
		}
		if (sec="Team sort") {
			teamSort.Insert(i)
		}
		if (sec="CC Systems") {
			ccFields.Insert(i)
		}
		if (sec="BPD Systems") {
			bpdFields.Insert(i)
		}
		if (sec="MEDS1") {
			meds1.Insert(i)
		}
		if (sec="MEDS2") {
			meds2.Insert(i)
		}
		if (sec="MEDS3") {
			meds3.Insert(i)
		}
		if (sec="MEDS4") {
			meds4.Insert(i)
		}
		if (sec="MEDS0") {
			meds0.Insert(i)
		}
		if (sec="Med_filt") {
			splitIni(i,c1,c2)
			%c1% := c2
		}
	}
Return
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