/**
 * =============================================================================================== *
 * @Author           : DreadfullyDespized (darkestdread@gmail.com)
 * @Script Name      : AHKGLRP - GLRP Autohotkey doohicky
 * @Script Version   : 1
 * @Homepage         : https://github.com/DreadfullyDespized/ahkgtav
 * @Creation Date    : 20191016
 * @Modification Date: 
 * @Description      : Simple autohotkey script to be used with GTAV FiveM GLRP.
 *                     Really just built around to automating repetitive RP related tasks.
 * -----------------------------------------------------------------------------------------------
 * @License          : Copyright ©2019-2020 DreadfullyDespized <GPLv3>
 *                     This program is free software: you can redistribute it and/or modify it under the terms of
 *                     the GNU General Public License as published by the Free Software Foundation,
 *                     either version 3 of  the  License,  or (at your option) any later version.
 *                     This program is distributed in the hope that it will be useful,
 *                     but WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY  OF MERCHANTABILITY
 *                     or FITNESS FOR A PARTICULAR  PURPOSE.  See  the GNU General Public License for more details.
 *                     You should have received a copy of the GNU General Public License along with this program.
 *                     If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>
 * -----------------------------------------------------------------------------------------------
 */

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

; Includes section if needed{
;}


; Directives{
#NoEnv
#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%
;}

Menu, Tray, Icon, shell32.dll, 194

; Basic Script Info{
global script := {  based           : scriptobj
                    ,name           : "AHKGLRP"
                    ,version        : "1"
                    ,author         : "DreadfullyDespized"
                    ,email          : "darkestdread@gmail.com"
                    ,Homepage       : "https://github.com/DreadfullyDespized/ahkgtav"
                    ,crtdate        : "20191016"
                    ,moddate        : ""
                    ,conf           : "GLRP-Config.ini"}
; }

