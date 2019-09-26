#NoEnv
SetWorkingDir %A_ScriptDir%
 
;Create test files
ifNotExist, Fruit.csv
FileAppend,
( 
11,Apple,20150211
0,Orange,20150509
25,Pear,20150927
)
,Fruit.csv 
 
ifNotExist, Color.csv
FileAppend,
(
10,Red,20150112
0,Green,20150421
15,Blue,20150808 
)
,Color.csv 
 
;Read in files
Fruit = Fruit.csv 
Color = Color.csv
 
Gui, Add, DDL, vItem gItem Altsubmit,Fruit|Color
Gui, Add, ComboBox, vType gGetVals Altsubmit,
Gui, Add, Edit, vDate,
Gui, Add, Text, vCount, % "         "
Gui, Add, Text, vTotal, % "                                      "
Gui, Show
return

GetVals:
Gui, Submit, NoHide

Loop, Read, % ( ItemType := ( Item = 1 ? "Fruit" : Item = 2 ? "Color" : "" ) ) ".csv", Tot := 0
{
    if ( a_index = Type )
    {
        Val := StrSplit( A_LoopReadLine, "`," )
    }

    Cnt := StrSplit( A_LoopReadLine, "`," )
    Tot += Cnt.1
}

Loop 2
    GuiControl,, % (i:=!i) ? "Count" : "Date", % i ? Val.1 : Val.3

GuiControl,, Total, % "Total " ItemType " " Tot

return
 
Item:
Gui, Submit, NoHide
;Clear variables
Line0=
DataArray=
 
;Read in file contents 
if Item = 1
{
  Loop,Read,%Fruit%
  {
    Line%A_Index% := A_LoopReadLine
    Line0 = %A_Index%
  }     
}
if Item = 2
{
  Loop,Read,%Color%
  {
    Line%A_Index% := A_LoopReadLine
    Line0 = %A_Index%
  }     
}
;Split the Type lines to show in the DDL
Loop, %Line0%
{  
  StringSplit, Type, Line%A_Index%, `,
  TypeArray := TypeArray . "|" . Type2
  
}
;Show all the Types in ComboBox List
GuiControl, 1:,Type,%TypeArray%   
TypeArray:="" ; Must also be reset or the ddl will be populated with both lists. feel free to move with others above.
return
 
GuiClose:
ExitApp