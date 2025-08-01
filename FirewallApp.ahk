/*
All settings can be found within the app itself, so there's no need to change anything.
While you can add themes manually, it is yet not recommended.

[General]
currentVersion=v0.9.5-enh
LastUser=
LastPos=

[Settings]
MainHotkey=PgDn
SuspendHotkey=!PgDn
Sounds=Default Sounds
FwPorts=80, 443
AutoFw=0
AutoFwDelay=590
SuspendTimeout=10
Theme=Dark Theme

[Sounds]
FirewallOn=
FirewallOff=
SuspendOn=
SuspendOff=

[Themes]
Dark Theme=272B34, FFFFFF, 0
Light Theme=F3F3F3, 000000, 0
Ultra Dark=141414, FFFFFF, 0

[End]
*/

#Requires AutoHotkey v2.0
#SingleInstance
#UseHook
#NoTrayIcon

; ^R::Reload
; ^Q::ExitApp

class App {
    static __New() {
        App.RunAsAdmin()
        App.Tray.Init()
        App.Gui.Init()
        App.Controls.Init()
        App.Settings.CheckUser()
        App.Theme.GetList()
        App.Settings.Apply()
        App.Gui.Show()
        OnExit(App.SaveAndExit)
    }

    static RunAsAdmin() {
        if (A_IsAdmin == 0) {
            Run("*RunAs " A_ScriptFullPath "")
            Pause()
        }
    }

    static SaveAndExit(*) {
        if (A_IsSuspended == 0) {
            App.Settings.Save()
        }
        App.Settings.SavePos()
        RunWait('netsh advfirewall firewall delete rule name="GTA Online Firewall"', , "hide")
        try {
            DllCall("ntdll\NtResumeProcess", "Ptr", processHandle)
            DllCall("CloseHandle", "Ptr", processHandle)
        }
        
    }

    class Tray {
        static Init() {
            A_TrayMenu.Delete()
            A_TrayMenu.ClickCount := 1
            A_TrayMenu.Add("Show", (*) => appGui.Restore())
            A_TrayMenu.Default := "Show"
            ; A_TrayMenu.Add("Centralize", (*) => appGui.Show("xCenter yCenter"))
            A_TrayMenu.Add("Reset Settings", (*) => (App.Gui.SwitchToPage("ResetMsg"), Suspend(true)))
            A_TrayMenu.Add()
            A_TrayMenu.Add("Restart", (*) => Reload())
            A_TrayMenu.Add("Exit", (*) => ExitApp())
            A_IconHidden := 0
        }
    }

    class Gui extends Gui {
        static Init() {
            global appGui := App.Gui("-MinimizeBox", "FirewallApp")
            appGui.BackColor := "272b34"
            appGui.OnEvent("Close", (*) => ExitApp())
            OnMessage(0x0201, App.Gui.Move)
        }

        static Show() {
            lastPos := App.Settings.Get("General", "LastPos")
            lastPos := StrSplit(lastPos, ",", " ")
            lastPos := Format("x{1} y{2}", lastPos*)
            appGui.Show(lastPos . " w200 h300")
            appGui["Page"].Opt("Disabled")
        }

        static Move(*) {
            MouseGetPos( , , , &controlName)
            try if (controlName == "" or appGui[controlName].Type ~= "\A(Text|GroupBox)")
                PostMessage(0x00A1, 2, , , appGui.Hwnd)
        }

        static SwitchToPage(pageName, *) {
            ControlFocus(appGui["Submit"])
            ; appGui["Version"].Visible := !(pageName ~= "\A(ResetMsg|UpdateMsg)")
            appGui["Page"].Opt("-Disabled")
            appGui["Page"].Choose(pageName)
            appGui["Page"].Opt("Disabled")
        }

        AddControl(type, options := "", fontStyle := "", text := "") {
            this.SetFont(fontStyle, "Verdana")
            control := this.Add(type, options, text)
            return control
        }
    }

