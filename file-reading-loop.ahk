dict_list=
(
this	that	other
here	there	everywhere
one	two	google
blue	red	AutoHotkey
)
Gui, Add, ListView, r4 w250 gCreateAbbr, Dictionary Item
Loop, parse, dict_list, `n
	Loop, parse, A_LoopField, %A_Tab%
		LV_Add("",A_LoopField)
Gui, Show, AutoSize Center, List
return

CreateAbbr:
if	(A_GuiEvent <> "DoubleClick")
	return
row :=	A_EventInfo, LV_GetText(item,row) 
Gui, 2: +Owner
Gui, 2: Add, Text, xm ym, Enter your abbreviations for this word`n(Use commas to separate multiple abbreviations):
Gui, 2: Add, Edit, wp vAbbr Section,
Gui, 2: Add, Button, xs gSetAbbr, OK
Gui, 2: Show, AutoSize Center, Abbr
return

SetAbbr:
Gui, 2: Submit
Gui, 2: Destroy
FileAppend, %item%`,%Abbr%`n,%SelectedFile%.csv
MsgBox, , Quick Dictionary, Your abbreviations were saved.
return