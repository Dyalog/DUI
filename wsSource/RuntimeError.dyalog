 {R}←RuntimeError DM;Msg;Caption;M;⎕TRAP;exec;f;v;debugLevel
⍝ Default runtime error trapping
 R←'' ⋄ ⎕TRAP←0 'S' ⍝ prevent looping in ⎕TRAP

⍝ Display the error in the output stream, in TTY mode this may be caught
 ⎕←Caption←'An error occured'
 ⎕←M←⎕FMT⍪((↑⎕DM)DM),⊂1↓⎕XSI,⍪⎕LC

 debugLevel←0
⍝ In debug mode we prepare a conversation window
 :If 2=⎕NC v←'#.DUI.Server.Config.Debug'
     debugLevel←⍎v
 :EndIf

 :If 1∨debugLevel>1
⍝ This is the callback program to the form we use
     ⎕FX(1+2↑⎕LC[1])↓endOfProgram↑⎕CR'RuntimeError'
⍝ exec arg;txt;new;ll
⍝ →0↓⍨' '∨.≠ll←⎕IO⊃⌽(⊂'')~⍨txt←'f.t'⎕WG'text'
⍝ :Trap 0
⍝     new←↓⎕FMT⍎ll
⍝     txt←txt,new
⍝ :Else
⍝     txt←txt,⎕DM
⍝ :EndTrap
⍝ 'f.t'⎕WS'text'(txt,⊂'')
endOfProgram:

    ⍝ We prepare the form, to exit close the form or use →
     :Trap 0
         'f'⎕WC'form'('fontobj'('APL385 Unicode' 16 1 0 0 400 0 0))
         'f.t'⎕WC'edit'(↓M)(0 0)(100 100)('style' 'multi')('accelerator' 13 0)('event' 30 'exec')
         'Msg'⎕WC'MsgBox'Caption'about to enter ⎕DQ on form' ⋄ ⎕DQ'Msg'
         ⎕DQ'f' ⍝ this bombs and is NOT trappable in 13.2!!!!
         →0
     :Else
         :Trap 0
             M←⎕FMT⍪((↑⎕DM)⎕DMX)
             'Msg'⎕WC'MsgBox' 'There was a problem in ⎕DQ'⎕DM ⋄ ⎕DQ'Msg'
             →0
         :EndTrap
     :EndTrap

    ⍝ If everything failed we assume we don't have a GUI:
     ⎕←'Enter an expression to debug this problem:'
L1:
     :Trap 0
         ⍎⍞{⍺}⍞←6↑''
     :Else
         ⍪⎕DM
     :End
     →L1

 :ElseIf debugLevel>0 ⍝ simple display of the problem
     :Trap 0  ⍝ try to display the error
         'Msg'⎕WC'MsgBox'Caption M ⋄ ⎕DQ'Msg'
     :EndTrap

 :EndIf ⍝ otherwise (no debug level) we simply die
