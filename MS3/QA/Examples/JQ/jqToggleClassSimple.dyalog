﻿ msg←Test dummy;output;button;Then;Is
 (output button)←Find¨'output' 'button'
 Is←{⍵≡output.GetAttribute⊂'class'}
 Then←{
     ~0∊⍴msg←'Wrong initial class'/⍨~Is ⍺:msg
     ~0∊⍴msg←'Missing transistion'/⍨(⍺≢⍵)∧Is ⍵⊣⎕DL 0.1⊣Click button:msg
     ~0∊⍴msg←'Wrong final class'/⍨~Is ⍵⊣⎕DL 2:msg
     ''
 }

 :If 1 ⍝ for consistency and easy of inserting more tests

 :AndIf 0=⍴msg←''Then'redclass' ⍝ added class

 :AndIf 0=⍴msg←'redclass'Then'' ⍝ removed class

 :EndIf
