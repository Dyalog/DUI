 r←MS3_teardown dummy
 r←''
 :If grdui=1 
    GR.APL'⍝ now shutting down this instance!' 
    ⍝ GR.APL'⎕OFF'   ⍝ this may give an endless loop of GR-Msgs
    ⎕ex'GR'   ⍝ this should trigger the destructor which should terminate the remote session - but it doesn't always work...
 :Else ⋄ {}myapl.Kill
 :EndIf
