:class ejNumericTextbox : #._SF._ejWidget
⍝ Description:: Syncfusion NumericTextbox widget
⍝ Constructor:: [text [symbology]]
⍝ Examples::
⍝ create input-element and ejNumericTextbox, set Selector to id of input-element:
⍝ '#i1 type=text'Add _.input ⋄ e←Add _.ejNumericTextbox ⋄ e.Selector←'#i1'
⍝      ↑↑ Note the type! The control will ensurethat only  numeric data is accepted.

    :field public shared readonly DocBase←'https://help.syncfusion.com/js/textboxes/overview'
    :field public shared readonly ApiLevel←1
    :field public shared readonly DocDyalog←'/Documentation/DyalogAPIs/Syncfusion/ejNumericTextbox.html'
    ∇ make
      :Access public
      JQueryFn←Uses←'ejNumericTextbox'
      :Implements constructor
    ∇
    ∇ make1 args
      :Access public
      JQueryFn←Uses←'ejNumericTextbox'
      :Implements constructor :base args
    ∇
:EndClass