; ============================================ SCRIPT AUTO UPDATER ============================================
update(lversion, logurl="", rfile="github", vline=13) {
    Msgbox,
          , % "Info"
          , % "Author: " . script.author . "`n"
            . "Name: " . script.name . "`n"
            . "Version: " . script.version . "`n"
            . "ModDate: " . script.moddate . "`n"
            . "Config: " . script.conf . "`n"
            . "Email: " . script.email

    `(rfile = "github") ? logurl := "https://raw.githubusercontent.com/DreadfullyDespized/ahkgtav/master/Changelog-GLRP.txt"

    RunWait %ComSpec% /c "Ping -n 1 -w 3000 google.com",, Hide  ; Check if we are connected to the internet
    
    if connected := !ErrorLevel
    {
        ; msgbox, Connected
        ; This one actually worked and created the changelog file.
        UrlDownloadToFile, %logurl%, %a_temp%\Changelog-GLRP.txt ; C:\Users\username\AppData\Local\Temp\logurl
        ; UrlDownloadToFile is being blocked at work
        if ErrorLevel
            msgbox, The file failed to download
        FileReadLine, line, %a_temp%\Changelog-GLRP.txt, %vline%
        RegexMatch(line, "\d", Version)
        if (rfile = "github") {
            rfile := "https://raw.githubusercontent.com/DreadfullyDespized/ahkgtav/master/AHKGLRP.ahk"
        }
        if (Version > lversion){
            Msgbox, 68, % "New Update Available"
                      , % "There is a new update available for this application.`n"
                        . "Do you wish to upgrade to V" Version "?"
                      , 10 ; 10s timeout
            IfMsgbox, Timeout
                return debug ? "* Update message timed out" : 1
            IfMsgbox, No
                return debug ? "* Update aborted by user" : 2
            deposit := A_ScriptDir "\AHKGLRP.ahk"
            UrlDownloadToFile, %rfile%, %deposit%
            Msgbox, 64, % "Download Complete"
                      , % "New version is now running and the old version will now close'n"
                        . "Enjoy the latest version!"
            Run, %deposit%
            ExitApp

        }
        return debug ? "* update() [End]" : 0
    }
    else
        return debug ? "* Connection Failed" : 3
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
config = GLRP-Config.ini
; ============================================ INI READING ============================================
; Section to read in the configuration file if it exists
IfExist, %config%
{
    ; Cleanup some of the old ini configuration portions
    IniDelete, %config%, Yourself, rolepick
    IniDelete, %config%, Yourself, |LEO|TOW|CIV|SAFR|GEORGE
    IniDelete, %config%, Normal, val2hkmsg
    IniDelete, %config%, Towing, towmsg1
    IniDelete, %config%, Keys, seatbelthk
    IniDelete, %config%, Keys, lighthk
    IniDelete, %config%, Keys, sirenhk
    IniDelete, %config%, Keys, yelphk
}
; Back to the reading of the configuration
IniRead, rolepick, %config%, Yourself, role, LEO
IniRead, callsign, %config%, Yourself, callsign, S-80
IniRead, name, %config%, Yourself, name, Dread
IniRead, title, %config%, Yourself, title, Deputy
IniRead, department, %config%, Yourself, department, BCSO
IniRead, phone, %config%, Yourself, phone, 00030
; Client communication and test mode
IniRead, delay, %config%, Yourself, delay, 80
IniRead, testmode, %config%, Yourself, testmode, 0
; Server related section
IniRead, ms, %config%, Server, ms, /me
IniRead, as, %config%, Server, as, /ad
; The hotkey related section
IniRead, spikeshk, %config%, Keys, spikeshk, ^.
IniRead, vehimgsearchhk, %config%, Keys, vehimgsearchhk, ^/
; Messages that correspond with the hotkeys
; Police related section
IniRead, dutystartmsg1, %config%, Police, dutystartmsg1, %ms% secures the bodycam to the chest and then turns it on and validates that it is recording and listening.
IniRead, dutystartmsg2, %config%, Police, dutystartmsg2, %ms% Validates that the Dashcam is functional in both audio and video.
IniRead, dutystartmsg3, %config%, Police, dutystartmsg3, %ms% Logs into the MWS computer.
IniRead, friskmsg, %config%, Police, friskmsg, %ms% Frisks the Subject looking for any weapons and removes ^1ALLLL ^0of them
IniRead, searchmsg, %config%, Police, searchmsg, %ms% Searches the Subject completely and stows ^1ALLLL ^0items into the evidence bags
IniRead, medicalmsg, %config%, Police, medicalmsg, Hello I am ^1%title% %name% %department%^0, Please use this time to perform the medical activities required for the wounds you have received.  Using ^1/do's ^0and ^1/me's ^0to simulate your actions and the Medical staff actions. -Once completed. Use ^1/do Medical staff waves the %title% in^0.
; Help related section
IniRead, micmsg, %config%, Help, micmsg, How to fix microphone - ESC -> Settings -> Voice Chat -> Toggle On/Off -> Increase Mic Volume and Mic Sensitivity -> Match audio devices to the one you are using.
IniRead, paystatemsg, %config%, Help, paystatemsg, State debt is composed of your Medical and Civil bills.  To see how much you have, type ^1/paystate^0.  To pay.  Go to the Courthouse front door on ^2Power Street / Occupation Avenue^0 and then use ^2/payticket (TicketID)^0 to pay it.  ^8State Debt must be paid from your bank account

; This section will need to be revamped to correspond with the penal code system for GLRP
IfNotExist, GLRP-Capital.csv
FileAppend,
(
Aggravated Assault on a Government Official,15000,360
)
,GLRP-Capital.csv

