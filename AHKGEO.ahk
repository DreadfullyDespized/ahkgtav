IF NOT A_IsAdmin
{
   Run *RunAs "%A_ScriptFullPath%"
   ExitApp
}

if (a_ahkversion < 1.1){
    Msgbox, 0x10
        , % "Error"
        , % "The AutoHotkey installed in your computer is not compatible with`n"
        . "this version of AHKGEO Doohicky.`n`n"
        . "Please use the compiled version of my script or upgrade your AutoHotkey.`n"
        . "The application will exit now."
    Exitapp
}

#NoEnv
#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

Menu, Tray, Icon, shell32.dll, 194

global script := {  based               : scriptobj
                    ,name               : "AHKGEO"
                    ,version            : "1"
                    ,author             : "DreadfullyDespized"
                    ,homepage           : "https://github.com/DreadfullyDespized/ahkgtav/releases"
                    ,crtdate            : "20201214"
                    ,moddate            : "20211124"
                    ,conf               : "GEO-Config.ini"
                    ,logurl             : "https://raw.githubusercontent.com/DreadfullyDespized/ahkgtav/master/" 
                    ,change             : "Changelog-GEO.txt"
                    ,bug                : "https://github.com/DreadfullyDespized/ahkgtav/issues/new?assignees=DreadfullyDespized&labels=bug&template=bug_report.md&title="
                    ,feedback           : "https://github.com/DreadfullyDespized/ahkgtav/issues/new?assignees=DreadfullyDespized&labels=enhancement&template=feature_request.md&title="}

global updatefile = % A_Temp "\" script.change
; Temp\script.change
global logurl = % script.logurl script.change
; https://raw.githubusercontent.com/DreadfullyDespized/ahkgtav/master/Changelog-GEO.txt
global chrglog = % A_ScriptDir "\Charge_log.txt"

RunWait %ComSpec% /c "Ping -n 1 -w 3000 google.com",, Hide  ; Check if we are connected to the internet
if connected := !ErrorLevel {
    UrlDownloadToFile, %logurl%, %updatefile%
    if (ErrorLevel = 1) {
        MsgBox, 16, Unable to communicate with github...well fuck...
        Return
    }
    FileRead, BIGFILE, %updatefile%
    StringGetPos, last25Location, BIGFILE,`n, L12
    StringTrimLeft, smallfile, BIGFILE, %last25Location%
}
ochecky := script.version "." script.moddate

; ============================================ SCRIPT AUTO UPDATER ============================================
update(ochecky) {
    RunWait %ComSpec% /c "Ping -n 1 -w 3000 google.com",, Hide  ; Check if we are connected to the internet
    if connected := !ErrorLevel {
        UrlDownloadToFile, %logurl%, %updatefile%
        if (ErrorLevel = 1) {
            MsgBox, 16, Unable to communicate with github...well fuck...
            Return
        }
        FileReadLine, line, %updatefile%, 13
        RegexMatch(line, "\d.\d{8}", Version)
        ; MsgBox, 64, % "REGEXMATCH CHECK"
        ;         ,   % "FileReadLine: " line "`n"
        ;             . "RegexMatch.Version: " Version
        rfile := script.logurl script.name ".ahk"
        if (Version > ochecky) {
            Msgbox, 68, % "New Update Available"
                      , % "There is a new update available for this application.`n"
                        . "Do you wish to upgrade to V" Version "?`n"
                        . "Local Version: " ochecky
                      , 10 ; 10s timeout
            IfMsgbox, Timeout
                return debug ? "* Update message timed out" : 1
            IfMsgbox, No
                return debug ? "* Update aborted by user" : 2
            deposit := A_ScriptDir "\AHKGEO.ahk"
            Msgbox, 64, % "Download Complete"
                      , % "New version is now running and the old version will now close'n"
                        . "Enjoy the latest version!"
            Run, %deposit%
            ExitApp
        }
        if (Version = ochecky) {
            MsgBox, 64, % "Up to Date"
                    , % "Online Version: " Version "`n"
                    . "Local Version: " ochecky
        }
        if (Version < ochecky) {
            MsgBox, 64, % "DEV Version!"
                    , % "Online Version: " Version "`n"
                    . "Local Version: " ochecky
        }
    } else {
        MsgBox, 16, % "No internets"
    }
}

; FiveM Chat formatting
; ^1 = Red Orange
; ^2 = Light Green
; ^3 = Light Yellow
; ^4 = Dark Blue
; ^5 = Light Blue
; ^6 = Violet
; ^7 = White
; ^8 = Blood Red
; ^9 = Fuchsia
; ^* = Bold
; ^_ = Underline
; ^~ = Strikethrough
; ^= = Underline + Strikethrough
; ^*^ = Bold + Underline + Strikethrough
; ^r = Cancel Formatting

