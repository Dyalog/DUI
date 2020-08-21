 msg←Test dummy
 ⎕DL 1  ⍝ allow some time to finish pageload etc.
 1 ejAccordionTab'Second' 'p2'
 msg←'output'WaitFor'You activated section 1' 'Accordion Selection Failed'
