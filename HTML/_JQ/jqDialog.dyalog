:Class jqDialog  : #._JQ._jqUIWidget
⍝ Description:: jQueryUI Dialog  Widget
⍝ Constructor:: [sel [options]
⍝ sel - Selector
⍝ options - a namespace or a vector of names and values, optionally nested as pairs(or a matrix of name/value-pairs.
⍝

    :field public shared readonly DocBase←'http://api.jqueryui.com/dialog/'
    :field public shared readonly ApiLevel←2


    ∇ Make0
      :Access public
      :Implements constructor
      JQueryFn←'dialog'
    ∇

    ∇ Make1 sel;options
      :Access public
      :Implements constructor 
      JQueryFn←'dialog'
      :If 0<≢sel
          sel←⊆sel
          Selector←⊃sel
          :If 0<≢options←1↓sel
              options←⊃options
              :If isRef⊃options ⋄ Options←⊃options ⍝ it's a namespace!
              :Else
                  :If 1=⍴⍴options         ⍝ vector
                  :AndIf (,2)≢,∪≢¨options ⍝ not of name/value-pairs: so it must be a simple vector with options and values
                      'Simple vector of options must have even number of elements!'⎕SIGNAL(2|≢options)/11
                      options←↓((0.5×≢options),2)⍴options
                  :ElseIf 2=⍴⍴options ⋄ options←↓options ⍝ convert a name/value matrix to N/V-pairs
                  :EndIf
                  Set/¨options
              :EndIf
          :EndIf
      :EndIf
    ∇


:EndClass