; Hotkey handlers
; ! = Alt
; ^ = Control
; # = Windows
; + = Shift
; < = Left operator
; > = Right operator
; * = Wildcard
; ~ = Allows native function to still be sent along with hotkey
; UP = If put into the hotkey will only fire off on the up stroke of the key

; The example below is a vertical stack
; ^Numpad0::
; ^Numpad1::
; MsgBox Pressing either Control+Numpad0 or Control+Numpad1 will display this message.
; return

; Combination hotkey example
; Numpad0 & Numpad1::MsgBox You pressed Numpad1 while holding down Numpad0.
; Numpad0 & Numpad2::Run Notepad

; Alternate way to handle Alt Tab
; RControl & RShift::AltTab  ; Hold down right-control then press right-shift repeatedly to move forward.
; RControl & Enter::ShiftAltTab  ; Without even having to release right-control, press Enter to reverse direction.

; Unfortunately.  The emojis don't actually save from the ahk to the data entry.
; Though if you enter them in the data entry.  They save within the ini.
; Configure these variables as you wish to be presented
textspace = y+3
towtype = f
config := script.conf
; ============================================ INI READING ============================================
; Section to read in the configuration file if it exists
IfExist, %config%
{
    ; Cleanup some of the old ini configuration portions
    ; IniDelete, %config%, Yourself, rolepick
    ; IniDelete, %config%, Server, rs
    ; IniDelete, %config%, Police, towmsg1
    ; IniDelete, %config%, Towing, towmsg1
    ; IniDelete, %config%, Keys, lighthk
    ; IniDelete, %config%, Normal,
}

GoSub, ReadConfig
eboxmsg = Danger %name% of the %department%

; ============================================ HELP TEXT FORMAT ============================================
; Main portion of the help text that is displayed
subhelptext = 
(
Police Hotkeys:
Control+1 = Config
Control+3 = Reload Script
Control+/ = Vehicle Image Search
arrestreport - Submits arrest report
citationreport - Submits citation report
searchreport - Submits search warrant report
warrantreport - Submits warrant report
Control+- = runplate
Control+. = spikestrip
tmedical - medical rp message
tmic = mic help
tgeohelp = Geodexon help
)

helptext = 
(
This script is used to well. Help you with some of the repetitive tasks within GTAV RP on Geodexon.
With the following commands available to you.  Added the ability to change syntax as well.
While running this script the following "side effects...features?"
1. NumLock Key will always be on.
2. ScrollLock Key will always be off
3. WINDOWSKEY + DEL it will empty your recycling bin.
4. WINDOWSKEY + ScrollLock it will pause the hotkeys.
5. WINDOWSKEY + Insert will reload the script.

ms Delay: Take your ping to the server and double it.  To fill this in with.

Police Commands:
--------------------
tdutystart - go on duty
arrestreport - Submits arrest report
citationreport - Submits citation report
searchreport - Submits search warrant report
warrantreport - Submits warrant report
tmedical - medical rp message
ttrunk - get itmes from trunk (medbag|slimjim|tintmeter|cones|gsr|breathalizer|bodybag|spikes)

Control+1 - Configuration screen
Control+3 - Reload Script
Control+4 - Update Checker
Control+5 - Police Overlay
Control+6 - Close Police Overlay
Control+. - SpikeStrip Toggle
Control+/ - vehicle image search (uses google images in browser)
Control+- - preps command for plate running

Tow Commands:
-----------------------
tstart - start tow shift/company
ttow - towing system
tsecure - secures tow straps
trelease - releases tow straps
tkitty - grabs kitty litter from truck

Help Commands:
--------------------
tmic = help text about fixing mic in local ooc
tgeohelp = display Geodexon help information in local ooc
)

helptext2 = 
(
If you wish to change any of the hotkeys.
This is the section to do so. Click on the box and then
hit the keys together to configure the hotkey.
)

reporttext = 
(
This section is used to handle report writting.  This can be witness statements, arrest reports or anything else that you run into that could be information for the department to be used.  Including shift notes. You must fill out all fields before you can actually file the report.  The report is appended to your LEO Log.
)

; ============================================ CUSTOM SYSTEM TRAY ============================================
; Removes all of the standard options from the system tray
Menu, Tray, NoStandard
Menu, Tray, Add, &Update Checker, ^4
Menu, Tray, Add, GTAV &Car Search, vehimghk
Menu, Tray, Add, &Reconfigure/Help, ^1
Menu, Tray, Add, &Police Overlay, ^5
Menu, Tray, Add, &Reload Script, ^3
Menu, Tray, Add, E&xit,Exit

