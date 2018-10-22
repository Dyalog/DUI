 {AppRoot}←{debug}Load site;WC2Root;empty;hr
 debug←{6::0 ⋄ debug}0
 WC2Root←⊃1 ⎕NPARTS ⎕WSID
 :If empty←site≡'' ⋄ site←'./MS3' ⋄ :EndIf
 :Trap debug↓0
     ⎕SE.SALT.Load WC2Root,'DUI -target=#'
     AppRoot←WC2Root #.DUI.makeSitePath site
     #.DUI.Load AppRoot
     :If #.Files.DirExists WC2Root,'QA'
         ⎕SE.SALT.Load WC2Root,'QA/QA -target=#'
     :EndIf
     ⎕←'Development environment loaded'

     :If #.Files.DirExists AppRoot
         :Trap 0
             ⎕SE.SALT.Load AppRoot,'/Code/*'
             ⎕SE.SALT.Load AppRoot,'/Code/Templates/*'
             ⎕←'"',AppRoot,'" loaded'
         :Else
             ⎕←'Error loading "',AppRoot,'" - ',⊃,/⎕DM
         :EndTrap
     :Else
         :If ~empty
             ⎕←'"',AppRoot,'" not found'
         :EndIf
         AppRoot←''
     :EndIf
 :Else
     ⎕←'Could not load development environment due to: ',⊃,/⎕DM
 :EndTrap
