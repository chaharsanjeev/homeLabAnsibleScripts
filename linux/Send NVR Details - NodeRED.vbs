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

	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	''Get System Uptime 
    Dim oOSs, oOS, lUpTime
    Set oOSs = objWMIService.ExecQuery("SELECT SystemUpTime FROM Win32_PerfFormattedData_PerfOS_System")
    For Each oOS In oOSs
        lUpTime = oOS.SystemUpTime
		
        If lUpTime < 3600  Then 
            uptime = Int(oOS.SystemUpTime / 60) & " minutes"
		ElseIf lUpTime < 86400 Then
            uptime = Int(oOS.SystemUpTime / 3600) & " hours"
        Else
            uptime = Int(oOS.SystemUpTime / 86400) & " days"
        End If
    Next

	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

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
 
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
 
	Dim XMLHttp
	Set XMLHttp = CreateObject("MSXML2.XMLHTTP")

	XMLHttp.Open "POST", "http://nodered.sc:1880/nvr_hdd_details", False
	XMLHttp.setRequestHeader "Content-Type", "application/text"
	XMLHttp.send Replace(json,"'","""") + Seperator + uptime + Seperator + kernal
	'Debug.print XMLHttp.responseText
	Set XMLHttp = Nothing