Gui, 6:Destroy
Gui, 6:-Caption +LastFound +ToolWindow
Gui, 6:Font, s10 cRed, Consolas
Gui, 6:Color, Black, Red
Gui, 6:Add, Text,, % "Name: " script.name
Gui, 6:Add, Text, %textspace% , % "FileName: " script.name ".ahk"
Gui, 6:Add, Text, %textspace% , % "Version: " ochecky
Gui, 6:Add, Text, %textspace% , % "Author: " script.author
Gui, 6:Add, Text, %textspace% , HomePage:
Gui, 6:Font, s10 Underline cTeal, Consolas
Gui, 6:Add, Text, x85 y79 gHomePage, HomePage
HomePage_TT := "Original home page hosted somewhere over the rainbow."
Gui, 6:Font
Gui, 6:Font, s10 cRed, Consolas
Gui, 6:Add, Text, x12 y96, % "Create Date: " script.crtdate
Gui, 6:Add, Text, %textspace% , % "Modified Date: " script.moddate
Gui, 6:Add, Text, %textspace% , Config File:
Gui, 6:Font, s10 Underline cTeal, Consolas
Gui, 6:Add, Text, x104 y130 geditconfig, ConfigFile
ConfigFile_TT := "Location of your configuration file"
Gui, 6:Font
Gui, 6:Font, s10 cRed, Consolas
Gui, 6:Add, Text, x12 y150 , Change Log: 
Gui, 6:Font, s10 Underline cTeal, Consolas
Gui, 6:Add, Text, x96 y150 gchangelog, ChangeLog
ChangeLog_TT := "Launches the locally downloaded changelog"
Gui, 6:Font
Gui, 6:Font, s10 cRed, Consolas
Gui, 6:Add, Button, x180 y198 h25 w80 gconfigure, Configure
configure_TT := "Configures the main portion of the application"
Gui, 6:Add, Button, x260 y198 h25 w70 gupdatecheck, Update
update_TT := "Checks for any updates on github compared to your version"
Gui, 6:Add, Button, x330 y198 h25 w40 gbug, BUG
bug_TT := "Brings you to github Issues BUG template"
Gui, 6:Add, Button, x370 y198 h25 w75 gfeedback, Feedback
feedback_TT := "Brings you to github Issues Feedback/Feature template"
Gui, 6:Add, Edit, -Wrap Readonly x200 y8 r11 w550 vupdatetext, % smallfile
updatetext_TT := ""
Gui, 6:Show,, Information
OnMessage(0x200, "WM_MOUSEMOVE")
Return

6GuiEscape:
Gui, 6:Cancel
Return

^5::
Gui, 7:Destroy
Gui, 7:+HwndID +E0x20 -Caption +LastFound +ToolWindow +AlwaysOnTop
Gui, 7:Font, s16 cRed w500, Consolas
Gui, 7:Color, Black
Gui, 7:Add, Text, x0 y0, %subhelptext%
Gui, 7:Show, X90 Y300, Overlay
WinSet, TransColor, Black 255, ahk_id%ID%
Gui, 7:-Caption
Return

^6::
Gui, 7:Cancel
Return

HomePage:
Run, % script.homepage
Return

EditConfig:
Run, % A_ScriptDir "\" script.conf
Return

Changelog:
Run, % A_Temp "\" script.change
Return

configure:
Gui, 6:Cancel
Send, ^1
Return

updatecheck:
Gui, 6:Cancel
Send, ^4
Return

bug:
Run, % script.bug
Return

feedback:
Run, % script.feedback
Return

#z::Menu, Tray, Show

Exit:
ExitApp
Return

^3::
    Reload
Return

^4::
    update(ochecky)
Return

vehimghk:
Gui, Search:Add, Edit, vgtavsearch w100
Gui, Search:Add, Button, Default gSearch, Search
Gui, Search:Show,, Gtav car model
Return

SearchGuiEscape:
SearchGuiClose:
Gui, Search:Cancel
Return

Search:
Gui, Search:Submit
gtavsearch = gta v %gtavsearch%
Run, http://www.google.com/search?tbm=isch&q=%gtavsearch%
Gui, Search:Destroy
Return

Gosub, UpdateConfig
Return

; ============================================ START HOTKEY CONFIRUATION ============================================
; SetKeyDelay , Delay, PressDuration, Play
SetKeyDelay, 0, 100
; Default state of lock keys
SetNumLockState, AlwaysOn
SetScrollLockState, AlwaysOff
; SetCapsLockState, AlwaysOff

; Convert CapsLock as a Shift
; Capslock::Shift
; Return

; RControl & RShift::AltTab  ; Hold down right-control then press right-shift repeatedly to move forward.
; Minor issue with this.  It is holding the normal 0 from being sent.  Will need to look into that.
; Numpad0 & Numpad3::AltTab ; Hold down Numpad0 and press Numpad3 to move forward in the AltTab.  Select the window with left click afterwards.

