:Class jqSelectmenu : #._JQ._jqUIWidget
⍝ Description:: jQueryUI Selectmenu-widget
⍝ Constructor:: [items [[selected] [[disabled] [prompt]]]]
⍝ items     - vector of options or 2 column matrix of displayed[;1] and returned[;2] values
⍝ selected  - Boolean or integer array indicating pre-selected options(s)
⍝ disabled  - Boolean or integer array indicating disabled options(s)
⍝ prompt    - first item to display (has no value) (default '[Select]')
⍝
⍝ OR
⍝
⍝ if one object is passed, we assume it is an instance of _.select that was created in advance
⍝ and will apply jqSelect to it.
⍝
⍝ Public Fields::
⍝ Items     - vector of options or 2 column matrix of displayed[;1] and returned[;2] values
⍝ Selected  - Boolean or integer array indicating pre-selected options(s)
⍝ Disabled  - Boolean or integer array indicating disabled options(s)
⍝ Prompt      - first item to display (has no value) (default '[Select]')
⍝

    :field public shared readonly DocBase←'http://api.jqueryui.com/button/'
    :field public shared readonly ApiLevel←3
    :field public shared readonly DocDyalog←'/Documentation/DyalogAPIs/jQuery/jqSelectmenu.html'

    :field public Items←0 2⍴⊂''     ⍝ vector or matrix [;1] display, [;2] value
    :field public Selected←⍬          ⍝ either Boolean integer vector indicating
    :field public Prompt←'[Select]'   ⍝ character vector "Prompt" choice - the first choice on the list and does not have a value
    :field public Disabled←⍬          ⍝ either Boolean integer vector indicating


    ∇ Make0
      :Access public
      :Implements constructor
      JQueryFn←'selectmenu'
      InternalEvents←,⊂'create'
    ∇

    ∇ Make1 args;i
      :Access public
      :Implements constructor
      JQueryFn←'selectmenu'
      args←eis args
      :If (|≡args)∊0 1 2
      :AndIf ~0∊⍴⊃args
          args←,⊂args
      :EndIf
      (Items Selected Disabled Prompt)←args defaultArgs Items Selected Disabled Prompt
      InternalEvents←,⊂'create'
    ∇

    ∇ r←Render;type;content
      :Access public
      ⍝ basically we're emulating the Select-Widget and then add the neccessary jQuery-Calls to jq'ize it^
      content←Content
      :If isInstance Items
          id←Items.SetId
          Content←Items
      :Else
          Content←SetId New ##._.Select(Items Selected Disabled Prompt)
      :EndIf
      r←renderIt Content
      :If JQueryFn≢''
          BuildHTML←0  ⍝ don't construct HTML in Render
          Selector←'#',id
          r,←⎕BASE.Render
          :else 
          {}⎕base.Render ⍝ nothing to render and to add to the page, but ensure other processing gets done (i.e. honouring "uses" etc.)
      :EndIf
      Content←content
    ∇
:EndClass
