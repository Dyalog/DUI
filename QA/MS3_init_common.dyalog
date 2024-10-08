 r←MS3_init_common params;cmd;myapl;logfile
⍝ DO NOT LOCALIZE GR, grdui or DUIdur , they are needed later...
⍝ needs the following repos as siblings of the paren't parent (ie /Git/DUI, /Git/GhostRider) : GhostRider
 r←''
 grdui←1  ⍝ during development: run DUI through GhostRider (the goal, but currentty not working),
          ⍝  1=GhostRider
          ⍝  0=use APLProcess to run DUI and connect to it with GhostRider to adjust Config-Settings,
          ⍝ ¯1=don't use GhostRider (don't fiddle with Config)
          ⍝ we need GhostRider for some fine-tuning of the config of the DUI-Server - but it's not too critical if we can't do that,...⌈
 DUIdir←1⊃⎕NPARTS ¯1↓1⊃1 ⎕NPARTS ##.TESTSOURCE
 ⎕SE.SALT.Load'APLProcess -target=#'
 ⎕SE.SALT.Load DUIdir,'QA/SeleniumTests.dyalog -target=#'
 ⎕SE.SALT.Load DUIdir,'QA/Selenium.dyalog -target=#.SeleniumTests'
logfile←##.TESTSOURCE,'duiprocesslog.txt'
 :If grdui≥0
    {} (⎕JSON'{"overwrite":1}')⎕SE.Link.Import #(DUIdir,'/QA/GhostRider.dyalog')
    
 :EndIf
 :If 1<≢##.args.Arguments ⋄ TestCase←2⊃##.args.Arguments ⋄ :Else ⋄ TestCase←'' ⋄ :EndIf
⍝ Start a separate APLProcess that serves the pages
 :If grdui=1
     GR←⎕NEW #.GhostRider('RIDE_SPAWNED=0 AppRoot=',DUIdir,'MS3/ ',params)  ⍝ RIDE_SPAWNED=0 should make the session visible - that has no effect on MB's machine.
     {}GR.APL'⎕load''',DUIdir,'DUI',''''
     GR.(INFO TRACE)←##.verbose×~##.quiet
     GR.DEBUG←##.halt
 :ElseIf grdui=0
     myapl←⎕NEW APLProcess((DUIdir,'DUI')('AppRoot=',DUIdir,'MS3/ ',params)0 'serve:*:4052' logfile)
 :Else
     myapl←⎕NEW APLProcess((DUIdir,'DUI')('AppRoot=',DUIdir,'MS3/ ',params)0 '' logfile))
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