^1::
    Gui, 1:Destroy
    Gui, 1:Font,, Consolas
    Gui, 1:Color, Silver
    Gui, 1:Add, Tab3,, Help|Configure ME!
    Gui, 1:Add, Edit, Readonly r36 w600 vhelptext, %helptext%
    Gui, 1:Tab, 2
    Gui, 1:Add, Text,, Role:
    Gui, 1:Add, Text,, CallSign:
    Gui, 1:Add, Text,, MyID:
    Gui, 1:Add, Text,, TowCompany:
    Gui, 1:Add, Text,, Name:
    Gui, 1:Add, Text,, Title:
    Gui, 1:Add, Text,, Department:
    Gui, 1:Add, Text,, ms Delay:
    Gui, 1:Add, Text,, First Party Action:
    Gui, 1:Add, Text, x210 y34, Phone Number:
    Gui, 1:Add, DropDownList, x90 y30 w110 vrolepick, |LEO|TOW|CIV|SAFR
    rolepick_TT := "Select the character role that you will be playing as"
    Gui, 1:Add, Edit, w110 vcallsign, %callsign%
    callsign_TT := "Callsign for your LEO/EMS character"
    Gui, 1:Add, Edit, w110 vmyid, %myid%
    myid_TT := "Your Train Ticket ID"
    Gui, 1:Add, Edit, w110 vtowcompany, %towcompany%
    towcompany_TT := "Towing company you work for. Name for /clockin command"
    Gui, 1:Add, Edit, w110 vname, %name%
    name_TT := "Name format Fist Initial.Last Name - D.Mallard for instance"
    Gui, 1:Add, Edit, w110 vtitle, %title%
    title_TT := "Title or Rank of your character"
    Gui, 1:Add, Edit, w110 vdepartment, %department%
    department_TT := "Department that your character works for"
    Gui, 1:Add, Edit, w110 vdelay, %delay%
    delay_TT := "milisecond delay.  Take your ping to the server x2"
    Gui, 1:Add, Edit, x140 y245 w60 vms, %ms%
    Gui, 1:Add, Edit, x290 y30 w110 vphone, %phone%
    phone_TT := "Your Phone number, (###) ###-####"
    Gui, 1:Add, Checkbox, x100 y470 vtestmode, Enable TestMode? Default, works in-game and notepad.
    Gui, 1:Add, Button, x280 y490 h25 w80 gSave1, Save
    Gui, 1:Add, Button, x511 y490 h25 w40 gbug, BUG
    Gui, 1:Add, Button, x550 y490 h25 w65 gfeedback, Feedback
    Gui, 1:Show,, Making the world a better place
    OnMessage(0x200, "WM_MOUSEMOVE")
    Gosub, ReadConfiguration ; Load configuration previously saved.
    Return

    1GuiEscape: ; Hitting escape key while open
    1GuiClose: ; Hitting the X while open
    Gui, 1:Cancel
    Return

    Save1:
    Gui, 1:Submit
    ; Police related section
    medicalmsg = Hello I am ^1%title% %name% %department%^0, Please use this time to perform the medical activities required for the wounds you have received.  Using ^1/do's ^0and ^1/me's ^0to simulate your actions and the Medical staff actions. -Once completed. Use ^1/do Medical staff waves the %title% in^0.
    GoSub, UpdateConfig

    ; ============================================ CUSTOM MSGS GUI ============================================
    ; Gui for all of the customized messages to display in-game
    Gui, 2:Destroy
    Gui, 2:Font,, Consolas
    Gui, 2:Color, Silver
    if (rolepick = "LEO") {
        Gui, 2:Add, tab3,, LEO|Help|General
    } else if (rolepick = "TOW") {
        Gui, 2:Add, tab3,, TOW|Help|General
        Gui, 2:Tab, 12
    } else if (rolepick = "SAFR") {
        Gui, 2:Add, tab3,, SAFR|Help|General
        Gui, 2:Tab, 12
    } else if (rolepick = "CIV") {
        Gui, 2:Add, tab3,, CIV|Help|General
        Gui, 2:Tab, 12
    } else {
        Gui, 2:Add, Tab3,, LEO|TOW|CIV|SAFR|Help|General
    }
    Gui, 2:Add, Text,, %helptext2%
    Gui, 2:Add, Text,x20 y78, tmedicalmsg:
    Gui, 2:Add, Text,x20 y370, Spikes:
    Gui, 2:Add, Text,, Vehicle Image Search:
    Gui, 2:Add, Text,, RunPlate:
    Gui, 2:Add, Edit,x98 y78 r4 vmedicalmsg w500, %medicalmsg%
    medicalmsg_TT := "OOC message that you would tell someone to perform their own medical process"
    Gui, 2:Add, Hotkey, w150 x150 y365 vspikeshk, %spikeshk%
    spikeshk_TT := "Hotkey to be used to deploy/remove spike strip"
    Gui, 2:Add, Hotkey, w150 vvehimgsearchhk, %vehimgsearchhk%
    vehimgsearchhk_TT := "Hotkey to search for a vehicle's image on google"
    Gui, 2:Add, Hotkey, w150 vrunplatehk, %runplatehk%
    runplatehk_TT := "Hotkey to run a plate"
    ; This section will pick the TOW
    if (rolepick = "LEO") {
        Gui, 2:Tab, 12
    } else if (rolepick = "TOW") {
        Gui, 2:Tab, 1
    } else if (rolepick = "SAFR") {
        Gui, 2:Tab, 13
    } else if (rolepick = "CIV") {
        Gui, 2:Tab, 13
    } else {
        Gui, 2:Tab, 2
    }
    Gui, 2:Add, Text,r2, ttowmsg1:
    Gui, 2:Add, Text,r2, ttowmsg2:
    Gui, 2:Add, Text,r2, tsecure1:
    Gui, 2:Add, Text,r2, tsecure2:
    Gui, 2:Add, Text,r2, treleasemsg1:
    Gui, 2:Add, Text,r2, treleasemsg2:
    Gui, 2:Add, Edit, r2 vttowmsg1 w500 x100 y30, %ttowmsg1%
    ttowmsg1_TT := "Hooking up vehicle from the front"
    Gui, 2:Add, Edit, r2 vttowmsg2 w500, %ttowmsg2%
    ttowmsg2_TT := "Hooking up vehicle from the rear"
    Gui, 2:Add, Edit, r2 vtsecure1 w500, %tsecure1%
    tsecure1_TT := "Securing the tow straps to the rear"
    Gui, 2:Add, Edit, r2 vtsecure2 w500, %tsecure2%
    tsecure2_TT := "Securing the tow straps to the front"
    Gui, 2:Add, Edit, r2 vtreleasemsg1 w500, %treleasemsg1%
    treleasemsg1_TT := "Releasing the cables and the winch from the rear"
    Gui, 2:Add, Edit, r2 vtreleasemsg2 w500, %treleasemsg2%
    treleasemsg2_TT := "Releasing the cables and the winch from the front"
    ; This section will pick the SAFR
    if (rolepick = "LEO") {
        Gui, 2:Tab, 13
    } else if (rolepick = "TOW") {
        Gui, 2:Tab, 13
    } else if (rolepick = "SAFR") {
        Gui, 2:Tab, 1
    } else if (rolepick = "CIV") {
        Gui, 2:Tab, 14
    } else {
        Gui, 2:Tab, 3
    }
    Gui, 2:Add, Text,r1, SAFR Placeholder - ideas certainly welcome :P
    ; This section will pick the CIV
    if (rolepick = "LEO") {
        Gui, 2:Tab, 14
    } else if (rolepick = "TOW") {
        Gui, 2:Tab, 14
    } else if (rolepick = "SAFR") {
        Gui, 2:Tab, 14
    } else if (rolepick = "CIV") {
        Gui, 2:Tab, 1
    } else {
        Gui, 2:Tab, 4
    }
    Gui, 2:Tab, Help,, Exact
    Gui, 2:Add, Text,x20 y30, tmicmsg:
    Gui, 2:Add, Text,x20 y150, Garbage Items:
    Gui, 2:Add, Edit, r3 w500 x110 y30 vmicmsg, %micmsg%
    micmsg_TT := "Message used to explain how to use/configure microphone"
    Gui, 2:Add, Edit, r5 w500 x110 y150 vItemsar, %Itemsar%
    Itemsar_TT := "Add items into this list, separated by commas to add to the glovebox and trunk search."
    Gui, 2:Tab, General,, Exact
    Gui, 2:Tab
    Gui, 2:Add, Button, default x10 y480 w80, OK  ; The label ButtonOK (if it exists) will be run when the button is pressed.
    Gui, 2:Add, Button, x520 y480 h25 w40 gbug, BUG
    Gui, 2:Add, Button, x560 y480 h25 w65 gfeedback, Feedback
    Gui, 2:Show,, Main responses for the system - builds from original variables
    OnMessage(0x200, "WM_MOUSEMOVE")
    Return

    2GuiClose:
    2GuiEscape:
    Msgbox Nope lol
    Gui, 2:Cancel
    Return

    2ButtonOK:
    Gui, 2:Submit  ; Save the input from the user to each control's associated variable.
    Gosub, UpdateConfig
    Gosub, hotkeys