    class Controls {
        static Init() {
            ; создаю "дефолтную" кнопку, которая нажимается при нажатии на Enter и смещает фокус на себя (для триггера ивента LoseFocus)
            ; использую для подтверждения изменений в элементах Edit по нажатию Enter 
            appGui.AddControl("Button", "vSubmit w0 Default")
                .OnEvent("Click", (control, *) => ControlFocus(control))

            if App.Update.IsAvailable() {
                appGui.AddControl("Link", "vVersion x44 y276 cWhite Center", "s8 Norm", "<a>Update</a> is available!")
                    .OnEvent("Click", (*) => (App.Gui.SwitchToPage("UpdateMsg"), Suspend(true)))
            } else {
                appGui.AddControl("Text", "vVersion x10 y276 w180 c525863 Center", "s8 Norm", App.Settings.Get("General", "currentVersion"))
            }

            appGui.AddControl("Tab2", "vPage w0 Choose1", , ["Main", "Settings", "Advanced", "Sounds", "ResetMsg", "UpdateMsg"])
            
            appGui["Page"].UseTab("Main")
                appGui.AddControl("Text", "vMainHotkeyPrompt x10 y15 w180 h36 cWhite Center", "s11 Bold")
                appGui.AddControl("Text", "vFwState x10 y105 w180 ce94b4b Center 0x4", "s25 Bold", "OFF")
                appGui.AddControl("CheckBox", "vAutoFwState x69 y210 cWhite", "s8 Norm", "AutoFW")
                    .OnEvent("Click", (control, *) => (App.Settings.Save(), App.Controls.TrayTipHandler(control))) ; App.Settings.Save() не нужен?
                appGui.AddControl("Button", "x14 y237 w78 h31 Background272b34", "s11 Norm", "Hide")
                    .OnEvent("Click", (*) => appGui.Hide())
                appGui.AddControl("Button", "x+16 wp hp Background272b34", "s11 Norm", "Settings")
                    .OnEvent("Click", (*) => (App.Gui.SwitchToPage("Settings"), Suspend(true)))

            appGui["Page"].UseTab("Settings")
                appGui.AddControl("Text", "x10 y10 w180 cWhite Center", "s17 Bold", "Settings")
                appGui.AddControl("GroupBox", "x10 y38 w180 h75 cWhite", "s8 Norm", "Hotkeys")
                    appGui.AddControl("Text", "Section xp+9 yp+20 cWhite", "s8 Norm", "Firewall")
                    appGui.AddControl("Hotkey", "vMainHotkey x+11 yp-3 w108", "s8 Norm")
                    appGui.AddControl("Text", "xs y+8 cWhite", "s8 Norm", "Suspend")
                    appGui.AddControl("Hotkey", "vSuspendHotkey x+5 yp-3 w108", "s8 Norm")
                appGui.AddControl("GroupBox", "x10 y116 w180 h75 cWhite", "s8 Norm", "Sounds")
                    appGui.AddControl("DDL", "vSounds xp+9 yp+17 w162 Choose2", "s8 Norm", ["Off", "Default Sounds", "Custom Sounds"])
                    appGui.AddControl("Button", "xp-1 y+4 w164", "s8 Norm", "Pick Custom Sounds")
                        .OnEvent("Click", (*) => App.Gui.SwitchToPage("Sounds"))
                appGui.AddControl("Button", "x14 y201 w172 h26 Background272b34", "s8 Norm", "Advanced Settings")
                    .OnEvent("Click", (*) => App.Gui.SwitchToPage("Advanced"))
                appGui.AddControl("Button", "x14 y237 w78 h31 Background272b34", "s11 Norm", "Cancel")
                    .OnEvent("Click", (*) => (App.Gui.SwitchToPage("Main"), App.Settings.Apply(), Suspend(false)))
                appGui.AddControl("Button", "x+16 wp hp Background272b34", "s11 Norm", "Save")
                    .OnEvent("Click", (*) => (Suspend(false), Reload()))

            appGui["Page"].UseTab("Advanced")
                appGui.AddControl("Text", "x10 y10 w180 cWhite Center", "s17 Bold", "Settings")
                appGui.AddControl("GroupBox", "x10 y38 w180 h75 cWhite", "s8 Norm", "Firewall")
                    appGui.AddControl("Text", "Section xp+9 yp+20 cWhite", "s8 Norm", "FW Ports")
                    appGui.AddControl("Edit", "vFwPorts x+5 yp-3 w107", "s8 Norm", "")
                        appGui["FwPorts"].OnEvent("LoseFocus", (control, *) => App.Controls.FormatRawInput(control))
                    appGui.AddControl("Text", "xs y+8 cWhite", "s8 Norm", "AutoFW Delay")
                    appGui.AddControl("Edit", "vAutoFwDelay x+5 yp-3 w77 Center", "s8 Norm", "1000ms")
                        appGui["AutoFwDelay"].OnEvent("Focus", (control, *) => SendMessage(0xB1, 0, -1, control))
                        appGui["AutoFwDelay"].OnEvent("LoseFocus", (control, *) => App.Controls.FormatRawInput(control))
                appGui.AddControl("GroupBox", "x10 y116 w180 h75 cWhite", "s8 Norm", "Other")
                    appGui.AddControl("Text", "Section xp+9 yp+20 cWhite", "s8 Norm", "Suspend Timeout")
                    appGui.AddControl("Edit", "vSuspendTimeout x+5 yp-3 w58", "s8 Norm", "")
                        appGui["SuspendTimeout"].OnEvent("Focus", (control, *) => SendMessage(0xB1, 0, -1, control))
                        appGui["SuspendTimeout"].OnEvent("LoseFocus", (control, *) => App.Controls.FormatRawInput(control))
                    appGui.AddControl("Text", "xs y+9 cWhite", "s8 Norm", "Theme")
                    appGui.AddControl("DDL", "vThemes x+5 yp-4 w118", "s8 Norm", [])
                        appGui["Themes"].OnEvent("Change", (control, *) => App.Theme.Apply())
                appGui.AddControl("Button", "x14 y201 w172 h26 Background272b34", "s8 Norm", "Reset All Settings")
                    .OnEvent("Click", (*) => App.Gui.SwitchToPage("ResetMsg"))
                appGui.AddControl("Button", "x14 y237 w78 h31 Background272b34", "s11 Norm", "Back")
                    .OnEvent("Click", (*) => App.Gui.SwitchToPage("Settings"))
                appGui.AddControl("Button", "x+16 wp hp Background272b34", "s11 Norm", "Save")
                    .OnEvent("Click", (*) => (Suspend(false), Reload()))

            appGui["Page"].UseTab("Sounds")
                appGui.AddControl("Text", "x10 y10 w180 cWhite Center", "s17 Bold", "Sounds")
                appGui.AddControl("GroupBox", "x10 y38 w180 h75 cWhite", "s8 Norm", "Firewall")
                    appGui.AddControl("Text", "Section xp+9 yp+20 cWhite", "s8 Norm", "ON")
                    appGui.AddControl("Edit", "vFirewallOnSound x45 yp-3 w110 ReadOnly", "s8 Norm", "")
                    appGui.AddControl("Button", "x+5 yp h21 w21", "s8 Norm", "📂")
                        .OnEvent("Click", (*) => App.Sound.Pick("FirewallOnSound"))
                    appGui.AddControl("Text", "xs y+8 cWhite", "s8 Norm", "OFF")
                    appGui.AddControl("Edit", "vFirewallOffSound x+5 yp-3 w110 ReadOnly", "s8 Norm", "")
                    appGui.AddControl("Button", "x+5 yp h21 w21", "s8 Norm", "📂")
                        .OnEvent("Click", (*) => App.Sound.Pick("FirewallOffSound"))
                appGui.AddControl("GroupBox", "x10 y116 w180 h75 cWhite", "s8 Norm", "Suspend")
                    appGui.AddControl("Text", "Section xp+9 yp+20 cWhite", "s8 Norm", "ON")
                    appGui.AddControl("Edit", "vSuspendOnSound x45 yp-3 w110 ReadOnly", "s8 Norm", "")
                    appGui.AddControl("Button", "x+5 yp h21 w21", "s8 Norm", "📂")
                        .OnEvent("Click", (*) => App.Sound.Pick("SuspendOnSound"))
                    appGui.AddControl("Text", "xs y+8 cWhite", "s8 Norm", "OFF")
                    appGui.AddControl("Edit", "vSuspendOffSound x+5 yp-3 w110 ReadOnly", "s8 Norm", "")
                    appGui.AddControl("Button", "x+5 yp h21 w21", "s8 Norm", "📂")
                        .OnEvent("Click", (*) => App.Sound.Pick("SuspendOffSound"))
                appGui.AddControl("Button", "x14 y201 w172 h26 Background272b34", "s8 Norm", "Clear All")
                appGui.AddControl("Button", "x14 y237 w78 h31 Background272b34", "s11 Norm", "Back")
                    .OnEvent("Click", (*) => App.Gui.SwitchToPage("Settings"))
                appGui.AddControl("Button", "x+16 wp hp Background272b34", "s11 Norm", "Save")
                    .OnEvent("Click", (*) => (Suspend(false), Reload()))
            
            appGui["Page"].UseTab("ResetMsg")
                appGui.AddControl("Text", "x10 y60 w180 cWhite Center", "s17 Bold", "Reset")
                appGui.AddControl("Text", "x10 y+20 w180 cWhite Center", "s11 Norm", "Do you want to reset the settings?")
                appGui.AddControl("Button", "x14 y+28 w78 h31 Background272b34", "s11 Norm", "Cancel")
                    .OnEvent("Click", (*) => (App.Gui.SwitchToPage("Main"), App.Settings.Apply(), Suspend(false)))
                appGui.AddControl("Button", "x+16 wp hp Background272b34", "s11 Norm", "Yes")
                    .OnEvent("Click", (*) => App.Settings.Reset())

            appGui["Page"].UseTab("UpdateMsg")
                appGui.AddControl("Text", "x10 y60 w180 cWhite Center", "s17 Bold", "Update")
                appGui.AddControl("Text", "x10 y+20 w180 cWhite Center", "s11 Norm", "Do you want to update the app?")
                appGui.AddControl("Button", "x14 y+28 w78 h31 Background272b34", "s11 Norm", "Cancel")
                    .OnEvent("Click", (*) => (App.Gui.SwitchToPage("Settings"), Suspend(false)))
                appGui.AddControl("Button", "x+16 wp hp Background272b34", "s11 Norm", "Yes")
                    .OnEvent("Click", (*) => App.Update.Procedure())
        }

