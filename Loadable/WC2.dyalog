:Namespace WC2 ⍝ Web Content Contruction for use with HTMLRenderer
⍝ Populated from /Loadable/WC2/

    Initialized←0

    APLVersion←{⊃(//)⎕VFI ⍵/⍨2>+\'.'=⍵}2⊃#.⎕WG 'APLVersion'
    SourceFile←{0::'' ⋄ 6:: 4⊃⊃5177⌶⍬ ⋄ SALT_Data.SourceFile}

    ∇ r←{force}Init arg;duiPath;path;boot;appPath;app;t
    ⍝ Bootstrap load from
      →0⍴⍨1=⊃r←(17>APLVersion)/1 'Dyalog v17.0 or later is required to use WC2'
     
      force←{6::⍵ ⋄ force}0
      :If Initialized>force
          →0⊣r←¯1 'Already initialized'
      :EndIf
     
      arg←,⊆arg
      (duiPath appPath)←2↑arg,(⍴arg)↓'' ''
     
      :If 0∊⍴duiPath ⍝ if no MiServer path specified, try looking at source path
      :AndIf ~0∊⍴t←SourceFile ⍬
          duiPath←⊃1 ⎕NPARTS (⊃1 ⎕NPARTS t),'/../'
      :EndIf
     
      :If ~⎕NEXISTS path←∊1 ⎕NPARTS duiPath,'/'
          →0⊣r←2 'DUI path not found: "',duiPath,'"'
      :EndIf
     
      :If ~0∊⍴app←appPath
      :AndIf ~⎕NEXISTS app←∊1 ⎕NPARTS appPath,'/'
          →0⊣r←3 'Application path not found: "',appPath,'"'
      :EndIf
     
      :If ~⎕NEXISTS boot←path,'Core/Boot.dyalog'
          →0⊣r←4 'Path does not appear to be MiServer: "',duiPath,'"'
      :EndIf
     
      ⎕SE.SALT.Load boot,' -target=#'
      #.Boot.(MSRoot AppRoot)←path app
      #.Boot.Load app
      #.Boot.ms←1 #.Boot.Init #.Boot.ConfigureServer app
      #.Boot.(Configure ms)
      Initialized←1
      r←0 'WC2 initialized'
    ∇

    ∇ r←Run arg
      →0⍴⍨0<⊃r←1 Init arg
     ⍝!!!WIP
    ∇
                         
    ∇ {r}←{attr}New args;cl
    ⍝ create a new instance
    ⍝ args can be an instance, a class, or just html/text
      :Access public shared
      r←''
      :If ~0∊⍴∊args
          :If 0=⎕NC'attr' ⋄ attr←'' ⋄ :EndIf
          r←attr #.HtmlElement.New args
      :EndIf
    ∇


:EndNamespace
