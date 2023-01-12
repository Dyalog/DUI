 msg←Test dummy;link;output
 :If 0∊⍴msg←'list or first list-item not found'/⍨0≡link←1⌷'CssSelectors'Find'ul#links > li > a'
     output←Find'output'
     msg←'Mouseover test failed'/⍨~{
         sink←MoveToElement link
         ∨/'this'⍷output.Text
     }Retry ⍬
 :EndIf
