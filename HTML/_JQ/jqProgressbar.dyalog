:Class jqProgressbar  : #._JQ._jqUIWidget
⍝ Description:: jQueryUI Progressbar  Widget
⍝ Constructor:: [max [value [Selector [options]]]]
⍝ max - Maximum value
⍝ value - Current value
⍝ options - a namespace or a vector of names and values, optionally nested as pairs(or a matrix of name/value-pairs.
⍝ Public Fields::
⍝ Max - see "max"
⍝ Value - see Value

    :field public shared readonly DocBase←'http://api.jqueryui.com/progressbar/'
    :field public shared readonly ApiLevel←3
    :field public Max←0
    :field public Value←0


    ∇ Make0
      :Access public
      :Implements constructor
      JQueryFn←'progressbar'
    ∇

    ∇ Make1 args;options
      :Access public
      :Implements constructor :base
      JQueryFn←'progressbar'
      :If 0<≢args
          args←,args
          (Max Value sel options)←args,(≢args)↓0 0 UNDEF UNDEF
          :If sel≢UNDEF ⋄ Selector←sel ⋄ :EndIf
          :If isRef⊃options ⋄ Options←⊃options ⍝ it's a namespace!
          :Else
              :If options≢UNDEF
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


    ∇ R←Render;text;cnt
      :Access public
      'max'Set Max
      :If isNum Value
      :OrIf ∧/Value∊_true _false ⍝ ^/ to avoid LENGTH ERROR in case2
          'value'Set Value
      :Else
          'value'Set{(⍸isNum¨⍵)⊃⍵}Value
          text←HtmlSafeText∊{(⍸isChar¨⍵)⊃⍵}Value
          style←'position:relative;'
          JavaScript←';$("#',id,' .progress-label").text("',text,'");'
          Container.Content←'<div class="progress-label" style="position:absolute;width: 100%;text-align: center;top:4px;font-weight:bold;text-shadow: 1px 1px 0 #fff;">',text,'</div>'
      :EndIf
      R←⎕BASE.Render
    ∇

    ∇ R←Update val;text
      :Access public
    ⍝ set new value...
      text←''
      :If ~isNum val
      :AndIf ~∨/val∊_true _false ⍝ ^/ to avoid LENGTH ERROR in case2
          text←HtmlSafeText∊{(⍸isChar¨⍵)⊃⍵}val
          val←{(⍸isNum¨⍵)⊃⍵}val
      :EndIf
     
      R←'$("#',id,'").progressbar({value:',(⍕val),'});'
      :If 0<≢text
          R,←'$("#',id,' .progress-label").text("',text,'");'
      :EndIf
    ∇
:EndClass