        static TrayTipHandler(control, *) {
            if appGui["AutoFwState"].Value == 1 {
                TrayTip("Enable Firewall while on a heist restart screen.", "Auto Firewall is Enabled!")
            }
        }

        static FormatHotkey(hotkey) {
            formattedHotkey := "[" . StrUpper(hotkey) . "]"
            formattedHotkey := StrReplace(formattedHotkey, "+", "Shift] [")
            formattedHotkey := StrReplace(formattedHotkey, "^", "Ctrl] [")
            formattedHotkey := StrReplace(formattedHotkey, "!", "Alt] [")
            return formattedHotkey
        }

        static FormatRawInput(control, *) {
            rawInput := control.Value
            
            try switch(control.Name) {
                case("FwPorts"):
                    formattedStr := RegExReplace(rawInput, "\D+", ",")
                    formattedStr := Trim(formattedStr, ",")
                    formattedStr := Sort(formattedStr, "N U D,")
                    formattedStr := StrReplace(formattedStr, ",", ", ")
                    if (formattedStr == "") {
                        formattedStr := "All"
                    }
                case("AutoFwDelay"):
                    formattedStr := RegExReplace(rawInput, "\D")
                    if (formattedStr != "") {
                        formattedStr .= "ms"
                    }
                case("SuspendTimeout"):
                    formattedStr := RegExReplace(rawInput, "\D")
                    if (formattedStr != "") {
                        formattedStr .= "s"
                    }
            }

            control.Value := formattedStr
        }
    }

