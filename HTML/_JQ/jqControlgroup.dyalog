﻿:class jqControlgroup : #._JQ._jqUIWidget

⍝ Description:: jQueryUI Controlgroup widget
⍝ Constructor:: [items [type]|selector]
⍝ items    - vector of input elements to create
⍝ type     - the input types (default 'button') of the created elements
⍝ selector - the jQuery/CSS selector to which to convert and manage as buttons
⍝ Public Fields::
⍝ Items    - vector of input elements to create
⍝ Type     - the input types (default 'button') of the created elements
⍝ Selector - the jQuery/CSS selector to which to convert and manage as buttons
⍝ Legend   - the legend of the containing Fieldset-to-be
⍝
⍝????????????????????????????????????????????? Should we support "direction" ????????????????????????????????????????????????????????????
⍝
⍝ Examples::

    :field public shared readonly DocBase←'https://jqueryui.com/controlgroup/'
    :field public shared readonly ApiLevel←3
    :field public shared readonly IntEvt←'create'
    :Field Public Items←UNDEF         ⍝ vector of items
    :Field Public Type←''
    :Field Public Legend←UNDEF



    ∇ Make
      :Access public
      :Implements constructor
      JQueryFn←'controlgroup'
      InternalEvents←IntEvt
    ∇

    ∇ Make1 arg
      :Access public
      :Implements constructor
      JQueryFn←'controlgroup'
      InternalEvents←IntEvt
      :If ''≢arg
          :Select |≡arg
          :CaseList 0 1 ⍝ '#myul'
              Selector←arg
          :Case 2  ⍝ ('One' 'Two' 'Three')
              Items←arg
          :Case 3 ⍝ (('One' 'Two' 'Three') 'radio')
              (Items Type)←arg
          :EndSelect
      :EndIf
    ∇

    ∇ r←Render;container;i;item;fs;type;button
      :Access Public
      r←''
      :If ''≢Selector
          id←Selector↓⍨'#'=⊃Selector
      :Else
          Selector←'#',SetId
      :EndIf
      :If UNDEF≢Items
          container←id New _.div
          :For i item type :InEach (⍳≢Items)Items((≢Items)⍴⊂⍣(1=≡,Type)⊢Type)
              :Select type
                           :CaseList '' 'button' 'submit' 'reset'
                  button←container.Add _.Button,⊂item id i
                  button.type←type,'button'/⍨0∊⍴type
              :CaseList 'checkbox' 'radio' 
                  button←container.Add _.Input,⊂type i item'right'
                  button.name←id
              :Else
                  'Invalid Type set for jqControlgroup'⎕SIGNAL 11
              :EndSelect
              button.id←id,'_',⍕i
          :EndFor
          :If UNDEF≢Legend
              fs←container.Push _.Fieldset
              fs.Legend←Legend
          :EndIf
          r,←container.Render
      :EndIf
      r,←⎕BASE.Render
    ∇
:endclass