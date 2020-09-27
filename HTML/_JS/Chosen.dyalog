:class Chosen : #._JQ._jqWidget
⍝ Description:: Enhanced HTML selects with search-box and improved multi-select
⍝ Constructor:: [choices [[selected] [[ disabled] [prompt]]]]
⍝ choices   - vector of choices or 2 column matrix of displayed[;1] and returned[;2] values
⍝ selected  - Boolean or integer array indicating pre-selected options(s)
⍝ disabled  - Boolean or integer array indicating disableded options(s)
⍝ prompt    - placeholder text for the element
⍝
⍝ Public Fields::
⍝ Choices     - vector of options or 2 column matrix of displayed[;1] and returned[;2] values
⍝ Selected    - Boolean or integer array indicating pre-selected options(s)
⍝ Disabled    - Boolean or integer array indicating disabled options(s)
⍝ Prompt      - placeholder text for the element 
⍝ Multiple    - Boolean indicating whether multiple items may be selected
⍝ GroupMarker - Character to indicate which elements are group headings (if any)
⍝
⍝ Examples::
⍝ Chosen  ('Choice 1' 'Choice 2' 'Choice 3')
⍝ Chosen  (3 2⍴'One' 'c1' 'Two' 'c2' 'Three' 'c3')
⍝ Chosen ((3 2⍴'One' 'c1' 'Two' 'c2' 'Three' 'c3') 2) ⍝ second item is selected
⍝ Chosen ((3 2⍴'One' 'c1' 'Two' 'c2' 'Three' 'c3') (0 1 0)) ⍝ second item is selected
⍝ Chosen ((3 2⍴'One' 'c1' 'Two' 'c2' 'Three' 'c3') 2 3 'Pick One') ⍝ second item is selected, third item is disabled
⍝ Chosen ((3 2⍴'One' 'c1' 'Two' 'c2' 'Three' 'c3') (2 3) 1) ⍝ second and third items are selected, first item is disabled

    :field public shared readonly DocBase←'https://harvesthq.github.io/chosen'

    :field public Choices←0 2⍴⊂''     ⍝ vector or matrix [;1] display, [;2] value
    :field public Selected←⍬          ⍝ either Boolean or integer vector indicating pre-selected items
    :field public Disabled←⍬          ⍝ either Boolean or integer vector indicating disabled items
    :field public Prompt←''           ⍝ character vector default field text
    :field public Multiple←0          ⍝ Boolean indicating whether multiple choices may be selected
    :field public GroupMarker←''      ⍝ leading character marking option groups


    ∇ make
      :Access public
      :Implements constructor
      makeCommon
    ∇

    ∇ make1 args
      :Access public
      :Implements constructor
      ⍝↓↓↓ deal with case of just Choices passed
      args←eis args
      :If (|≡args)∊0 1 2
      :AndIf ~0∊⍴⊃args
          args←,⊂args
      :EndIf
      (Choices Selected Disabled Prompt)←args defaultArgs Choices Selected Disabled Prompt
      makeCommon
    ∇

    ∇ makeCommon
      ContainerTag←'select'
      Container←⎕NEW #._html.select
      JQueryFn←Uses←'chosen'
    ∇

    ∇ r←Render
      :Access public
      Content←opts←''
      SetInputName
      Container.Add BuildChoices(Choices Selected Disabled)
      r←⎕BASE.Render
    ∇

    ∇ r←BuildChoices(opts sel dis);v
      :Access public
      r←''
      :If ~0∊⍴opts
          opts←eis opts
          :If 1=⍴⍴opts
              opts←opts,⍪opts
          :EndIf
      :EndIf
     
      v←⍳⍬⍴⍴opts
      (sel dis)←v∘∊∘{∧/⍵∊0 1:⍵/⍳⍴⍵ ⋄ ⍵}∘,¨sel dis
      :If {6::0 ⋄ 1⊣Attrs[]}⍬                 ⍝ if calling as public shared, Attrs (an instance element) won't exist
          :If Multiple∨1<+/sel                ⍝ if we have multiple set or more than 1 item selected
          :AndIf 0∊⍴⊃Attrs[⊂'multiple']       ⍝ and the multiple attribute is not set
              Attrs[⊂'multiple']←⊂'multiple'  ⍝ then set it
          :EndIf
          :If ~0∊⍴Prompt
              'data-placeholder'Container.Set Prompt
          :EndIf
      :EndIf
      r,←FormatChoices(opts sel dis)
    ∇

    ∇ r←FormatChoices(opts sel dis);o;s;d;grouped
      :Access Public
      r←''
      :If 1=⍴⍴opts ⋄ opts←opts,⍪opts ⋄ :EndIf
      :If 1=≢opts ⋄ opts←(⊂'')⍪opts ⋄ (sel dis)←0,¨sel dis ⋄ :EndIf ⍝ if single option, need to insert blank per Chosen documentation
      :For o s d :InEach (↓opts)sel dis
          :If GroupMarker≡1↑1⊃o
              r,←'<optgroup label="',(1↓1⊃o),'"',(d/' disabled="disabled"'),'/>'
          :Else
              r,←'<option',({⍵ ine' value="',(HtmlSafeText ⍵),'"'}2⊃o),(s/' selected="selected"'),(d/' disabled="disabled"'),'>',(1⊃o),'</option>'
          :EndIf
      :EndFor
    ∇

    ∇ r←{selector}ReplaceChoices args;sel;opts;dis;prompt
    ⍝ Replaces select elements options - used by callback functions
    ⍝ Ex: r←Execute ReplaceChoices ('New Option 1' 'New Option 2') 1
    ⍝ arg = options [[selected] [disabled] [prompt]]
      :Access public
      :If 0=⎕NC'selector' ⋄ selector←'#',id ⋄ :EndIf
      args←eis args
      :If (|≡args)∊0 1 2
      :AndIf ~0∊⍴⊃args
          args←,⊂args
      :EndIf
      (opts sel dis prompt)←args defaultArgs Choices ⍬ ⍬ Prompt
      r←selector #.JQ.Replace BuildChoices(opts sel dis)
      r,←#.JQ.Execute'$("',selector,'").trigger("chosen:updated")'
    ∇

:endclass
