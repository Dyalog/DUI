 r←MS3_test dummy
⍝ if you use -trace to trace into tests, this will cause a stop here.
⍝ Feel free to continue, as DUI.Test also honours that flag...
 r←##.(trace {(⍺×2)+⍵∧~⍺} halt) #.DUI.Test(DUIdir,'/MS3/')TestCase config