IfNotExist, GLRP-Felony.csv
FileAppend,
(
Murder,15000,60
Aggravated Assault,15000,60
Kidnapping,15000,60
Aggravated Robbery,15000,60
Grand Larceny,15000,60
Money Laundering,15000,60
Possession Manufacture Sale or Delivery of Controlled Substance: Marijuana,15000,60
Possession Manufacutre Sale or Delivery of Controlled Substance: Schedule I,15000,60
Manslaughter,12500,45
Robbery,12500,45
Money Laundering,12500,45
Criminal Mischief,12500,45
Larceny,12500,45
Bribery,12500,45
Directing Activities of Gang or Crime Syndicate,12500,45
Possession Manufacture Sale or Delivery of Controlled Substance: Marijuana,12500,45
Possession Manufacture Sale or Delivery of Controlled Substance: Schedule I,12500,45
Permitting or Facilitating Escape,12500,45
Hit and Run,12500,45
Arson,10000,20
Money Laundering,10000,20
Criminal Mischief,10000,20
Larceny,10000,20
Deadly Conduct,10000,20
Breach of Computer Security,10000,20
Witness Tampering,10000,20
Tampering with or Fabricating Evidence,10000,20
Impersonating a Public Servant Government Official or Attorney,10000,20
Escape from Custody,10000,20
Forgery,10000,20
Firearm Smuggling,10000,20
Unlawful Possession of Firearms or Firearm Magazines,10000,20
Possession Manufacture Sale or Delivery of Marijuana,10000,20
Possession Manufacture Delivery of Controlled Substance: Schedule I,10000,20
Criminal Negligence,10000,20
Possession of Destructive Device,10000,20
False Imprisonment,10000,20
Possession of an Illegal or Dangerous Weapon,10000,20
Unlawful Concealed Carry of Firearm,10000,20
)
,GLRP-Felony.csv

IfNotExist, GLRP-Citation.csv
FileAppend,
(
10-19 MPH Over,200,
)
,GLRP-Citation.csv

IfNotExist, GLRP-Misdemeanor.csv
FileAppend,
(
Arson 2nd Degree,1500,20

)
,GLRP-Misdemeanor.csv

; ============================================ HELP TEXT FORMAT ============================================
; Main portion of the help text that is displayed
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
tbodybag - get local to bodybag
timpound - place impound sticker
tplate - notes the plate
tvin = notes the vin
ttrunk - get itmes from trunk (medbag|slimjim|tintmeter|cones|gsr|breathalizer|bodybag)

Control+2 - NDG Ticket|Misdemeanor|Felony Calculator
Control+. - SpikeStrip Toggle
Control+/ - vehicle image search (uses google images in browser)
Control+- - runs plate along with saving plate on clipboard
Control+= - ncic name along with saving name on clipboard

Help Commands:
--------------------
tmic = help text about fixing mic
tpaystate = help text about paying state
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
capitaltext = 
(
This is the portion to handle capital charges.
For x2 or more charges.  This should be annotated on report. not Arson 1st Degree x2 in the /arrest or /bill
All indicated arrest/bill amounts are the MAX not the suggested.
)

; ============================================ CUSTOM SYSTEM TRAY ============================================
; Removes all of the standard options from the system tray
Menu, Tray, NoStandard
Menu, Tray, Add, &Update Checker, ^4
Menu, Tray, Add, &Reload Script, ^3
Menu, Tray, Add, &Ticket Calc, ^2
Menu, Tray, Add, &Reconfigure/Help, ^1
Menu, Tray, Add, GTAV &Car Search, vehimghk
Menu, Tray, Add, E&xit,Exit

#z::Menu, Tray, Show

Exit:
ExitApp
Return

