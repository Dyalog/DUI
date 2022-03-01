 msg←Test dummy;slr
 slr←Selenium.RETRYLIMIT
 Selenium.RETRYLIMIT←10   ⍝ wait a bit longer
 'fname' 'lname'SendKeys¨'Morten' 'Kromberg'
 msg←'output'WaitFor'Hi Morten Kromberg!'
 Selenium.RETRYLIMIT←slr