    class Firewall {
        static Toggle(state?) {
            static isActive := false
            ; isActive := !isActive
            isActive := state ?? !isActive
            if (isActive == true) {
                gamePath := ""
                try gamePath := WinGetProcessPath("ahk_exe gta5.exe")
                try gamePath := WinGetProcessPath("ahk_exe gta5_enhanced.exe")
                if (gamePath == "" ){
                    TrayTip("Start the game first!")
                    isActive := false
                    return
                }
                App.Firewall.Enable(gamePath)
            } else {
                App.Firewall.Disable()
            }
        }

        static Enable(gamePath) {
            App.Sound.PlaySound("FirewallOnSound")
            ports := appGui["FwPorts"].Value
            ports := StrReplace(ports, ", ", ",")
            ports := " remoteport=" . ports
            if (InStr(ports, "all")) {
                ports := ""
            }
            appGui["FwState"].Opt("c83f783")
            appGui["FwState"].Value := "ON"
            RunWait('netsh advfirewall firewall add rule name="GTA Online Firewall" dir=out action=block' . ports . ' protocol=TCP program="' . gamePath . '"', , "hide")
            if appGui["AutoFwState"].Value == 1 {
                SetTimer(App.AutoFw.WaitRestartScreen, 1)
            }
        }

        static Disable() {
            App.Sound.PlaySound("FirewallOffSound")
            appGui["FwState"].Opt("ce94b4b")
            appGui["FwState"].Value := "OFF"
            RunWait('netsh advfirewall firewall delete rule name="GTA Online Firewall"', , "hide")
            SetTimer(App.AutoFw.WaitRestartScreen, 0)
            SetTimer(App.AutoFw.WaitNoRestartScreen, 0)
        }
    }

