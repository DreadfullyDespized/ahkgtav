/**
 * =============================================================================================== *
 * @Author           : DreadfullyDespized (darkestdread@gmail.com)
 * @Script Name      : AHKGTAV - SOE Autohotkey doohicky
 * @Script Version   : 10.0.0
 * @Homepage         : https://evolpcgaming.com/forums/topic/15014-a-little-something-i-use-and-work-on/
 * @Creation Date    : 20180718
 * @Modification Date: 20190318
 * @Description      : Simple autohotkey script to be used with GTAV FiveM SoE.
 *                     Really just built around to automating repetitive RP related tasks.
 * -----------------------------------------------------------------------------------------------
 * @License          : Copyright ©2019-2019 DreadfullyDespized <GPLv3>
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
                    ,name           : "AHKGTAV"
                    ,version        : "10.0.0"
                    ,author         : "DreadfullyDespized"
                    ,email          : "darkestdread@gmail.com"
                    ,Homepage       : "https://evolpcgaming.com/forums/topic/15014-a-little-something-i-use-and-work-on/"
                    ,logfile        : "https://github.com/DreadfullyDespized/ahkgtav"
                    ,rfile          : "https://github.com/DreadfullyDespized/ahkgtav"
                    ,crtdate        : "20180718"
                    ,moddate        : "20190318"
                    ,conf           : "GTAV-Config.ini"}
; }

; update(10.0.0, "https://raw.githubusercontent.com/DreadfullyDespized/ahkgtav/master/Changelog.txt", "github", 13) 

/*
This has been disabled for the time being until I get more time to look at it and work on it.

if the version is in line 1 of the log file and your compiled script is in that url, lVersion is a variable containing a number that will be compared to the one in the log file.

note that my function is designed to open the file downloaded by default
so if the downloaded file is an archive it will be opened
if it is a script it will be run so as if it is an EXE file...
the best would be if the file being downloaded is an installer (or installer script) that will copy the necessary files/folders to the user automatically.
*/

