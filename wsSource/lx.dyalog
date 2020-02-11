 lx;App;Port;NoLink
 :If 0∊⍴2 ⎕NQ'.' 'GetEnvironment' 'AttachDebugger'
     WC2Root←(1⊃⎕NPARTS ⎕WSID)      ⍝ WCRoot ist the directory containing the workspace.
     ⎕SE.SALT.Load WC2Root,'DUI.dyalog'
⍝ looks for envVars AppRoot, MSPort and NoLink.
     :If 0<≢App←2 ⎕NQ'.' 'GetEnvironment' 'AppRoot'
         NoLink←1{0=≢⍵:⍺ ⋄ (,'1')≡,⍵}⍕+2 ⎕NQ'.' 'GetEnvironment' 'NoLink'
         :If 0<Port←⍬⍴2⊃⎕VFI 2 ⎕NQ'.' 'GetEnvironment' 'MSPort'
             DUI.Run App Port WC2Root NoLink
         :Else
             DUI.Run App''WC2Root NoLink
         :EndIf
     :Else
         ⎕←'      DUI.Run''./MS3''        ⍝ run the sample app with HRServer (using HTMLRenderer)'
         ⎕←'      DUI.Run''./MS3'' 8080   ⍝ run the sample app with MiServer (using your browser)'
     :EndIf
 :Else
     ⎕←'      Start not run because AttachDebugger was set'Start''
 :EndIf
