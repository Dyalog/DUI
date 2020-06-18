 msg←Test dummy;res;tab;CR
⍝ Just check to see whether the litte multiplication table seems to have been produced
 CR←⎕UCS 13
 tab←msg←res←''
 :Trap 0
     tab←'CssSelectors'Find'#myTable td'
 :EndTrap
 :If tab≡'' ⋄ msg←'Problem locating table',,CR,↑⎕DM ⋄ →0 ⋄ :EndIf
 :Trap 0
     res←tab[98 99].Text  ⍝ could crash because of m018239
 :EndTrap
 :If res≡'' ⋄ msg←'Problem indexing table',,CR,↑⎕DM ⋄ →0 ⋄ :EndIf
 msg←'Expected output was not produced.'/⍨'90' '100'≢res