    class AutoFw {
        static WaitRestartScreen := () => App.AutoFw.WaitRestartScreenMethod()
        static WaitNoRestartScreen := () => App.AutoFw.WaitNoRestartScreenMethod()
        static Timeout := App.Settings.Get("Settings", "AutoFwDelay")

        static WaitRestartScreenMethod() {
            if PixelSearch(&x, &y, 0, 0, A_ScreenWidth, A_ScreenHeight / 2, 0x217625) {
                SetTimer(App.AutoFw.WaitRestartScreen, 0)
                SetTimer(App.AutoFw.WaitNoRestartScreen, 1)
            }
        }

        static WaitNoRestartScreenMethod() {
            if not PixelSearch(&x, &y, 0, 0, A_ScreenWidth, A_ScreenHeight / 2, 0x217625) {
                SetTimer(App.AutoFw.WaitNoRestartScreen, 0)
                Sleep(App.AutoFw.Timeout)
                App.Firewall.Toggle(false)
            }
        }
    }

    class Suspend {
        static Timeout := App.Settings.Get("Settings", "SuspendTimeout") * 1000
        static ToggleCallback := () => App.Suspend.Toggle()
        ; static ToggleCallback := App.Suspend.Toggle.Bind(App.Suspend) 
        ; static ToggleCallback := ObjBindMethod(App.Suspend, "Toggle")

        static Toggle() {
            processID := ""
            try processID := WinGetPID("ahk_exe gta5.exe")
            try processID := WinGetPID("ahk_exe gta5_enhanced.exe")
            if (processID == "") {
                TrayTip("Start the game first!")
                return
            }
            static isActive := true
            isActive := !isActive
            if not isActive {
                App.Suspend.Enable(processID)
            } else {
                App.Suspend.Disable()
            }
        }