Return

; Empty Recycle Bin
#Del::FileRecycleEmpty ; Windows + Del
Return

; Suspend Hotkey
#ScrollLock::Suspend ; Windows + ScrollLock
Return

; Reload Hotkey
#Insert::Reload ; Windows + Insert
Return

#\::ListVars
Return

; ====================== GTAV Stuff =========================

; not used on NDG - F4 F9 F10 F11

; ============================================ LEO Stuff ============================================
#if (rolepick = "LEO")

    ; This will lay the spikes or remove the spikes based on variable.
    ; ^.:: ; Control + . in-game
    sphk:
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /spikes
        Send, {RCtrl down}v{RCtrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; Runplate to be ran and save the plate you ran, also caches the name into clipboard
    ; ^-:: ; Control + -
    rphk:
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard := "/runplate "
        Send, {Rctrl down}v{Rctrl up}
    }
    Return

    ; This will be used to set your callsign for the environment.
    :*:tdutystart:: ; Type tdutystart in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        if (!callsign) {
            InputBox, callsign, CallSign, Enter your callsign to use.
        }
        if (!name) {
            Inputbox, name, Name, Enter your name to use.
        }
        clipaboard = %clipboard%
        Sleep, %delay%
        ; Turns on the vehicle engine
        Clipboard = /engine
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        ; Puts on your seatbelt
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /belt
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        ; Put on body armor
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /use armor
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        ; Toggle 911 phone calling
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /911t
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        ; Set Radio Channel to 1 (emergency)
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /rc 1
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        ; Set Radio Volume to 0.8
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /rvol 0.8
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; Tells subject on how to do the medical RP for themselves.
    :*:tmedical:: ; Type tmedical in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %medicalmsg%
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; Test running through timing.
    :*:ttest:: ; Type ttest in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = /e notepad
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %ms% notes a few things to himself that he thinks are important.
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; Items that can be pulled out from the trunk of a vehicle.
    :*:ttrunk:: ; Type ttrunk in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        InputBox, titem, Trunk Item, What do you want from your trunk?
        if ErrorLevel
            Return
        else
        if (titem = "medbag" || titem = "lockpick" || titem = "cones" || titem = "gsr" || titem = "breathalizer" || titem = "bodybag" || titem = "spikes") {
            clipaboard = %clipboard%
            Send, {enter}
            Sleep, %delay%
            Send, {l down}
            Sleep, %delay%
            Send, {l up}
            Sleep, %delay%
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            Clipboard = /trunk
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            if (titem = "cones") {
                Clipboard = %ms% Grabs a few %titem% from the trunk
            } else if (titem = "gsr") {
                Clipboard = %ms% Grabs a %titem% kit from the trunk
            } else if (titem = "spikes") {
                Clipboard = %ms% Grabs a spikestrip from the trunk
            } else {
                Clipboard = %ms% Grabs a %titem% from the trunk
            }
            Send, {Rctrl down}v{Rctrl up}{enter}
            If (titem = "medbag") {
                Sleep, %delay%
                Send, {t down}
                Sleep, %delay%
                Send, {t up}
                Sleep, %delay%
                Clipboard = /inventory
                Send, {Rctrl down}v{Rctrl up}{enter}
                Msgbox, Once completed with your inventory actions. Close inventory and then press T.
                KeyWait, t, D
            }
            Sleep, %delay%
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            Clipboard = /trunk
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Send, {l down}
            Sleep, %delay%
            Send, {l up}
            Sleep, %delay%
            Clipboard = %clipaboard%
        } else {
            Send, {enter}
            MsgBox, That %titem% is not in your trunk. Try again.
        }
    }
    Return

    ; Submits the template to author an arrest.
    :*:arrestreport::
        Time := A_NowUTC
        Time += -5, H
        FormatTime, newTime, % Time, HH:mm:ss
        FormatTime, Date,, MM/dd/yyyy
        clipaboard = %clipboard%
        Sleep, %delay%
        clipboard = 
