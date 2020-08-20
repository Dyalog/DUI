 msg←Test dummy;Msg;slave;min;max;LeftUntil;RightUntil;RL
 RL←Selenium.RETRYLIMIT
 Selenium.RETRYLIMIT←50   ⍝ temporarily increase it (as we may need many D&D-Ops)
⍝  LeftUntil←{∨/(Find ⍺).Text≡⍕⍵⊣(⍎⍺)DragAndDropToOffset ¯25 0}
⍝  RightUntil←{∨/(Find ⍺).Text≡⍕⍵⊣(⍎⍺)DragAndDropToOffset 25 0}
 ⍝ "tolerant sliding" - since this involves screensizes etc., we just make sure that we're "getting close"

 LeftUntil←{(1∊⍵∊(¯5+⍳10)+⌈/2⊃⎕VFI(Find ⍺).Text)⊣(⍎⍺)DragAndDropToOffset ¯25 0}
 RightUntil←{(1∊⍵∊(¯5+⍳10)+⌈/2⊃⎕VFI(Find ⍺).Text)⊣(⍎⍺)DragAndDropToOffset 25 0}

 Msg←/∘'Wrong limit'~
 (slave min max)←⌷'CssSelectors'Find'.ui-slider-handle'

 :If 1

 :AndIf 0=⍴msg←Msg{'slave'LeftUntil 20}Retry ⍬

 :AndIf 0=⍴msg←Msg{'slave'RightUntil 40}Retry ⍬

 :AndIf 0=⍴msg←Msg{'min'LeftUntil 0}Retry ⍬

 :AndIf 0=⍴msg←Msg{'slave'RightUntil 40}Retry ⍬

 :AndIf 0=⍴msg←Msg{'max'RightUntil 100}Retry ⍬

 :AndIf 0=⍴msg←Msg{'slave'RightUntil 100}Retry ⍬

 :EndIf

 Selenium.RETRYLIMIT←RL
