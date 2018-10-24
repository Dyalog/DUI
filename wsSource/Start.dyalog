 r←{loadfirst}Start arg;site;appRoot;dyalog;FileSep;isWin;sampleMiSite;folderize;NL;ws;congaPath
⍝ This is the program used to start DUI
⍝ site is either:
⍝   - a character vector containing the path of the MiSite to run
⍝   - a 3 element vector of character vectors containing
⍝     [1] the path of the MiSite
⍝     [2] (optional) the path to MiServer
⍝     [3] (optional) the path to Conga shared libraries
⍝         '⍺' - path to the interpreter
⍝         '⍵' - path of the current workspace,
⍝         '↓' - current path (as returned by ⎕CMD 'pwd' or 'cd')
⍝         ''  - Conga default
⍝         'pathname' - user specified path
⍝ loadfirst is a Boolean indicating whether to load all of the necessary classes in #
⍝           this is useful when developing MiSites in that you can edit MiPages in #

 NL←⎕UCS 13
 folderize←{∊1 ⎕NPARTS⊃{⍺,(⍵=1)/'/'}/0 1 ⎕NINFO ⍵}
 arg←,⊆arg
 (AppRoot MSPort WC2Root)←3↑arg,(≢arg)↓''⍬''

 :If 0=⎕NC'⎕SE.SALT' ⍝ Do we have SALT?
     #.SALT.Boot
    ⍝ Set up a trap for runtime errors
     :If ' '∧.=2 ⎕NQ'.' 'GetEnvironment' 'RIDE_INIT'
         ⎕TRAP←(0 'E' '⍎#.RuntimeError ⎕DMX')
     :EndIf
 :EndIf

 :If 'jenkins'≡7↑2 ⎕NQ'.' 'GetEnvironment' 'BUILD_TAG'
     ⎕TRAP←0 'E' '⎕PW←2000⋄{⍵.({⍵,⍪⍎¨⍵}↓⎕nl 2)}⎕dmx ⋄ ⎕off 12'
 :EndIf

 :If ~0∊⍴2 ⎕NQ'.' 'GetEnvironment' 'AttachDebugger'
     ∘∘∘ ⍝ remote debugging entry point
 :EndIf

 :If 9.1=#.⎕NC⊂'DUI'
     :If #.DUI.isRunning
         ⎕←'DUI is currently running "',(#.DUI.AppRoot),'".'
         ⍞←'Shut down and start "',site,'"? [y/N] '
         :If (~(¯1↑⍞)∊'Yy')
             →0
         :Else
             #.Stop
         :EndIf
     :EndIf
 :EndIf

 :If {6::⍵ ⋄ 1⊣loadfirst}0 ⋄ Load site ⋄ :EndIf

 :If 0∊⍴AppRoot
     :If 0∊⍴AppRoot←2 ⎕NQ'.' 'GetEnvironment' 'AppRoot'
         ⎕←'      Start ''./MS3'' ⍝ Run the DUI demonstration site'
         :Return
     :Else
         MSPort←2 ⎕NQ'.' 'GetEnvironment' 'MSPort'
         WC2Root←2 ⎕NQ'.' 'GetEnvironment' 'WC2Root'
     :EndIf
 :EndIf

 :If 0∊⍴WC2Root ⋄ WC2Root←⊃1 ⎕NPARTS ⎕WSID ⋄ :EndIf
 WC2Root←folderize WC2Root

 :Trap 912 ⍝ 912 is signalled by DrA in the event of a server failure

     :If 0=⎕NC'DUI'
         ⎕SE.SALT.Load WC2Root,'DUI'
     :EndIf

     :If #.Files.DirExists AppRoot
         DUI.Run AppRoot MSPort WC2Root
     :Else
         r←'DUI NOT started - "',AppRoot,'" not found'
     :EndIf
 :Else ⍝ we only get here if we're trapping errors and we hit a server error
     :Trap 0
         Stop  ⍝ try to shut down gracefully
     :EndTrap
     ⎕OFF
 :EndTrap
