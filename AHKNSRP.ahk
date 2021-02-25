IF NOT A_IsAdmin
{
   Run *RunAs "%A_ScriptFullPath%"
   ExitApp
}

if (a_ahkversion < 1.1){
    Msgbox, 0x10
        , % "Error"
        , % "The AutoHotkey installed in your computer is not compatible with`n"
        . "this version of AHKGTAV Doohicky.`n`n"
        . "Please use the compiled version of my script or upgrade your AutoHotkey.`n"
        . "The application will exit now."
    Exitapp
}

#NoEnv
#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

Menu, Tray, Icon, shell32.dll, 194

global script := {  based               : scriptobj
                    ,name               : "AHKNSRP"
                    ,version            : "1"
                    ,author             : "DreadfullyDespized"
                    ,Homepage           : "NA"
                    ,crtdate            : "20210224"
                    ,moddate            : "20210224"
                    ,conf               : "NSRP-Config.ini"
                    ,logurl             : "https://raw.githubusercontent.com/DreadfullyDespized/ahkgtav/master/" 
                    ,change             : "Changelog-NSRP.txt"
                    ,bug                : "https://github.com/DreadfullyDespized/ahkgtav/issues/new?assignees=DreadfullyDespized&labels=bug&template=bug_report.md&title="
                    ,feedback           : "https://github.com/DreadfullyDespized/ahkgtav/issues/new?assignees=DreadfullyDespized&labels=enhancement&template=feature_request.md&title="}

global updatefile = % A_Temp "\" script.change
global logurl = % script.logurl script.change
global chrglog = % A_ScriptDir "\Charge_log.txt"
UrlDownloadToFile, %logurl%, %updatefile%
if (ErrorLevel = 1) {
    msgbox, Unable to communicate with github...well fuck...
    Return
}
FileRead, BIGFILE, %updatefile%
StringGetPos, last25Location, BIGFILE,`n, L12
StringTrimLeft, smallfile, BIGFILE, %last25Location%

; This will become the new version checker usage at some point.
; This will be used once it is fully flushed out.

FileReadLine, checkdate, %A_ScriptFullPath%, 29
FileReadLine, checkv, %A_ScriptFullPath%, 25
RegexMatch(checkv,"\d",cver)
RegexMatch(checkdate,"\d+",cdate)
checky := cver "." cdate
ochecky := script.version "." script.moddate
; if (checky >= ochecky) {
;     msgbox,, Version Checker, % "Current Version: " cver "   Old Version: " script.version "`n"
;         . "Current Date: " cdate "   Old Date: " script.moddate "`n"
;         . "Main Version: " checky "   Old Main Version: " ochecky
; }

; ============================================ SCRIPT AUTO UPDATER ============================================
update(ochecky) {
    RunWait %ComSpec% /c "Ping -n 1 -w 3000 google.com",, Hide  ; Check if we are connected to the internet
    if connected := !ErrorLevel {
        FileReadLine, line, %updatefile%, 13
        RegexMatch(line, "\d.\d{8}", Version)
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
            deposit := A_ScriptDir "\AHKNSRP.ahk"
            if (A_ComputerName = "Z017032") {
                msgbox,,, Asset is %A_ComputerName%
            } else {
                UrlDownloadToFile, %rfile%, %deposit%
                if (ErrorLevel = 1) {
                    msgbox, Unable to communicate with github...well fuck...
                    Return
                }
            }
            Msgbox, 64, % "Download Complete"
                      , % "New version is now running and the old version will now close'n"
                        . "Enjoy the latest version!"
            Run, %deposit%
            ExitApp
        }
        if (Version = ochecky) {
            MsgBox, 64, % "Up to Date"
                    , % "Source Version: " Version "`n"
                    . "Local Version: " ochecky
        }
        if (Version < ochecky) {
            MsgBox, 64, % "DEV Version!"
                    , % "Source Version: " Version "`n"
                    . "Local Version: " ochecky
        }
    } else {
        MsgBox, 68, % "No internets"
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
config = NSRP-Config.ini

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
warrantreport - Submits warrant report
ttrunk - opens the trunk
ttv - Check trunk on approach
)

helptext = 
(
This script is used to well. Help you with some of the repetitive tasks within GTAV RP on NSRP.
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
tdutystart - go on duty (bodycam/engine start)
arrestreport - Submits arrest report
citationreport - Submits citation report
warrantreport - Submits warrant report
timpound - place impound sticker
ttrunk - get itmes from trunk
ttv - Touches the vehicle's trunk lid to leave print and make sure secure

Control+1 - Configuration screen
Control+3 - Reload Script
Control+4 - Update Checker
Control+5 - Police Overlay
Control+6 - Close Police Overlay
Control+/ - vehicle image search (uses google images in browser)

Help Commands:
--------------------
tmic = help text about fixing mic in local ooc
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
; Menu, Tray, Add, &Ticket Calc, ^2
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
HomePage_TT := "Original home page on NSRP forums"
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
    Gui, 1:Add, Text,, Name:
    Gui, 1:Add, Text,, Title:
    Gui, 1:Add, Text,, Department:
    Gui, 1:Add, Text,, ms Delay:
    Gui, 1:Add, Text,, First Party Action:
    Gui, 1:Add, Text, x210 y34, Phone Number:
    Gui, 1:Add, DropDownList, x90 y30 w110 vrolepick, LEO
    rolepick_TT := "Select the character role that you will be playing as"
    Gui, 1:Add, Edit, w110 vcallsign, %callsign%
    callsign_TT := "Callsign for your LEO/EMS character"
    Gui, 1:Add, Edit, w110 vname, %name%
    name_TT := "Name format Fist Initial.Last Name - D.Mallard for instance"
    Gui, 1:Add, Edit, w110 vtitle, %title%
    title_TT := "Title or Rank of your character"
    Gui, 1:Add, Edit, w110 vdepartment, %department%
    department_TT := "Department that your character works for"
    Gui, 1:Add, Edit, w110 vdelay, %delay%
    delay_TT := "milisecond delay.  Take your ping to the server x2"
    Gui, 1:Add, Edit, x140 y191 w60 vms, %ms%
    Gui, 1:Add, Edit, x290 y30 w110 vphone, %phone%
    phone_TT := "Your Phone number"
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
        Gui, 2:Add, tab3,, LEO
    }
    Gui, 2:Add, Text,, %helptext2%
    Gui, 2:Add, Text,x20 y82, tdutystartmsg:
    Gui, 2:Add, Text,x20 y150, Vehicle Image Search:
    Gui, 2:Add, Text,, RunPlate:
    Gui, 2:Add, Edit, r4 vdutystartmsg w500 x115 y80, %dutystartmsg%
    dutystartmsg1_TT := "Bodycam duty start message"
    Gui, 2:Add, Hotkey,x150 y146 w150 vvehimgsearchhk, %vehimgsearchhk%
    vehimgsearchhk_TT := "Hotkey to search for a vehicle's image on google"
    Gui, 2:Add, Hotkey, w150 vrunplatehk, %runplatehk%
    runplatehk_TT := "Hotkey to run a plate"
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