(

TimeLine: %Date% - %newTime% EST

Officers Involved:
%callsign% | %name%

Location(s): 

Any Nickname(s): 

Is he or she known to be a part of a gang: 

Incident Report:
------------------------------------------------------------------------

------------------------------------------------------------------------

Seized Item(s): 

Evidence: 

Plead Guilty/NotGuilty:

Nothing else follows ---------- %title% %name% of the %department% ----------
)
        Send, {Rctrl down}v{Rctrl up}
        Sleep, %delay%
        clipboard = %clipaboard%
    Return

    ; Submits the template to author a citation.
    :*:citationreport::
        Time := A_NowUTC
        Time += -5, H
        FormatTime, newTime, % Time, HH:mm:ss
        FormatTime, Date,, MM/dd/yyyy
        clipaboard = %clipboard%
        Sleep, %delay%
        clipboard = 
(
TimeLine: %Date% - %newTime% EST

Location(s): 

Vehicle Plate: 
Vehicle VIN: 
Vehicle Description: 

Briefly describe the offense:
------------------------------------------------------------------------

------------------------------------------------------------------------

Nothing else follows ---------- %title% %name% of the %department% ----------
)
        Send, {Rctrl down}v{Rctrl up}
        Sleep, %delay%
        clipboard = %clipaboard%
    Return

    ; Submits the template to author a search warrant.
    :*:searchreport::
        Time := A_NowUTC
        Time += -5, H
        FormatTime, newTime, % Time, HH:mm:ss
        FormatTime, Date,, MM/dd/yyyy
        clipaboard = %clipboard%
        Sleep, %delay%
        clipboard = 