^4::
update(5)
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
    Gui, 1:Add, Text,, Advertisement:
    Gui, 1:Add, Text, x210 y34, Phone Number:
    Gui, 1:Add, DropDownList, x100 y30 w80 vrolepick, |LEO
    rolepick_TT := "Select the character role that you will be playing as"
    Gui, 1:Add, Edit, w80 vcallsign, %callsign%
    callsign_TT := "Callsign for your LEO/EMS character"
    Gui, 1:Add, Edit, w80 vname, %name%
    name_TT := "Name format Last Name - Dread for instance"
    Gui, 1:Add, Edit, w80 vtitle, %title%
    title_TT := "Title or Rank of your character"
    Gui, 1:Add, Edit, w80 vdepartment, %department%
    department_TT := "Department that your character works for"
    Gui, 1:Add, Edit, w80 vdelay, %delay%
    delay_TT := "milisecond delay.  Take your ping to the server x2"
    Gui, 1:Add, Edit, x140 y192 w80 vms, %ms%
    Gui, 1:Add, Edit, x140 y218 w80 vas, %as%
    Gui, 1:Add, Edit, x290 y30 w80 vphone, %phone%
    phone_TT := "Your Phone number for your character"
    Gui, 1:Add, Checkbox, x100 y470 vtestmode, Enable TestMode? Default, works in-game and notepad.
    Gui, 1:Add, Button, x280 y490 w80 gSave1, Save
    Gui, 1:Show,, Making the world a better place
    OnMessage(0x200, "WM_MOUSEMOVE")
    Gosub, ReadConfiguration ; Load configuration previously saved.
    Return

    GuiEscape: ; Hitting escape key while open
    GuiClose: ; Hitting the X while open
    ; MsgBox Nope lol
    Gui, 1:Cancel
    Return

    Save1:
    Gui, 1:Submit
    ; IniWrite, value, filename, section, key
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
    IniWrite, %as%, %config%, Server, as
    ; Police related section
    medicalmsg = Hello I am ^1%title% %name% %department%^0, Please use this time to perform the medical activities required for the wounds you have received.  Using ^1/do's ^0and ^1/me's ^0to simulate your actions and the Medical staff actions. -Once completed. Use ^1/do Medical staff waves the %title% in^0.
    IniWrite, %medicalmsg%, %config%, Police, medicalmsg
    IniRead, medicalmsg, %config%, Police, medicalmsg, Hello I am ^1%title% %name% %department%^0, Please use this time to perform the medical activities required for the wounds you have received.  Using ^1/do's ^0and ^1/me's ^0to simulate your actions and the Medical staff actions. -Once completed. Use ^1/do Medical staff waves the %title% in^0.
    ; Return

    ; ============================================ CUSTOM MSGS GUI ============================================
    ; Gui for all of the customized messages to display in-game
    Gui, 2:Destroy
    Gui, 2:Font,, Consolas
    if (rolepick = "LEO") {
        Gui, 2:Add, tab3,, LEO|Help
    }
    Gui, 2:Add, Text,, %helptext2%
    Gui, 2:Add, Text,r2 w100, tdutystartmsg1:
    Gui, 2:Add, Text,r2, tdutystartmsg2:
    Gui, 2:Add, Text,, tdutystartmsg3:
    Gui, 2:Add, Text,r2, tfriskmsg:
    Gui, 2:Add, Text,r2, tsearchmsg:
    Gui, 2:Add, Text,r4, tmedicalmsg:
    Gui, 2:Add, Text,, Spikes:
    Gui, 2:Add, Text,, Vehicle Image Search:
    Gui, 2:Add, Edit, r2 vdutystartmsg1 w500 x115 y80, %dutystartmsg1%
    dutystartmsg1_TT := "Bodycam duty start message"
    Gui, 2:Add, Edit, r2 vdutystartmsg2 w500, %dutystartmsg2%
    dutystartmsg2_TT := "Dashcam duty start message"
    Gui, 2:Add, Edit, vdutystartmsg3 w500, %dutystartmsg3%
    dutystartmsg3_TT := "Log into the MWS/CAD"
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
    Gui, 2:Tab, Help,, Exact
    Gui, 2:Add, Text,r3 w100, tmicmsg:
    Gui, 2:Add, Text,r2, tpaystatemsg:
    Gui, 2:Add, Edit, r3 vmicmsg w500 x100 y30, %micmsg%
    micmsg_TT := "Message used to explain how to use/configure microphone"
    Gui, 2:Add, Edit, r2 vpaystatemsg w500, %paystatemsg%
    paystatemsg_TT := "Message used to explain how to handle state debt"
    Gui, 2:Tab
    Gui, 2:Add, Button, default w80 xm, OK  ; The label ButtonOK (if it exists) will be run when the button is pressed.
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
    Gui, 5:Add, Text, y10, Offender ID:
    Gui, 5:Add, Text, x190 y10, CautionCode:
    Gui, 5:Add, Edit, x85 y5 w60 voffenderid, 0
    Gui, 5:Add, DropDownList, x265 y5 w50 vcautioncode, |G|PH|V|ST|E|M
        cautioncode_TT :=
    (
"G = Gang Affiliated
PH = Police Hater
V = Violent
ST = Suicidal Tendancies - Approved by SAFR Only
E = Escape Risk
M = Mental Instability - Approved by SAFR Only"
    )
    Gui, 5:Add, Button, x320 y4 gcautioncode vcaucode, Set
    caucode_TT := "Setting {CautionCode} once will add it, setting the same caution code will removeit, they are toggled."
    Gui, 5:Add, Tab3, x10, Capital|Felony|Misdemeanor|Citation
    Gui, 5:Add, Edit, Readonly r3 w680 vcapitaltext, %capitaltext%
            Loop, read, %A_ScriptDir%\GLRP-Capital.csv
	{
	    StringSplit, val, A_LoopReadLine,`,
        c_LineNumber = %A_Index%
	    Loop,%Val0%
            cf_offense_%c_LineNumber% := val1
            cf_fine_%c_LineNumber% := val2
            cf_arrest_%c_LineNumber% := val3
            if (c_LineNumber == 20) {
                Gui, 5:Add, Button, x353 y112 gcapisub vcfBtn%c_LineNumber%, %val1%-%c_LineNumber%
            } else {
                Gui, 5:Add, Button, gcapisub vcfBtn%c_LineNumber%, %val1%-%c_LineNumber%
            }
	}
    Gui, 5:Tab, 2
    Gui, 5:Add, Edit, Readonly r3 w680 vfelonytext, %felonytext%
            Loop, read, %A_ScriptDir%\GLRP-Felony.csv
	{
	    StringSplit, val, A_LoopReadLine,`,
        c_LineNumber = %A_Index%
	    Loop,%Val0%
            f_offense_%c_LineNumber% := val1
            f_fine_%c_LineNumber% := val2
            f_arrest_%c_LineNumber% := val3
            if (c_LineNumber == 20) {
                Gui, 5:Add, Button, x353 y112 gfelosub vfBtn%c_LineNumber%, %val1%-%c_LineNumber%
            } else {
                Gui, 5:Add, Button, gfelosub vfBtn%c_LineNumber%, %val1%-%c_LineNumber%
            }
	}
    Gui, 5:Tab, 3
    Gui, 5:Add, Edit, Readonly r3 w680 vmisdemeanortext, %misdemeanortext%
        Loop, read, %A_ScriptDir%\GLRP-Misdemeanor.csv
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
    Gui, 5:Tab, 4
        Gui, 5:Add, Edit, Readonly r4 w680 vcitationtext, %citationtext%
    Loop, read, %A_ScriptDir%\GLRP-Citation.csv
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

    Gui, 5:Tab
    Gui, 5:Add, Edit, Readonly r5 w703 vpText
    pText_TT := "Use this section to copy the arrest/bill/ticket from, to enter into the game."
    Gui, 5:Add, Button, gcheck2 vsubmit, Submit
    Submit_TT := "Cleans out the record and updates the Charge Log file."
    Gui, 5:Add, Button, x60 y767 gwarrant vwarrant, ToWarrant
    warrant_TT := "Converts the charges to a Warrant format."
    Gui, 5:Add, Button, x150 y767 gcwarrant vcwarrant, ClearWarrant
    cwarrant_TT := "Provides command to wipe all warrants on a offender id."
    Gui, 5:Add, Button, x670 y767 gclear vclear, Clear
    Clear_TT := "Clears out all entries without saving them."
    Gui, 5:Show,, Citation | Misdemeanor | Felony | CautionCode - LEO Calculator
    OnMessage(0x200, "WM_MOUSEMOVE")
    lastEdit := ""
    Return

    5GuiEscape:
    5GuiClose:
    Gui, 5:Cancel
    Return
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