; not used on NSRP - F4 F9 F10 F11
; Pressing T to open chat and then typing unrack/rack

; ============================================ LEO Stuff ============================================
#if (rolepick = "LEO")

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
        Clipboard = %dutystartmsg%
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, m
        KeyWait, t, D
        Send, %A_Tab%
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; Touches the vehicle on approach
    :*:ttv:: ; Type ttv in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %ms% touches the trunk lid of the vehicle
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
        Clipboard = %ms% lhand notes a few things to himself that he thinks are important.
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; Pulls out notepad to write out and plate impound sticker on vehicle
    :*:timpound:: ; Type timpound in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %ms% tears off the written impound sticker and places it on the vehicle
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /impound
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; Items that can be pulled out from the trunk of a vehicle.
    :*:ttrunk:: ; Type ttrunk in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
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
        Send, %A_Tab%
        KeyWait, t, D
        Sleep, %delay%
        Send, {l down}
        Sleep, %delay%
        Send, {l up}
        Sleep, %delay%
        Clipboard = %clipaboard%
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
Time: %newTime% EST
Date: %Date%

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

Charge(s): 

Did the suspect Plead Guilty, Not Guilty, or No Contest?

Nothing else follows ---------------- %title% %name% of the %department% ----------------
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
Time: %newTime% EST
Date: %Date%

Location(s): %location%

Briefly describe the offense:
------------------------------------------------------------------------

------------------------------------------------------------------------

Nothing else follows ---------------- %title% %name% of the %department% ----------------
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

Time: %newTime% EST
Date: %Date%
Officers Involved(Names):
%callsign% | %name%

Incident Report:
------------------------------------------------------------------------

------------------------------------------------------------------------

Probable Cause(must include evidence either photographic, documentation or bodycam): %probablecause%

Evidence of Positive Identificatoin(Photograph of Fingerprint Scanner/ID etc.): %evidence%

Charge(s): %charges%

Nothing else follows ---------------- %title% %name% of the %department% ----------------
)
        Send, {Rctrl down}v{Rctrl up}
        Sleep, %delay%
        clipboard = %clipaboard%
    Return

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
    hotkey, %vehimgsearchhk%, vehimghk, On
    hotkey, %runplatehk%, rphk, On
Return

ReadConfig:
    ; Back to the reading of the configuration
    IniRead, rolepick, %config%, Yourself, role, LEO
    IniRead, callsign, %config%, Yourself, callsign, 360
    IniRead, name, %config%, Yourself, name, D.Mallard
    IniRead, title, %config%, Yourself, title, Trooper
    IniRead, department, %config%, Yourself, department, DPS
    IniRead, phone, %config%, Yourself, phone, (378) 232-9350
    ; Client communication and test mode
    IniRead, delay, %config%, Yourself, delay, 80
    IniRead, testmode, %config%, Yourself, testmode, 0
    ; Server related section
    IniRead, ms, %config%, Server, ms, /me
    ; The hotkey related section
    IniRead, vehimgsearchhk, %config%, Keys, vehimgsearchhk, ^/
    IniRead, runplatehk, %config%, Keys, runplatehk, ^-
    ; Messages that correspond with the hotkeys
    ; Police related section
    IniRead, dutystartmsg, %config%, Police, dutystartmsg, %ms% secures bodycam and validates functionality, then turns on the dashcam and validates functionality.
    ; Help related section
    IniRead, micmsg, %config%, Help, micmsg, How to fix your microphone - ^2ESC^0 -> ^2Settings^0 -> ^2Voice Chat^0 -> ^2Turn On/Off^0.
Return

UpdateConfig:
; ============================================ WRITE INI SECTION ============================================
    IniWrite, %rolepick%, %config%, Yourself, role
    IniWrite, %callsign%, %config%, Yourself, callsign
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
    IniWrite, %vehimgsearchhk%, %config%, Keys, vehimgsearchhk
    IniWrite, %runplatehk%, %config%, Keys, runplatehk
    ; Messages that correspond with the hotkeys
    ; Police related 
    IniWrite, %dutystartmsg%, %config%, Police, dutystartmsg
    ; Help related section
    IniWrite, %micmsg%, %config%, Help, micmsg
; ============================================ READ INI SECTION ============================================
    Gosub, ReadConfig
Return