(
REQUEST DATE: %Date% - %newTime% EST

REQUESTED BY:
%callsign% | %name%

TO BE ENFORCED UPON: 

PROPERTIES TO SEARCH: 

SEARCH REQUEST: 

SUMMARY OF JUSTIFICATION:
------------------------------------------------------------------------

------------------------------------------------------------------------

SUPPORTING DOCUMENTS/EVIDENCE:


Nothing else follows ---------- %title% %name% of the %department% ----------
)
        Send, {Rctrl down}v{Rctrl up}
        Sleep, %delay%
        clipboard = %clipaboard%
    Return

    ; Submits the template to author a warrant.
    :*:warrantreport::
        Time := A_NowUTC
        Time += -5, H
        FormatTime, newTime, % Time, HH:mm:ss
        FormatTime, Date,, MM/dd/yyyy
        InputBox, subject, Warrant Subject, Who do you want to put on the warrant?
        StringUpper, subject, subject
        clipaboard = %clipboard%
        Sleep, %delay%
        clipboard = 
(
THE STATE OF SAN ANDREAS VS %subject% - To Any PEACE OFFICER In the State of San Andreas Greetings: YOU ARE HEREBY COMMANDED to arrest %subject% if found in the State of San Andreas, and bring him before a Justice of the Peace for Precinct No. 1 of Los Santos County, San Andreas to answer to the STATE OF SAN ANDREAS for the charges and incident below.

TimeLine: %Date% - %newTime% EST
Officers Involved(Names):
%callsign% | %name%

Incident Report:
------------------------------------------------------------------------

------------------------------------------------------------------------

Probable Cause(must include evidence either photographic, documentation): 

Evidence of Positive Identification (Photograph of Fingerprint Scanner/ID etc.): 

Nothing else follows ---------- %title% %name% of the %department% ----------
)
        Send, {Rctrl down}v{Rctrl up}
        Sleep, %delay%
        clipboard = %clipaboard%
    Return

    ; ============================================ CIV Stuff ============================================
#If (rolepick = "CIV")
    ; ============================================ TOW Stuff ============================================
#If (rolepick = "TOW")
    :*:tstart:: ; Type tstart in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = /rc 105
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /clockin %towcompany%
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; To start the tow of a front or rear facing vehicle.
    :*:ttow:: ; Type ttow in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        InputBox, towtype, Facing Direction, Type f for front b for back.
        if (towtype = "f" || towtype = "b") {
            clipaboard = %clipboard%
            Sleep, %delay%
            Clipboard = /emote kneel
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            if (towtype = "f") {
                Clipboard = %ttowmsg1%
            } else if (towtype = "b") {
                Clipboard = %ttowmsg2%
            }
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Clipboard = /tow
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Clipboard = %clipaboard%
        } else {
            MsgBox, f or b only. Try again.
        }
    }
    Return

    ; To secure the vehicle to the tow truck.
    :*:tsecure:: ; Type tsecure in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = /emote kneel
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        if (towtype = "f") {
            Clipboard = %tsecure1%
        } else {
            Clipboard = %tsecure2%
        }
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; To release the vehicle from the tow truck.
    :*:trelease:: ; Type trelease in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        if (towtype = "f") {
            Clipboard = %treleasemsg1%
        } else {
            Clipboard = %treleasemsg2%
        }
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /tow
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; To pull out Kitty Litter from tow truck for use.
    :*:tkitty:: ; Type tkitty in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %ms% opens the toolbox and removes kitty litter from it
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return
    ; ============================================ SAFR Stuff ============================================
#If (rolepick = "SAFR")
    ; ============================================ HELP Stuff ============================================
#IF
; This provides the help text for micropohone fixing in local ooc chat
:*:tmic:: ; Type tmic in-game
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Clipboard = %micmsg%
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    Clipboard = %clipaboard%
}
Return

; This provides the help text for Geodexon information in local ooc chat
:*:tgeohelp:: ; Type tgeohelp in-game
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Clipboard := "GeoDexon Forums at ^1 https://geodexon.net/index.php ^0 to join the Dicksword go to ^2 https://discord.gg/QFQmpejhPT"
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    Clipboard = %clipaboard%
}
Return

; ============================================ MAIN RUN FUNCTIONS ============================================

ReadConfiguration: ; Read the saved configuration
IfExist, %config% ; First check if it was saved.
{
; IniRead, outputvar, filename, section, key, default
IniRead, rolepick, %config%, Yourself, role
GuiControl, ChooseString, rolepick, %rolepick% ; Submit
}
Return

; ============================================ TOOLTIP FUNCTION ============================================

WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 500
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip % %CurrControl%_TT  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 3000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

; ============================================ CUSTOM DEFINED HOTKEYS ============================================
; Initializes the hotkeys for generation.

