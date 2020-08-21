 r←MS3_init_common params;cmd
⍝ vars are global by design here ;)
⍝ needs the following repos as siblings of the paren't parent (ie /Git/DUI, /Git/GhostRider) : GhostRider
 r←''
 grdui←1  ⍝ during development: run DUI through GhostRider (the goal, but currentty not working), 
          ⍝  1=GhostRider
          ⍝  0=use APLProcess to run DUI and connect to it with GhostRider to adjust Config-Settings, 
          ⍝ ¯1=don't use GhostRider (don't fiddle with Config)
          ⍝ we need GhostRider for some fine-tuning of the config of the DUI-Server - but it's not too critical if we can't do that,...⌈
 DUIdir←1⊃⎕NPARTS ¯1↓1⊃1 ⎕NPARTS ##.TESTSOURCE
 ⎕SE.SALT.Load'APLProcess'
 ⎕SE.SALT.Load DUIdir,'QA/SeleniumTests.dyalog -target=#'
 ⎕SE.SALT.Load DUIdir,'../Selenium/Selenium.dyalog -target=#.SeleniumTests'
 :If grdui≥0 ⋄ ⎕SE.SALT.Load(1⊃⎕NPARTS ¯1↓DUIdir),'/GhostRider/GhostRider.dyalog -target=#' ⋄ :EndIf
 :If 1<≢##.args.Arguments ⋄ TestCase←2⊃##.args.Arguments ⋄ :else ⋄ TestCase←'' ⋄ :EndIf
⍝ Start a separate APLProcess that serves the pages
 :If grdui=1
     GR←⎕NEW #.GhostRider('AppRoot=',DUIdir,'MS3/ ',params)
     GR.APL'⎕load''',DUIdir,'DUI',''''
 :ElseIf grdui=0
     myapl←⎕NEW APLProcess((DUIdir,'DUI')('AppRoot=',DUIdir,'MS3/ ',params)0 'serve:*:4052')
 :Else
     myapl←⎕NEW APLProcess((DUIdir,'DUI')('AppRoot=',DUIdir,'MS3/ ',params))
 :EndIf

 'DUI'#.⎕NS''
 #.DUI.AppRoot←DUIdir,'/MS3/'
 #.DUI.WC2Root←DUIdir
 {}⎕SE.SALT.Load DUIdir,'DUI.dyalog -target=#'

 {}#.DUI.Initialize
 #.SeleniumTests.Selenium.QUIETMODE←##.quiet

 ⍝ Connect to the DUI-Instance
 :If grdui>¯1
     :If grdui=0 ⋄ GR←⎕NEW #.GhostRider 4052 ⋄ :End
 ⍝ override settings with appropriate values (according to ]DTest-Flags) in the local DUI (used for testing) as well as the server
     cmd←'#.Boot.ms.Config.LogMessageLevel←',⍕(0 1 ¯1)[(2+##.verbose)*##.quiet=0]   ⍝ 0-none -1-all 1-error/important 2-warning 4-informational 8-Transactional
     ⍎cmd ⋄ {}GR.APL cmd
     cmd←'#.Boot.ms.Config.(Production TrapErrors)←','01'[2-##.halt]
     ⍎cmd ⋄ {}GR.APL cmd
 :EndIf
