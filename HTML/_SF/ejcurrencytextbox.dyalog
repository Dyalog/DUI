:class ejCurrencyTextbox : #._SF._ejWidget
⍝ Description:: Syncfusion CurrencyTextbox widget
⍝ Constructor:: [options]
⍝ Examples::
⍝ create input-element and ejCurrencyTextbox, set Selector to id of input-element:
⍝ '#i1 type=text'Add _.input ⋄ e←Add _.ejCurrencyTextbox ⋄ e.Selector←'#i1'
⍝      ↑↑ Note the type! The control will ensurethat only  numeric data is accepted.

    :field public shared readonly DocBase←'https://help.syncfusion.com/js/currency/overview'
    :field public shared readonly ApiLevel←1
    ∇ make
      :Access public
      JQueryFn←Uses←'ejCurrencyTextbox'
      :Implements constructor
    ∇
    ∇ make1 args
      :Access public
      JQueryFn←Uses←'ejCurrencyTextbox'
      :Implements constructor :base args
    ∇
:EndClass