hotkeys:
    hotkey, %spikeshk%, sphk, On
    hotkey, %vehimgsearchhk%, vehimghk, On
    hotkey, %runplatehk%, rphk, On
Return

ReadConfig:
    ; Back to the reading of the configuration
    IniRead, rolepick, %config%, Yourself, role, LEO
    IniRead, callsign, %config%, Yourself, callsign, 100
    IniRead, myid, %config%, Yourself, myid, 7
    IniRead, towcompany, %config%, Yourself, towcompany, PotatoWax
    IniRead, name, %config%, Yourself, name, Mallard
    IniRead, title, %config%, Yourself, title, CMDR
    IniRead, department, %config%, Yourself, department, LSPD
    IniRead, phone, %config%, Yourself, phone, (304) 631-0826
    ; Client communication and test mode
    IniRead, delay, %config%, Yourself, delay, 70
    IniRead, testmode, %config%, Yourself, testmode, 0
    ; Server related section
    IniRead, ms, %config%, Server, ms, /me
    ; The hotkey related section
    IniRead, spikeshk, %config%, Keys, spikeshk, ^.
    IniRead, vehimgsearchhk, %config%, Keys, vehimgsearchhk, ^/
    IniRead, runplatehk, %config%, Keys, runplatehk, ^-
    ; Messages that correspond with the hotkeys
    ; Police related section
    IniRead, Itemsar, %config%, Police, Itemsar, Twinkie Wrappers,Hotdog buns,Potato chip bags,Used Diappers,Tools,Keyboards
    IniRead, medicalmsg, %config%, Police, medicalmsg, Hello I am ^1%title% %name% %department%^0, Please use this time to perform the medical activities required for the wounds you have received.  Using ^1/me's ^0to simulate your actions and the Medical staff actions. -Once completed. Use ^1%ms% Medical staff waves the %title% in^0.
    ; Towing related section
    IniRead, ttowmsg1, %config%, Towing, ttowmsg1, %ms% attaches the winch cable to the front of the vehicle
    IniRead, ttowmsg2, %config%, Towing, ttowmsg2, %ms% attaches the winch cable to the rear of the vehicle
    IniRead, tsecure1, %config%, Towing, tsecure1, %ms% secures the rear of the vehicle with extra tow straps
    IniRead, tsecure2, %config%, Towing, tsecure2, %ms% secures the front of the vehicle with extra tow straps
    IniRead, treleasemsg1, %config%, Towing, treleasemsg1, %ms% releases the extra tow cables from the rear and pulls the winch release lever
    IniRead, treleasemsg2, %config%, Towing, treleasemsg2, %ms% releases the extra tow cables from the front and pulls the winch release lever
    ; Help related section
    IniRead, micmsg, %config%, Help, micmsg, How to fix your microphone - ^2ESC^0 -> ^2Settings^0 -> ^2Voice Chat^0 -> ^2Toggle On/Off^0 -> ^2Increase Mic Volume and Mic Sensitivity^0 -> Match audio devices to the one you are using.
Return

UpdateConfig:
; ============================================ WRITE INI SECTION ============================================
    IniWrite, %rolepick%, %config%, Yourself, role
    IniWrite, %callsign%, %config%, Yourself, callsign
    IniWrite, %myid%, %config%, Yourself, myid
    IniWrite, %towcompany%, %config%, Yourself, towcompany
    IniWrite, %name%, %config%, Yourself, name
    IniWrite, %title%, %config%, Yourself, title
    IniWrite, %department%, %config%, Yourself, department
    IniWrite, %phone%, %config%, Yourself, phone
    ; Client communication and test mode
    IniWrite, %delay%, %config%, Yourself, delay
    IniWrite, %testmode%, %config%, Yourself, testmode
    ; Server related section
    IniWrite, %ms%, %config%, Server, ms
    ; The hotkey related section
    IniWrite, %spikeshk%, %config%, Keys, spikeshk
    IniWrite, %vehimgsearchhk%, %config%, Keys, vehimgsearchhk
    IniWrite, %runplatehk%, %config%, Keys, runplatehk
    ; Messages that correspond with the hotkeys
    ; Police related 
    IniWrite, %Itemsar%, %config%, Police, Itemsar
    IniWrite, %medicalmsg%, %config%, Police, medicalmsg
    ; Towing related section
    IniWrite, %ttowmsg1%, %config%, Towing, ttowmsg1
    IniWrite, %ttowmsg2%, %config%, Towing, ttowmsg2
    IniWrite, %tsecure1%, %config%, Towing, tsecure1
    IniWrite, %tsecure2%, %config%, Towing, tsecure2
    IniWrite, %treleasemsg1%, %config%, Towing, treleasemsg1
    IniWrite, %treleasemsg2%, %config%, Towing, treleasemsg2
    ; Help related section
    IniWrite, %micmsg%, %config%, Help, micmsg
; ============================================ READ INI SECTION ============================================
    Gosub, ReadConfig
Return