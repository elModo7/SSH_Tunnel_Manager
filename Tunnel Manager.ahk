global compiledForConsole := 0 ; ¡¡Important!! Depending on how you want to compile the script, output will be given via console (Chalk) or native MsgBox
; Last changed date: 30/04/2025 19:15
; OS Version ...: Windows 10 x64 and Above (Support not guaranteed on Windows 7)
;@Ahk2Exe-SetName elModo7's Tunnel Manager
;@Ahk2Exe-SetDescription SSH Tunnel Manager for proxying`, securing and pivoting.
;@Ahk2Exe-SetVersion 1.3.3
;@Ahk2Exe-SetCopyright Copyright (c) 2025`, elModo7
;@Ahk2Exe-SetOrigFilename Tunnel Manager.exe
; INITIALIZE
; *******************************
/*
TODO:
- TCP / Websocket Interop (Server)

REQUIERES:
- Windows 7 x64 (Windows 10+ Recommended)
- AutoHotkey U64 1.1.31+

PARAMS:
-nogui (Disables GUI)
-silent (Disables Tray Notifications)
-notray (Removes Tray Icon)
-hidden (Starts Hidden)
-autostart (Starts Tunneling on Startup)
-profile <profile_path>

FEATURES:
- Support Local, Remote and Dynamic SSH Tunneling
- Server and Tunnel Profiling
- Neutron Web UI
- Console Output
- Auto Accept SSH Key
- Silent Mode with Profile Select / Silent/NoGUI (1.2.24+)
- Hide Tray icon option for Shadow Mode (1.2.16+)
- DRM Copy Protection included via Online Validation of Serial based on Hardware Fingerprint
- Temporary Tunnels without Saving
- Relaunch Tunnel on disconnect
- No need for a full reload on profile select
- Online version checker based on GitHub repo
- Allow enabling/disabling per proflie+tunnel configuration
- Keep track of last used profile (path)
- Config checks on repeated/incorrect tunnel configurations (Improved in 1.2.11+)
- DRM Two Way Encryption (1.2.10+)
- Quick Copy Tunnel (1.2.14+)
- QR Code Generator (1.2.17+) / Press Ctrl while the app is active and click on Copy Link Button
- Discord WebHook Notify / Telegram API Notify / PushBullet Notify (1.2.18+)
- Console Output Toggle (1.2.21+)
- Reload Tunnel While Running (1.2.23+) / Allows restarting the tunnel in case configuration changed and you are working remotely
- Quick Hide/Show by Double Clicking Tray Icon (1.2.23+)
- Increased Command Line Tools and Tray Actions (1.2.24+)
- Parameter info on cmd (chalk) or msgbox (1.2.24+)
- Added License (1.2.26+) removed on 1.2.29
- Auto Update PLink Client to the latest version on first run (1.2.28+)
- Option to download latest PLink or use built in on first run or proxy deletion (1.2.29+)
- Fully Open Source (1.2.29+)
- Remove DRM Protection (No Serial Required) (1.2.29+)
- Track Updates with GitHub Releases (https://api.github.com/repos/elModo7/Tunnel_Manager/releases/latest) (1.3.0+)
- Add About window and Icons to Tray Menu (1.3.2+)

DROPPED / DISCARDED:
- Keep Serial active for 7 days before asking again (DRM Security Risk)
- Change order of each individual Tunnel
- IRC Notify
- IRC Control Plugin
- Telegram API Control Plugin

BUGFIXES:
- Too Many Hotkeys Triggered (1.2.22)
- Profile Param had to be last param or else it wouldn't load (1.2.28)

FUTURE PLANS:

*/
#NoEnv
#SingleInstance, Force
#Persistent
#MaxHotkeysPerInterval, 999 ; Not really used but in case other programs may send hotkeys really fast ignoring this line could be an issue
SetWorkingDir, %A_ScriptDir%
SetBatchLines, -1
global version := "1.3.3"
global isVisible := 1
global cmdProxy, programData, programDataJson, notificationsData, notificationsDataJson, profile, mytcp