citsub:
gui,submit,nohide
RegExMatch(A_GuiControl, "\d+$", n)
if (n == 6 and InStr(PEdit,"Commercial Vehicle Fine")) {
    msgbox, Commercial Vehicle fine can not be by itself.
} else if (InStr(PEdit,"/bill")) {
    msgbox, Please Clean out the Misedeamnor or Felony before issuing a ticket.
} else if (n == 6) {
    offenseadd = % c_offense_%n%
    offense =  %offense% | %offenseadd%
    fine += % c_fine_%n%
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
return

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

capisub:
gui,submit,nohide
RegExMatch(A_GuiControl, "\d+$", n)
if (InStr(PEdit,"/ticket")) {
msgbox, You must Clear the Ticket before issuing Felony chargers.
} else if (offense) {
    offenseadd = % cf_offense_%n%
    offense = %offense% | %offenseadd%
    fine += % cf_fine_%n%
    arrest += % cf_arrest_%n%
    PEdit = 
    (
/arrest %offenderid% %arrest% | %offense% | (%name% - %department%)
/bill %offenderid% %fine% | %offense% | (%name% - %department%)
    )
} else {
    offense = % cf_offense_%n%
    fine = % cf_fine_%n%
    arrest = % cf_arrest_%n%
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
FormatTime, TimeString,, yyyyMMdd hh:mm:ss
FileAppend,
(
%TimeString%
%PEdit%
`n
), Charge_log.txt
lastEdit := A_ScriptDir "\Charge_log.txt Updated"
offense :=
fine :=
arrest :=
PEdit :=
guicontrol,,pText,% lastEdit
return

clear:
gui,submit,nohide ;updates gui variable
lastEdit := "Cleared Records"
offense :=
fine :=
arrest :=
PEdit :=
guicontrol,,pText,% lastEdit
return

^3::
    Reload
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
        InputBox, vehplate, VehPlate, Enter the plate you wish to lookup.
        if (vehplate = "") {
                ; MsgBox, No plate was entered, Try again.
        } else {
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            Clipboard = /runplate %vehplate%
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Clipboard = %vehplate%
        }
    }
    Return

    ; ncic to be ran and save the name you ran, also caches the name into clipboard
    ; ^=:: ; Control + =
    cphk:
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        InputBox, ncicname, NCICName, Enter the ID you wish to lookup.
        if (ncicname = "") {
                ; MsgBox, No name was entered, Try again.
        } else {
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            Clipboard = /ncic %ncicname%
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            ncicname := StrReplace(ncicname, "/", A_Space)
            Clipboard = %ncicname%
        }
    }
    Return

    ; This might actually work if you want to save the text that was typed
    ; ncic version 2 will actually be used to pull up the users information from text entry
    ^\:: ; Control + \
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || WinActive("*Untitled - Notepad") || (testmode = 1)) {
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        clipboard = /ncic
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{space}
        Input, ncicname, V T12 L40 C, {enter}.{esc}{tab},,
        ncicname := StrReplace(ncicname, "/", A_Space)
        if (ncicname = "") {
            msgbox, No name was entered, try again.
        } else {
            Sleep, %delay%
            clipboard = %ncicname%
        }
    }
    return

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
        Clipboard = /touchveh
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
        Clipboard = %ms% tears off the written impound sticker and places it on the vehicle
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
        clipboard = %clipaboard%
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
                Clipboard = %ms% grabs a few %titem% from the trunk
                ClipWait
            } else if (titem = "gsr") {
                Clipboard = %ms% grabs a %titem% kit from the trunk
                ClipWait
            } else {
                Clipboard = %ms% grabs a %titem% from the trunk
                ClipWait
            }
            Send, {Rctrl down}v{Rctrl up}{enter}
            If (titem = "medbag") {
                Sleep, %delay%
                Send, {t down}
                Sleep, %delay%
                Send, {t up}
                Sleep, %delay%
                Clipboard = /e %titem%
                ClipWait
                Send, {Rctrl down}v{Rctrl up}{enter}
            }
            Sleep, %delay%
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            Clipboard = /trunk
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            clipboard = %clipaboard%
        } else {
            Send, {enter}
            MsgBox, That %titem% is not in your trunk. Try again.
        }
    }
    Return
    ; ============================================ HELP Stuff ============================================
#IF
; This provides the help text for micropohone fixing
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

; This provides help text for the paying of state debt
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
Return

fuckakey:
    hotkey, %spikeshk%, sphk, Off
    hotkey, %vehimgsearchhk%, vehimghk, Off
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
    IniWrite, %as%, %config%, Server, as
    ; The hotkey related section
    IniWrite, %spikeshk%, %config%, Keys, spikeshk
    IniWrite, %vehimgsearchhk%, %config%, Keys, vehimgsearchhk
    ; Messages that correspond with the hotkeys
    ; Police related section
    IniWrite, %dutystartmsg1%, %config%, Police, dutystartmsg1
    IniWrite, %dutystartmsg2%, %config%, Police, dutystartmsg2
    IniWrite, %dutystartmsg3%, %config%, Police, dutystartmsg3
    IniWrite, %friskmsg%, %config%, Police, friskmsg
    IniWrite, %searchmsg%, %config%, Police, searchmsg
    IniWrite, %medicalmsg%, %config%, Police, medicalmsg
    ; Help related section
    IniWrite, %micmsg%, %config%, Help, micmsg
    IniWrite, %paystatemsg%, %config%, Help, paystatemsg
; ============================================ READ INI SECTION ============================================
    ; Back to the reading of the configuration
    IniRead, rolepick, %config%, Yourself, role, LEO
    IniRead, callsign, %config%, Yourself, callsign, D6
    IniRead, name, %config%, Yourself, name, Dread
    IniRead, title, %config%, Yourself, title, Deputy
    IniRead, department, %config%, Yourself, department, BCSO
    IniRead, phone, %config%, Yourself, phone, 00030
    ; Client communication and test mode
    IniRead, delay, %config%, Yourself, delay, 80
    IniRead, testmode, %config%, Yourself, testmode, 0
    ; Server related section
    IniRead, ms, %config%, Server, ms, /me
    IniRead, as, %config%, Server, as, /ad
    ; The hotkey related section
    IniRead, spikeshk, %config%, Keys, spikeshk, ^.
    IniRead, vehimgsearchhk, %config%, Keys, vehimgsearchhk, ^/
    ; Messages that correspond with the hotkeys
    ; Police related section
    IniRead, dutystartmsg1, %config%, Police, dutystartmsg1, %ms% secures the bodycam to the chest and then turns it on and validates that it is recording and listening.
    IniRead, dutystartmsg2, %config%, Police, dutystartmsg2, %ms% Validates that the Dashcam is functional in both audio and video.
    IniRead, dutystartmsg3, %config%, Police, dutystartmsg3, %ms% Logs into the MWS computer.
    IniRead, friskmsg, %config%, Police, friskmsg, %ms% Frisks the Subject looking for any weapons and removes ^1ALLLL ^0of them
    IniRead, searchmsg, %config%, Police, searchmsg, %ms% Searches the Subject completely and stows ^1ALLLL ^0items into the evidence bags
    IniRead, medicalmsg, %config%, Police, medicalmsg, Hello I am ^1%title% %name% %department%^0, Please use this time to perform the medical activities required for the wounds you have received.  Using ^1/do's ^0and ^1/me's ^0to simulate your actions and the Medical staff actions. -Once completed. Use ^1/do Medical staff waves the %title% in^0.
    ; Help related section
    IniRead, micmsg, %config%, Help, micmsg, How to fix microphone - ESC -> Settings -> Voice Chat -> Toggle On/Off -> Increase Mic Volume and Mic Sensitivity -> Match audio devices to the one you are using.
    IniRead, paystatemsg, %config%, Help, paystatemsg, State debt is composed of your Medical and Civil bills.  To see how much you have, type ^1/paystate^0.  To pay.  Go to the Courthouse front door on ^2Power Street / Occupation Avenue^0 and then use ^2/payticket (TicketID)^0 to pay it.  ^8State Debt must be paid from your bank account
Return

/*
 * * * Compile_AHK SETTINGS BEGIN * * *
[AHK2EXE]
Exe_File=AHKGLRP.exe
[VERSION]
Set_Version_Info=1
File_Version=1
Internal_Name=AHKGLRP
Legal_Copyright=GNU General Public License 3.0
Original_Filename=AHKGLRP.exe
Product_Name=AHKGLRP
Product_Version=1
* * * Compile_AHK SETTINGS END * * *
*/