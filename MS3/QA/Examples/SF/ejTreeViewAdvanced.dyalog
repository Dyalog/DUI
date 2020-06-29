 msg←Test dummy

 ⍝ Test that we can add a node
 Click'Add'
 'LinkText'Click'Added_1' ⍝ Select the new node
 :If 0=⍴msg←'output'WaitFor'Select on unknown' 'Add node failed'

 ⍝ Test that we can check a node
     'tv'SendKeys Space   ⍝ Turn checkbox on
 :AndIf 0=⍴msg←'output'WaitFor'Check on unknown' 'Check node failed'

 ⍝ Test for proper model
     Click'Del' ⍝ delete the node server side
     'tv'SendKeys Delete ⍝ make the client model match
     Click'Mod' ⍝ ... and display the model
 :AndIf 0=⍴msg←'Display Model button did not work, or models do not agree.'/⍨~{72=('CssSelectors'Find'#tvModel td').Count}Retry ⍬
 ⍝ ↑↑dunno why this checked for 33?  (8 rows + header x 8 cols + 2header-cells = 72+2=74)  MB,Jun24th, 2020
     msg←'tvModel'WaitFor'Server≡Browser' 'Server/Browser model mismatch.'

 :EndIf
