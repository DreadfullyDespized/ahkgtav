buttons=↑,↓,←,→,÷,±

y=5

x=5



Loop, parse, buttons, CSV

	{

	 ButtonText:=A_LoopField

	 If Mod(A_Index,4)=0

	 	y+=30

	 If (x > 95)

	 	x=5

	 Gui, Add, Button, W25 H25 Y%y% X%x% gLabel, % ButtonText

	 x+=30

	} 	

Gui, Show

Return



Label:

ControlGetFocus, OutputVar, A

ControlGetText, Text, %OutputVar%, A

MsgBox % Text	

Return



GuiEsc:

GuiClose:

ExitApp

Return