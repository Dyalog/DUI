:Class jqTooltip  : #._JQ._jqUIWidget
⍝ Description:: jQueryUI Progressbar  Widget
⍝ Constructor:: [tip [items [options]]]
⍝ tip - Content of the tooltip. Can be a (a) an HTML-String, (b) a HTML-Object ... 
⍝ items - a selector indicating the items that should show tooltip (and optionally an attribute with the tooltip-content)
⍝         This is one of the rare case where a selector is not needed - by default ALL elements with a title-attibute will get a tooltip. items is typically used for finer selection of elements.
⍝ options - a namespace or a vector of names and values, optionally nested as pairs(or a matrix of name/value-pairs.
⍝ Public Fields::
⍝ Tip - see "tip"
⍝ Items - see "items"

    :field public shared readonly DocBase←'http://api.jqueryui.com/tooltip/'
    :field public shared readonly ApiLevel←3
    :field public Tip←''
    :field public Items←''


    ∇ Make0
      :Access public
      :Implements constructor
      JQueryFn←'tooltip'
    ∇

    ∇ Make1 args;options
      :Access public
      :Implements constructor :base
      JQueryFn←'tooltip'
      :If 0<≢args
          args←,args
          (tip items options)←args,(≢args)↓3/UNDEF
          :If tip≢UNDEF ⋄ Tip←sel ⋄ :EndIf
          :If items≢UNDEF ⋄ Items←sel ⋄ :EndIf
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
:if ''≡s←Selector ⋄ Selector←'document'⋄:endif
:if Items≢''⋄'items'Set Items⋄:endif
:if Items≢''⋄'content'Set Tip⋄:endif
      R←⎕BASE.Render
      Selector←s
    ∇


:EndClass
