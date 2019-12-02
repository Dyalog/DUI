 lx;App;Port
 :If 0∊⍴2 ⎕NQ'.' 'GetEnvironment' 'AttachDebugger'
⍝ looks for envVars AppRoot and MSPort
     :If 0<≢App←2 ⎕NQ'.' 'GetEnvironment' 'AppRoot'
         :If 0<Port←⍬⍴2⊃⎕VFI 2 ⎕NQ'.' 'GetEnvironment' 'MSPort'
             DUI.Run App Port(1⊃⎕NPARTS ⎕WSID)
         :Else
             DUI.Run App''(1⊃⎕NPARTS ⎕WSID)
         :EndIf
     :Else
         ⎕←'      DUI.Run''./MS3''        ⍝ run the sample app with HRServer (using HTMLRenderer)'
         ⎕←'      DUI.Run''./MS3'' 8080   ⍝ run the sample app with MiServer (using your browser)'
     :EndIf
 :Else
     ⎕←'Start not run because AttachDebugger was set'Start''
 :EndIf
