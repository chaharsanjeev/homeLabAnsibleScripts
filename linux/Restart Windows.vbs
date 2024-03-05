' NOTES: Restart Windows but before this stop NVR Services
'****************************************************************************************
	
	'Stop Service
	strServiceName = "BlueIris"
	Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
	Set colListOfServices = objWMIService.ExecQuery("Select * from Win32_Service Where Name ='" & strServiceName & "'")
	
	For Each objService in colListOfServices
		If (LCase(objService.State) = LCase("Running")) Then
			objService.StopService()
			WScript.Sleep (5*60*1000) ''Wait for 5 minutes to ensure its completly stopped
		End If
	Next
	
	
	''Restart Windows Now
	Dim objShell
	Set objShell = WScript.CreateObject("WScript.Shell")
	objShell.Run "C:\WINDOWS\system32\shutdown.exe -r -t 180 -d p:0:0"  'restart windows - before this wait for 3 minutes and reason for restart is "Planned"
	
	
	
