  :class jqAutocomplete : #._JQ._jqUIWidget
⍝ Description:: jQueryUI Autocomplete widget
⍝ Constructor:: [pars]
⍝ pars - parameters
⍝
⍝ Public Fields::
⍝ Terms     - list of suggested terms for autocomplete
⍝

    :field public shared readonly DocBase←'http://api.jqueryui.com/autocomplete/'
    :field public shared readonly ApiLevel←3

    :field public Terms←''

    ∇ Make0
      :Access public
      :Implements constructor
      JQueryFn←'autocomplete'
    ∇

    ∇ Make1 pars
      :Access public
      pars←(⊂'autocomplete'),eis pars
      :Implements constructor :base pars
    ∇

    ∇ r←Render;t;opt
      :Access public
      :If ~0∊⍴Terms
        Options.source←Terms
      :EndIf
      r←⎕BASE.Render
    ∇
  :EndClass
