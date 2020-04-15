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
                    ,name               : "AHKNDG"
                    ,version            : "8"
                    ,author             : "DreadfullyDespized"
                    ,Homepage           : "https://forum.newdawn.fun/t/a-little-something-that-i-use-and-work-on/1218"
                    ,crtdate            : "20190707"
                    ,moddate            : "20191104"
                    ,conf               : "NDG-Config.ini"
                    ,logurl             : "https://raw.githubusercontent.com/DreadfullyDespized/ahkgtav/master/"
                    ,change             : "Changelog-NDG.txt"
                    ,bug                : "https://github.com/DreadfullyDespized/ahkgtav/issues/new?assignees=DreadfullyDespized&labels=bug&template=bug_report.md&title="
                    ,feedback           : "https://github.com/DreadfullyDespized/ahkgtav/issues/new?assignees=DreadfullyDespized&labels=enhancement&template=feature_request.md&title="
                    ,citlaw             : "https://forum.newdawn.fun/t/ndg-traffic-laws/555"
                    ,mislaw             : "https://forum.newdawn.fun/t/ndg-misdemeanor-laws/558"
                    ,fellaw             : "https://forum.newdawn.fun/t/ndg-felony-laws/559"}

global updatefile = % A_Temp "\" script.change
global logurl = % script.logurl script.change
global chrglog = % A_ScriptDir "\Charge_log.txt"
If (A_ComputerName = "Z017032") {
    ; msgbox,,, Asset is %A_ComputerName%
} else {
    UrlDownloadToFile, %logurl%, %updatefile%
    if (ErrorLevel = 1) {
        msgbox, Unable to communicate with update site.
        Return
    }
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
update(lversion) {
    RunWait %ComSpec% /c "Ping -n 1 -w 3000 google.com",, Hide  ; Check if we are connected to the internet
    if connected := !ErrorLevel {
        FileReadLine, line, %updatefile%, 13
        RegexMatch(line, "\d", Version)
        rfile := script.logurl script.name ".ahk"
        if (Version > lversion) {
            Msgbox, 68, % "New Update Available"
                      , % "There is a new update available for this application.`n"
                        . "Do you wish to upgrade to V" Version "?"
                      , 10 ; 10s timeout
            IfMsgbox, Timeout
                return debug ? "* Update message timed out" : 1
            IfMsgbox, No
                return debug ? "* Update aborted by user" : 2
            deposit := A_ScriptDir "\AHKNDG.ahk"
            if (A_ComputerName = "Z017032") {
                msgbox,,, Asset is %A_ComputerName%
            } else {
                UrlDownloadToFile, %rfile%, %deposit%
                if (ErrorLevel = 1) {
                    msgbox, Unable to communicate with update site.
                    Return
                }
            }
            Msgbox, 64, % "Download Complete"
                      , % "New version is now running and the old version will now close'n"
                        . "Enjoy the latest version!"
            Run, %deposit%
            ExitApp
        }
        if (Version = lversion) {
            MsgBox, 64, % "Up to Date"
                    , % "Source Version: " Version "`n"
                    . "Local Version: " lversion
        }
        if (Version < lversion) {
            MsgBox, 64, % "DEV Version!"
                    , % "Source Version: " Version "`n"
                    . "Local Version: " lversion
        }
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
config = NDG-Config.ini
; ============================================ INI READING ============================================
; Section to read in the configuration file if it exists
IfExist, %config%
{
    ; Cleanup some of the old ini configuration portions
    IniDelete, %config%, Yourself, rolepick
    IniDelete, %config%, Yourself, |LEO|TOW|CIV|SAFR
    IniDelete, %config%, Normal, val2hkmsg
    IniDelete, %config%, Towing, towmsg1
    IniDelete, %config%, Keys, seatbelthk
    IniDelete, %config%, Keys, lighthk
    IniDelete, %config%, Keys, sirenhk
    IniDelete, %config%, Keys, yelphk
}

GoSub, ReadConfig

IfNotExist, NDG-Citation.csv
FileAppend,
(
10-19 MPH Over,200,
20-29 MPH Over,400,
30+ MPH Over,600,
Broken Windshield,250,
Careless Driving,1000,
Commercial Vehicle Fine,1000,
Driving under the Influence,2500,30
Excessive vehicle noise,400,
Failure to have correct registration on vehicle,600,
Failure to have registration displayed on vehicle,350,
Failure to use Headlights at night,250,
Failure to use signal when turning/changing lanes,150,
Failure to yield right of way to traffic,400,
Failure to yield to emergency vehicle,600,
Hit and Run,5000,20
Illegal passing,200,
Illegal turn,400,
Illegal U-Turn,400,
Illegally parked vehicle,400,
Impeding flow of traffic,500,
Running a red light,400,
Running a stop sign,300,
Tailight or headlight out,250,
Traveling wrong way,300,
Unroadworthy vehicle,300,
)
,NDG-Citation.csv

IfNotExist, NDG-Misdemeanor.csv
FileAppend,
(
Arson 2nd Degree,1500,20
Assault 2nd Degree,2500,15
Attempted Grand Theft Auto,1000,10
Brandishing of a Firearm,1000,10
Destruction of Government Property,1500,15
Destruction of Property,1000,10
Disorderly Conduct,500,10
Domestic Violence,1000,20
Driving on suspended license,1000,10
Driving without a license,1500,15
Failure to comply with lawful order,700,15
Failure to identify to LEO,,99999
Failure to pay fines,1000,15
Failure to supply documentation to LEO,700,15
False 911 calls,1500,20
False Report,1500,20
Harassment,1000,10
JayWalking,200,
Joyriding,600,15
Loitering,500,
Petty Theft,1500,15
Poaching,500,20
Possession of a stolen identification,1500,10
Posession of burglary tools,1000,20
Possession of illegal substance (General),1500,20
Possession of Marijuana,1000,
Prostitution,800,10
Public Indecency,500,10
Public Intoxication,800,10
Reckless Driving,2500,15
Reckless Endangerment,2000,20
Stalking,1500,15
Street Racing,1500,20
Trespassing,1000,10
Trespassing on Government Property,2500,15
Unlawful Imprisonment,1500,10
Unlawful use of a weapon,3000,20
)
,NDG-Misdemeanor.csv

IfNotExist, NDG-Felony.csv
FileAppend,
(
Aiding and Abetting/Accessory,,
Arson 1st Degree,3000,35
Assault 1st Degree,4000,30
Assault on Emergency Services,6000,40
Assault with a deadly weapon,5500,35
Attempted murder,5000,40
Attempted murder of Emergency Services,7000,50
Bribery of a Public Servant,3000,10
Burglary,3500,30
Conspiracy to Commit a Criminal Act,1500,15
Criminal Possession of Government Issued Equipment,5000,25
Criminal threat,4000,20
Destruction of physical evidence,1000,30
Escaping Custody,3000,20
Falsifying Government Document,3000,20
Fleeing and Eluding,1500,15
Fraud,1500,10
Grand Theft,3500,30
Grand Theft Auto,1500,20
Illegal possession of a Weapon/Firearm,2500,20
Impersonation,1000,10
Impersonation of an Emergency Services,2500,20
Kidnapping,3000,25
Manslaughter,5500,30
Murder,7000,50
Murder of a Emergency Services,12000,60
Obstruction of Justice,2000,10
Possession of a outlawed Weapon,3000,30
Possession of Marijuana with intent to sell,2500,15
Robbery/Armed Robbery,6000,30
Terroristic Acts,30000,999
Vehiclular Manslaughter,5500,30
)
,NDG-Felony.csv

; ============================================ HELP TEXT FORMAT ============================================
; Main portion of the help text that is displayed
subhelptext = 
(
Police Hotkeys:
Control+1 = Config
Control+2 = Ticket Calc
Control+3 = Reload Script
Control+/ = Vehicle Image Search
Control+- = runplate
Control+. = spikestrip
Control+K = Calls for TOW
Control+J = Lets TOW know information
tmedical - medical rp message
tmic = mic help
tpaystate = paystate help
tndghelp = ndg help
)

helptext = 
(
This script is used to well. Help you with some of the repetitive tasks within GTAV RP on SoE.
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
tdutystart - go on duty (launches mws)
tfrisk - frisks subject
tsearch - searches subject
tmedical - medical rp message
timpound - place impound sticker
tplate - notes the plate
tvin = notes the vin
ttrunk - get itmes from trunk (medbag|slimjim|tintmeter|cones|gsr|breathalizer|bodybag)
tglovebox - searches through the interior of a vehicle
tstrunk - searches through the trunk of the vehicle - Face the trunk

Control+1 - Configuration screen
Control+2 - NDG Ticket|Misdemeanor|Felony Calculator
Control+3 - Reload Script
Control+4 - Update Checker
Control+5 - Police Overlay
Control+6 - Close Police Overlay
Control+. - SpikeStrip Toggle
Control+/ - vehicle image search (uses google images in browser)
Control+- - preps command for plate running
Control+K - call for tow over radio
Control+J - tell tow whats going on

Tow Commands:
-----------------------
tadv - display your towing advertisement
tstart - start tow shift/company
tsend - initial send it
tonway - showing 76 to them
ttow - towing system
tsecure - secures tow straps
trelease - releases tow straps
tkitty - grabs kitty litter from truck

Help Commands:
--------------------
tmic = help text about fixing mic in local ooc
tpaystate = help text about paying state in local ooc
tndghelp = display ndg help information in local ooc

General Commands:
---------------------------
tgun - use firearm
tscrap - rp the scrap to truck
F9 - enables/disables engine
Shift+F11 - valet phone check
F11 - Pull vehicle out from valet
F6 - Pull out phone to record
)

helptext2 = 
(
If you wish to change any of the hotkeys.
This is the section to do so. Click on the box and then
hit the keys together to configure the hotkey.
)

citationtext = 
(
This is the portion to handle citations/tickets.
You can not GROUP tickets, they must be issued one per infraction.
The DB records it as one ticket per /ticket given.
All indicated arrest/ticket amounts are the MAX not the suggested.
)

misdemeanortext = 
(
This is the portion to handle misdemeanor charges.
For x2 or more charges.  This should be annotated on report. not Arson 2nd Degree x2 in the /arrest or /bill
All indicated arrest/bill amounts are the MAX not the suggested.
)

felonytext = 
(
This is the portion to handle felony charges.
For x2 or more charges.  This should be annotated on report. not Arson 1st Degree x2 in the /arrest or /bill
All indicated arrest/bill amounts are the MAX not the suggested.
)

; ============================================ CUSTOM SYSTEM TRAY ============================================
; Removes all of the standard options from the system tray
Menu, Tray, NoStandard
Menu, Tray, Add, &Update Checker, ^4
Menu, Tray, Add, &Ticket Calc, ^2
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
HomePage_TT := "Original home page on NDG forums"
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
    update(script.version)
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
; Both numbers should match to work with your ping to the server.
; Take your ping to the server and then times it by two to equal the delay numbers
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

; This will setup all of the variables for the script

^1::
    gosub, fuckakey
    ; ============================================ TESTING GUI ============================================
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
    Gui, 1:Add, Text,, The following should only be modified if playing on a different server.
    Gui, 1:Add, Text,, Radio:
    Gui, 1:Add, Text,, Third Party Action:
    Gui, 1:Add, Text,, First Party Action:
    Gui, 1:Add, Text,, Advertisement:
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
    Gui, 1:Add, Edit, x140 y272 w60 vrs, %rs%
    Gui, 1:Add, Edit, w60 vds, %ds%
    Gui, 1:Add, Edit, w60 vms, %ms%
    Gui, 1:Add, Edit, w60 vas, %as%
    Gui, 1:Add, Edit, x290 y30 w110 vphone, %phone%
    phone_TT := "Your Phone number, after 555-"
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
    ; MsgBox Nope lol
    Gui, 1:Cancel
    Return

    Save1:
    Gui, 1:Submit
    ; Towing related section
    tadv = %as% I work for [^3%towcompany%^0] and we do cool tow stuff that makes tows happy 555-%phone%!!
    tsend = %rs% [^3TOW%myid%^0] Send it!
    ; Police related section
    medicalmsg = Hello I am ^1%title% %name% %department%^0, Please use this time to perform the medical activities required for the wounds you have received.  Using ^1/do's ^0and ^1/me's ^0to simulate your actions and the Medical staff actions. -Once completed. Use ^1/do Medical staff waves the %title% in^0.
    towmsg1 = %rs% [^1%callsign%^0] to [^3TOW^0]
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
    Gui, 2:Add, Text,x20 y82, tdutystartmsg1:
    Gui, 2:Add, Text,x20 y122, tdutystartmsg2:
    Gui, 2:Add, Text,x20 y162, tdutystartmsg3:
    Gui, 2:Add, Text,x20 y192, towmsg1:
    Gui, 2:Add, Text,x20 y216, tfriskmsg:
    Gui, 2:Add, Text,x20 y256, tsearchmsg:
    Gui, 2:Add, Text,x20 y296, tmedicalmsg:
    Gui, 2:Add, Text,x20 y370, Spikes:
    Gui, 2:Add, Text,, Vehicle Image Search:
    Gui, 2:Add, Text,, RunPlate:
    Gui, 2:Add, Text,x350 y370, Tow Initiate:
    Gui, 2:Add, Text,, Tow Information:
    Gui, 2:Add, Edit, r2 vdutystartmsg1 w500 x115 y80, %dutystartmsg1%
    dutystartmsg1_TT := "Bodycam duty start message"
    Gui, 2:Add, Edit, r2 vdutystartmsg2 w500, %dutystartmsg2%
    dutystartmsg2_TT := "Dashcam duty start message"
    Gui, 2:Add, Edit, vdutystartmsg3 w500, %dutystartmsg3%
    dutystartmsg3_TT := "Log into the MWS/CAD"
    Gui, 2:Add, Edit, r1 vtowmsg1 w500, %towmsg1%
    towmsg1_TT := "Initial call to tow on radio"
    Gui, 2:Add, Edit, r2 vfriskmsg w500, %friskmsg%
    friskmsg_TT := "Message for when frisking a subject"
    Gui, 2:Add, Edit, r2 vsearchmsg w500, %searchmsg%
    searchmsg_TT := "Message for when searching a subject completely"
    Gui, 2:Add, Edit, r4 vmedicalmsg w500, %medicalmsg%
    medicalmsg_TT := "OOC message that you would tell someone to perform their own medical process"
    Gui, 2:Add, Hotkey, w150 x150 y365 vspikeshk, %spikeshk%
    spikeshk_TT := "Hotkey to be used to deploy/remove spike strip"
    Gui, 2:Add, Hotkey, w150 vvehimgsearchhk, %vehimgsearchhk%
    vehimgsearchhk_TT := "Hotkey to search for a vehicle's image on google"
    Gui, 2:Add, Hotkey, w150 vrunplatehk, %runplatehk%
    runplatehk_TT := "Hotkey to run a plate"
    Gui, 2:Add, Hotkey, w150 x450 y365 vtowcallhk, %towcallhk%
    towcallhk_TT := "Initiates the request for a tow truck"
    Gui, 2:Add, Hotkey, w150 vtowrespondhk, %towrespondhk%
    towrespondhk_TT := "Lets the tow truck know where you are and what you want them to tow"
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
    Gui, 2:Add, Text,r3, tadv:
    Gui, 2:Add, Text,r1, tsend:
    Gui, 2:Add, Text,r2, ttowmsg1:
    Gui, 2:Add, Text,r2, ttowmsg2:
    Gui, 2:Add, Text,r2, tsecure1:
    Gui, 2:Add, Text,r2, tsecure2:
    Gui, 2:Add, Text,r2, treleasemsg1:
    Gui, 2:Add, Text,r2, treleasemsg2:
    Gui, 2:Add, Edit, r3 vtadv w500 x100 y30, %tadv%
    tadv_TT := "Advertisement you use for your tow company"
    Gui, 2:Add, Edit, r1 vtsend w500, %tsend%
    tsend_TT := "Typical send it tow response to call for tow"
    Gui, 2:Add, Edit, r2 vttowmsg1 w500, %ttowmsg1%
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
    Gui, 2:Add, Text,x20 y85, tpaystatemsg:
    Gui, 2:Add, Text,x20 y150, Garbage Items:
    Gui, 2:Add, Edit, r3 w500 x110 y30 vmicmsg, %micmsg%
    micmsg_TT := "Message used to explain how to use/configure microphone"
    Gui, 2:Add, Edit, r4 w500 x110 y85 vpaystatemsg, %paystatemsg%
    paystatemsg_TT := "Message used to explain how to handle state debt"
    Gui, 2:Add, Edit, r5 w500 x110 y150 vItemsar, %Itemsar%
    Itemsar_TT := "Add items into this list, separated by commas to add to the glovebox and trunk search."
    Gui, 2:Tab, General,, Exact
    Gui, 2:Add, Text, , tgunmsg:
    Gui, 2:Add, Text, r2, valet2hkmsg:
    Gui, 2:Add, Text, , phrechkmsg:
    Gui, 2:Add, Text, y200 x20, Engine Hotkey:
    Gui, 2:Add, Text,, Valet App Hotkey:
    Gui, 2:Add, Text,, Valet Call Hotkey:
    Gui, 2:Add, Text,, Phone Record Hotkey:
    Gui, 2:Add, Edit, r1 vgunmsg w500 x100 y30, %gunmsg%
    gunmsg_TT := "Action message to draw a firearm"
    Gui, 2:Add, Edit, r2 vvalet2hkmsg w500, %valet2hkmsg%
    valet2hkmsg_TT := "Action to be used to pull out a vehicle from the valet"
    Gui, 2:Add, Edit, r1 vphrechkmsg w500, %phrechkmsg%
    phrechkmsg_TT := "Action message to be used when pulling out phone to record"
    Gui, 2:Add, Hotkey, w150 x140 y195 venginehk, %enginehk%
    enginehk_TT := "Hotkey to be used to force the /engine on when cruise doesn't work"
    Gui, 2:Add, Hotkey, w150 vvalet1hk, %valet1hk%
    valet1hk_TT := "Hotkey to use your phone valet app"
    Gui, 2:Add, Hotkey, w150 vvalet2hk, %valet2hk%
    valet2hk_TT := "Hotkey to call for the valet to get your vehicle"
    Gui, 2:Add, Hotkey, w150 vphrechk, %phrechk%
    phrechk_TT := "Hotkey to start recording with your phone"
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

^2::
    Gui, 5:Destroy
    Gui, 5:Font,, Consolas
    Gui, 5:Color, Silver
    Gui, 5:Add, Text, y10, Offender ID:
    Gui, 5:Add, Text, x140 y10, CautionCode:
    Gui, 5:Add, Text, x300 y10, ArrestMod:
    Gui, 5:Add, Text, x413 y10, FineMod:
    Gui, 5:Add, Text, x583 y10, Plate:
    Gui, 5:Add, Edit, x85 y6 w50 voffenderid Limit6, 0
    offenderid_TT := "This would be the citizen id that is on their ID - DOUBLE CHECK IT!"
    Gui, 5:Add, DropDownList, x215 y6 w40 vcautioncode, |G|PH|V|ST|E|M
    cautioncode_TT :=
    (
"G = Gang Affiliated
PH = Police Hater
V = Violent
ST = Suicidal Tendancies - Approved by SAFR Only
E = Escape Risk
M = Mental Instability - Approved by SAFR Only"
    )
    Gui, 5:Add, Button, x255 y5 gcautioncode vcaucode, Set
    caucode_TT := "Setting {CautionCode} once will add it, setting the same caution code will removeit, they are toggled"
    Gui, 5:Add, Edit, x360 y6 w45 varrestmod Limit5, 0
    arrestmod_TT := "This would modify the original max time to what you specify"
    Gui, 5:Add, Edit, x464 y6 w50 vfinemod Limit6, 0
    billmod_TT := "This would modify the original max fine/ticket to what you specify"
    Gui, 5:Add, Edit, x623 y6 w70 vplate Limit8, 0
    plate_TT := "License plate of the vehicle in question"
    Gui, 5:Add, Button, x515 y5 gchargemod vchgmod, Set Mods
    chgmod_TT := "This should configure both the arrestmod and the bill/ticket mod"
    Gui, 5:Add, Tab3, x10, Citation|Misdemeanor|Felony|PrettyFaces
    Gui, 5:Add, Edit, Readonly r4 w680 vcitationtext, %citationtext%
    Loop, read, %A_ScriptDir%\NDG-Citation.csv
	{
	    StringSplit, val, A_LoopReadLine,`,
        c_LineNumber = %A_Index%
	    Loop,%Val0%
            c_offense_%c_LineNumber% := val1
            c_fine_%c_LineNumber% := val2
            c_arrest_%c_LineNumber% := val3
            if (c_LineNumber == 20) {
                Gui, 5:Add, Button, x353 y124 gcitsub vcBtn%c_LineNumber%, %val1%-%c_LineNumber%
            } else {
                Gui, 5:Add, Button, gcitsub vcBtn%c_LineNumber%, %val1%-%c_LineNumber%
            }
	}
    Gui, 5:Font, s12 Underline cBlue, Consolas
    Gui, 5:Add, Text, x590 y650 gcitationlaw vcitationlaw, Citation-Law
    citationlaw_TT := "Government website with all of the Traffic related laws.  Use for reference."
    Gui, 5:Font
    Gui, 5:Tab, 2
    Gui, 5:Add, Edit, Readonly r3 w680 vmisdemeanortext, %misdemeanortext%
        Loop, read, %A_ScriptDir%\NDG-Misdemeanor.csv
	{
	    StringSplit, val, A_LoopReadLine,`,
        c_LineNumber = %A_Index%
	    Loop,%Val0%
            m_offense_%c_LineNumber% := val1
            m_fine_%c_LineNumber% := val2
            m_arrest_%c_LineNumber% := val3
            if (c_LineNumber == 20) {
                Gui, 5:Add, Button, x353 y112 gmisdsub vmBtn%c_LineNumber%, %val1%-%c_LineNumber%
            } else {
                Gui, 5:Add, Button, gmisdsub vmBtn%c_LineNumber%, %val1%-%c_LineNumber%
            }
	}
    Gui, 5:Font, s12 Underline cBlue, Consolas
    Gui, 5:Add, Text, x565 y650 gmisdemeanorlaw vmisdemeanorlaw, Misdemeanor-Law
    misdemeanorlaw_TT := "Government website with all of the Misdemeanor related laws.  Use for reference."
    Gui, 5:Font
    Gui, 5:Tab, 3
    Gui, 5:Add, Edit, Readonly r3 w680 vfelonytext, %felonytext%
            Loop, read, %A_ScriptDir%\NDG-Felony.csv
	{
	    StringSplit, val, A_LoopReadLine,`,
        c_LineNumber = %A_Index%
	    Loop,%Val0%
            f_offense_%c_LineNumber% := val1
            f_fine_%c_LineNumber% := val2
            f_arrest_%c_LineNumber% := val3
            if (c_LineNumber == 20) {
                Gui, 5:Add, Button, x365 y112 gfelosub vfBtn%c_LineNumber%, %val1%-%c_LineNumber%
            } else {
                Gui, 5:Add, Button, gfelosub vfBtn%c_LineNumber%, %val1%-%c_LineNumber%
            }
	}
    Gui, 5:Font, s12 Underline cBlue, Consolas
    Gui, 5:Add, Text, x610 y650 gfelonylaw vfelonylaw, Felony-Law
    felonylaw_TT := "Government website with all of the Felony related laws.  Use for reference."
    Gui, 5:Font
    Gui, 5:Tab, 4
    Gui, 5:Add, Text, x15 y65, Vehicle Report:
    Gui, 5:Add, Text, x15 y95, License Status:
    Gui, 5:Add, DropDownList, x105 y60 w90 vvehreport, |recovered|stolen
    vehreport_TT :=
    (
"Recovered = Reports the plate entered recovered
Stolen = Reports the plate entered stolen"
    )
    Gui, 5:Add, DropDownList, x105 y90 w90 vlrevoke, |revoke|reinstate
    lrevoke_TT :=
    (
"revoke = revokes the selected license
reinstate = reinstates the select license"
    )
    Gui, 5:Add, DropDownList, x195 y90 w90 vltype, |drivers|gun|hunting
    ltype_TT :=
    (
"drivers = revokes or reinstates drivers license
gun = revokes or reinstates gun license
hunting = revokes or reinstates hunting license"
    )
    Gui, 5:Add, Button, x195 y60 gvcheck vvset, Set Vehicle
    Gui, 5:Add, Button, x285 y90 glcheck vlset, Set License
    Gui, 5:Tab
    Gui, 5:Add, Edit, Readonly r5 w706 vpText
    pText_TT := "Use this section to copy the arrest/bill/ticket from, to enter into the game."
    Gui, 5:Add, Button, gcheck2 vsubmit, Submit
    Submit_TT := "Cleans out the record and updates the Charge Log file."
    Gui, 5:Add, Button, x60 y768 gwarrant vwarrant, ToWarrant
    warrant_TT := "Converts the charges to a Warrant format."
    Gui, 5:Add, Button, x125 y768 gcwarrant vcwarrant, ClearWarrant
    cwarrant_TT := "Provides command to wipe all warrants on a offender id."
    Gui, 5:Add, Button, x250 y768 gclear vclear, Clear
    Clear_TT := "Clears out all entries without saving them."
    Gui, 5:add, Button, x292 y768 gclearall vclearall, ClearAll
    clearall_TT := "Clears all possible fields other then the Offender ID"
    Gui, 5:Add, Button, x610 y768 h25 w40 gbug, BUG
    Gui, 5:Add, Button, x650 y768 h25 w65 gfeedback, Feedback
    Gui, 5:Show,, Citation | Misdemeanor | Felony | CautionCode - LEO Calculator
    OnMessage(0x200, "WM_MOUSEMOVE")
    lastEdit := ""
    Return

    5GuiEscape:
    5GuiClose:
    Gui, 5:Cancel
    Return
Return

citationlaw:
Run, % script.citlaw
Return

misdemeanorlaw:
Run, % script.mislaw
Return

felonylaw:
Run, % script.fellaw
Return

cautioncode:
gui,submit,nohide
PEdit = 
(
/cautioncode %offenderid% %cautioncode%
)
if (lastEdit == ""){
    guicontrol,,pText,% PEdit
    LastEdit := PEdit
} else {
    guicontrol,,pText,% PEdit
    lastEdit :=
}
Return

cwarrant:
gui,submit,nohide
PEdit = 
(
/warrant %offenderid% clear
)
if (lastEdit == ""){
    guicontrol,,pText,% PEdit
    LastEdit := PEdit
} else {
    guicontrol,,pText,% PEdit
    lastEdit :=
}
Return

warrant:
gui,submit,nohide
FormatTime, TimeString,, MM.dd.yy
PEdit = 
(
/warrant %offenderid% %offense% | (%name% - %department% - %TimeString%)
)
if (lastEdit == ""){
    guicontrol,,pText,% PEdit
    LastEdit := PEdit
} else {
    guicontrol,,pText,% PEdit
    lastEdit :=
}
Return

chargemod:
gui,submit,nohide
if (!arrestmod) {
    arrestmod := arrest
}
if (!finemod) {
    finemod := fine
}
Taste := StrSplit(PEdit, A_Space, "/")
if (InStr(PEdit,"/arrest")) {
    Grab1 := arrest
}
if (Instr(PEdit,"/ticket") or Instr(PEdit,"/bill")) {
    Grab2 := fine
}
if (arrestmod > arrest) {
    msgbox,64, Danger %name% of the %department%, You can not go beyond the maximum arrest time of [%arrest%] minutes based on the charges provided.  Please clear and try again.
    Return
}
if (finemod > fine) {
    msgbox,64, Danger %name% of the %department%, You can not go beyond the maximum fine/bill of [$%fine%] based on the charges provided.  Please clear and try again.
    Return
}
PEdit := StrReplace(PEdit,Grab1,arrestmod,,Limit := 1)
arrest := arrestmod
PEdit := StrReplace(PEdit,Grab2,finemod,,Limit := 1)
fine := finemod
if (lastEdit == ""){
    guicontrol,,pText,% PEdit
    LastEdit := PEdit
} else {
    guicontrol,,pText,% PEdit
    lastEdit :=
}
Return

citsub:
gui,submit,nohide
RegExMatch(A_GuiControl, "\d+$", n)
if (n == 6 and InStr(PEdit,"Commercial Vehicle Fine")) {
    msgbox, Commercial Vehicle fine can not be by itself.
} else if (InStr(PEdit,"/bill")) {
    msgbox, Please Clean out the Misedeamnor or Felony before issuing a ticket.
} else if (n == 6 and InStr(PEdit,"/arrest")) {
    offensea = %offense%
    offenseadd = % c_offense_%n%
    offense =  %offense% | %offenseadd%
    fine += % c_fine_%n%
    if (arrest) {
        PEdit = 
        (
/arrest %offenderid% %arrest% | %offensea% | (%name% - %department%)
/ticket %offenderid% %fine% | %offense% | (%name% - %department%)
        )
    } else {
        PEdit = 
        (
/ticket %offenderid% %fine% | %offense% | (%name% - %department%)
        )
    }
} else if (n == 6 and InStr(PEdit,"/ticket")) {
    offenseadd = % c_offense_%n%
    offense =  %offense% | %offenseadd%
    fine += % c_fine_%n%
    if (arrest) {
        PEdit = 
        (
/arrest %offenderid% %arrest% | %offensea% | (%name% - %department%)
/ticket %offenderid% %fine% | %offense% | (%name% - %department%)
        )
    } else {
        PEdit = 
        (
/ticket %offenderid% %fine% | %offense% | (%name% - %department%)
        )
    }
} else if (n == 6) {
    PEdit = 
(
You can not issue a Commercial Vehicle fine only by itself.  This must be an additional charge.
)
} else {
    offense = % c_offense_%n%
    fine = % c_fine_%n%
    arrest = % c_arrest_%n%
    if (arrest) {
        PEdit = 
        (
/arrest %offenderid% %arrest% | %offense% | (%name% - %department%)
/ticket %offenderid% %fine% | %offense% | (%name% - %department%)
        )
    } else {
        PEdit = 
        (
/ticket %offenderid% %fine% | %offense% | (%name% - %department%)
        )
    }
}
if (lastEdit == ""){
    guicontrol,,pText,% PEdit
    LastEdit := PEdit
} else {
    guicontrol,,pText,% PEdit
    lastEdit :=
}
Return

misdsub:
gui,submit,nohide
RegExMatch(A_GuiControl, "\d+$", n)
if (InStr(PEdit,"/ticket")) {
msgbox, You must Clear the Ticket before issuing Misdemanor chargers.
} else if (offense) {
    offenseadd = % m_offense_%n%
    offense = %offense% | %offenseadd%
    fine += % m_fine_%n%
    arrest += % m_arrest_%n%
    PEdit = 
    (
/arrest %offenderid% %arrest% | %offense% | (%name% - %department%)
/bill %offenderid% %fine% | %offense% | (%name% - %department%)
    )
} else {
    offense = % m_offense_%n%
    fine = % m_fine_%n%
    arrest = % m_arrest_%n%
    PEdit = 
    (
/arrest %offenderid% %arrest% | %offense% | (%name% - %department%)
/bill %offenderid% %fine% | %offense% | (%name% - %department%)
    )
}
if (lastEdit == ""){
    guicontrol,,pText,% PEdit
    LastEdit := PEdit
} else {
    guicontrol,,pText,% PEdit
    lastEdit :=
}
return

felosub:
gui,submit,nohide
RegExMatch(A_GuiControl, "\d+$", n)
if (InStr(PEdit,"/ticket")) {
    msgbox, You must Clear the Ticket before issuing Felony chargers.
} else if (n == 1 and InStr(PEdit, "Aiding and Abetting")) {
    msgbox, Aiding and Abetting cannot be on itself.
} else if (n == 1 and offense) {
    offenseadd = % f_offense_%n%
    offense = %offense% | %offenseadd%
    fine += % f_fine_%n%
    arrest += % f_arrest_%n%
    PEdit = 
    (
/arrest %offenderid% %arrest% | %offense% | (%name% - %department%)
/bill %offenderid% %fine% | %offense% | (%name% - %department%)
    )
} else if (offense) {
    offenseadd = % f_offense_%n%
    offense = %offense% | %offenseadd%
    fine += % f_fine_%n%
    arrest += % f_arrest_%n%
    PEdit = 
    (
/arrest %offenderid% %arrest% | %offense% | (%name% - %department%)
/bill %offenderid% %fine% | %offense% | (%name% - %department%)
    )
} else if (n == 1) {
    PEdit = 
    (
You can not issue a Aiding and Abetting charge by itself.  This must be an additional charge.        
    )
} else {
    offense = % f_offense_%n%
    fine = % f_fine_%n%
    arrest = % f_arrest_%n%
    PEdit = 
    (
/arrest %offenderid% %arrest% | %offense% | (%name% - %department%)
/bill %offenderid% %fine% | %offense% | (%name% - %department%)
    )
}
if (lastEdit == ""){
    guicontrol,,pText,% PEdit
    LastEdit := PEdit
} else {
    guicontrol,,pText,% PEdit
    lastEdit :=
}
return

check2:
gui,submit,nohide ;updates gui variable
FormatTime, TimeString,, yyyyMMdd HH:mm:ss
FileAppend,
(
%TimeString%
%PEdit%
`n
), %chrglog%
lastEdit := chrglog " Updated"
offense :=
fine :=
arrest :=
PEdit :=
guicontrol,,pText,% lastEdit
; Run %chrglog%
Return

lcheck:
gui,submit,nohide
if (!offenderid) {
    msgbox You are required to enter an offenderid
    Return
} else if (!lrevoke) {
    msgbox Please select to revoke or reinstate
    Return
} else if (!ltype) {
    msgbox Please select license type
    Return
} else {
    PEdit = 
(
/license %lrevoke% %ltype% %offenderid%
)
}
if (lastEdit == ""){
    guicontrol,,pText,% PEdit
    LastEdit := PEdit
} else {
    guicontrol,,pText,% PEdit
    lastEdit :=
}
Return

vcheck:
gui,submit,nohide
if (!plate) {
    msgbox Please enter in a license plate first
    Return 
} else if (!vehreport) {
    msgbox Please select recovered or stolen
    return
} else {
    PEdit = 
(
/reportveh %vehreport% %plate%
)
}
if (lastEdit == ""){
    guicontrol,,pText,% PEdit
    LastEdit := PEdit
} else {
    guicontrol,,pText,% PEdit
    lastEdit :=
}
Return

clear:
gui,submit,nohide ;updates gui variable
lastEdit := "Cleared Records"
offense :=
fine :=
arrest :=
PEdit :=
guicontrol,,pText,% lastEdit
Return

clearall:
gui,submit,nohide
lastEdit := "Full Clear Completed"
offense :=
fine :=
finemod :=
arrest := 
arrestmod :=
PEdit :=
guicontrol,,pText,% lastEdit
guicontrol,,arrestmod,0
guicontrol,,finemod,0
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
; Pressing T to open chat and then typing unrack/rack

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
        ClipWait
        Send, {RCtrl down}v{RCtrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
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
        ClipWait
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
        Clipboard = /fuelhud
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /gps
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %dutystartmsg1%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %dutystartmsg2%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %dutystartmsg3%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {F9 down}
        Sleep, %delay%
        Send, {F9 up}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Changes radio channel to channel 5 and then calls for tow on that channel.
    ; ^k:: ; Control + k
    tchk:
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /rc 5
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %towmsg1%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Sending out the tow location to towid.
    ; ^j:: ; Control + j
    trhk:
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        InputBox, towloc, Tow Location, Enter Towing Location
        if (towloc = "") {
            MsgBox, No tow Location was entered, Try again.
        } else {
            InputBox, towid, Tow ID, Enter Towing ID
            if (towid = "") {
                Msgbox, No Tow ID was entered.  Try again.
            } else {
                InputBox, veh, Vehicle, Description and color
                if (veh = "") {
                    MsgBox No Vehicle was entered. Try again.
                } else {
                    clipaboard = %clipboard%
                    Sleep, %delay%
                    Send, {t down}
                    Sleep, %delay%
                    Send, {t up}
                    Sleep, %delay%
                    Clipboard = %rs% [^1%callsign%^0] to [^3TOW%towid%^0] I have a %veh% for you at %towloc%
                    ClipWait
                    Send, {Rctrl down}v{Rctrl up}{enter}
                    Sleep, %delay%
                    clipboard = %clipaboard%
                }
            }
        }
    }
    Return

    ; Frisks the Subject for weapons.
    :*:tfrisk:: ; Type tfrisk in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %friskmsg%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /frisk
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Fully searches the Subject.
    :*:tsearch:: ; Type tsearch in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %searchmsg%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /search
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Touches the vehicle on approach
    :*:ttv:: ; Type ttv in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %ms% touches the trunk lid of the vehicle
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Tells subject on how to do the medical RP for themselves.
    :*:tmedical:: ; Type tmedical in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %medicalmsg%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Test running through timing.
    :*:ttest:: ; Type ttest in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = /e notepad
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %ms% notes a few things to himself that he thinks are important.
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Pulls out the notepad to write out the plate of the vehicle
    :*:tplate:: ; Type tplate in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = /e notepad
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %ms% notes the plate down
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {m down}
        Sleep, %delay%
        Send, {m up}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Pulls out notepad to write out the vin of the vehicle.
    :*:tvin:: ;Type tvin in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = /e notepad
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %ms% notes the vin information
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /vin
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Pulls out notepad to write out and plate impound sticker on vehicle
    :*:timpound:: ; Type timpound in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = /e notepad
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %ds% tears off the written impound sticker and places it on the vehicle
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /impound
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; Searches through the glovebox of a vehicle
    :*:tglovebox:: ; Type tglovebox in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        Items := StrSplit(Itemsar, ",")
        Random, Item, 1, Items.MaxIndex()
        Picked := Items[Item]
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %ms% begins searching the the interior of the vehicle and finds some %Picked%.
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /access
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Clipboard = %clipaboard%
    }
    Return

    ; Searches through the trunk of a vehicle
    :*:tstrunk:: ; Type tstrunk in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        Items := StrSplit(Itemsar, ",")
        Random, Item, 1, Items.MaxIndex()
        Picked := Items[Item]
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = /trunk
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %ms% begins searching the the trunk of the vehicle and finds some %Picked%.
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /access
        ClipWait
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
        if (titem = "medbag" || titem = "slimjim" || titem = "tintmeter" || titem = "cones" || titem = "gsr" || titem = "breathalizer" || titem = "bodybag") {
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
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            if (titem = "cones") {
                Clipboard = %ds% Grabs a few %titem% from the trunk
                ClipWait
            } else if (titem = "gsr") {
                Clipboard = %ds% Grabs a %titem% kit from the trunk
                ClipWait
            } else {
                Clipboard = %ds% Grabs a %titem% from the trunk
                ClipWait
            }
            Send, {Rctrl down}v{Rctrl up}{enter}
            If (titem = "medbag") {
                Sleep, %delay%
                Send, {t down}
                Sleep, %delay%
                Send, {t up}
                Sleep, %delay%
                Clipboard = /access
                ClipWait
                Send, {Rctrl down}v{Rctrl up}{enter}
                Msgbox, Once completed with your inventory actions, Press T
                KeyWait, t, D
            }
            Sleep, %delay%
            Clipboard = /trunk
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Send, {l down}
            Sleep, %delay%
            Send, {l up}
            Sleep, %delay%
            clipboard = %clipaboard%
        } else {
            Send, {enter}
            MsgBox, That %titem% is not in your trunk. Try again.
        }
    }
    Return
    ; ============================================ CIV Stuff ============================================
#If (rolepick = "CIV")
    ; Proper way to pull out a firearm.
    :*:tgun:: ; Type tgun in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %gunmsg%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {6 down}
        Sleep, %delay%
        Send, {6 up}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return
    ; ============================================ TOW Stuff ============================================
#If (rolepick = "TOW")
    :*:tstart:: ; Type tstart in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = /rc %trc%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /clockin %towcompany%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    :*:tadv:: ; Type tadv in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %tadv%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    :*:tsend:: ; Type tsend in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %tsend%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Responds to anyone that may be calling for tow.
    :*:tonway:: ; Type tonway in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        InputBox, caller, Tow Location, Enter Caller information
        if (caller = "") {
            MsgBox, No Caller information was entered, Try again.
        } else {
            InputBox, eta, Tow ID, Enter Estimated Time of Arrival (ETA) in minutes.
            if (eta = "") {
                Msgbox, No ETA was entered.  Try again.
            } else {
                clipaboard = %clipboard%
                Sleep, %delay%
                Clipboard = %rs% [^3TOW%myid%^0] to [^1%caller%^0] will be 76 to you ETA %eta% mikes.
                ClipWait
                Send, {Rctrl down}v{Rctrl up}{enter}
                Sleep, %delay%
                clipboard = %clipaboard%
            }
        }
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
            ClipWait
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
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Clipboard = /tow
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            clipboard = %clipaboard%
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
        ClipWait
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
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
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
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /tow
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; To pull out Kitty Litter from tow truck for use.
    :*:tkitty:: ; Type tkitty in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %ds% opens the toolbox and removes kitty litter from it
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return
    ; ============================================ SAFR Stuff ============================================
#If (rolepick = "SAFR")
    ; Items that can be pulled out from the trunk of a vehicle.
    :*:ttrunk:: ; Type ttrunk in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        vehicle = bus
        Inputbox, bside, Choose your side!, Which side of the %vehicle% are you on? Use l or r for left or right.
        if  (bside = "l" || bside = "r") {
            InputBox, bitem, Item, What do you want to get from your %vehicle%?
            if ErrorLevel
                Return
            else
                if (bitem = "medbag" || bitem = "cones" || bitem = "bodybag") {
                    clipaboard = %clipboard%
                    SLeep, %delay%
                    Clipboard = /door b%bside%
                    ClipWait
                    Send, {Rctrl down}v{Rctrl up}{enter}
                    Sleep, %delay%
                    Send, {t down}
                    Sleep, %delay%
                    Send, {t up}
                    Sleep, %delay%
                    if (bitem = "cones") {
                        Clipboard = %ds% grabs a few %bitem% from the %vehicle%
                        ClipWait
                    } else {
                        Clipboard = %ds% grabs a %bitem% from the %vehicle%
                        ClipWait
                    }
                    Send, {Rctrl down}v{Rctrl up}{enter}
                    If (bitem = "medbag") {
                        Sleep, %delay%
                        Send, {t down}
                        Sleep, %delay%
                        Send, {t up}
                        Sleep, %delay%
                        Clipboard = /e %bitem%
                        ClipWait
                        Send, {Rctrl down}v{Rctrl up}{enter}
                    }
                    Sleep, %delay%
                    Send, {t down}
                    Sleep, %delay%
                    Send, {t up}
                    Sleep, %delay%
                    Clipboard = /door b%bside%
                    ClipWait
                    Send, {Rctrl down}v{Rctrl up}{enter}
                    Sleep, %delay%
                    clipboard = %clipaboard%
                } else {
                    Send, {enter}
                    MsgBox, That %bitem% is not in your %vehicle%. Try again.
                }
        } else {
            Send, {enter}
            MsgBox, That %bside% is not a proper %vehicle%. Try agian.
        }
    }
    Return
    ; ============================================ HELP Stuff ============================================
