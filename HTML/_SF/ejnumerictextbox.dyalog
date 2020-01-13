:class ejNumericTextbox : #._SF._ejWidget
⍝ Description:: Syncfusion NumericTextbox widget
⍝ Constructor:: [DecimalPlaces [WatermarkText [ShowSpinButton]]]
⍝ Public Fields::
⍝ DecimalPlaces - controls nr. of decimals (Default: 0)
⍝ WatermarkText - text to display in empty input
⍝ ShowSpinButton - boolean: show spin buttons? (Default: 0)
⍝ Examples::
⍝ create input-element and ejNumericTextbox, set Selector to id of input-element:
⍝ '#i1 type=text'Add _.input ⋄ e←Add _.ejNumericTextbox ⋄ e.Selector←'#i1'
⍝      ↑↑ Note the type! The control will ensurethat only  numeric data is accepted.

    :field public shared readonly DocBase←'https://help.syncfusion.com/js/textboxes/overview'
    :field public shared readonly ApiLevel←1
    :field public shared readonly DocDyalog←'/Documentation/DyalogAPIs/Syncfusion/ejNumericTextbox.html'
    :field publuc DecimalPlaces←0
    :field public WatermarkText←''
    :field public ShowSpinButton←0

    ∇ make
      :Access public
      JQueryFn←Uses←'ejNumericTextbox'
      :Implements constructor
    ∇

    ∇ make1 args
      :Access public
      JQueryFn←Uses←'ejNumericTextbox'
      :Implements constructor
      (DecimalPlaces WatermarkText ShowSpinButton)←args defaultArgs DecimalPlaces WatermarkText ShowSpinButton
    ∇

    ∇ r←Render
      :Access public
      :If WatermarkText≢'' ⋄ 'watermarkText'Set WatermarkText ⋄ :EndIf
      'decimalPlaces'Set DecimalPlaces
      'showSpinButton'Set(1+ShowSpinButton)⊃_false _true
      r←⎕BASE.Render
    ∇
:EndClass
