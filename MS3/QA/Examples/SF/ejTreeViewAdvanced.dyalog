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
⍝ 20220226, MBaas: disabled this test for the time being (we know this doesn't work)
⍝ if our testing could handle WARNINGS, it might be worthwhile to issue one - but that's not doable atm...
⍝ :AndIf 0=⍴msg←'Display Model button did not work, or models do not agree.'/⍨~{72=('CssSelectors'Find'#tvModel td').Count}Retry ⍬
⍝     msg←'tvModel'WaitFor'Server≡Browser' 'Server/Browser model mismatch.'

 :EndIf
