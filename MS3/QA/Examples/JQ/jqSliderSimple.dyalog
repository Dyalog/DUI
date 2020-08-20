 msg←Test dummy;handle;output;Msg;SlideUntil;RL
 RL←Selenium.RETRYLIMIT
 Selenium.RETRYLIMIT←50   ⍝ temporarily increase it (as we may need many D&D-Ops)

 output←Find'output'
 Msg←/∘'Could not move slider'~
 ⍝ "tolerant sliding" - since this involves screensizes etc., we just make sure that we're "getting close"
 ⍝ (after all - this about making sure that the slider slides at all. Perfect geometry is secondary ;))
 SlideUntil←{(1∊⍵∊(¯5+⍳10)+(≢¨⍵)/(-≢⍵)↑2⊃⎕VFI output.Text)⊣handle DragAndDropToOffset ⍺ 0}

 :If 1 ⍝ for consistency and easy of inserting more tests

     handle←'CssSelector'Find'#Default span'
 :AndIf 0=⍴msg←output WaitFor'Default Slider changed to 0'⊣Click handle

 :AndIf 0=⍴msg←Msg{30 SlideUntil 100}Retry ⍬

     handle←'CssSelector'Find'#Ranged span'
 :AndIf 0=⍴msg←output WaitFor'Ranged Slider changed to 20 40'⊣Click handle

 :AndIf 0=⍴msg←Msg{30 SlideUntil 100 ⍬}Retry ⍬

     handle←⊃⌽⌷'CssSelectors'Find'#Ranged span'
 :AndIf 0=⍴msg←Msg{¯30 SlideUntil ⍬ 0}Retry ⍬

 :EndIf

End:
 Selenium.RETRYLIMIT←RL
