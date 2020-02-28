 msg←Test dummy
 'inp2'SendKeys'morten'
 Click'btnSub'
 :If 0∊⍴msg←'Failed to detect invalid input'/⍨0≡Find'lblYourInput' ⍝ inp5 will be gone if POST succeeded
     'inp2'SendKeys'@dyalog.apl'
     Click'btnSub'
     msg←'lblYourInput'WaitFor'Here''s your input'
 :EndIf