#IF
; This provides the help text for micropohone fixing in local ooc chat
:*:tmic:: ; Type tmic in-game
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Clipboard = %micmsg%
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    clipboard = %clipaboard%
}
Return

; This provides help text for the paying of state debt in local ooc chat
:*:tpaystate:: ; Type tpaystate in-game
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Clipboard = %paystatemsg%
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    clipboard = %clipaboard%
}
Return

; This provides the help text for newdawngaming inforamtion in local ooc chat
:*:tndghelp:: ; Type tndg in-game
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Clipboard := "New Dawn Gaming information at ^1 https://forum.newdawn.fun/ ^0 for the forums and for the player list ^2 https://newdawn.fun/ ^0 for guides ^8 https://forum.newdawn.fun/c/for-new-members/guides"
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    clipboard = %clipaboard%
}
Return

; This will run the /engine command to toggle engine state
; F9:: ; Press F9 in-game
enhk:
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Send, {t down}
    Sleep, %delay%
    Send, {t up}
    Sleep, %delay%
    clipboard = /engine
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    clipboard = %clipaboard%
}
Return

; This is the ability to check your valet on the phone
; +F11:: ; Press Shift+F11 in-game
val1hk:
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Send, {t down}
    Sleep, %delay%
    Send, {t up}
    Sleep, %delay%
    clipboard = /e phoneplay
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    Send, {t down}
    Sleep, %delay%
    Send, {t up}
    Sleep, %delay%
    clipboard = /valet
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    clipboard = %clipaboard%
}
Return

