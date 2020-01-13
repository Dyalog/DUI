:class ejCurrencyTextbox : #._SF._ejWidget
⍝ Description:: Syncfusion CurrencyTextbox widget
⍝ Constructor:: [CurrencySymbol [DecimalPlaces [IncrementStep]]
⍝ Public Fields:: 
⍝ CurrencySymbol - the currency-symbol to use.
⍝ DecimalPlaces - number of decimal places (Defaul:2)
⍝ IncrementStep - step size when changing input through spinners
⍝ Examples::
⍝ create input-element and ejCurrencyTextbox, set Selector to id of input-element:
⍝ '#i1 type=text'Add _.input ⋄ e←Add _.ejCurrencyTextbox ⋄ e.Selector←'#i1'
⍝      ↑↑ Note the type! The control will ensurethat only  numeric data is accepted.

    :field public shared readonly DocBase←'https://help.syncfusion.com/js/currency/overview'
    :field public shared readonly ApiLevel←1
    :field public CurrencySymbol←''
    :field public DecimalPlaces←2
    :field public IncrementStep←⍬

    ∇ make
      :Access public
      JQueryFn←Uses←'ejCurrencyTextbox'
      :Implements constructor
    ∇
    ∇ make1 args
      :Access public
      JQueryFn←Uses←'ejCurrencyTextbox'
      (CurrencySymbol DecimalPlaces IncrementStep)←args defaultArgs CurrencySymbol DecimalPlaces IncrementStep
      :Implements constructor
    ∇

    ∇ r←Render
      :Access public
      :If CurrencySymbol≢'' ⋄ 'currencySymbol'Set CurrencySymbol ⋄ :EndIf
       'decimalPlaces'Set DecimalPlaces 
      :If IncrementStep≢⍬ ⋄ 'incrementStep'Set IncrementStep ⋄ :EndIf
      r←⎕BASE.Render
    ∇
:EndClass
