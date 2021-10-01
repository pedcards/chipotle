/* 	CHIPOTLE = Children's Heart Center InPatient Online Task List Environment (C)2014-2021 TC
*/

/*	Todo lists: 
*/

#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetTitleMatchMode, RegEx
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
#Include %A_ScriptDir%\Includes
#Persistent		; Keep program resident until ExitApp

vers := "2.4.5.8"
user := A_UserName
FormatTime, sessdate, A_Now, yyyyMM
eventlog(">>>>> Session started.")
LV_Colors.OnMessage()

FileGetTime, iniDT, chipotle.ini
FileGetTime, exeDT, chipotle.exe
iniDT -= %exeDT%, Seconds										; Will be negative if chipotle.ini is older.
FileInstall, chipotle.ini, chipotle.ini, (iniDT<0)				; Overwrite if chipotle.exe is newer (and contains newer .ini)
if (iniDT < 0) {
	eventlog("==============================")
	eventlog("Initialized version " vers)
	eventlog("==============================")
}
;FileInstall, pscp.exe, pscp.exe								; Necessary files (?)
;FileInstall, queso.exe, queso.exe
;FileInstall, printer.png, printer.png

Sleep 500

global path
scr:=screenDims()
win:=winDim(scr)
gosub getIni

if InStr(A_WorkingDir,"Ahk") {
	isLocal := true
	;FileDelete, currlist.xml
	path:=pathDEV
} else {
	path:=pathPRD
}
if (ObjHasValue(admins,user)) {
	isAdmin := true
	tmp:=CMsgBox("Administrator","Which user role?","*&Normal CHIPOTLE|&CICU CHILI|&ARNP Con Carne|Coordinator|BPD","Q","V")
	if (tmp~="CHILI") {
		isCICU := true
	} 
	if (tmp~="ARNP") {
		isARNP := true
	}
	if (tmp~="Coord") {
		isCoord := true
	}
	if (tmp~="BPD") {
		isBPD := true
	}
}
if (ObjHasValue(coordusers,user)) {
	isCoord := true
}
if (ObjHasValue(cicuUsers,user)) {
	isCICU = true
}
if (ObjHasValue(ArnpUsers,user)) {
	isARNP := true
}
if (ObjHasValue(pharmUsers,user)) {
	isARNP := true
	isPharm := true
}
if (ObjHasValue(bpdUsers,user)) {
	isBPD := true
}

mainTitle1 := "CHIPOTLE"												; Default title, unless changed below
mainTitle2 := "Children's Heart Center InPatient"
mainTitle3 := "Organized Task List Environment"

if (isCICU) {
	loc := makeLoc("CICU")										; loc[] defines the choices offered from QueryList. You can only break your own list.
	callLoc := "CICUSur"
	mainTitle1 := "CHILI"
	mainTitle2 := "Children's Heart Center"
	mainTitle3 := "Inpatient Longitudinal Integrator"
} else if (isARNP) {
	loc := makeLoc("CSR","CICU")
	callLoc := "CSR"
	mainTitle1 := "CON CARNE"
	mainTitle2 := "Collective Organized Notebook"
	mainTitle3 := "for Cardiac ARNP Efficiency"
} else if (isCoord) {
	loc := makeLoc("CSR","CICU","ICUCons")
} else if (isBPD) {
	loc := makeLoc("PHTN")
	mainTitle1 := "CILANTRO"
	mainTitle2 := "Combined Interface for Longitudinal Aggregation"
	mainTitle3 := "Networked Team Rounds Organizer"
}