        static Enable(processID) {
            SetTimer(App.Suspend.ToggleCallback, App.Suspend.Timeout)
            App.Sound.PlaySound("SuspendOnSound")
            global processHandle := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", false, "UInt", processID, "Ptr")
            DllCall("ntdll\NtSuspendProcess", "Ptr", processHandle)
        }

        static Disable() {
            SetTimer(App.Suspend.ToggleCallback, 0)
            App.Sound.PlaySound("SuspendOffSound")
            DllCall("ntdll\NtResumeProcess", "Ptr", processHandle)
            DllCall("CloseHandle", "Ptr", processHandle)
        }
    }

    class Sound {
        static Pick(controlName) {
            appGui.Opt("+OwnDialogs")
            currentValue := appGui[controlName].Value
            appGui[controlName].Value := FileSelect("S3", currentValue, "Pick custom sound", "Audio files (*.wav; *.mp3)")
        }

        static PlaySound(controlName) {
            switch (appGui["Sounds"].Text) {
                case ("Off"):
                    return
                case ("Default Sounds"):
                    App.Sound.PlayDefaultSound(controlName)
                case ("Custom Sounds"):
                    App.Sound.PlayCustomSound(controlName)
            } 
        }

        static PlayDefaultSound(controlName) {
            switch (controlName) {
                case ("FirewallOnSound"): SoundBeep(500)
                case ("FirewallOffSound"): SoundBeep(300)
                case ("SuspendOnSound"): SoundBeep(200)
                case ("SuspendOffSound"): SoundBeep(100)
            }
        }

        static PlayCustomSound(controlName) {
            customSound := appGui[controlName].Value
            if (customSound == "") {
                App.Sound.PlayDefaultSound(controlName)
                return
            }
            if not FileExist(customSound) {
                App.Sound.PlayDefaultSound(controlName)
                appGui[controlName].Value := ""
                return
            }
            SoundPlay(customSound)
        }
    }

    class Theme {
        static GetList() {
            themesArr := []
            themesList := App.Settings.Get("Themes")
            themesList := StrSplit(themesList, "`n")
            for theme in themesList {
                themeInfo := StrSplit(theme, "=", " ")
                themeName := themeInfo[1]
                themesArr.Push(themeName)
            }
            appGui["Themes"].Add(themesArr)
        }

        static Apply() {
            currentTheme := appGui["Themes"].Text
            themeOptions := App.Settings.Get("Themes", currentTheme)
            themeOptions := StrSplit(themeOptions, ",", " ")
            backColor := themeOptions[1]
            textColor := themeOptions[2]
            isToolWindow := themeOptions[3]

            appGui.BackColor := backColor

            for control in appGui {
                if (control.Name ~= "\A(FwState|Version)")
                    continue
                else if (control.Type ~= "(Text|Link|CheckBox|GroupBox)")
                    control.Opt("c" textColor)
                else if (control.Type == "Button")
                    control.Opt("+Background" backColor)
            }

            (isToolWindow == 1) ? appGui.Opt("ToolWindow") : appGui.Opt("-ToolWindow")
        }
    }

    class Update {
        static GetReleaseJSON() {
            apiRequest := ComObject("WinHttp.WinHttpRequest.5.1")
            apiRequest.Open("GET", "https://api.github.com/repos/Asteos96/FirewallApp/releases/latest")
            try apiRequest.Send()
                catch {
                    return
                }
            releaseInfo := apiRequest.ResponseText
            return releaseInfo
        }

        static ParseLatestVersion(key := "tag_name") {
            releaseInfo := App.Update.GetReleaseJSON()
            if not (releaseInfo) {
                return
            }
            releaseInfoArr := StrSplit(releaseInfo, ",", ',[]{}')
            for pair in releaseInfoArr {
                if InStr(pair, key) {
                    output := StrReplace(pair, '"')
                    output := StrReplace(output, key . ":")
                }
            }
            return output
        }

