:Namespace SeleniumTests

    ∇ x←eis x
⍝ Enclose if simple
      :If (≡x)∊0 1 ⋄ x←,⊂,x ⋄ :EndIf
    ∇

    ∇ r←lopFirst url
    ⍝ remove first segment of URL
      r←{⍵/⍨(1+'/'=1↑⍵)≤+\'/'=⍵}url
    ∇

    ∇ r←stop Run1Test page;name;ref;Test
     ⍝ eg MS3Test '/QA/DC/InputGridSimple'
     
      Selenium.GoTo SITE,lopFirst page ⍝ Drop the "QA"
      :If 'Test'≡name←⎕SE.SALT.Load #.DUI.AppRoot,page
          :Trap stop×9999
              'Test'⎕STOP⍨1/⍨2=stop ⍝ stop on line 1 if stop=2
              :If stop⌊0≠⍴r←Test ⍬
                  ⎕←'test for ',page,' failed:' ⋄ ⎕←r ⋄ ⎕←'Rerun:' ⋄ '      Test ⍬'
                  ∘∘∘
              :EndIf
          :Else
              r←'Trapped error: ',,⍕⎕DMX.EN
          :EndTrap
      :Else ⋄ r←#.DUI.AppRoot,page,' does not define a function called Test'
      :EndIf
    ∇

    ∇ r←{ext}FindAllFiles root;folders;ext
      :If 0=⎕NC'ext' ⋄ ext←Config.DefaultExtension ⋄ :EndIf
      root,←'/'/⍨~'/\'∊⍨¯1↑root ⍝ append trailing / if missing
      r←root∘,¨(('*',ext)#.Files.List root)[;1]
      :If 0≠⍴folders←{(('.'≠⊃¨⍵[;1])∧⍵[;4])/⍵[;1]}#.Files.List root
          r←r,⊃,/ext FindAllFiles¨root∘,¨folders
      :EndIf
    ∇

    ∇ r←stop_port Test site;count;ctl;examples;f;fail;nodot;start;t;time;z;i;START;COUNT;FAIL;Config;selpath;files;n;ext;filter;⎕PATH;keynames;maxlen;⎕USING;stopOnError;stop
      ⍝ stop: 0 (default) ignore but report errors; 1 stop on error; 2 stop before every test
      ⍝⍵: site filter config
      ⍝                config refers to a named entry in Selenium/settings.json
      stop←⊃stop_port
      r←''
      (site filter config)←3↑(eis site),'' '' ''
      #.DUI.WC2Root←1⊃⎕NPARTS ¯1↓1⊃⎕NPARTS SALT_Data.SourceFile
      #.DUI.AppRoot←site
   ⍝   :If 0=⍴AppRoot←#.DUI.Load ' -nolink'
   ⍝       ⎕←'Test abandoned' ⋄ →0
   ⍝   :EndIf
   ⍝
     
     ⍝ selpath←({∊'/',⍨¨¯1↓'/\'#.Utils.penclose ⍵}#.Boot.MSRoot),'Selenium/'
      selpath←(1⊃⎕NPARTS ¯1↓1⊃⎕NPARTS ¯1↓1⊃⎕NPARTS SALT_Data.SourceFile),'Selenium/'
      :If 0=⎕NC'Selenium'
          :Trap 0 ⋄ ⎕SE.SALT.Load selpath,'Selenium'
          :Else
              ⎕←'Selenium library not found at: ',selpath
              →0⍴⍨0∊⍴selpath←{⍞↓⍨⍴⍞←⍵,': '}'Selenium path'
              :Trap 0 ⋄ ⎕SE.SALT.Load selpath,'Selenium'
              :Else ⋄ ⎕←'Unable to load Selenium' ⋄ →0
              :EndTrap
          :EndTrap
      :EndIf
      ⎕PATH,←' Selenium'
      Selenium.DLLPATH←selpath
      :If config≢''
        Selenium.ApplySettings config
      :Else
          ∘∘∘ ⍝ Can't run w/o config!
      :EndIf
     
     
      :If 0≠⊃z←#.DUI.Initialize
          ⎕←'Error initializing!'⋄⎕←z
          ∘∘∘
      :EndIf
     
     
      n←⍴files←(⍴#.DUI.AppRoot)↓¨¯7↓¨'.dyalog'FindAllFiles #.DUI.AppRoot,'QA'
      ⍝ // Add code to compare this to the mipages found in the whole app
      :If 0≠≢filter
          files←(filter ⎕S'%')files
          ⎕←'Selected: ',(⍕⍴files),' of ',(⍕n),' tests.'
      :EndIf
      n←⍴files
      ⍝SITE←'http://127.0.0.1:',⍕⊃1↓stop_port,Config.Port
      ⍝SITE←'http://',(2 ⎕NQ'.' 'TCPGetHostID'),':',(⍕{6::⍵.MSPort ⋄ ⍵.Port}#.Boot.ms.Config)
      ⎕←'Site=',SITE←'http://',(2 ⎕NQ'.' 'TCPGetHostID'),':',⍕⊃1↓stop_port,⍎⍕{6::⍵.MSPort ⋄ ⍵.Port}#.Boot.ms.Config

⍝⍝ Un-comment to play music while testing:
⍝      :If site filter≡'MS3' ''
⍝          ⎕CMD('"\Program Files (x86)\Windows Media Player\wmplayer.exe" "',AppRoot,'\Examples\Data\tellintro.mp3"')''
⍝      :EndIf
     
      Selenium.InitBrowser''
     
     ⍝ Localize non-alphanumeric key names for easy access
      keynames←⍕#.SeleniumTests.Selenium.Keys.⎕NL ¯2
      ⍎keynames,'←∊#.SeleniumTests.Selenium.Keys.(',keynames,')'
     
      START←⎕AI[3] ⋄ COUNT←0 ⋄ FAIL←0
      maxlen←¯2+⌈/⊃∘⍴¨files
     
      :For i :In ⍳n
          COUNT+←1
          :If 0=⍴t←stop Run1Test{⍵⊣⍞←(⎕UCS 13),maxlen↑lopFirst ⍵}z←i⊃files
              ⍞←'*** PASSED ***'
          :Else
              FAIL+←1
              r,←⊂z
              ⍞←'*** FAILED *** #',(⍕i),' of ',(⍕n),': ',z,': ',t
          :EndIf
      :EndFor
     
      ⎕←'Total of ',(⍕COUNT),' samples tested in ',(∊(⍕¨24 60⊤⌊0.5+(⎕AI[3]-START)÷1000),¨'ms'),': ',(⍕FAIL),' failed.'
     
      Selenium.BROWSER.Quit
    ∇

    ∇ path←home Normalize path;z
      z←(⊂2↑path)∊'./' '.\'
      path←(z/home),(z×2)↓path
      path←∊1 ⎕NPARTS path
    ∇


:EndNamespace