; ============================================ SCRIPT AUTO UPDATER ============================================
update(lversion, logurl="", rfile="github", vline=13){
    global s_author=script.author, s_name=script.name
    Msgbox, 0x10
          , % "Error"
          , % "Author: " . script.author . "`n"
            . "Name: " . script.name . "`n"
            . "Version: " . script.version . "`n"
            . "Email: " . script.email
    
    `(rfile = "github") ? logurl := "https://www.github.com/" s_author "/" s_name "/raw/master/Changelog.txt"

    RunWait %ComSpec% /c "Ping -n 1 -w 3000 google.com",, Hide  ; Check if we are connected to the internet
    
    if connected := !ErrorLevel
    {
        msgbox, Connected
        ; This one actually worked and created the changelog file.
        UrlDownloadToFile, %logurl%, %a_temp%\Changelog.txt ; C:\Users\username\AppData\Local\Temp\logurl
        ; UrlDownloadToFile is being blocked at work
        if ErrorLevel
            msgbox, The file failed to download
        FileReadLine, logurl, %a_temp%\logurl, %vline%
        RegexMatch(logurl, "v(*)", Version)
        if (rfile = "github"){
            ; So far it is getting to this point at home
            msgbox, 0x10
                  , % "It got passsed the regex"
                  , % "Version: " . Version . "`n" ; Not getting anything from this one.
                  . "logurl: " . logurl . "`n"
                  . "Version1: " . Version1 . "`n" ; Not getting anything from this one.
                  . "lversion: " . lversion ; Not getting anything from this one.
            if (a_iscompiled)
                rfile := "https://github.com/downloads/" s_author "/" s_name "/" s_name "-" Version "-Compiled.zip"
            else 
                rfile := "https://github.com/" s_author "/" s_name "/zipball/" Version
        }
        if (Version1 > lversion){
            Msgbox, 68, % "New Update Available"
                      , % "There is a new update available for this application.`n"
                        . "Do you wish to upgrade to " Version "?"
                      , 10 ; 10s timeout
            IfMsgbox, Timeout
                return debug ? "* Update message timed out" : 1
            IfMsgbox, No
                return debug ? "* Update aborted by user" : 2
            FileSelectFile, lfile, S16, %a_temp%
            UrlDownloadToFile, %rfile%, %lfile%
            Msgbox, 64, % "Download Complete"
                      , % "To install the new version simply replace the old file with the one`n"
                      .   "that was downloaded.`n`n The application will exit now."
            Run, %lfile%
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
config = GTAV-Config.ini
; ============================================ INI READING ============================================
; Section to read in the configuration file if it exists
IfExist, %config%
{
    ; Cleanup some of the old ini configuration portions
    IniDelete, %config%, Yourself, rolepick
    IniDelete, %config%, Yourself, |LEO|TOW|CIV|SAFR|GEORGE
    IniDelete, %config%, Normal, val2hkmsg
}
; Back to the reading of the configuration
IniRead, rolepick, %config%, Yourself, role, LEO
IniRead, callsign, %config%, Yourself, callsign, A06
IniRead, myid, %config%, Yourself, myid, 1
IniRead, towcompany, %config%, Yourself, towcompany, skinnydick
IniRead, name, %config%, Yourself, name, Dread
IniRead, title, %config%, Yourself, title, Officer
IniRead, department, %config%, Yourself, department, LSPD
IniRead, phone, %config%, Yourself, phone, 38915
; Client communication and test mode
IniRead, delay, %config%, Yourself, delay, 150
IniRead, testmode, %config%, Yourself, testmode, 0
; Server related section
IniRead, rs, %config%, Server, rs, /r
IniRead, ca, %config%, Server, ca, /answer
IniRead, cs, %config%, Server, cs, /c
IniRead, ds, %config%, Server, ds, /do
IniRead, ms, %config%, Server, ms, /me
IniRead, as, %config%, Server, as, /ad
IniRead, los, %config%, Server, los, /l
; The hotkey related section
IniRead, spikeshk, %config%, Keys, spikeshk, ^.
IniRead, vehimgsearchhk, %config%, Keys, vehimgsearchhk, ^/
IniRead, runplatehk, %config%, Keys, runplatehk, ^-
IniRead, cpichk, %config%, Keys, cpichk, ^=
IniRead, 911respondhk, %config%, Keys, 911respondhk, ^9
IniRead, towcallhk, %config%, Keys, towcallhk, ^k
IniRead, towrespondhk, %config%, Keys, towrespondhk, ^j
IniRead, seatbelthk, %config%, Keys, seatbelthk, F1
IniRead, valet1hk, %config%, Keys, valet1hk, +F11
IniRead, valet2hk, %config%, Keys, valet2hk, F11
IniRead, phrechk, %config%, Keys, phrechk, F6
IniRead, robhk, %config%, Keys, robhk, ^r
; Messages that correspond with the hotkeys
; Police related section
IniRead, cuffmsg1, %config%, Police, cuffmsg1, %ds% pull out his hand cuffs to cuff the Subject
IniRead, cuffmsg2, %config%, Police, cuffmsg2, %ds% pulls out his keys to release the Subject from the cuffs
IniRead, 911msg, %config%, Police, 911msg, %cs% What is the nature of your emergency and the location?
IniRead, 311msg, %config%, Police, 311msg, %cs% What may I be able to assist you with today?
IniRead, dutystartmsg1, %config%, Police, dutystartmsg1, %ds% secures the bodycam to the chest and then turns it on and validates that it is recording and listening.
IniRead, dutystartmsg2, %config%, Police, dutystartmsg2, %ds% Validates that the Dashcam is functional in both audio and video.
IniRead, dutystartmsg3, %config%, Police, dutystartmsg3, %ds% Logs into the MWS computer.
IniRead, friskmsg, %config%, Police, friskmsg, %ds% Frisks the Subject looking for any weapons and removes ^1ALLLL ^0of them
IniRead, searchmsg, %config%, Police, searchmsg, %ds% Searches the Subject completely and stows ^1ALLLL ^0items into the evidence bags
IniRead, medicalmsg, %config%, Police, medicalmsg, %los% Hello I am ^1%title% %name% %department%^0, Please use this time to perform the medical activities required for the wounds you have received.  Using ^1/do's ^0and ^1/me's ^0to simulate your actions and the Medical staff actions. -Once completed. Use ^1/do Medical staff waves the Officer in^0.
IniRead, towmsg1, %config%, Police, towmsg1, %rs% [^1%callsign%^0] to [^3TOW^0]
; Towing related section
IniRead, towad, %config%, Towing, towad, %as% I work for [^3%towcompany%^0] and we do cool tow stuff that makes tows happy 555-%phone%!!
IniRead, tsend, %config%, Towing, tsend, %rs% [^3TOW%myid%^0] Send it!
IniRead, ttowmsg1, %config%, Towing, ttowmsg1, %ds% attaches the winch cable to the front of the vehicle
IniRead, ttowmsg2, %config%, Towing, ttowmsg2, %ds% attaches the winch cable to the rear of the vehicle
IniRead, tsecure1, %config%, Towing, tsecure1, %ds% secures the rear of the vehicle with extra tow straps
IniRead, tsecure2, %config%, Towing, tsecure2, %ds% secures the front of the vehicle with extra tow straps
IniRead, treleasemsg1, %config%, Towing, treleasemsg1, %ds% releases the extra tow cables from the rear and pulls the winch release lever
IniRead, treleasemsg2, %config%, Towing, treleasemsg2, %ds% releases the extra tow cables from the front and pulls the winch release lever
; Help related section
IniRead, micmsg, %config%, Help, micmsg, %los% How to fix microphone - ESC -> Settings -> Voice Chat -> Toggle On/Off -> Increase Mic Volume and Mic Sensitivity -> Match audio devices to the one you are using.
IniRead, paystatemsg, %config%, Help, paystatemsg, %los% State Debt is from medical/legal bills.  If you have any it takes 50`% of your wages.  To be able to see your current state debt type "/paystate" to pay off state debt "/paystate amount".
; Normal related section
IniRead, gunmsg, %config%, Normal, gunmsg, %ds% pulls out his ^1pistol ^0from under his shirt
IniRead, valet2hkmsg, %config%, Normal, valet2hkmsg, %ms% puts in his ticket into the valet and presses the button to receive his selected vehicle
IniRead, phrechkmsg, %config%, Normal, phrechkmsg, %ds% Pulls out their phone and starts recording audio and video
IniRead, robhkmsg, %config%, Normal, robhkmsg, %ms% takes the persons phone`, weapons`, and any cash on them
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
tcuff - cuff
tuncuff - uncuff
t911 - answer 911
t311 - answer 311
tfrisk - frisks subject
tsearch - searches subject
tmedical - medical rp message
tbodybag - get local to bodybag
timpound - place impound sticker
tplate - notes the plate
tvin = notes the vin
ttrunk - get itmes from trunk (medbag|slimjim|tintmeter|cones|gsr|breathalizer|bodybag)

Control+. - spikes/rspikes
Control+/ - vehicle image search (uses google)
Control+- - runs plate along with saving plate on clipboard
Control+= - cpic name along with saving name on clipboard
Control+9 - 911 units on the way
Control+K - call for tow over radio
Control+J - tell tow whats going on

Tow Commands:
-----------------------
towad - display your towing advertisement
tstart - start tow shift/company
tsend - initial send it
tonway - showing 76 to them
ttow - towing system
tsecure - secures tow straps
trelease - releases tow straps
tkitty - grabs kitty litter from truck

Help Commands:
--------------------
tmic = help text about fixing mic
tpaystate = help text about paying state

General Commands:
---------------------------
tgun - use firearm
tscrap - rp the scrap to truck
F1 - enables/disables seatbelt
Shift+F11 - valet phone check
F11 - Pull vehicle out from valet
F6 - Pull out phone to record
Control+R - Rob Bystander
)

helptext2 = 
(
If you wish to change any of the hotkeys.
This is the section to do so. Click on the box and then
hit the keys together to configure the hotkey.
)

; ============================================ CUSTOM SYSTEM TRAY ============================================
; Removes all of the standard options from the system tray
Menu, Tray, NoStandard
Menu, Tray, Add, &Reconfigure/Help, ^1
Menu, Tray, Add, GTAV &Car Search, vehimghk
Menu, Tray, Add, E&xit,Exit

#z::Menu, Tray, Show

Exit:
ExitApp
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

; Configure Variables to be used
; Do not touch or change this section
spikes = 0
towtype = f
stopped = 0

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
    Gui, 1:Add, Text,, MyID:
    Gui, 1:Add, Text,, TowCompany:
    Gui, 1:Add, Text,, Name:
    Gui, 1:Add, Text,, Title:
    Gui, 1:Add, Text,, Department:
    Gui, 1:Add, Text,, ms Delay:
    Gui, 1:Add, Text,, The following should only be modified if playing on a different server.
    Gui, 1:Add, Text,, Radio:
    Gui, 1:Add, Text,, CallAnswer:
    Gui, 1:Add, Text,, CallReply:
    Gui, 1:Add, Text,, Third Party Action:
    Gui, 1:Add, Text,, First Party Action:
    Gui, 1:Add, Text,, Advertisement:
    Gui, 1:Add, Text,, Local OOC:
    Gui, 1:Add, Text, x210 y34, Phone Number:
    Gui, 1:Add, DropDownList, x100 y30 w80 vrolepick, |LEO|TOW|CIV|SAFR|GEORGE
    rolepick_TT := "Select the character role that you will be playing as"
    Gui, 1:Add, Edit, w80 vcallsign, %callsign%
    callsign_TT := "Callsign for your LEO/EMS character"
    Gui, 1:Add, Edit, w80 vmyid, %myid%
    myid_TT := "Your Train Ticket ID"
    Gui, 1:Add, Edit, w80 vtowcompany, %towcompany%
    towcompany_TT := "Towing company you work for. Name for /clockin command"
    Gui, 1:Add, Edit, w80 vname, %name%
    name_TT := "Last Name of your character"
    Gui, 1:Add, Edit, w80 vtitle, %title%
    title_TT := "Title of your character"
    Gui, 1:Add, Edit, w80 vdepartment, %department%
    department_TT := "Department that your character works for"
    Gui, 1:Add, Edit, w80 vdelay, %delay%
    delay_TT := "milisecond delay.  Take your ping to the server x2"
    Gui, 1:Add, Edit, x150 y272 w80 vrs, %rs%
    Gui, 1:Add, Edit, w80 vca, %ca%
    Gui, 1:Add, Edit, w80 vcs, %cs%
    Gui, 1:Add, Edit, w80 vds, %ds%
    Gui, 1:Add, Edit, w80 vms, %ms%
    Gui, 1:Add, Edit, w80 vas, %as%
    Gui, 1:Add, Edit, w80 vlos, %los%
    Gui, 1:Add, Edit, x290 y30 w80 vphone, %phone%
    phone_TT := "Last 5 of your current characters phone number"
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
    IniWrite, %ca%, %config%, Server, ca
    IniWrite, %cs%, %config%, Server, cs
    IniWrite, %ds%, %config%, Server, ds
    IniWrite, %ms%, %config%, Server, ms
    IniWrite, %as%, %config%, Server, as
    IniWrite, %los%, %config%, Server, los
    ; Return

    ; ============================================ CUSTOM MSGS GUI ============================================
    ; Gui for all of the customized messages to display in-game
    Gui, 2:Destroy
    Gui, 2:Font,, Consolas
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
    Gui, 2:Add, Text, w100, tcuffmsg1:
    Gui, 2:Add, Text,, tcuffmsg2:
    Gui, 2:Add, Text,, t911msg:
    Gui, 2:Add, Text,, t311msg:
    Gui, 2:Add, Text,r2, tdutystartmsg1:
    Gui, 2:Add, Text,r2, tdutystartmsg2:
    Gui, 2:Add, Text,, tdutystartmsg3:
    Gui, 2:Add, Text,, towmsg1:
    Gui, 2:Add, Text,r2, tfriskmsg:
    Gui, 2:Add, Text,r2, tsearchmsg:
    Gui, 2:Add, Text,r4, tmedicalmsg:
    Gui, 2:Add, Text,, Spikes:
    Gui, 2:Add, Text,, Vehicle Image Search:
    Gui, 2:Add, Text,, RunPlate:
    Gui, 2:Add, Text,, CPIC:
    Gui, 2:Add, Text,x350 y475, 911 Responding:
    Gui, 2:Add, Text,, Tow Initiate:
    Gui, 2:Add, Text,, Tow Information:
    Gui, 2:Add, Edit, r1 vcuffmsg1 w500 x115 y80, %cuffmsg1% ; The ym option starts a new column of controls.
    cuffmsg1_TT := "Displayed message for putting someone in cuffs"
    Gui, 2:Add, Edit, r1 vcuffmsg2 w500, %cuffmsg2%
    cuffmsg2_TT := "Displayed message for taking someone out of cuffs"
    Gui, 2:Add, Edit, r1 v911msg w500, %911msg%
    911msg_TT := "Initial response message when answering 911"
    Gui, 2:Add, Edit, r1 v311msg w500, %311msg%
    311msg_TT := "Initial response message when answering 311"
    Gui, 2:Add, Edit, r2 vdutystartmsg1 w500, %dutystartmsg1%
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
    Gui, 2:Add, Hotkey, w150 x150 y470 vspikeshk, %spikeshk%
    spikeshk_TT := "Hotkey to be used to deploy/remove spike strip"
    Gui, 2:Add, Hotkey, w150 vvehimgsearchhk, %vehimgsearchhk%
    vehimgsearchhk_TT := "Hotkey to search for a vehicle's image on google"
    Gui, 2:Add, Hotkey, w150 vrunplatehk, %runplatehk%
    runplatehk_TT := "Hotkey to run a plate and keep it on clipboard"
    Gui, 2:Add, Hotkey, w150 vcpichk, %cpichk%
    cpichk_TT := "Hotkey to cpic a name and keep name on clipboard"
    Gui, 2:Add, Hotkey, w150 x450 y470 v911respondhk, %911respondhk%
    911respondhk_TT := "Hotkey to tell the 911/311 that units are on the way"
    Gui, 2:Add, Hotkey, w150 vtowcallhk, %towcallhk%
    towcallhk_TT := "Initiates the request for a tow truck"
    Gui, 2:Add, Hotkey, w150 vtowrespondhk, %towrespondhk%
    towrespondhk_TT := "Lets the tow truck know where you are and what you want them to tow"
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
    Gui, 2:Add, Text,r3 w100, towad:
    Gui, 2:Add, Text,r1, tsend:
    Gui, 2:Add, Text,r2, ttowmsg1:
    Gui, 2:Add, Text,r2, ttowmsg2:
    Gui, 2:Add, Text,r2, tsecure1:
    Gui, 2:Add, Text,r2, tsecure2:
    Gui, 2:Add, Text,r2, treleasemsg1:
    Gui, 2:Add, Text,r2, treleasemsg2:
    Gui, 2:Add, Edit, r3 vtowad w500 x100 y30, %towad%
    towad_TT := "Advertisement you use for your tow company"
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
    Gui, 2:Add, Text,r1 w100, SAFR Placeholder - ideas certainly welcome :P
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
    Gui, 2:Add, Text, w150, robhkmsg:
    Gui, 2:Add, Text,, Robbery Hotkey:
    Gui, 2:Add, Edit, r1 vrobhkmsg w500 x80 y30, %robhkmsg%
    robhkmsg_TT := "Action to be used to rob someone"
    Gui, 2:Add, Hotkey, w150 x120 y56 vrobhk, %robhk%
    robhk_TT := "Hotkey to be used to rob someone"
    Gui, 2:Tab, Help,, Exact
    Gui, 2:Add, Text,r3 w100, tmicmsg:
    Gui, 2:Add, Text,r2, tpaystatemsg:
    Gui, 2:Add, Edit, r3 vmicmsg w500 x100 y30, %micmsg%
    micmsg_TT := "Message used to explain how to use/configure microphone"
    Gui, 2:Add, Edit, r2 vpaystatemsg w500, %paystatemsg%
    paystatemsg_TT := "Message used to explain how to handle state debt"
    Gui, 2:Tab, General,, Exact
    Gui, 2:Add, Text, w150, tgunmsg:
    Gui, 2:Add, Text, r2 w150, valet2hkmsg:
    Gui, 2:Add, Text, w150, phrechkmsg:
    Gui, 2:Add, Text, w150 y200 x20, Seatbelt Hotkey:
    Gui, 2:Add, Text,, Valet App Hotkey:
    Gui, 2:Add, Text,, Valet Call Hotkey:
    Gui, 2:Add, Text,, Phone Record Hotkey:
    Gui, 2:Add, Edit, r1 vgunmsg w500 x100 y30, %gunmsg%
    gunmsg_TT := "Action message to draw a firearm"
    Gui, 2:Add, Edit, r2 vvalet2hkmsg w500, %valet2hkmsg%
    valet2hkmsg_TT := "Action to be used to pull out a vehicle from the valet"
    Gui, 2:Add, Edit, r1 vphrechkmsg w500, %phrechkmsg%
    phrechkmsg_TT := "Action message to be used when pulling out phone to record"
    Gui, 2:Add, Hotkey, w150 x150 y195 vseatbelthk, %seatbelthk%
    seatbelthk_TT := "Hotkey to be used to put on or take off seatbelt"
    Gui, 2:Add, Hotkey, w150 vvalet1hk, %valet1hk%
    valet1hk_TT := "Hotkey to use your phone valet app"
    Gui, 2:Add, Hotkey, w150 vvalet2hk, %valet2hk%
    valet2hk_TT := "Hotkey to call for the valet to get your vehicle"
    Gui, 2:Add, Hotkey, w150 vphrechk, %phrechk%
    phrechk_TT := "Hotkey to start recording with your phone"
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

; not used on SoE - F1 F4 F5 F6 F7 F10 F11
; Pressing T to open chat and then typing unrack/rack

; ============================================ LEO Stuff ============================================
#if (rolepick = "LEO")
    ; This will lay the spikes or remove the spikes based on variable.
    ;  ^.:: ; Control + . in-game
    sphk:
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        if (spikes = 0) {
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            Clipboard = /spikes
            ClipWait
            Send, {RCtrl down}v{RCtrl up}{enter}
            spikes = 1
        } else {
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            Clipboard = /rspikes
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            spikes = 0
        }
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; This will cuff someone
    :*:tcuff:: ; Type tcuff in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %cuffmsg1%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /cuff
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; This will uncuff someone
    :*:tuncuff:: ; Type tuncuff in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %cuffmsg2%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /uncuff
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Initiate a 911 call answer.
    :*:t911:: ; Type t911 in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %ca%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Sleep, %delay%
        Clipboard = %911msg%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Initiate a 311 call answer.
    :*:t311:: ; Type t311 in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %ca%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Sleep, %delay%
        Clipboard = %311msg%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Notifies caller help is on the way.
    ; ^9:: ; Control + 9
    91rhk:
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %cs% Units will be on the way to your location.
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Runplate to be ran and save the plate you ran, also caches the name into clipboard
    ; ^-:: ; Control + -
    rphk:
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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

    ; Cpic to be ran and save the name you ran, also caches the name into clipboard
    ; ^=:: ; Control + =
    cphk:
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        InputBox, cpicname, CpicName, Enter the name you wish to lookup. first/last.
        if (cpicname = "") {
                ; MsgBox, No name was entered, Try again.
        } else {
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            Clipboard = /cpic %cpicname%
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            cpicname := StrReplace(cpicname, "/", A_Space)
            Clipboard = %cpicname%
        }
    }
    Return

    ; This might actually work if you want to save the text that was typed
    ; Cpic version 2 will actually be used to pull up the users information from text entry
    ^\:: ; Control + \
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        clipboard = /cpic
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{space}
        Input, cpicname, V T12 L40 C, {enter}.{esc}{tab},,
        cpicname := StrReplace(cpicname, "/", A_Space)
        if (cpicname = "") {
            msgbox, No name was entered, try again.
        } else {
            Sleep, %delay%
            clipboard = %cpicname%
        }
    }
    return

    ; This will be used to set your callsign for the environment.
    :*:tdutystart:: ; Type tdutystart in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        if (!callsign) {
            InputBox, callsign, CallSign, Enter your callsign to use.
        }
        if (!name) {
            Inputbox, name, Name, Enter your name to use.
        }
        clipaboard = %clipboard%
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %medicalmsg%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Used to hadndle putting someone in a bodybag (locals).
    ; :*:tbodybag:: ; Type tbodybag in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
        Clipboard = %ds% places bodybag down near the body
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = /place bodybag
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %ds% slowly slides the body into the bodybag
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        Send, {t down}
        Sleep, %delay%
        Send, {t up}
        Sleep, %delay%
        Clipboard = %ds% The Coroner comes by and picks up the body bag
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return

    ; Test running through timing.
    :*:ttest:: ; Type ttest in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = /e notepad2
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
        clipboard = %clipaboard%
    }
    Return

    ; Items that can be pulled out from the trunk of a vehicle.
    :*:ttrunk:: ; Type ttrunk in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        InputBox, titem, Trunk Item, What do you want from your trunk?
        if ErrorLevel
            Return
        else
        if (titem = "medbag" || titem = "slimjim" || titem = "tintmeter" || titem = "cones" || titem = "gsr" || titem = "breathalizer" || titem = "bodybag") {
            clipaboard = %clipboard%
            Sleep, %delay%
            Clipboard = /car t open
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            if (titem = "cones") {
                Clipboard = %ds% grabs a few %titem% from the trunk
                ClipWait
            } else if (titem = "gsr") {
                Clipboard = %ds% grabs a %titem% kit from the trunk
                ClipWait
            } else {
                Clipboard = %ds% grabs a %titem% from the trunk
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
            Clipboard = /car t
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
    ; ============================================ CIV Stuff ============================================
#If (rolepick = "CIV")
    ; Proper way to pull out a firearm.
    :*:tgun:: ; Type tgun in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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

    :*:towad:: ; Type towad in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        clipaboard = %clipboard%
        Sleep, %delay%
        Clipboard = %towad%
        ClipWait
        Send, {Rctrl down}v{Rctrl up}{enter}
        Sleep, %delay%
        clipboard = %clipaboard%
    }
    Return


    :*:tsend:: ; Type tsend in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        vehicle = bus
        Inputbox, bside, Choose your side!, Which side of the %vehicle% are you on? Use l or r for left or right.
        if  (bside = "l" || bside = "r") {
            InputBox, bitem, Item, What do you want to get from your %vehicle%?
            if ErrorLevel
                Return
            else
                if (bitem = "medbag" || bitem = "cones" || bitem = "bodybag") {
                    clipaboard = %clipboard%
                    Sleep, %delay%
                    Clipboard = /car b%bside% open
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
                    Clipboard = /car b%bside%
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
    ; ============================================ GEORGE Stuff ============================================
#If (rolepick = "GEORGE")
    ; Mainly used for George's scrap collecting.
    :*:tscrap:: ; Type tscrap in-game
    if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
        InputBox, scrapside, Facing Direction, Type l or r side.
        if (scrapside="l" || scrapside="r") {
            clipaboard = %clipboard%
            Sleep, %delay%
            Clipboard = %ds% unties one of the bailing wires on the %scrapside% side and then stashes some of the items he found on the bed
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            Send, {t down}
            Sleep, %delay%
            Send, {t up}
            Sleep, %delay%
            Clipboard = %ds% Secures the items and then pulls the bailing wire to the %scrapside% side. Then ties it back up.
            ClipWait
            Send, {Rctrl down}v{Rctrl up}{enter}
            Sleep, %delay%
            clipboard = %clipaboard%
        } else {
            MsgBox, Left or Right only. Try again.
        }
    }
    Return
    ; ============================================ HELP Stuff ============================================
#IF
; This provides the help text for micropohone fixing
:*:tmic:: ; Type tmic in-game
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Clipboard = %paystatemsg%
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    clipboard = %clipaboard%
}
Return

; This is a quick way of buckling or unbuckling your seatbelt
; F1:: ; Press F1 in-game
sbhk:
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Send, {t down}
    Sleep, %delay%
    Send, {t up}
    Sleep, %delay%
    clipboard = /seatbelt
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    clipboard = %clipaboard%
}
Return

; This is the ability to check your valet on the phone
; +F11:: ; Press Shift+F11 in-game
val1hk:
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
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

; This will be used to rob someone and strip them of everything
; ^r:: ; Press Control+R in-game
rbhk:
if (WinActive("FiveM") || WinActive("Untitled - Notepad") || (testmode = 1)) {
    clipaboard = %clipboard%
    Sleep, %delay%
    Send, {t down}
    Sleep, %delay%
    Send, {t up}
    Sleep, %delay%
    clipboard = %robhkmsg%
    ClipWait
    Send, {Rctrl down}v{Rctrl up}{enter}
    Sleep, %delay%
    Send, {t down}
    Sleep, %delay%
    Send, {t up}
    Sleep, %delay%
    clipboard = /stealcash
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
    hotkey, %cpichk%, cphk, On
    hotkey, %911respondhk%, 91rhk, On
    hotkey, %towcallhk%, tchk, On
    hotkey, %towrespondhk%, trhk, On
    hotkey, %seatbelthk%, sbhk, On
    hotkey, %valet1hk%, val1hk, On
    hotkey, %valet2hk%, val2hk, On
    hotkey, %phrechk%, phrhk, On
    hotkey, %robhk%, rbhk, On
Return

fuckakey:
    hotkey, %spikeshk%, sphk, Off
    hotkey, %vehimgsearchhk%, vehimghk, Off
    hotkey, %runplatehk%, rphk, Off
    hotkey, %cpichk%, cphk, Off
    hotkey, %911respondhk%, 91rhk, Off
    hotkey, %towcallhk%, tchk, Off
    hotkey, %towrespondhk%, trhk, Off
    hotkey, %seatbelthk%, sbhk, Off
    hotkey, %valet1hk%, val1hk, Off
    hotkey, %valet2hk%, val2hk, Off
    hotkey, %phrechk%, phrhk, Off
    hotkey, %robhk%, rbhk, Off
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
    IniWrite, %ca%, %config%, Server, ca
    IniWrite, %cs%, %config%, Server, cs
    IniWrite, %ds%, %config%, Server, ds
    IniWrite, %ms%, %config%, Server, ms
    IniWrite, %as%, %config%, Server, as
    IniWrite, %los%, %config%, Server, los
    ; The hotkey related section
    IniWrite, %spikeshk%, %config%, Keys, spikeshk
    IniWrite, %vehimgsearchhk%, %config%, Keys, vehimgsearchhk
    IniWrite, %runplatehk%, %config%, Keys, runplatehk
    IniWrite, %cpichk%, %config%, Keys, cpichk
    IniWrite, %911respondhk%, %config%, Keys, 911respondhk
    IniWrite, %towcallhk%, %config%, Keys, towcallhk
    IniWrite, %towrespondhk%, %config%, Keys, towrespondhk
    IniWrite, %seatbelthk%, %config%, Keys, seatbelthk
    IniWrite, %valet1hk%, %config%, Keys, valet1hk
    IniWrite, %valet2hk%, %config%, Keys, valet2hk
    IniWrite, %phrechk%, %config%, Keys, phrechk
    IniWrite, %robhk%, %config%, Keys, robhk
    ; Messages that correspond with the hotkeys
    ; Police related section
    IniWrite, %cuffmsg1%, %config%, Police, cuffmsg1
    IniWrite, %cuffmsg2%, %config%, Police, cuffmsg2
    IniWrite, %911msg%, %config%, Police, 911msg
    IniWrite, %311msg%, %config%, Police, 311msg
    IniWrite, %dutystartmsg1%, %config%, Police, dutystartmsg1
    IniWrite, %dutystartmsg2%, %config%, Police, dutystartmsg2
    IniWrite, %dutystartmsg3%, %config%, Police, dutystartmsg3
    IniWrite, %friskmsg%, %config%, Police, friskmsg
    IniWrite, %searchmsg%, %config%, Police, searchmsg
    IniWrite, %medicalmsg%, %config%, Police, medicalmsg
    IniWrite, %towmsg1%, %config%, Police, towmsg1
    ; Towing related section
    IniWrite, %towad%, %config%, Towing, towad
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
    IniWrite, %robhkmsg%, %config%, Normal, robhkmsg
; ============================================ READ INI SECTION ============================================
    ; Re-reads all of the configuration information to validate
    IniRead, rolepick, %config%, Yourself, role, LEO
    IniRead, callsign, %config%, Yourself, callsign, A06
    IniRead, myid, %config%, Yourself, myid, 1
    IniRead, towcompany, %config%, Yourself, towcompany, skinnydick
    IniRead, name, %config%, Yourself, name, Dread
    IniRead, title, %config%, Yourself, title, Officer
    IniRead, department, %config%, Yourself, department, LSPD
    IniRead, phone, %config%, Yourself, phone, 38915
    ; Client communication and test mode
    IniRead, delay, %config%, Yourself, delay, 150
    IniRead, testmode, %config%, Yourself, testmode, 0
    ; Server related section
    IniRead, rs, %config%, Server, rs, /r
    IniRead, ca, %config%, Server, ca, /answer
    IniRead, cs, %config%, Server, cs, /c
    IniRead, ds, %config%, Server, ds, /do
    IniRead, ms, %config%, Server, ms, /me
    IniRead, as, %config%, Server, as, /ad
    IniRead, los, %config%, Server, los, /l
    ; The hotkey related section
    IniRead, spikeshk, %config%, Keys, spikeshk, ^.
    IniRead, vehimgsearchhk, %config%, Keys, vehimgsearchhk, ^/
    IniRead, runplatehk, %config%, Keys, runplatehk, ^-
    IniRead, cpichk, %config%, Keys, cpichk, ^=
    IniRead, 911respondhk, %config%, Keys, 911respondhk, ^9
    IniRead, towcallhk, %config%, Keys, towcallhk, ^k
    IniRead, towrespondhk, %config%, Keys, towrespondhk, ^j
    IniRead, seatbelthk, %config%, Keys, seatbelthk, F1
    IniRead, valet1hk, %config%, Keys, valet1hk, +F11
    IniRead, valet2hk, %config%, Keys, valet2hk, F11
    IniRead, phrechk, %config%, Keys, phrechk, F6
    IniRead, robhk, %config%, Keys, robhk, ^r
    ; Messages that correspond with the hotkeys
    ; Police related section
    IniRead, cuffmsg1, %config%, Police, cuffmsg1, /do pull out his hand cuffs to cuff the Subject
    IniRead, cuffmsg2, %config%, Police, cuffmsg2, /do pulls out his keys to release the Subject from the cuffs
    IniRead, 911msg, %config%, Police, 911msg, /c What is the nature of your emergency and the location?
    IniRead, 311msg, %config%, Police, 311msg, /c What may I be able to assist you with today?
    IniRead, dutystartmsg1, %config%, Police, dutystartmsg1, /do secures the bodycam to the chest and then turns it on and validates that it is recording and listening.
    IniRead, dutystartmsg2, %config%, Police, dutystartmsg2, /do Validates that the Dashcam is functional in both audio and video.
    IniRead, dutystartmsg3, %config%, Police, dutystartmsg3, /do Logs into the MWS computer.
    IniRead, friskmsg, %config%, Police, friskmsg, /do Frisks the Subject looking for any weapons and removes ^1ALLLL ^0of them
    IniRead, searchmsg, %config%, Police, searchmsg, /do Searches the Subject completely and stows ^1ALLLL ^0items into the evidence bags
    IniRead, medicalmsg, %config%, Police, medicalmsg, /l Hello I am ^1Officer Dread LSPD^0, Please use this time to perform the medical activities required for the wounds you have received.  Using ^1/do's ^0and ^1/me's ^0to simulate your actions and the Medical staff actions. -Once completed. Use ^1/do Medical staff waves the Officer in^0.
    IniRead, towmsg1, %config%, Police, towmsg1, /r [^1A06^0] to [^3TOW^0]
    ; Towing related section
    IniRead, towad, %config%, Towing, towad, /ad I work for [^3skinnydick^0] and we do cool tow stuff that makes tows happy 555-99999!!
    IniRead, tsend, %config%, Towing, tsend, /r [^3TOW1^0] Send it
    IniRead, ttowmsg1, %config%, Towing, ttowmsg1, /do attaches the winch cable to the front of the vehicle
    IniRead, ttowmsg2, %config%, Towing, ttowmsg2, /do attaches the winch cable to the rear of the vehicle
    IniRead, tsecure1, %config%, Towing, tsecure1, /do secures the rear of the vehicle with extra tow straps
    IniRead, tsecure2, %config%, Towing, tsecure2, /do secures the front of the vehicle with extra tow straps
    IniRead, treleasemsg1, %config%, Towing, treleasemsg1, /do releases the extra tow cables from the rear and pulls the winch release lever
    IniRead, treleasemsg2, %config%, Towing, treleasemsg2, /do releases the extra tow cables from the front and pulls the winch release lever
    ; Help related section
    IniRead, micmsg, %config%, Help, micmsg, /l How to fix microphone - ESC -> Settings -> Voice Chat -> Toggle On/Off -> Increase Mic Volume and Mic Sensitivity -> Match aduio devices to the one you are using.
    IniRead, paystatemsg, %config%, Help, paystatemsg, /l To be able to see your current state debt type "/paystate" to pay off state debt "/paystate amount".
    ; Normal related section
    IniRead, gunmsg, %config%, Normal, gunmsg, /do pulls out his ^1pistol ^0from under his shirt
    IniRead, valet2hkmsg, %config%, Normal, valet2hkmsg, /me puts in his ticket into the valet and presses the button to receive his selected vehicle
    IniRead, phrechkmsg, %config%, Normal, phrechkmsg, /do Pulls out their phone and starts recording audio and video
    IniRead, robhkmsg, %config%, Normal, robhkmsg, /me takes the persons phone`, weapons`, and any cash on them
Return

/*
 * * * Compile_AHK SETTINGS BEGIN * * *
[AHK2EXE]
Exe_File=AHKGTAV.exe
[VERSION]
Set_Version_Info=1
File_Version=9.0.0
Internal_Name=AHKGTAV
Legal_Copyright=GNU General Public License 3.0
Original_Filename=AHKGTAV.exe
Product_Name=AHKGTAV
Product_Version=9.0.0
* * * Compile_AHK SETTINGS END * * *
*/