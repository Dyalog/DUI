:class ejDropDownList : #._SF._ejWidget
⍝ Description:: Syncfusion DropDownList widget

    :field public shared readonly DocBase←'https://help.syncfusion.com/js/dropdownlist/overview'
    :field public shared readonly ApiLevel←1
    :field public shared readonly DocDyalog←'/Documentation/DyalogAPIs/Syncfusion/ejDropDownList.html'
    :field public shared readonly IntEvt←'beforePopupHide' 'beforePopupShown' 'change' 'checkChange' 'create' 'destroy' 'popupHide' 'popupShown' 'select'   
    


    ∇ make
      :Access public
      JQueryFn←Uses←'ejDropDownList'
      :Implements constructor
      InternalEvents←IntEvt
    ∇

    ∇ make1 args
      :Access public
      JQueryFn←Uses←'ejDropDownList'
      :Implements constructor 
      InternalEvents←IntEvt
    ∇
:EndClass