plinkPromptDownload() ; PLink install
FileInstall, lib/quricol64.dll, % A_Temp "\quricol64.dll", 0 ; Install but do not overwrite quircol64.dll
FileCreateDir, % A_Temp "\Tunnel_Manager"
FileInstall, res/ico/network2.ico, % A_Temp "\Tunnel_Manager\network2.ico" 
FileInstall, res/ico/refresh.ico, % A_Temp "\Tunnel_Manager\refresh.ico" 
FileInstall, res/ico/cut_visibility.ico, % A_Temp "\Tunnel_Manager\cut_visibility.ico" 
FileInstall, res/ico/download.ico, % A_Temp "\Tunnel_Manager\download.ico" 
FileInstall, res/ico/info.ico, % A_Temp "\Tunnel_Manager\info.ico" 
FileInstall, res/ico/close3.ico, % A_Temp "\Tunnel_Manager\close3.ico" 
FileInstall, res/ico/blocked.ico, % A_Temp "\Tunnel_Manager\blocked.ico" 

#Include <cJSON>
#Include <aes_crypt>
#Include <Neutron>
#Include <chalk>
#Include <webhook_notify>
#Include <DownloadToFile>
global nogui := 0
global silent := 0
global notray := 0
global startHidden := 0
global tunneling := 0
global autostart := 0
profileSelected := 0
global chalk := new Chalker()
; Load last used profile from registry or use default
RegRead, profile, HKEY_CURRENT_USER\Software\elModo7's Tunnel Manager, LastUsedProfile
profile := profile ? profile : "default.json"

loudWarning := chalk.bold.yellow.underline("Tunnel Manager - elModo7 Soft " version "`r`n")
FileAppend, %loudWarning%, *
Loop, %0%
{
	param := %A_Index%
	switch param
	{
		case "-h":
			loudWarning := chalk.bold.red.underline("`r`nAvailable commands:")
			FileAppend, %loudWarning%, *
			chalkMsg := "`r`n-silent -> Silent notification mode`r`n-nogui -> Disables GUI`r`n-autostart -> Starts tunneling on startup`r`n-profile -> Select *.json profile path`r`n-notray -> Disables tray icon`r`n-hidden -> Hides the GUI on startup`r`n"
			quietCorrection := chalk.cyan(chalkMsg)
			FileAppend, %quietCorrection%, *
			if(!compiledForConsole)
				MsgBox, % "Available commands:`n" chalkMsg
			ExitApp
		case "-silent": silent := 1
		case "-nogui": nogui := 1
		case "-hidden": startHidden := 1
		case "-notray": notray := 1
		case "-autostart": autostart := 1
		case "-profile": profileSelected := 1
		default:
			if(profileSelected != 2){
				loudWarning := chalk.bold.red.underline("`r`nUnknown command!")
				FileAppend, %loudWarning%, *
				chalkMsg := "`r`nType -h for a list of available commands`r`n"
				quietCorrection := chalk.cyan(chalkMsg)
				FileAppend, %quietCorrection%, *
				if(!compiledForConsole)
					MsgBox, % "Unknown command!:`n" chalkMsg
				ExitApp
			}
	}
	if(profileSelected == 1)
		profileSelected++
	else if(profileSelected == 2){
		profile := param
		profileSelected++ ; Fix bug, profile had to be last setting because profileSelected was never further increased
	}
}
if(notray){
	Menu, Tray, NoIcon
}else{
	Menu, Tray, NoStandard
	Menu, Tray, Tip, Tunnel Manager elModo7 %version%
	Menu, Tray, Add, Start Tunneling, toggleTunneling
	Menu tray, Icon, Start Tunneling, % A_Temp "\Tunnel_Manager\network2.ico"
	Menu, Tray, Add, Restart Tunneling, runTunnel
	Menu tray, Icon, Restart Tunneling, % A_Temp "\Tunnel_Manager\refresh.ico"
	Menu, Tray, Add,
	if(!nogui)
	{
		Menu, Tray, Add, Hide Client, toggleVisibility
		Menu tray, Icon, Hide Client, % A_Temp "\Tunnel_Manager\cut_visibility.ico"
		Menu, Tray, Add, Look for Updates, lookForUpdates
		Menu tray, Icon, Look for Updates, % A_Temp "\Tunnel_Manager\download.ico"
	}
	Menu, Tray, Add
	Menu, tray, add, % "Tunnel Manager Info", showAboutScreen
	Menu tray, Icon, % "Tunnel Manager Info", % A_Temp "\Tunnel_Manager\info.ico"
	Menu, Tray, Add, Exit, ExitSub
	Menu tray, Icon, Exit, % A_Temp "\Tunnel_Manager\close3.ico"
}

