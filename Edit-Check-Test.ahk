Gui, Add, Edit, x12 y10 w210 h20 vpEdit,
Gui, Add, Button, x222 y10 w110 h20 gcheck, Submit
Gui, Add, Text, x12 y40 w320 h80 vpText
Gui, Show, x127 y87 h135 w350, Gui
lastEdit := ""
Return

check:
gui,submit,nohide ;updates gui variable
if (lastEdit == "") { ;if lastEdit contains nothing, then this is the first value
	guicontrol,,pText,% pEdit "`n`nEnter another value to test comparison"
	lastEdit := pEdit
} else { ;if lastEdit DOES contain something, then this is the second value and we can compare now
	if (pEdit = lastEdit) { ;if last value = current vlue
		guicontrol,,pText,% pEdit " is the same as " lastEdit
	} else {
		guicontrol,,pText,% pEdit " is NOT the same as " lastEdit
	}
	lastEdit := "" ;return lastEdit variable to empty
}
return


GuiClose:
ExitApp