Docs := Object()
outGrps := []
outGrpV := {}
tmpIdxG := 0
Loop, Read, outdocs.csv
{
	tmp := StrSplit(A_LoopReadLine,",","""")
	if (tmp.1="Name" or tmp.1="end" or tmp.1="") {					; header, end, or blank lines
		continue
	}
	if (tmp.2="" and tmp.3="" and tmp.4="") {						; Fields 2,3,4 blank = new group
		tmpGrp := tmp.1
		tmpIdx := 0
		tmpIdxG += 1
		outGrps.Insert(tmpGrp)
		continue
	}
	if (tmp.4="group") {											; Field4 "group" = synonym for group name
		tmpIdx += 1													; if including names, place at END of group list to avoid premature match
		Docs[tmpGrp,tmpIdx]:=tmp.1
		outGrpV[tmpGrp] := "callGrp" . tmpIdxG
		continue
	}
	tmpIdx += 1														; Otherwise format Crd name to first initial, last name
	nameF := strX(tmp.1,"",1,0," ",1,1)
	nameL := strX(tmp.1," ",1,1,"",0)
	tmpPrv := substr(nameF,1,1) . ". " . nameL
	Docs[tmpGrp,tmpIdx] := tmpPrv
	outGrpV[tmpGrp] := "callGrp" . tmpIdxG
}
outGrpV["Other"] := "callGrp" . (tmpIdxG+1)
outGrpV["TO CALL"] := "callGrp" . (tmpIdxG+2)

initDone = true
Gosub GetIt
Gosub MainGUI

WinWaitClose, CHIPOTLE main
Gosub SaveIt
eventlog("<<<<< Session completed.")
sleep, 2000
ExitApp


;	===========================================================================================
#Include getini.ahk
;	===========================================================================================
/*	Clipboard copier
	Will wait resident until clipboard change, then will save clipboard to file.
	Tends to falsely trigger a couple of times first. Will exit after .clip successfully saved.
*/
/*																; add ";" to save clipboard
OnClipboardChange:
	FileSelectFile, clipname, 8, , Name of .clip file, *.clip
	If (clipname) {			; If blank (e.g. pressed cancel), continue; If saved, then exitapp
		IfNotInString, clipname, .clip
			clipname := clipname . ".clip"
		FileDelete %clipname%
		FileAppend %ClipboardAll%, %clipname%
		ExitApp
	}
Return

^F12::
	;~ FileSelectFile , clipname,, %A_ScriptDir%/files, Select file:, AHK clip files (*.clip)
	clipname := "cores0927.clip"
	FileRead, Clipboard, *c %clipname%
Return

*/

;	===========================================================================================

listsort(list,parm="",ord:="") {
/*	Sort a given list:
		arg list =	location list to sort (e.g. CICUSur, EP, ICUCons, CSR, CICU, TXP, Cards, Ward, PHTN)
		opt parm =	sort key from ptParse (e.g. Svc, Unit, Room, StatCons)
					if "", calcs service sort order (CSR, CRD, TXP, PICU, NICU, etc), adds points for consult and not on list.
		opt ord =	-1 for descending
	Reads MRNs from existing /root/lists/list node.
	Sorts list by criteria.
	Rewrites old node with newly sorted order.
*/
	global y, teamSort
	var := Object()
	col := ["mrn","sort","Room","Unit","Svc"]
	node := y.selectSingleNode("/root/lists/" . list)
	Loop % (mrns := node.selectNodes("mrn")).length 
	{
		mrn := mrns.Item(A_index-1).text
		pt := ptParse(mrn)
		if (list="TXP" and ((pt.Svc="Cardiology") or (pt.Svc="Cardiac Surgery"))) {						; If on TXP list AND on CRD or CSR
			y.selectSingleNode("/root/id[@mrn='" mrn "']/status").setAttribute("txp", "on")				; Set status flag.
		}
		ptSort := (inList:=ObjHasValue(teamSort,pt.svc,"RX"))*10 + (pt.statcons) + (!(inList))*100
		var[A_Index] := {mrn:mrn,sort:ptSort,room:pt.Room,unit:pt.Unit,svc:pt.svc}
	}
	if !(parm) {									; special sort: Svc->Unit->Room->ptSort
		i:=5
		while i>1 {
			sort2D(var,col[i])
			i -= 1
		}
	} else {
		sort2D(var,ObjHasValue(col,parm))
	}
	removeNode("/root/lists/" list)
	FormatTime, now, A_Now, yyyyMMddHHmm
	node := y.addElement(list,"/root/lists",{date:now})
	for key,val in var {
		y.addElement("mrn","/root/lists/" list,var[A_index].mrn)
	}
;	y.viewXML()
}

Sort2D(Byref TDArray, KeyName, Order=1) {
/*	modified from https://sites.google.com/site/ahkref/custom-functions/sort2darray	
	TDArray : a two dimensional TDArray
	KeyName : the key name to be sorted
	Order: 1:Ascending 0:Descending
*/
	For index2, obj2 in TDArray {           
		For index, obj in TDArray {
			if (lastIndex = index)
				break
			if !(A_Index = 1) && ((Order=1) ? (TDArray[prevIndex][KeyName] > TDArray[index][KeyName]) : (TDArray[prevIndex][KeyName] < TDArray[index][KeyName])) {    
			   tmp := TDArray[index]
			   TDArray[index] := TDArray[prevIndex]
			   TDArray[prevIndex] := tmp  
			}         
			prevIndex := index
		}     
		lastIndex := prevIndex
	}
}

readStorkList() {
/*	Directly read a Stork List XLS.
	Sheets
		(1) is "Potential cCHD"
		(2) is "Neonatal echo and Regional Cons"
		(3) is archives
	
*/
	global y
		, stork_hdr, stork_cel
	
	storkPath := A_WorkingDir "\files\fetal\stork.xlsx"
	if !FileExist(storkPath) {
		MsgBox None!
		return
	}
	progress,,Opening file...,Initialization
	if IsObject(y.selectSingleNode("/root/lists/stork")) {
		RemoveNode("/root/lists/stork")
	}
	y.addElement("stork","/root/lists"), {date:timenow}
		
	oWorkbook := ComObjGet(storkPath)
	colArr := ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q"] ;array of column letters
	stork_hdr := Object()
	stork_cel := Object()
	
	Loop 
	{
		RowNum := A_Index
		chk := oWorkbook.Sheets(1).Range("A" RowNum).value
		if (RowNum=1) {
			upDate := chk
			continue
		}
		if !(chk)
			break
		
		Loop
		{	
			ColNum := A_Index
			if (colnum>maxcol)
				maxcol:=colnum
			cel := oWorkbook.Sheets(1).Range(colArr[ColNum] RowNum).value
			if ((cel="") && (colnum=maxcol))
				break
			if (rownum=2) {
				if (cel~="Mother's Name") {
					cel:="Names"
				}
				if (cel~="Mother.*SCH.*#") {
					cel:="Mother SCH"
				}
				if (cel~="Mother.*\sU.*#") {
					cel:="Mother UW"
				}
				if (cel~="Planned.*del.*date") {
					cel:="Planned date"
				}
				if (cel~="i)Most.*Recent.*Consult") {
					cel:="Recent dates"
				}
				if (cel~="i)cord.*blood") {
					cel:="Cord blood"
				}
				if (cel~="i)care.*plan.*ORCA") {
					cel:="Orca plan"
				}
				if (cel~="i)Continuity.*Cardio") {
					cel:="CRD"
				}
				stork_hdr[ColNum] := trim(cel)
			} else {
				stork_cel[ColNum] := cel
			}
		}
		stork_mrn := Round(storkVal("Mother SCH"))
		progress, % 100*RowNum/40, Scanning records..., % stork_mrn
		if !(stork_mrn)
			continue
		y.addElement("id","/root/lists/stork",{mrn:stork_mrn})
		stork_str := "/root/lists/stork/id[@mrn='" stork_mrn "']"
		
		stork_names := storkVal("Names")
		if (instr(stork_names,",",,,2)) {												; A second "," means baby name present
			pos2 := RegExMatch(stork_names,"i)(?<=\s)[a-z\-\/]+,",,instr(stork_names,",",,,1))
			name2 := trim(substr(stork_names,pos2))
			name1 := trim(substr(stork_names,1,pos2-1))
			y.addElement("mother", stork_str)
				y.addElement("nameL", stork_str "/mother", trim(strX(name1,,0,0,", ",1,2)))
				y.addElement("nameF", stork_str "/mother", trim(strX(name1,", ",0,2)))
			y.addElement("baby", stork_str)
				y.addElement("nameL", stork_str "/baby", trim(strX(name2,,0,0,", ",1,2)))
				y.addElement("nameF", stork_str "/baby", trim(strX(name2,", ",0,2)))
		} else {
			y.addElement("mother", stork_str)
				y.addElement("nameL", stork_str "/mother", trim(strX(stork_names,,0,0,", ",1,2)))
				y.addElement("nameF", stork_str "/mother", trim(strX(stork_names,", ",0,2)))
		}
		y.addElement("UW", stork_str "/mother", storkVal("Mother UW"))
		y.addElement("home", stork_str "/mother", storkVal("Home"))
		
		y.addElement("birth", stork_str)
		y.addElement("hosp", stork_str "/birth", storkVal("Delivery Hosp"))
		y.addElement("edc", stork_str "/birth", storkVal("EDC"))
		
		y.addElement("mode", stork_str "/birth",stregX(storkVal("Planned date"),"",1,0,"\d",1))
		y.addElement("planned", stork_str "/birth",stregX(storkVal("Planned date") "<<<","\d",1,0,"<<<",1))
		
		y.addElement("dx", stork_str "/baby", storkVal("Diagnosis"))
		
		y.addElement("notes", stork_str "/baby", storkVal("Comments"))
		
		y.addElement("cont", stork_str)
		getPnProv("CRD", stork_str "/cont")
		
		y.addElement("enc", stork_str)
		getPnProv("Recent dates", stork_str "/enc")
		
		y.addElement("cord", stork_str "/birth", storkVal("Cord blood"))
		
		y.addElement("orca", stork_str "/birth", storkVal("Orca Plan"))
	}
	Progress, Hide

	oExcel := oWorkbook.Application
	oExcel.quit

	MsgBox Stork List updated.
	Writeout("/root/lists","stork")
	Eventlog("Stork List updated.")
Return
}

getPnProv(cel,node) {
	global y
	
	cel := trim(cleanSpace(storkVal(cel))," `t`r`n")									; Make some corrections for common typos
	cel := RegExReplace(cel,"([:\/]) ","$1")
	cel := RegExReplace(cel,";",":")
	cel := RegExReplace(cel,"([[:alpha:]])(\d)","$1/$2")
	
	loop, parse, cel, %A_Space%, `r`n
	{
		prov := parsePnProv(A_LoopField)
		y.addElement("prov", node, {svc:prov.svc,date:prov.date}, prov.prov)
	}
}

parsePnProv(txt) {
	svc := stregX(txt,"",1,0,"[:\/]",1,nn)
	prov := stregX(txt "<<<","[:\/]",1,1,"(\/)|(<<<)",1,nn)
	dt := substr(txt,nn+1)
	return {svc:trim(svc), prov:trim(prov," ()"), date:trim(dt)}
}

storkVal(val) {
	global stork_cel, stork_hdr
	res := stork_cel[ObjHasValue(stork_hdr,val)]
	return res
}

getCall(dt) {
	z := new XML("call.xml")
	callObj := {}
	Loop, % (callDate:=z.selectNodes("/root/forecast/call[@date='" dt "']/*")).length {
		k := callDate.item(A_Index-1)
		callEl := k.nodeName
		callVal := k.text
		callObj[callEl] := callVal
	}
	return callObj
}

IcuMerge() {
	global y, timenow, loc_surg, csrDocs
	
	;~ FormatTime, cicuDate, A_Now, yyyyMMdd
	tmpDT_crd := substr(y.selectSingleNode("/root/lists/Cards").getAttribute("date"),1,8)
	tmpDT_csr := substr(y.selectSingleNode("/root/lists/CSR").getAttribute("date"),1,8)
	tmpDT_cicu := substr(y.selectSingleNode("/root/lists/CICU").getAttribute("date"),1,8)

	cicuSurPath := "/root/lists/CICUSur"
	if IsObject(y.selectSingleNode(cicuSurPath)) {										; Clear the old list and refresh all
		removeNode(cicuSurPath)
	}
	y.addElement("CICUSur","/root/lists", {date:timenow})
	
	loop, % (c1:=y.selectNodes("/root/lists/CICU/mrn")).length {						; Copy existing ICU bed list to CICUSur
		y.addElement("mrn",cicuSurPath, c1.item(A_Index-1).text)
	}
	writeOut("/root/lists","CICUSur")
	
	SurUnitPath := "/root/lists/SurUnit"												; Clear old Sur-R6 list
	if IsObject(y.selectSingleNode(SurUnitPath)) {
		removeNode(SurUnitPath)
	}
	y.addElement("SurUnit","/root/lists", {date:timenow})
	
	Loop, % (c1:=y.selectNodes("/root/lists/CSR/mrn")).length {							; Copy CSR patients on SUR-R6
		c1mrn := c1.item(A_Index-1).text												; to SurUnitPath
		c1str := "/root/id[@mrn='" c1mrn "']"
		c1loc := y.selectSingleNode(c1str "/demog/data/unit").text
		if (c1loc=loc_Surg) {
			y.addElement("mrn",SurUnitPath,c1mrn)
		}
	}
	WriteOut("/root/lists","SurUnit")
	
	if (tmpDT_csr=tmpDT_cicu) {															; When both CSR and CICU up to date
		Loop, % (c2:=y.selectNodes("/root/lists/CSR/mrn")).length {						; Scan CSR list for SURGCNTR patients
			c2mrn := c2.item(A_Index-1).text
			c2str := "/root/id[@mrn='" c2mrn "']"
			c2loc := y.selectSingleNode(c2str "/demog/data/unit").text
			if (c2loc="SURGCNTR") {
				y.addElement("mrn",cicuSurPath,c2mrn)									; and add to cicuSurPath
				if !IsObject(y.selectSingleNode(c2str "/plan/call"))
					y.addElement("call", c2str "/plan")
				tmpN = 
				tmpN += 1, day
				tmpN := substr(tmpN,1,8)
				y.selectSingleNode(c2str "/plan/call").setAttribute("next", tmpN)		; set a call for tomorrow
				WriteOut(c2str "/plan","call")
				eventlog(c2mrn " Call sequence auto-initiated.")
			}
		}
		WriteOut("/root/lists","CICUSur")
	}
	if (tmpDT_crd=tmpDT_cicu) {															; When both CARDS and CICU are up to date
		Loop, % (c2:=y.selectNodes("/root/lists/Cards/mrn")).length {					; Scan Cards list for SURGCNTR patients
			c2mrn := c2.item(A_Index-1).text
			c2str := "/root/id[@mrn='" c2mrn "']"
			c2loc := y.selectSingleNode(c2str "/demog/data/unit").text
			c2attg := y.selectSingleNode(c2str "/demog/data/attg").text
			if (c2loc="SURGCNTR" and ObjHasValue(CSRdocs,c2attg)) {						; Cards list, SurgCntr, and CSR attg
				y.addElement("mrn",cicuSurPath,c2mrn)									; add to cicuSurPath					
				if !IsObject(y.selectSingleNode(c2str "/plan/call"))
					y.addElement("call", c2str "/plan")
				tmpN = 
				tmpN += 1, day
				tmpN := substr(tmpN,1,8)
				y.selectSingleNode(c2str "/plan/call").setAttribute("next", tmpN)		; set a call for tomorrow
				WriteOut(c2str "/plan","call")
				eventlog(c2mrn " Call sequence auto-initiated.")
			}
		}
		WriteOut("/root/lists","CICUSur")
	}
return
}

getCentrip() {
	global y
	c := new XML("data_in\centripetus\CentripData.xml")
	
	loop, % (nodes:=c.selectNodes("/xml/CentripData/Surgery")).Length
	{
		progress % 100*A_index/20
		el := []
		k := nodes.item(A_index-1)
		el.uid := nodeTxt(k,"CaseNumber")
		el.mrn := nodeTxt(k,"MRN")
		dtmp := parseDate(nodeTxt(k,"SurgDt"))
		el.dt := substr(dtmp.YYYY dtmp.MM dtmp.DD dtmp.hr dtmp.min "00",1,14)
		el.surgeon := strX(nodeTxt(k,"Surgeon"),"",1,1,",",1)
		el.cpb := nodeTxt(k,"CPBTm")
		el.xc := nodeTxt(k,"XClampTm")
		loop, % (procs:=k.selectNodes(".//Procedure")).Length
		{
			pr := procs.item(A_Index-1)
			el.procs .= strQ(nodeTxt(pr,"Description"),"###; ")
		}
		ptStr := "/root/id[@mrn='" el.mrn "']"
		prStr := ptStr "/data/procs/surg[@case='" el.uid "']"
		if !IsObject(y.selectSingleNode(ptStr)) {										; No id@mrn in currlist
			continue
		}
		if IsObject(y.selectSingleNode(prStr)) {										; Surgery already captured
			continue
		}
		makeNodes(el.mrn,"data/procs")
		y.addElement("surg",ptStr "/data/procs",{case:el.uid})
		y.addElement("date",prStr,el.dt)
		y.addElement("surgeon",prStr,el.surgeon)
		y.addElement("times",prStr,{cpb:el.cpb,xc:el.xc})
		y.addElement("desc",prStr,trim(el.procs," `;"))
		
		writeout(ptStr,"data")
		eventlog("Updated Centripetus data for " el.mrn)
	}
	progress, off
	return
}

nodeTxt(node,el) {
	x := node.selectSingleNode(el).text
	return x
}

PatNode(mrn,path,node) {
	global y
	return y.selectSingleNode("/root/id[@mrn='" mrn "']/" path "/" node)
}

ReplacePatNode(path,node,value) {
	global y
	if (k := y.selectSingleNode(path "/" node)) {	; Node exists, even if empty.
		y.setText(path "/" node, value)
	} else {
		y.addElement(node, path, value)
	}
}

ObjHasValue(aObj, aValue, rx:="") {
; modified from http://www.autohotkey.com/board/topic/84006-ahk-l-containshasvalue-method/	
	if (rx="med") {
		med := true
	}
    for key, val in aObj
		if (rx) {
			if (med) {													; if a med regex, preface with "i)" to make case insensitive search
				val := "i)" val
			}
			if (aValue ~= val) {
				return, key, Errorlevel := 0
			}
		} else {
			if (val = aValue) {
				return, key, ErrorLevel := 0
			}
		}
    return, false, errorlevel := 1
}

breakDate(x) {
; Disassembles 201502150831 into Yr=2015 Mo=02 Da=15 Hr=08 Min=31 Sec=00
	D_Yr := substr(x,1,4)
	D_Mo := substr(x,5,2)
	D_Da := substr(x,7,2)
	D_Hr := substr(x,9,2)
	D_Min := substr(x,11,2)
	D_Sec := substr(x,13,2)
	FormatTime, D_day, x, ddd
	return {"YYYY":D_Yr, "MM":D_Mo, "DD":D_Da, "ddd":D_day
		, "HH":D_Hr, "min":D_Min, "sec":D_sec}
}

ParseDate(x) {
	mo := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
	moStr := "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"
	dSep := "[ \-\._/]"
	date := []
	time := []
	x := RegExReplace(x,"[,\(\)]")
	
	if (x~="\d{4}.\d{2}.\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z") {
		x := RegExReplace(x,"[TZ]","|")
	}
	if RegExMatch(x,"i)(\d{1,2})" dSep "(" moStr ")" dSep "(\d{4}|\d{2})",d) {			; 03-Jan-2015
		date.dd := zdigit(d1)
		date.mmm := d2
		date.mm := zdigit(objhasvalue(mo,d2))
		date.yyyy := d3
		date.date := trim(d)
	}
	else if RegExMatch(x,"i)\b(" moStr "|\d{1,2})" dSep "(\d{1,2})" dSep "(\d{4}|\d{2})",d) {	; Jan-03-2015, 01-03-2015
		date.dd := zdigit(d2)
		date.mmm := objhasvalue(mo,d1) 
			? d1
			: mo[d1]
		date.mm := objhasvalue(mo,d1)
			? zdigit(objhasvalue(mo,d1))
			: zdigit(d1)
		date.yyyy := (d3~="\d{4}")
			? d3
			: (d3>50)
				? "19" d3
				: "20" d3
		date.date := trim(d)
	}
	else if RegExMatch(x,"i)(" moStr ")\s+(\d{1,2}),?\s+(\d{4})",d) {					; Dec 21, 2018
		date.mmm := d1
		date.mm := zdigit(objhasvalue(mo,d1))
		date.dd := zdigit(d2)
		date.yyyy := d3
		date.date := trim(d)
	}
	else if RegExMatch(x,"\b(\d{4})[\-\.](\d{2})[\-\.](\d{2})\b",d) {					; 2015-01-03
		date.yyyy := d1
		date.mm := d2
		date.mmm := mo[d2]
		date.dd := d3
		date.date := trim(d)
	}
	else if RegExMatch(x,"\b(19|20\d{2})(\d{2})(\d{2})((\d{2})(\d{2})(\d{2})?)?\b",d)  {	; 20150103174307 or 20150103
		date.yyyy := d1
		date.mm := d2
		date.mmm := mo[d2]
		date.dd := d3
		date.date := d1 "-" d2 "-" d3
		
		time.hr := d5
		time.min := d6
		time.sec := d7
		time.time := d5 ":" d6 . strQ(d7,":###")
	}
	
	if RegExMatch(x,"iO)(\d+):(\d{2})(:\d{2})?(:\d{2})?(.*)?(AM|PM)?",t) {				; 17:42 PM
		hasDays := (t.value[4]) ? true : false 											; 4 nums has days
		time.days := (hasDays) ? t.value[1] : ""
		time.hr := trim(t.value[1+hasDays])
		if (time.hr>23) {
			time.days := floor(time.hr/24)
			time.hr := mod(time.hr,24)
			DHM:=true
		}
		time.min := trim(t.value[2+hasDays]," :")
		time.sec := trim(t.value[3+hasDays]," :")
		time.ampm := trim(t.value[5])
		time.time := trim(t.value)
	}

	return {yyyy:date.yyyy, mm:date.mm, mmm:date.mmm, dd:date.dd, date:date.date
			, YMD:date.yyyy date.mm date.dd
			, MDY:date.mm "/" date.dd "/" date.yyyy
			, days:zdigit(time.days)
			, hr:zdigit(time.hr), min:zdigit(time.min), sec:zdigit(time.sec)
			, ampm:time.ampm, time:time.time
			, DHM:zdigit(time.days) ":" zdigit(time.hr) ":" zdigit(time.min) " (DD:HH:MM)" 
 			, DT:date.mm "/" date.dd "/" date.yyyy " at " zdigit(time.hr) ":" zdigit(time.min) ":" zdigit(time.sec) }
}

Rand( a=0.0, b=1 ) {
/*	from VxE http://www.autohotkey.com/board/topic/50564-why-no-built-in-random-function-in-ahk/?p=315957
	Rand() ; - A random float between 0.0 and 1.0 (many uses)
	Rand(6) ; - A random integer between 1 and 6 (die roll)
	Rand("") ; - New random seed (selected randomly)
	Rand("", 12345) ; - New random seed (set explicitly)
	Rand(50, 100) ; - Random integer between 50 and 100 (typical use)
*/
	IfEqual,a,,Random,,% r := b = 1 ? Rand(0,0xFFFFFFFF) : b
	Else Random,r,a,b
	Return r
}

niceDate(x) {
	if !(x)
		return error
	FormatTime, x, %x%, MM/dd/yyyy
	return x
}

year4dig(x) {
	if (StrLen(x)=4) {
		return x
	}
	if (StrLen(x)=2) {
		return (x<50)?("20" x):("19" x)
	}
	return error
}

zDigit(x) {
; Add leading zero to a number
	return SubStr("0" . x, -1)
}

cleanString(x) {
	replace := {"{":"["															; substitutes for common error-causing chars
				,"}":"]"
				, "\":"/"
				,chr(241):"n"}
				
	for what, with in replace													; convert each WHAT to WITH substitution
	{
		StringReplace, x, x, %what%, %with%, All
	}
	
	x := RegExReplace(x,"[^[:ascii:]]")											; filter remaining unprintable (esc) chars
	
	StringReplace, x,x, `r`n,`n, All										; convert CRLF to just LF
	loop																		; and remove completely null lines
	{
		StringReplace x,x,`n`n,`n, UseErrorLevel
		if ErrorLevel = 0	
			break
	}
	
	return x
}

cleanspace(ByRef txt) {
	StringReplace txt,txt,`n,%A_Space%, All
	StringReplace txt,txt,%A_Space%.%A_Space%,.%A_Space%, All
	loop
	{
		StringReplace txt,txt,%A_Space%%A_Space%,%A_Space%, UseErrorLevel
		if ErrorLevel = 0	
			break
	}
	return txt
}

cleanwhitespace(txt) {
	Loop, Parse, txt, `n, `r
	{
		if (A_LoopField ~= "i)[a-z]+") {
			nxt .= A_LoopField "`n"
		}
	}
	return nxt
}

fieldType(x) {
	global CIS_colRx
	for key,val in CIS_colRx
	{
		if (x ~= val) {
			return key
		}
	}
	return error
}

screenDims() {
	W := A_ScreenWidth
	H := A_ScreenHeight
	DPI := A_ScreenDPI
	Orient := (W>H)?"L":"P"
	Scale := round(100*DPI/96)
	Type := (W=1536)?"L":"D"															; 1536px=_L_aptop/Remote, 1920px=_D_esktop/Full
	;MsgBox % "W: "W "`nH: "H "`nDPI: "DPI
	return {W:W, H:H, DPI:DPI, OR:Orient, Scale:Scale, Type:Type}
}
winDim(scr) {
	global ccFields
	num := ccFields.MaxIndex()
	if (scr.or="L") {
		aspect := (scr.W/scr.H >= 1.5) ? "W" : "N"	; 1.50-1.75 probable 16:9 aspect, 1.25-1.33 probable 4:3 aspect
		;MsgBox,, % aspect, % W/H
		wX := scr.H * ((aspect="W") ? 1.5 : 1)
		wY := scr.H-80
		rCol := wX*.3						; R column is 1/3 width
		bor := 10
		boxWf := wX-rCol-2*bor				; box fullwidth is remaining 2/3
		boxWh := boxWf/2
		boxWq := boxWf/4
		rH := 12
		demo_h := rH*8
		butn_h := rh*6
		cont_h := wY-demo_H-bor-butn_h
		field_h := (cont_h-20)/num
	} else {
		wX := scr.W
		wY := scr.H
	}
	return { BOR:Bor, wX:wX, wY:wY
		,	boxF:boxWf
		,	boxH:boxWh
		,	boxQ:boxWq
		,	demo_H:demo_H
		,	cont_H:cont_H
		,	field_H:field_H
		,	rCol:rCol
		,	rH:rH}
}


#Include gui-main.ahk
#Include gui-CallList.ahk
#Include gui-TeamList.ahk
#Include gui-PatList.ahk
#Include gui-PatListCC.ahk
#Include gui-plNotes.ahk
#Include gui-Tasks.ahk
#Include gui-plData.ahk
#Include gui-cards.ahk
#Include process.ahk
#Include io.ahk
#Include labs.ahk
#Include meds.ahk
#Include print.ahk

#Include xml.ahk
#Include StrX.ahk
#Include StRegX.ahk
#Include Class_LV_Colors.ahk
#Include sift3.ahk
#Include CMsgBox.ahk
#Include ScrCmp.ahk
#Include FindText.ahk