        static IsAvailable() {
            currentVersion := App.Settings.Get("General", "currentVersion")
            latestVersion := App.Update.ParseLatestVersion("tag_name")
            if not (latestVersion) {
                return
            }
            if currentVersion != latestVersion {
                return true
            }
            return false
        }

        static Procedure() {
            latestVersionLink := App.Update.ParseLatestVersion("browser_download_url")
            FileMove(A_ScriptFullPath, A_ScriptFullPath ".old", 1)
	        Download(latestVersionLink, A_ScriptFullPath)
            Reload()
        }
    }

    class Settings {
        static IniPath := A_ScriptFullPath
        ; static iniPath := A_MyDocuments "/fw_settings.ini"
        
        static Get(section, key?) {
            output := IniRead(App.Settings.IniPath, section, key?)
            return output
        }

        static SavePos() {
            ; appGui.Opt("-Owner")
            appGui.GetPos(&appPosX, &appPosY)
            IniWrite(appPosX . ", " . appPosY, App.Settings.IniPath, "General", "LastPos")
        }

        static Save() {
            mainHotkey := appGui["MainHotkey"].Value
            IniWrite(mainHotkey, App.Settings.IniPath, "Settings", "MainHotkey")

            suspendHotkey := appGui["SuspendHotkey"].Value
            IniWrite(suspendHotkey, App.Settings.IniPath, "Settings", "SuspendHotkey")

            sounds := appGui["Sounds"].Text
            IniWrite(sounds, App.Settings.IniPath, "Settings", "Sounds")

            fwPorts := appGui["FwPorts"].Value
            IniWrite(fwPorts, App.Settings.IniPath, "Settings", "FwPorts")

            autoFwState := appGui["AutoFwState"].Value
            IniWrite(autoFwState, App.Settings.IniPath, "Settings", "AutoFw")

            autoFwDelay := appGui["AutoFwDelay"].Value
            autoFwDelay := StrReplace(autoFwDelay, "ms")
            IniWrite(autoFwDelay, App.Settings.IniPath, "Settings", "AutoFwDelay")

            suspendTimeout := appGui["SuspendTimeout"].Value
            suspendTimeout := StrReplace(suspendTimeout, "s")
            IniWrite(suspendTimeout, App.Settings.IniPath, "Settings", "SuspendTimeout")

            firewallOnSound := appGui["FirewallOnSound"].Value
            IniWrite(firewallOnSound, App.Settings.IniPath, "Sounds", "FirewallOn")
            
            firewallOffSound := appGui["FirewallOffSound"].Value
            IniWrite(firewallOffSound, App.Settings.IniPath, "Sounds", "FirewallOff")

            suspendOnSound := appGui["SuspendOnSound"].Value
            IniWrite(suspendOnSound, App.Settings.IniPath, "Sounds", "SuspendOn")

            suspendOffSound := appGui["SuspendOffSound"].Value
            IniWrite(suspendOffSound, App.Settings.IniPath, "Sounds", "SuspendOff")

            theme := appGui["Themes"].Text
            IniWrite(theme, App.Settings.IniPath, "Settings", "Theme")
        }

        static CheckUser() {
            IsNewUser := !(A_UserName == App.Settings.Get("General", "LastUser"))

            if (IsNewUser == true) {
                App.Settings.WriteDefault()
            }
        }