; This is the ability to do an emote/do with pulling out a vehicle
; F11:: ; Press F11 in-game
val2hk:
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Send, {t down}
    Sleep, %delay%
    Send, {t up}
    Sleep, %delay%
    clipboard = %valet2hkmsg%
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    Send, {t down}
    Sleep, %delay%
    Send, {t up}
    Sleep, %delay%
    clipboard = /e atm
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    Send, {e down}
    Sleep, %delay%
    Send, {e up}
    Sleep, %delay%
    clipboard = %clipaboard%
}
Return

; This will be used to start the video recording in character civilian
; F6:: ; Press F6 in-game
phrhk:
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Send, {t down}
    Sleep, %delay%
    Send, {t up}
    Sleep, %delay%
    clipboard = %phrechkmsg%
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    Send, {t down}
    Sleep, %delay%
    Send, {t up}
    Sleep, %delay%
    clipboard = /e film
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    clipboard = %clipaboard%
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
    hotkey, %towcallhk%, tchk, On
    hotkey, %towrespondhk%, trhk, On
    hotkey, %enginehk%, enhk, On
    hotkey, %valet1hk%, val1hk, On
    hotkey, %valet2hk%, val2hk, On
    hotkey, %phrechk%, phrhk, On
Return

fuckakey:
    hotkey, %spikeshk%, sphk, Off
    hotkey, %vehimgsearchhk%, vehimghk, Off
    hotkey, %runplatehk%, rphk, Off
    hotkey, %towcallhk%, tchk, Off
    hotkey, %towrespondhk%, trhk, Off
    hotkey, %enginehk%, enhk, Off
    hotkey, %valet1hk%, val1hk, Off
    hotkey, %valet2hk%, val2hk, Off
    hotkey, %phrechk%, phrhk, Off
