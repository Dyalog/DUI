:Class MS3Server : MiServer
⍝ This is an example of a customized MiServer
⍝ The MiServer class exposes several overridable methods that can be customized by the user
⍝ In this case we customize the onServerLoad method
⍝ The ClassName parameter in the Server.xml configuration file is used to specify the customized class

    :Include #.MS3SiteUtils ⍝∇:require =/MS3SiteUtils

    ∇ Make config
      :Access Public
      :Implements Constructor :Base config
    ∇

    ∇ onServerLoad
      :Access Public Override
    ⍝ Handle any server startup processing
      {}C ⍝ initialize CACHE
    ∇

    ∇ onServerStart;inst;class;mps
      :Access public override
⍝ Uncomment to pre-render index.mipage:
     ⍝ ⎕SE.SALT.Load #.DUI.AppRoot,'Code/Templates/MiPageSample.dyalog'
     ⍝ inst←⎕NEW ⎕SE.SALT.Load #.DUI.AppRoot,'index.mipage'
     ⍝ inst.Compose
     ⍝ C.index←inst.Render
    ∇
:EndClass
