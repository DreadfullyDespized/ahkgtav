#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

file = %A_ScriptDir%\Configuration.ini
Gui, Add, Text, x11 y84 w50 h20 BackgroundTrans, Skill 3
Gui, Add, DropDownList, x61 y84 w50 h150 vKey3, |F1|F2|F3|F4
Gui, Add, Button, x141 y244 w80 h30 gSave1, Save_Ini
Gui, Show, x767 y247 h284 w230, GUI
Gosub, ReadConfiguration ;Load configuration previously saved.
return

Save1:
Gui, Submit,nohide
IniWrite, %Key3%, %file%, DDL, |F1|F2|F3|F4
return

ReadConfiguration:          ;Read the saved configuration
IfExist, %file%             ;First check if it was saved.
{
IniRead, Key3, %file%, DDL, |F1|F2|F3|F4
GuiControl, ChooseString, Key3, %Key3% ;Submit
}
return

GuiClose:
ExitApp
