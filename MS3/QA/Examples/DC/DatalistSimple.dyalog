 msg←Test dummy
⍝ unfortunately we can't select option from a datalist using Selenium
⍝ see https://bugs.chromium.org/p/chromedriver/issues/detail?id=1183
⍝ the recommended workaround (send Down + Enter) does not work (Enter triggers submit, Tab does not select)
 :If 0 ⍝ for the time being, test disable test
     'opts'∘SendKeys¨'F'Down Tab ⍝ Auto-complete using F, down-arrow
     Click'btnPressMe'
     msg←'output'WaitFor'You selected "Four"!'
 :EndIf
