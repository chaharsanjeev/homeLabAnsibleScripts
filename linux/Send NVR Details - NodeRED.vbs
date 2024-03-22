' NOTES: This script is called by disk space usage check and send to NODE-RED
'****************************************************************************************

	Option Explicit

	'On Error Resume Next

	Const ForReading = 1
	Const ForWriting = 2
	Const ForAppending = 8

	Const Seperator = "__##__##__"

	Dim objItem, colItems,objWMIService
	Dim strDriveType, strDiskSize, txt
		
	Set objWMIService = GetObject("winmgmts:\\localhost\root\cimv2")
	Set colItems = objWMIService.ExecQuery("Select * from Win32_LogicalDisk WHERE DriveType=3")

	Dim data,json, uptime,kernal

	uptime = ""
	kernal = ""

	data = ""
	json = ""

	For Each objItem in colItems
		DIM pctFreeSpace,strFreeSpace,strusedSpace, strUsagePer
			'pctFreeSpace = INT((objItem.FreeSpace / objItem.Size) * 1000)/10
			strDiskSize = FormatNumber((objItem.Size/1073741824),0)
			strFreeSpace = FormatNumber((objItem.FreeSpace/1073741824),0)
			strUsedSpace = FormatNumber(((objItem.Size-objItem.FreeSpace)/1073741824),0)
			
			strUsagePer = FormatNumber((strUsedSpace/ strDiskSize) * 100,0)
			'msgbox objItem.Name & vbtab & strDiskSize & vbtab & strUsedSpace & vbTab & strFreeSpace
			'data = objItem.Name & vbtab & strDiskSize & vbtab & strUsedSpace & vbTab & strFreeSpace
			data = "{'totalsize': " + Replace(strDiskSize,",","") + ", 'used': " + Replace(strUsedSpace,",","") + ", 'free_per': " + Replace(strUsagePer,",","") + ", 'name': '" + Replace(objItem.Name,":","") + "', 'free': " + Replace(strFreeSpace,",","") + "}"
		
		If Len(json) > 0 Then 
			json = json + "," + data
		Else 
			json = data 
		End If

		strDiskSize = ""
		strFreeSpace = ""
		strUsedSpace = ""
	Next

	json = "[" +  json + "]"

	WScript.Echo vbNewLine +  "Disk Usage: " + json + vbNewLine 


	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	''Get System Uptime 
    'Dim oOSs, oOS, lUpTime
    'Set oOSs = objWMIService.ExecQuery("SELECT SystemUpTime FROM Win32_PerfFormattedData_PerfOS_System")
    'For Each oOS In oOSs
    '    lUpTime = oOS.SystemUpTime
	'		
    '    If lUpTime < 3600  Then 
    '        uptime = Int(oOS.SystemUpTime / 60) & " minutes"
	'ElseIf lUpTime < 86400 Then
    '        uptime = Int(oOS.SystemUpTime / 3600) & " hours"
    '    Else
    '        uptime = Int(oOS.SystemUpTime / 86400) & " days"
    '    End If
    'Next
	
	Dim objShell,ret,text,fso,file 
		
	Dim tempFolder
	Dim tempFile 
	
	Set fso  = CreateObject("Scripting.FileSystemObject")
	
	tempFolder = fso.GetSpecialFolder(2)
	tempFile = tempFolder + "\output.txt"
	
	Set objShell = WScript.CreateObject("WScript.Shell")
	ret = objShell.Run("cmd /c systeminfo | find " + Chr(34) + "System Boot Time:" + Chr(34) + " > " + tempFile, 0, true)
	
	Set file = fso.OpenTextFile(tempFile, 1)
	text = file.ReadAll
	file.Close
	fso.DeleteFile(tempFile)
	
	If (text <> "") Then 
		text = Trim(Replace(text,"System Boot Time:",""))
		text = Replace(text,","," ")

		Dim seconds,minutes, hours,days, weeks,work

		work = DateDiff("s",text,Now)

		seconds = work Mod 60
		work = work \ 60
		minutes = work Mod 60
		work = work \ 60
		hours = work Mod 24
		work = work \ 24
		days = work Mod 7
		work = work \ 7
		weeks = work

		Dim s: s = ""
		Dim renderStarted: renderStarted = False

		If (weeks <> 0) Then
			renderStarted = True
			s = s & ", " & CStr(weeks)
			If (weeks = 1) Then
				s = s & " week "
			Else
				s = s & " weeks "
			End If
		End If

		If (days <> 0 OR renderStarted) Then
			renderStarted = True
			s = s & ", " &  CStr(days)
			If (days = 1) Then
				s = s & " day "
			Else
				s = s & " days "
			End If
		End If

		If (hours <> 0 OR renderStarted) Then
			renderStarted = True
			s = s & ", " & CStr(hours)
			If (hours = 1) Then
				s = s & " hour "
			Else
				s = s & " hours "
			End If
			
		End If

		If (minutes <> 0 OR renderStarted) Then
			renderStarted = True
			s = s & ", " & CStr(minutes)
			If (minutes = 1) Then
				s = s & " minute "
			Else
				s = s & " minutes "
			End If
		End If

		's = s & ", " & CStr(seconds)
		'If (seconds = 1) Then
		'	s = s & " sec "
		'Else
		'	s = s & " secs "
		'End If

		s = Trim(s)
		if (Left(s,1) = ",") Then 
			s = Right(s,Len(s)-1)
		End If
		s = "up " + Trim(s)
	
		uptime = s
	End If
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

	WScript.Echo vbNewLine +  "Uptime: " + uptime 

	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	''Get OS Name
	Dim oCols
    Dim oCol
	Dim sWMIQuery
	sWMIQuery = "SELECT Caption FROM Win32_OperatingSystem"
    Set oCols = objWMIService.ExecQuery(sWMIQuery)
    For Each oCol In oCols
        kernal = oCol.Caption
    Next
 
	WScript.Echo vbNewLine +  "Kernal: " + kernal
	
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
 
	Dim XMLHttp
	Set XMLHttp = CreateObject("MSXML2.XMLHTTP")

	XMLHttp.Open "POST", "http://nodered.sc:1880/nvr_hdd_details", False
	XMLHttp.setRequestHeader "Content-Type", "application/text"
	XMLHttp.send Replace(json,"'","""") + Seperator + uptime + Seperator + kernal
	WScript.Echo vbNewLine +  "HTTP Response: " + XMLHttp.responseText + vbNewLine 
	
	If XMLHttp.Status >= 400 And XMLHttp.Status <= 599 Then
      Wscript.Echo "Error Occurred : " & XMLHttp.status & " - " & XMLHttp.statusText
Else
      Wscript.Echo "Success : " & XMLHttp.status & " - " & XMLHttp.ResponseText
End If

	Set XMLHttp = Nothing