if(!nogui){
	neutron := new NeutronWindow()
	neutron.Load("Tunnel_manager.html")
	neutron.Gui("+LabelNeutron")
	neutron.Show("w1200 h500")
}

if(ProcessExist("proxy.exe")){
	OnMessage(0x44, "OnMsgBox")
	MsgBox 0x2, Proxy is already running!, A previous instance of the Proxy has been detected.`nIt is recommended to close previous instances before continuing.`n`nWhat will you do?
	OnMessage(0x44, "")
	IfMsgBox Abort, {
		; Close previous instance of Proxy
		RunWait, taskkill /IM proxy.exe /F,, Hide
	} Else IfMsgBox Retry, {
		; Continue Anyways
	} Else IfMsgBox Ignore, {
		ExitApp
	}
}

if(!FileExist(profile)){
	; Profile file not found
	if(profile != "default.json"){
		; Profile is not default, hence it was specified by the user and it doesn't exist, notify the user (if profile is default and it doesn't exist, create it silently)
		loudWarning := chalk.bold.red.underline("`r`nProfile " profile " not found, reverting to default!")
		FileAppend, %loudWarning%, *
		if(!compiledForConsole)
			MsgBox, % "Profile " profile " not found, reverting to default!"
	}
	profile := "default.json"
	if(!FileExist(profile)){
		; Default profile not found (create sample profile)
		FileAppend, % tunnelsSampleFile(), %profile%, UTF-8
	}
	; Writes new profile to registry
	RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\elModo7's Tunnel Manager, LastUsedProfile, %profile%
}
FileRead, programDataJson, %profile%
programData := JSON.Load(programDataJson)
if(FileExist("notifications_conf.json")){
	FileRead, notificationsDataJson, notifications_conf.json
	notificationsData := JSON.Load(notificationsDataJson)
	if(notificationsData.enabled){
		neutron.wnd.enableNotifications()
	}else{
		neutron.wnd.disableNotifications()
	}
}else{
	notificationsData := {}
}

if(programData.console_enabled){
	neutron.wnd.enableConsole()
}else{
	neutron.wnd.disableConsole()
}

OnExit, ExitSub

if(!nogui){
	neutron.doc.getElementById("programDataJson").innerHTML := programDataJson ; Hidden Variable so that JS creates the table
	Gui, Show, w1200 h500, Tunnel Manager - elModo7 Soft
}

if(startHidden)
	gosub toggleVisibility

if(autostart)
	toggleTunneling() ; Runs the tunnel

OnMessage(0x404, "AHK_ICONCLICKNOTIFY") ; Detect Tray Icon Clicks
return

toggleTunneling(){
	global
	if(tunneling){
		stopTunnel()
	}else{
		runTunnel()
	}
}

ProcessExist(Name){
	Process,Exist,%Name%
	return Errorlevel
}

OnMsgBox() {
    DetectHiddenWindows, On
    Process, Exist
    If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
        ControlSetText Button1, Kill Previous
        ControlSetText Button2, Continue
        ControlSetText Button3, Exit App
    }
}

settings(unhandledParam := ""){
	global
	neutron.doc.getElementById("ip_field").value := programData.proxy_ip
	neutron.doc.getElementById("port_field").value := programData.proxy_port
	neutron.doc.getElementById("user_field").value := programData.proxy_user
	neutron.doc.getElementById("password_field").value := Crypt.Decrypt.String("AES", "ECB", programData.proxy_password, "elModo7Soft-2023")
}

notifications(unhandledParam := ""){
	global
	neutron.doc.getElementById("discord_webhook").value := notificationsData.discord_webhook
	neutron.doc.getElementById("pushbullet_token").value := notificationsData.pushbullet_token
	neutron.doc.getElementById("telegram_token").value := notificationsData.telegram_token
	neutron.doc.getElementById("telegram_chat_id").value := notificationsData.telegram_chat_id
}

saveNotificationsSettings(unhandledParam := ""){
	global
	if(neutron.doc.getElementById("notifications_enabled_span").innerHTML == "Notifications Enabled"){
		notificationsData.enabled := 1
	}else{
		notificationsData.enabled := 0
	}
	notificationsData.discord_webhook := neutron.doc.getElementById("discord_webhook").value
	notificationsData.pushbullet_token := neutron.doc.getElementById("pushbullet_token").value
	notificationsData.telegram_token := neutron.doc.getElementById("telegram_token").value
	notificationsData.telegram_chat_id := neutron.doc.getElementById("telegram_chat_id").value
	notificationsDataJson := JSON.Dump(notificationsData)
	FileDelete, notifications_conf.json
	FileAppend, %notificationsDataJson%, notifications_conf.json, UTF-8
}

selectProfile(unhandledParam := ""){
	global
	FileSelectFile, profile,,, Select profile, Config Files (*.json)
	if(!ErrorLevel && profile != ""){
		; V1.2.6 DO NOT RELOAD TUNNEL MANAGER ON PROFILE CHANGE
		FileRead, programDataJson, %profile%
		programData := JSON.Load(programDataJson)
		neutron.doc.getElementById("programDataJson").innerHTML := programDataJson
		neutron.wnd.refreshProgramData()
		RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\elModo7's Tunnel Manager, LastUsedProfile, %profile%
		/* AUTORELOAD
		if A_IsCompiled
			Run "%A_ScriptFullPath%" -profile "%profile%"
		else
			Run "%A_AhkPath%" /force "%A_ScriptFullPath%" -profile "%profile%"
		ExitApp
		*/
	}
}

saveServerSettings(unhandledParam := ""){
	global
	proxy_ip := neutron.doc.getElementById("ip_field").value
	proxy_port := neutron.doc.getElementById("port_field").value
	proxy_user := neutron.doc.getElementById("user_field").value
	proxy_password := neutron.doc.getElementById("password_field").value
	programData.proxy_ip := proxy_ip
	programData.proxy_port := proxy_port
	programData.proxy_user := proxy_user
	programData.proxy_password := Crypt.Encrypt.String("AES", "ECB", proxy_password, "elModo7Soft-2023")
	programData.accepted_key := 0
	if(neutron.doc.getElementById("console_enabled_span").innerHTML == "Console Output Enabled"){
		programData.console_enabled := 1
	}else{
		programData.console_enabled := 0
	}
	FileDelete, %profile%
	programDataJson := JSON.Dump(programData)
	FileAppend, % programDataJson, %profile%, UTF-8
	programData := JSON.Load(programDataJson)
	neutron.doc.getElementById("programDataJson").innerHTML := programDataJson
}

saveRules(unhandledParam := ""){
	global
	FileDelete, %profile%
	programDataJson := neutron.doc.getElementById("programDataJson").innerHTML
	FileAppend, % programDataJson, %profile%, UTF-8
	programData := JSON.Load(programDataJson)
}

runTunnel(unhandledParam := ""){
	global
	if(!nogui){
		programData := JSON.Load(neutron.doc.getElementById("programDataJson").innerHTML)
	}
	sendNotificationOnce := 1
	RunWait, taskkill /IM proxy.exe /F,, Hide
	if(!tunneling){
		tunneling := 1
		setTrayTunneling()
	}else{
		setTrayTunneling(1)
	}
	gosub, runTunnelThread
}

saveAndRun(unhandledParam := ""){
	global
	saveRules()
	runTunnel()
}

stopTunnel(unhandledParam := ""){
	global
	SetTimer, runTunnelThread, Off
	tunneling := 0
	setTrayTunneling()
	RunWait, taskkill /IM proxy.exe /F,, Hide
	sendNotifications("Tunnel Manager", A_ComputerName "_" A_UserName " - Tunnel Manager Stopped")
}

runTunnelThread:
	if(!ProcessExist("proxy.exe"))
	{
		passwd := Crypt.Decrypt.String("AES", "ECB", programData.proxy_password, "elModo7Soft-2023")
		str_tunnels := ""
		local_ports_used := []
		remote_ports_used := []
		for key, tunnel in programData.tunnels
		{
			if(tunnel.enabled){
				StringUpper, type, % tunnel.type
				tunnel.type := type
				str_tunnels .= "-" tunnel.type " "
				if(tunnel.type == "L" || tunnel.type == "R"){
					if(tunnel.source_port == ""){
						showErrorModal("Rule Configuration Error:", "Error in Source Port, undefined source port.")
						return
					}else if(tunnel.source_port >= 65535 || tunnel.source_port <= 0){
						showErrorModal("Rule Configuration Error:", "Error in Source Port, source port has to be below 0 and lower than 65535: " tunnel.source_port)
						return
					}
					destinationTmp := StrSplit(tunnel.destination, ":")
					if(destinationTmp.length() != 2){
						showErrorModal("Rule Configuration Error:", "Error in Destination Address, expected format:<br>Ip:Port")
						return
					}else if(destinationTmp[1] == ""){
						destinationTmp[1] := "127.0.0.1"
						tunnel.destination := destinationTmp[1] ":" destinationTmp[2]
					}else if(destinationTmp[2] == ""){
						showErrorModal("Rule Configuration Error:", "Error in Destination Address, port was not defined.")
						return
					}else if(destinationTmp[2] >= 65535 || destinationTmp[2] <= 0){
						showErrorModal("Rule Configuration Error:", "Error in Destination Port, source port has to be below 0 and lower than 65535:" destinationTmp[2])
						return
					}
					str_tunnels .= tunnel.source_port ":" tunnel.destination " "
				}else if(tunnel.type == "D"){
					if(tunnel.source_port == ""){
						showErrorModal("Rule Configuration Error:", "Error in Source Port, undefined source port.")
						return
					}else if(tunnel.source_port >= 65535 || tunnel.source_port <= 0){
						showErrorModal("Rule Configuration Error:", "Error in Source Port, source port has to be below 0 and lower than 65535: " tunnel.source_port)
						return
					}
					str_tunnels .= tunnel.source_port
				}else{
					showErrorModal("Rule Configuration Error:", "Error in Tunnel Type, must be R, L or D.")
					return
				}
				; Check for duplicate ports
				if(tunnel.type == "L" || tunnel.type == "D"){
					if(hasVal(local_ports_used, tunnel.source_port)){
						showErrorModal("Rule Configuration Error:", "Error in Source Port, duplicate Local/Dynamic port:<br>" tunnel.source_port)
						return
					}
					else{
						local_ports_used.push(tunnel.source_port)
					}
				}else if(tunnel.type == "R"){
					if(hasVal(remote_ports_used, tunnel.source_port)){
						showErrorModal("Rule Configuration Error:", "Error in Source Port, duplicate Remote port:<br>" tunnel.source_port)
						return
					}
					else{
						remote_ports_used.push(tunnel.source_port)
					}
				}
			}
		}
		if(str_tunnels == ""){
			showErrorModal("Rule Configuration Error:", "No tunnels created or none active found!")
			return
		}
		cmdProxy := A_Temp "\proxy.exe " str_tunnels " -N -batch -no-antispoof -pw " passwd " " programData.proxy_user "@" programData.proxy_ip " -P " programData.proxy_port
		cmdProxyAcceptKey := "cmd /c echo yes | " A_Temp "\proxy.exe -agent -pw " passwd " " programData.proxy_user "@" programData.proxy_ip " -P " programData.proxy_port
		if(!programData.accepted_key){
			RunWait, %cmdProxyAcceptKey%,, % programData.console_enabled ? "" : "Hide" ; Automatically accepts key of SSH Server once
			programData.accepted_key := "1"
			FileDelete, %profile%
			programDataJson := JSON.Dump(programData)
			FileAppend, % programDataJson, %profile%, UTF-8
			neutron.doc.getElementById("programDataJson").innerHTML := programDataJson			
		}
		Run, %cmdProxy%,, % programData.console_enabled ? "" : "Hide"
		if(sendNotificationOnce){
			sendNotificationOnce := 0
			sendNotifications("Tunnel Manager", A_ComputerName "_" A_UserName " - Tunnel Manager Started for: " programData.proxy_user "@" programData.proxy_ip ":" programData.proxy_port " - Tunnels: " str_tunnels)
		}
		if(!silent)
			TrayTip, Tunnel Manager, Tunnel manager is running in the background.
		SetTimer, runTunnelThread, 15000 ; Make it persistent in case of proccess failure or crash
	}
return

setTrayTunneling(alreadyTunneling = 0){
	global
	if(!tunneling){
		if(!notray)			
			Menu, tray, Rename, Stop Tunneling, Start Tunneling
			Menu tray, Icon, Start Tunneling, % A_Temp "\Tunnel_Manager\network2.ico"
		if(!nogui)
			neutron.wnd.stopTunnelVisual()
	}else if(!alreadyTunneling){
		if(!notray)
			Menu, tray, Rename, Start Tunneling, Stop Tunneling
			Menu tray, Icon, Stop Tunneling, % A_Temp "\Tunnel_Manager\blocked.ico"
		if(!nogui)
			neutron.wnd.runTunnelVisual()
	}
}

showErrorModal(title, content){
	global
	neutron.wnd.stopTunnel()
	neutron.doc.getElementById("defaultErrorModalTitle").innerHTML := title
	neutron.doc.getElementById("defaultErrorModalText").innerHTML := content
	neutron.wnd.showDefaultErrorModal()
}

hasVal(haystack, needle) {
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}

tunnelsSampleFile(){
	samplePasswd := Crypt.Encrypt.String("AES", "ECB", "proxypassword", "elModo7Soft-2023")
	txt =
	(
{
  "tunnels": [
    {
      "name_rule": "Local VNC Forward",
      "source_port": "7786",
      "destination": "127.0.0.1:5900",
	  "enabled": "1",
      "type": "R"
    },
    {
      "name_rule": "VNC Tunnel to PC",
      "source_port": "7787",
      "destination": "192.168.1.128:5900",
	  "enabled": "1",
      "type": "L"
    },
    {
      "name_rule": "Dynamic SOCKS Tunnel",
      "source_port": "7788",
      "destination": "",
	  "enabled": "1",
      "type": "D"
    },
	{
      "name_rule": "Gateway Router Tunnel",
      "source_port": "80",
      "destination": "192.168.1.1:80",
	  "enabled": "0",
      "type": "L"
    },
	{
      "name_rule": "Local Tomcat Forward",
      "source_port": "7789",
      "destination": "127.0.0.1:8080",
	  "enabled": "1",
      "type": "R"
    }
  ],
  "proxy_ip": "sampledomain.com",
  "proxy_port": "22",
  "proxy_user": "proxy_user",
  "proxy_password": "%samplePasswd%",
  "accepted_key": "0",
  "console_enabled": "0"
}
	)
	return txt
}

toggleVisibility:
	DetectHiddenWindows, On
	if isVisible
	{
		WinHide, Tunnel Manager - elModo7 Soft
		if(!nogui)
			Menu, tray, Rename, Hide Client, Show Client
		isVisible = 0
	}
	else
	{
		WinShow, Tunnel Manager - elModo7 Soft
		WinActivate, Tunnel Manager - elModo7 Soft
		if(!nogui)
			Menu, tray, Rename, Show Client, Hide Client
		isVisible = 1
	}
return

copyTunnel(unhandledParam := "", tunnelIp := ""){
	global
	if(Trim(tunnelIp) != ""){
		; if Control key is pressed down, instead of copying it to the clipboard it will show a QR Code for a quick HTTP access
		if(GetKeyState("Control", "P")){
			sFile := A_Temp "\" A_NowUTC ".png"
			https := ""
			if(GetKeyState("Shift", "P")) ; If Shift is pressed down, the QR Code will be generated for HTTPS
				https := "s"
			DllCall( A_Temp "\quricol64.dll\GeneratePNG","str", sFile , "str", "http" https "://" tunnelIp, "int", 4, "int", 2, "int", 0)
			GUI,pic:Destroy
			GUI,pic:-Caption +ToolWindow
			GUI,pic:Add,Pic, x0 y0 w232 h232 hwndhimage,% sFile
			GUI,pic:Show,w232 h232
		}else{
			Clipboard := tunnelIp
			ToolTip, Copied!
			SetTimer, removeTooltip, 500
		}
	}else{
		showErrorModal("Invalid Tunnel Type", "The tunnel you selected could not be copied to the clipboard because it didn't have a recognized type.<br>Try using one of the defined (L, R or D)")
	}
}

PICGUIEscape:
  GUI,pic:Destroy
return

lookForUpdates:
	gitHubData := JSON.Load(urlDownloadToVar("https://api.github.com/repos/elModo7/Tunnel_Manager/releases/latest"))
	gitHubVersion := gitHubData.tag_name
	versionDiff := VerCmp(gitHubVersion, version)
	if(versionDiff == "-1"){
		neutron.doc.getElementById("msgVersionCheck").innerHTML := "Your Tunnel Manager is more recent than the current public version:<br>Local: v" version "<br>Remote: v" gitHubVersion
	}else if(versionDiff == "0"){
		neutron.doc.getElementById("msgVersionCheck").innerHTML := "Tunnel Manager is up to date:<br>Local: v" version "<br>Remote: v" gitHubVersion
	}else if(versionDiff == "1"){
		neutron.doc.getElementById("msgVersionCheck").innerHTML := "There is a new Tunnel Manager version:<br>Local: v" version "<br>Remote: v" gitHubVersion "<br><br><a href='#' onclick='ahk.downloadLatestVersion()'>You can download it by clicking this message.</a>"
	}
	neutron.wnd.showVersionCheckModal()
return

plinkPromptDownload(){
	global
	; 1.2.28 GitHub sometimes has issues with compiled files on the repo, add download
	if(!FileExist(A_Temp "\proxy.exe")){
		OnMessage(0x44, "OnMsgBoxPromptPlink")
		MsgBox 0x31, PLink.exe not found, This software requires plink.exe to run`, you can either download the latest version or use the built in one (recommended).`n
		OnMessage(0x44, "")

		IfMsgBox OK, {
			FileInstall, lib/proxy.exe, % A_Temp "\proxy.exe", 0 ; 1.2.28: Do not replace Plink each time
		} Else IfMsgBox Cancel, {
			DownloadFile("https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe", A_Temp "\proxy.exe")
		}
	}
}

OnMsgBoxPromptPlink() {
	DetectHiddenWindows, On
	Process, Exist
	If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
		ControlSetText Button1, Use built in
		ControlSetText Button2, Download
	}
}

downloadLatestVersion(unhandledParam := ""){
	Run, https://github.com/elModo7/Tunnel_Manager/releases/latest
}

; Since VerCompare is > 1.1.36.1 I will use this to keep compatibility with lower versions of AHK
VerCmp(V1, V2) {           ; VerCmp() for Windows by SKAN on D35T/D37L @ tiny.cc/vercmp 
Return ( ( V1 := Format("{:04X}{:04X}{:04X}{:04X}", StrSplit(V1 . "...", ".",, 5)*) )
       < ( V2 := Format("{:04X}{:04X}{:04X}{:04X}", StrSplit(V2 . "...", ".",, 5)*) ) )
       ? -1 : ( V2<V1 ) ? 1 : 0
}

urlDownloadToVar(url,raw:=0,userAgent:="",headers:=""){
	if (!regExMatch(url,"i)https?://"))
		url:="https://" url
	try {
		hObject:=comObjCreate("WinHttp.WinHttpRequest.5.1")
		hObject.open("GET",url)
		if (userAgent)
			hObject.setRequestHeader("User-Agent",userAgent)
		if (isObject(headers)) {
			for i,a in headers {
				hObject.setRequestHeader(i,a)
			}
		}
		hObject.send()
		return raw?hObject.responseBody:hObject.responseText
	} catch e
		return % e.message
}

AHK_ICONCLICKCHECK()
{
	global AHK_ICONCLICKCOUNT
	if  (AHK_ICONCLICKCOUNT = 1)		; LEFT CLK
	{
		;~ Menu, LeftClickMenu, Show
	}
	else if (AHK_ICONCLICKCOUNT = 2)	; LEFT DBCLK
	{
		gosub, toggleVisibility
	}
	return 0
}

AHK_ICONCLICKNOTIFY(wParam,lParam)
{
	global AHK_ICONCLICKCOUNT
	if (lParam = 0x201)
	{
		AHK_ICONCLICKCOUNT := 1
		SetTimer, AHK_ICONCLICKCHECK, -200
	}
	else if (lParam = 0x203)
	{
		AHK_ICONCLICKCOUNT := 2
	}
	else if (lParam = 0x205)			; RIGHT CLK
	{
		Menu, Tray, Show			; launch standard menu
		;~ Menu, RightClickMenu, Show	; or a custom one
	}
	else if (lParam = 0x208)			; MIDDLE CLK
	{
		TrayTip, Tunnel Manager - elModo7 Soft, % "A software by Víctor Santiago Martínez Picardo`nv" version
	}
	return 0
}

