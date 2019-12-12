:Class jqSelectable  : #._JQ._jqUIWidget
⍝ Description:: jQueryUI Selectable widget
⍝ Constructor:: [sel [options]
⍝ sel - Selector
⍝ options - a namespace or a vector of names and values, optionally nested as pairs(or a matrix of name/value-pairs.
⍝

    :field public shared readonly DocBase←'http://api.jqueryui.com/selectable/'
    :field public shared readonly ApiLevel←3


    ∇ Make0
      :Access public
      :Implements constructor
      JQueryFn←'selectable'
    ∇

    ∇ Make1 sel;options
      :Access public
      :If 0<≢sel
          sel←⊆sel
          Selector←sel
          :If 0<≢options←1↓sel
              :If isRef⊃options ⋄ Options←⊃options ⍝ it's a namespace!
              :Else
                  :If 1=⍴⍴options         ⍝ vector
                  :AndIf (,2)≢,∪≢¨options ⍝ not of name/value-pairs: so it must be a simple vector with options and values
                      'Simple vector of options must have even number of elements!'⎕SIGNAL(2|≢options)/11
                      options←↓((0.5×≢options),2)⍴options
                  :ElseIf 2=⍴⍴options ⋄ options←↓options ⍝ convert a name/value matrix to N/V-pairs
                  :EndIf
                  Options.{v←2⊃⍵ ⋄ ⍎(1⊃⍵),'←v'}¨options
              :EndIf
          :EndIf
      :EndIf
      JQueryFn←'selectable'
      :Implements constructor :base
    ∇

    ∇ r←Render;t;opt
      :Access public
      r←⎕BASE.Render
    ∇
:EndClass
