; Note: Requies AutoHotkey v1.1.20+

Gui, Add, Button, w400 h30 gBtnClick vBtn1, 1
Gui, Add, Button, w400 h30 gBtnClick vBtn2, 2
Gui, Add, Button, w400 h30 gBtnClick vBtn3, 3
Gui, Add, Button, w400 h30 gBtnClick vBtn4, 4
Gui, Show
Return

BtnClick() {
	static arrText := ["text for btn one", "text for btn two"]
	RegExMatch(A_GuiControl, "\d+$", n)
	MsgBox, % arrText[n]
    ListVars
}

GuiClose() {
	ExitApp
}