showLicense(){
	global neutron, nogui, silent, startHidden, autostart
	if(!nogui && !silent && !startHidden && !autostart){
		RegRead, firstRun, HKEY_CURRENT_USER\Software\elModo7's Tunnel Manager, FirstRun
		if(firstRun == 0 || firstRun == ""){
			RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\elModo7's Tunnel Manager, FirstRun, 1
			neutron.wnd.showLicenseModal()
		}
	}

}

closeApp(unhandledParam := ""){
	gosub, ExitSub
}

removeTooltip:
	ToolTip
return

NeutronClose:
GuiClose:
ExitSub:
	RunWait, taskkill /IM proxy.exe /F,, Hide
ExitApp

showAboutScreen:
	showAboutScreen("SSH Tunnel Manager v" version, "Network tool for proxying, pivoting, bypassing firewalls and securing connections over SSH. This app does heavy use of plink.exe")
return

; Hotkeys
#If WinActive("Tunnel Manager - elModo7 Soft")
	*~Control::neutron.wnd.setQRMode()
	*~Control Up::neutron.wnd.revertQRMode()
#If

#Include <aboutScreen>

; Neutron's FileInstall Resources
FileInstall, Tunnel_manager.html, Tunnel_manager.html
FileInstall, bootstrap.min.css, bootstrap.min.css
FileInstall, font-awesome.min.css, font-awesome.min.css
FileInstall, bootstrap.min.js, bootstrap.min.js
FileInstall, jquery.min.js, jquery.min.js
FileInstall, fontawesome-webfont.woff, fontawesome-webfont.woff