        static WriteDefault() { ; записать дефолтные настройки в .ini
            IniWrite(A_UserName, App.Settings.IniPath, "General", "LastUser")
            IniWrite("Center, Center", App.Settings.IniPath, "General", "LastPos")

            IniWrite("PgDn", App.Settings.IniPath, "Settings", "MainHotkey")
            IniWrite("!PgDn", App.Settings.IniPath, "Settings", "SuspendHotkey")
            IniWrite("Default Sounds", App.Settings.IniPath, "Settings", "Sounds")
            IniWrite("80, 443", App.Settings.IniPath, "Settings", "FwPorts")
            IniWrite("0", App.Settings.IniPath, "Settings", "AutoFw")
            IniWrite("590", App.Settings.IniPath, "Settings", "AutoFwDelay")
            IniWrite("10", App.Settings.IniPath, "Settings", "SuspendTimeout")
            IniWrite("Dark Theme", App.Settings.IniPath, "Settings", "Theme")

            IniWrite("", App.Settings.IniPath, "Sounds", "FirewallOn")
            IniWrite("", App.Settings.IniPath, "Sounds", "FirewallOff")
            IniWrite("", App.Settings.IniPath, "Sounds", "SuspendOn")
            IniWrite("", App.Settings.IniPath, "Sounds", "SuspendOff")
            
            IniWrite("F3F3F3, 000000, 0", App.Settings.IniPath, "Themes", "Light Theme")
            IniWrite("272B34, FFFFFF, 0", App.Settings.IniPath, "Themes", "Dark Theme")
            IniWrite("141414, FFFFFF, 0", App.Settings.IniPath, "Themes", "Ultra Dark")
        }

        static Apply() { ; применить настройки из .ini к приложению
            try { ; для сброса настроек в случае некорректного значения или повреждения .ini файла
                mainHotkey := App.Settings.Get("Settings", "MainHotkey")
                
                mainHotkeyPrompt := App.Controls.FormatHotkey(mainHotkey)
                appGui["MainHotkeyPrompt"].Value := "Press " . mainHotkeyPrompt

                Hotkey("~" mainHotkey, App.Firewall.Toggle)
                appGui["MainHotkey"].Value := mainHotkey

                suspendHotkey := App.Settings.Get("Settings", "SuspendHotkey")
                Hotkey("~" suspendHotkey, App.Suspend.Toggle)
                appGui["SuspendHotkey"].Value := suspendHotkey

                sounds := App.Settings.Get("Settings", "Sounds")
                appGui["Sounds"].Choose(sounds)

                fwPorts := App.Settings.Get("Settings", "FwPorts")
                appGui["FwPorts"].Value := fwPorts
                App.Controls.FormatRawInput(appGui["FwPorts"])

                autoFwState := App.Settings.Get("Settings", "AutoFw")
                appGui["AutoFwState"].Value := autoFwState
                
                autoFwDelay := App.Settings.Get("Settings", "AutoFwDelay")
                appGui["AutoFwDelay"].Value := autoFwDelay
                App.Controls.FormatRawInput(appGui["AutoFwDelay"])

                suspendTimeout := App.Settings.Get("Settings", "SuspendTimeout")
                appGui["SuspendTimeout"].Value := suspendTimeout
                App.Controls.FormatRawInput(appGui["SuspendTimeout"])

                firewallOnSound := App.Settings.Get("Sounds", "FirewallOn")
                appGui["FirewallOnSound"].Value := firewallOnSound
                
                firewallOffSound := App.Settings.Get("Sounds", "FirewallOff")
                appGui["FirewallOffSound"].Value := firewallOffSound

                suspendOnSound := App.Settings.Get("Sounds", "SuspendOn")
                appGui["SuspendOnSound"].Value := suspendOnSound
                
                suspendOffSound := App.Settings.Get("Sounds", "SuspendOff")
                appGui["SuspendOffSound"].Value := suspendOffSound

                theme := App.Settings.Get("Settings", "Theme")
                appGui["Themes"].Choose(theme)
            } catch {
                MsgBox("App.Settings.Apply failed. Reset.")
                App.Settings.Reset()
            }
            App.Theme.Apply()
        }

        static Reset() {
            IniWrite("", App.Settings.IniPath, "General", "LastUser")
            Reload()
            Pause()
        }
    }
}