Return

ReadConfig:
    ; Back to the reading of the configuration
    IniRead, rolepick, %config%, Yourself, role, LEO
    IniRead, callsign, %config%, Yourself, callsign, D6
    IniRead, myid, %config%, Yourself, myid, 30
    IniRead, towcompany, %config%, Yourself, towcompany, DonkeyDick
    IniRead, name, %config%, Yourself, name, Dread
    IniRead, title, %config%, Yourself, title, Deputy
    IniRead, department, %config%, Yourself, department, LSSD
    IniRead, phone, %config%, Yourself, phone, 00030
    ; Client communication and test mode
    IniRead, delay, %config%, Yourself, delay, 80
    IniRead, testmode, %config%, Yourself, testmode, 0
    ; Server related section
    IniRead, rs, %config%, Server, rs, /r
    IniRead, ds, %config%, Server, ds, /do
    IniRead, ms, %config%, Server, ms, /me
    IniRead, as, %config%, Server, as, /ad
    ; The hotkey related section
    IniRead, spikeshk, %config%, Keys, spikeshk, ^.
    IniRead, vehimgsearchhk, %config%, Keys, vehimgsearchhk, ^/
    IniRead, runplatehk, %config%, Keys, runplatehk, ^-
    IniRead, towcallhk, %config%, Keys, towcallhk, ^k
    IniRead, towrespondhk, %config%, Keys, towrespondhk, ^j
    IniRead, enginehk, %config%, Keys, enginehk, F9
    IniRead, valet1hk, %config%, Keys, valet1hk, +F11
    IniRead, valet2hk, %config%, Keys, valet2hk, F11
    IniRead, phrechk, %config%, Keys, phrechk, F10
    ; Messages that correspond with the hotkeys
    ; Police related section
    IniRead, Itemsar, %config%, Police, Itemsar, Twinkie Wrappers,Hotdog buns,Potato chip bags,Used Diappers,Tools,Keyboards
    IniRead, dutystartmsg1, %config%, Police, dutystartmsg1, %ds% secures the bodycam to the chest and then turns it on and validates that it is recording and listening.
    IniRead, dutystartmsg2, %config%, Police, dutystartmsg2, %ds% Validates that the Dashcam is functional in both audio and video.
    IniRead, dutystartmsg3, %config%, Police, dutystartmsg3, %ds% Logs into the MWS computer.
    IniRead, friskmsg, %config%, Police, friskmsg, %ds% Frisks the Subject looking for any weapons and removes ^1ALLLL ^0of them
    IniRead, searchmsg, %config%, Police, searchmsg, %ds% Searches the Subject completely and stows ^1ALLLL ^0items into the evidence bags
    IniRead, medicalmsg, %config%, Police, medicalmsg, Hello I am ^1%title% %name% %department%^0, Please use this time to perform the medical activities required for the wounds you have received.  Using ^1/do's ^0and ^1/me's ^0to simulate your actions and the Medical staff actions. -Once completed. Use ^1/do Medical staff waves the %title% in^0.
    IniRead, towmsg1, %config%, Police, towmsg1, %rs% [^1%callsign%^0] to [^3TOW^0]
    ; Towing related section
    IniRead, tadv, %config%, Towing, tadv, %as% I work for [^3%towcompany%^0] and we do cool tow stuff that makes tows happy 555-%phone%!!
    IniRead, tsend, %config%, Towing, tsend, %rs% [^3TOW%myid%^0] Send it!
    IniRead, ttowmsg1, %config%, Towing, ttowmsg1, %ds% attaches the winch cable to the front of the vehicle
    IniRead, ttowmsg2, %config%, Towing, ttowmsg2, %ds% attaches the winch cable to the rear of the vehicle
    IniRead, tsecure1, %config%, Towing, tsecure1, %ds% secures the rear of the vehicle with extra tow straps
    IniRead, tsecure2, %config%, Towing, tsecure2, %ds% secures the front of the vehicle with extra tow straps
    IniRead, treleasemsg1, %config%, Towing, treleasemsg1, %ds% releases the extra tow cables from the rear and pulls the winch release lever
    IniRead, treleasemsg2, %config%, Towing, treleasemsg2, %ds% releases the extra tow cables from the front and pulls the winch release lever
    ; Help related section
    IniRead, micmsg, %config%, Help, micmsg, How to fix microphone - ESC -> Settings -> Voice Chat -> Toggle On/Off -> Increase Mic Volume and Mic Sensitivity -> Match audio devices to the one you are using.
    IniRead, paystatemsg, %config%, Help, paystatemsg, State debt is composed of your Medical and Civil bills.  To see how much you have, type ^1/paystate^0.  To pay.  Go to the Courthouse front door on ^2Power Street / Occupation Avenue^0 and then use ^2/payticket (TicketID)^0 to pay it.  ^8State Debt must be paid from your bank account
    ; Normal related section
    IniRead, gunmsg, %config%, Normal, gunmsg, %ds% pulls out his ^1pistol ^0from under his shirt
    IniRead, valet2hkmsg, %config%, Normal, valet2hkmsg, %ms% puts in his ticket into the valet and presses the button to receive his selected vehicle
    IniRead, phrechkmsg, %config%, Normal, phrechkmsg, %ds% Pulls out their phone and starts recording audio and video
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
    IniWrite, %rs%, %config%, Server, rs
    IniWrite, %ds%, %config%, Server, ds
    IniWrite, %ms%, %config%, Server, ms
    IniWrite, %as%, %config%, Server, as
    ; The hotkey related section
    IniWrite, %spikeshk%, %config%, Keys, spikeshk
    IniWrite, %vehimgsearchhk%, %config%, Keys, vehimgsearchhk
    IniWrite, %runplatehk%, %config%, Keys, runplatehk
    IniWrite, %towcallhk%, %config%, Keys, towcallhk
    IniWrite, %towrespondhk%, %config%, Keys, towrespondhk
    IniWrite, %enginehk%, %config%, Keys, enginehk
    IniWrite, %valet1hk%, %config%, Keys, valet1hk
    IniWrite, %valet2hk%, %config%, Keys, valet2hk
    IniWrite, %phrechk%, %config%, Keys, phrechk
    ; Messages that correspond with the hotkeys
    ; Police related 
    IniWrite, %Itemsar%, %config%, Police, Itemsar
    IniWrite, %dutystartmsg1%, %config%, Police, dutystartmsg1
    IniWrite, %dutystartmsg2%, %config%, Police, dutystartmsg2
    IniWrite, %dutystartmsg3%, %config%, Police, dutystartmsg3
    IniWrite, %friskmsg%, %config%, Police, friskmsg
    IniWrite, %searchmsg%, %config%, Police, searchmsg
    IniWrite, %medicalmsg%, %config%, Police, medicalmsg
    IniWrite, %towmsg1%, %config%, Police, towmsg1
    ; Towing related section
    IniWrite, %tadv%, %config%, Towing, tadv
    IniWrite, %tsend%, %config%, Towing, tsend
    IniWrite, %ttowmsg1%, %config%, Towing, ttowmsg1
    IniWrite, %ttowmsg2%, %config%, Towing, ttowmsg2
    IniWrite, %tsecure1%, %config%, Towing, tsecure1
    IniWrite, %tsecure2%, %config%, Towing, tsecure2
    IniWrite, %treleasemsg1%, %config%, Towing, treleasemsg1
    IniWrite, %treleasemsg2%, %config%, Towing, treleasemsg2
    ; Help related section
    IniWrite, %micmsg%, %config%, Help, micmsg
    IniWrite, %paystatemsg%, %config%, Help, paystatemsg
    ; Normal related section
    IniWrite, %gunmsg%, %config%, Normal, gunmsg
    IniWrite, %valet2hkmsg%, %config%, Normal, valet2hkmsg
    IniWrite, %phrechkmsg%, %config%, Normal, phrechkmsg
; ============================================ READ INI SECTION ============================================
    Gosub, ReadConfig
Return