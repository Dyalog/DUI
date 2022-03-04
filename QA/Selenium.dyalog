:Namespace Selenium ⍝ V 2.11.0
⍝ This namespace allows scripted browser actions. Use it to QA websites, inluding RIDE.
⍝
⍝ 2017 05 09 Adam: Version info added
⍝ 2017 05 23 Adam: now gives helpful messages for DLL problems, harmonised ADOC utils
⍝ 2020 02 12 MBaas 2.10: updated to use a config (.json)-file to facilitate testing with various browsers (incl. HTMLRenderer)
⍝ 2020 05 08 MBaas: praparing for cross-platformness;new folder-structure for drivers
⍝ 2020 07 11 MBaas: lots of changes to make it working on ALL platforms;revised structure of settings (AND names of parameter DRIVERS → DRIVER)
⍝ 2021 11 15 MBaas: 2.11.0 settings.json may now use "SELENIUM_DRIVERPATH" to point to the folder with the downloaded drivers -
⍝                   this way it becomes more generally usable and less platform-dependent. Changed to semantic versioning. Settings file now JSON5.
⍝ 2021 02 22 MBaas: MAJOR UPDATE
⍝                   now using WebDriver4 and NuGet. This removes the need to distribute DLLs. (started development on branch "WebDriver4")
⍝                   - removed all paths from settings.json
⍝                   - we're aiming to kewep all changes "under the cover". Selenium should behave as before.
⍝ WIP:   There has been a change wrt FindElements - this needs to be fully implemented...
⍝        No other outstanding items atm...(more testing needed)
⍝        Not yet cross-platform (BHC is on it...)
⍝

    :Section ADOC

    ∇ t←Describe
      t←1↓∊(⎕UCS 10),¨{⍵/⍨∧\(⊂'')≢¨⍵}Comments ⎕SRC ⎕THIS ⍝ first block of non-empty comment lines
    ∇

    ∇ (n v d)←Version;f;s
      s←⎕SRC ⎕THIS
      f←Words⊃s                     ⍝ split first line
      n←2⊃f                         ⍝ ns name
      v←'V'~⍨⊃⌽f                    ⍝ version number
      d←1↓∊'-',¨3↑Words⊃⌽Comments s ⍝ date
    ∇

    Words←{⎕ML←3 ⋄ ⍵⊂⍨' '≠⍵}
    Comments←{1↓¨⍵/⍨∧\'⍝'=⊃∘{(∨\' '≠⍵)/⍵}¨⍵}1∘↓


    :EndSection ───────────────────────────────────────────────────────────────────────────────────

    :Section INITIALISATION

    ⎕WX←3

    DEFAULTBROWSER←'Chrome'
    RETRYLIMIT←DEFAULTRETRYLIMIT←5 ⍝ seconds

    EXT←'.dyalog'
    RIDEEXT←'.ridetest'

    PORT←8080
    :EndSection ───────────────────────────────────────────────────────────────────────────────────

    :Section MAIN FRAMEWORK PROGRAMS
    ∇ failed←{stop_site_match_config}Test path_filter;⎕USING;stop;match;site
      ⍝ stop: 0 (default) ignore but report errors; 1 stop on error; 2 stop before every test
      ⍝ site: port number (default is PORT) or URL
      ⍝ match: 0 (default) run all tests on the baseURL; 1 run tests on baseURL matching dir struct
      ⍝ config: points to an entry of your settinghs.json-Foöe
      'stop_site_match_config'DefaultTo 0
      :If 82=⎕DR stop_site_match_config  ⍝ handle mode where just the name of a config is given
          stop_site_match_config←0 0 0,⊂stop_site_match_config
      :EndIf
      :If 0<≢4⊃4↑stop_site_match_config
      :AndIf 0<≢4⊃stop_site_match_config
          ApplySettings 4⊃stop_site_match_config
      :EndIf
      InitBrowser''
      (⍎,∘'←∊Keys.(',,∘')')⍕Keys.⎕NL ¯2 ⍝ Localize non-alphanumeric key names for easy access
      failed←({3<≢⍵:3↑⍵ ⋄ ⍵}stop_site_match_config)RunAllTests path_filter
      BROWSER.Quit
    ∇

    ∇ path←base NormalizePath path
      path base←{('/'@{'\'=⍵})⍵}¨path base
      base←base,('/'≠⊃⌽base)/'/'
      :If './'≡2↑path ⋄ path←base,2↓path   ⍝ relative path
 ⍝     :ElseIf... ⍝ are there any more cases to consider???
      :EndIf
    ∇

    ∇ InitBrowser settings;browser;files;msg;path;len;options;opt;pth;subF;suffix;drv;opts;p;cap;BSVC;z;pckgs;Selenium;slnm;av;f
      options←''
      :If 0=##.⎕NC'NugetConsum'
          :If 0=≢src←50 ⎕ATX 1⊃⎕SI                                                    ⍝ loaded with 2⎕FIX or ]Get etc.
          :AndIf 0=≢src←{l←⍵[≢⍵;] ⋄ '⍝∇⍣§'≢4↑l:'' ⋄ 1↓(1=+\l='§')/l}⎕CR 1⊃⎕SI         ⍝ if ]LOADed
          :AndIf 0=⎕NEXISTS src←'/git/Selenium/NugetConsum.dyalog'
              {}⎕SE.UCMD'Get  https://github.com/Dyalog/Selenium/blob/ImprovedSettings/NugetConsum.dyalog  -target=',⍕##    ⍝ TODO: fix path when this goes into "main"
          :Else
              home←1⊃⎕NPARTS src
              0 ## ⎕SE.SALT.Load home,'NugetConsum.dyalog'
          :EndIf
      :Else
      :EndIf
      :If ×⎕NC'BROWSER' ⍝ close any open browser
          BROWSER.Quit
      :EndIf
⍝      :If 0=⎕NC'SETTINGS'
      ApplySettings settings
 ⍝     :EndIf
      browser←SETTINGS.Browser.ns  ⍝ ns is also the "name" of the browser...
      pckgs←0 4⍴⍬
     
     
      :Trap 0 ⍝ Try to find out if Browser is alive - not always reliable
          {}BROWSER.Url
      :Else
     
          pckgs⍪←SETTINGS.Components.WebDriver.(n v u f)
          pckgs[1;3],←⊂⊂'OpenQA.Selenium.',SETTINGS.Browser.ns  ⍝ also ⎕USE namespace of selected browser
      ⍝↑↑↑↑ this makes some assumptions about the namespaces - so we need to use WebDriver!
          :For nm :In SETTINGS.Components.optional.⎕NL ¯9
              p←SETTINGS.Components.optional⍎nm
              :If 0=p.⎕NC'enabled'
              :OrIf p.enabled∊1(⊂'true')
                  pckgs⍪←p.{6::'' ⋄ ⍎⍵}¨'nvuf'
              :EndIf
          :EndFor
          av←'-'~⍨⎕C 1⊃'.'⎕WG'aplversion'
          :Select SETTINGS.Browser.o
          :Case 'ChromeDriver'
              f←'driver/',(('dows' '64'⎕R'' '32')av),'/chromedriver',('w'=1⊃av)/'.exe'
          :EndSelect
     
          pckgs⍪←SETTINGS.Browser.(n v ⎕NULL),⊂f  ⍝ VALUE ERROR indicates we don't know your browser!
⍝ ⎕←pckgs
⍝      pckgs⍪←'Selenium.WebDriver.ChromeDriver' '98.0.4758.8000'⎕NULL chromedriver
⍝      pckgs⍪←'Newtonsoft.Json' '12.0.1' '' ''
     
     
          slnm←⎕NEW ##.NugetConsum.Project'Selenium'
          slnm.Quiet←0{6::⍺ ⋄ ⍎⍵}'QUIETMODE'
          {slnm.Add ⎕NEW ##.NugetConsum.Package ⍵}¨↓pckgs
     
          {}slnm.Restore
          nugetPackage←slnm
          ⎕USING←(⊂'System'),slnm.Using
     
⍝      drv←⎕NEW(⍎SETTINGS.Browser.o)⍬
          f←(slnm.Packages{(⍺.id⍳⊂⍵)⊃⍺}SETTINGS.Browser.n).FullPath   ⍝ get path from package def
          f1←∊1↓⎕NPARTS f
          pth←1⊃⎕NPARTS f
          BSVC←(⍎SETTINGS.Browser.o,'Service').CreateDefaultService(pth)(f1)
          BSVC.Start
          :Trap 90
              z←1⊣BSVC.IsRunning
          :Else
              z←0
          :EndTrap
     
          options←InitOptions browser
          :If 9=⎕NC'BROWSEROPTIONS'  ⍝ if var exists
          :AndIf 0<≢BROWSEROPTIONS
              :For opt :In BROWSEROPTIONS.⎕NL-2
                  ⍎'options.',(∊opt),'←BROWSEROPTIONS.',,∊opt
              :EndFor
          :EndIf
     
          :If 2=SETTINGS.Browser.⎕NC'AdditionalCapabilities'
          :AndIf 0 ⍝ not yet ripe for production!
              :For cap :In SETTINGS.Browser.AdditionalCapabilities
                  options.AddAdditionalCapability(cap.name)(cap.value)
              :EndFor
          :EndIf
          :If 2=SETTINGS.Browser.⎕NC'AddArguments'
              :For opt :In SETTINGS.Browser.AddArguments
                  options.AddArgument⊂opt
              :EndFor
          :EndIf
          :If 2=SETTINGS.Browser.⎕NC'LoggingPreferences'
              cap←options.ToCapabilities
     
              :For p :In SETTINGS.Browser.LoggingPreferences
                  options.SetLoggingPreference p.type(⍎p.level)
              :EndFor
          :EndIf
⍝          :If 0<SETTINGS.Browser{0::0⍴' ' ⋄ ≢⍺(⍎⍵).⎕NL ¯2}'Options'
⍝              :For opt :In SETTINGS.Browser.Options.⎕NL ¯2
⍝                  options⍎opt,'←',{' '⎕DR⍥=⍵:'''',⍵,'''' ⋄ ⍕⍵}SETTINGS.Browser.Options⍎opt
⍝              :EndFor
⍝          :EndIf
     
     
          :If ~z
              ⎕←'Could not create instance of ',browser,'DriverService.'
              ⎕←'You may have to adjust file-permissions to make this file executable:'
              :If 'w'=1⊃av
                  ⎕←⎕SH'icacls ',f
              :Else
                  ⎕←⎕SH'ls -l ',f
              :EndIf
              'Could not create DriverService - check msg in session'⎕SIGNAL 11
          :EndIf
          :If options≡''
              BROWSER←⎕NEW(⍎SETTINGS.Browser.o)BSVC
          :Else
              BROWSER←⎕NEW(⍎SETTINGS.Browser.o)(BSVC options)
          :EndIf
     
     
          CURRENTBROWSER←browser
          ACTIONS←⎕NEW Selenium.Interactions.Actions BROWSER
     
          :If ~0{6::⍺ ⋄ ⍎⍵}'QUIETMODE' ⋄ ⎕←'Starting ',browser ⋄ :EndIf
     
      :End
      :If ~×#.⎕NC'MAX'
          :Trap 90           ⍝ can't do that with CEF
              BROWSER.Manage.Window.Maximize
          :EndTrap
      :EndIf
    ∇
    ∇ options←InitOptions browser
      options←⎕NEW⍎browser,'Options'
    ∇

    ∇ SaveScreenshot ToFile
      BROWSER.GetScreenshot.SaveAsFile⊂ToFile
    ∇

    ∇ failed←stop_site_match RunAllTests path_filter;files;maxlen;n;start;i;file;msg;time;path;filter;allfiles;hasfilter;shutUp;showMsg;prefix
      path filter←2↑(eis path_filter),⊂''
      shutUp←0{6::⍺ ⋄ ⍎⍵}'QUIETMODE'  ⍝ use QUIETMODE to suppress everything BUT error-messages
      showMsg←⍎(1+shutUp⊃)'{⍵}' '{}'
      allfiles←(≢path)↓¨FindAllFiles path
      hasfilter←×≢filter
      files←filter ⎕S'%'⍣hasfilter⊢allfiles
      n←≢files
      showMsg'Selected: ',(⍕n),(hasfilter/' of ',⍕≢allfiles),' tests.'
      maxlen←⌈/≢¨files
      failed←''
      start←⎕AI[3]
      :For i file :InEach (⍳n)files
          prefix←(⎕UCS 13),maxlen↑file
          msg←stop_site_match Run1Test path file
          :If 0=⍴msg
              showMsg prefix,' *** PASSED ***'
          :Else
              failed,←⊂file
              ⎕←prefix,' *** FAILED *** #',(⍕i),' of ',(⍕n),': ',msg
          :EndIf
      :EndFor
      time←∊'ms',¨⍨⍕¨24 60⊤⌊0.5+0.001×⎕AI[3]-start
      showMsg←'Total of ',(⍕n),' samples tested in ',time,': ',(⍕≢failed),' failed.'
    ∇

    ∇ r←stop_site_match Run1Test(path file);name;Test;stop;site;match
      stop site match←3↑stop_site_match
      site←Urlify site
      {~UrlIs ⍵:GoTo ⍵}site,'/',match/file↓⍨¯7×EXT≡¯7↑file
      :Select ⊃⌽'.'Split file
      :Case RIDEEXT
          name←⎕FX'msg←Test dummy' 'RideScript','⍝',¨⊃⎕NGET(path,file)1 ⍝ Create Test function from raw RIDE script
      :Case EXT
          name←⎕SE.SALT.Load path,file
      :EndSelect
      :If ×⎕NC'name'
      :AndIf 'Test'≡name
          :Trap 0/⍨0=stop
              'Test'⎕STOP⍨1/⍨2=stop ⍝ stop on line 1 if stop=2
              r←Test ⍬
              :If stop⌊×≢r
                  ⎕←'test for ',file,' failed:'
                  ⎕←r
                  ⎕←'      Test ⍬    ⍝ to Rerun'
                  ⎕←'      →⎕LC      ⍝ to continue'
                  (⎕LC[1]+1)⎕STOP 1⊃⎕SI
              :EndIf
          :Else
              r←'Trapped error: ',,⍕⎕DMX.EN
          :EndTrap
      :EndIf
    ∇
    :EndSection ───────────────────────────────────────────────────────────────────────────────────

    :Section MISERVER UTILITIES
    ∇ {ok}←id ListMgrSelect items;elements
     ⍝ Move items from left to right in a MiServer ejListManager control
      ok←1
      elements←(id,'_left')FindListItems items
      elements DragAndDrop¨⊂id,'_right_container'
    ∇

    ∇ {ok}←{open}ejAccordionTab(tabText ctlId)
     ⍝ Make sure that a control, within an accordiontab, is visible or not
      ok←1
      'open'DefaultTo 1
      :If open≠(BROWSER.FindElement(By.Id⊂ctlId)).Displayed ⍝ If it doesn't have the desired state
          'LinkText'Click tabText
          {(open ctlId)←⍵
              open=(BROWSER.FindElement(By.Id⊂ctlId)).Displayed}Retry open ctlId
      :EndIf
    ∇

    ∇ r←id FindListItems text;li;ok
     ⍝ Find list items with a given text within element with id (e.g. [Syncfusion ej]ListBox items)
      (ok li)←{li←⌷'CssSelectors'Find'#',⍵,' li' ⋄ (0≠⍴li)li}Retry id
      r←(li.Text∊eis text)/li
    ∇
    :EndSection ───────────────────────────────────────────────────────────────────────────────────

    :Section COVER FUNCTIONS
    ∇ ClearInput obj;q
      :If 0≢q←Find obj
          q.Clear
      :EndIf
    ∇

    ∇ {ok}←obj SendKeys text;q;i;k
     ⍝ Send keystrokes - see Keys.⎕NL -2 for special keys like Keys.Enter
     ⍝ Note that even 'A' Control 'X' will be interpreted as Ctrl+A,X
     ⍝ To get A,Ctrl+X use 'A'(Control 'X')
      ok←1
      q←Find obj
      :If q≢0  ⍝ make sure that we found it!
          text←eis text
          i←4~⍨Keys.(Shift Control Alt)⍳¯1↓text
          ACTIONS.Reset
          :For k :In i
              (ACTIONS.(KeyDown ##.k⌷Keys.(Shift Control Alt))).Build.Perform
          :EndFor
          q.SendKeys,¨text~Keys.(Shift Control Alt)
      :EndIf
    ∇


    ∇ {ok}←id SetInputValue text;s;i;r
⍝ Set the value of an input control to text.
      :If ∨/i←text='"'
          text←(1+i)/text
          text[(⍸i)+(0,¯1↓+\i)[⍸i]]←'\'
      :EndIf
      s←'document.getElementById("',id,'").value= "',text,'";'
      ok←1
      :Trap 0
          r←ExecuteScript s
      :Else
          ok←0
      :EndTrap
    ∇

    ∇ {ok}←{type}Click id;b;ok;time
     ⍝ Click on an element, by default identified by id. See "Find" for options
      ok←1
      'type'DefaultTo'Id'
      b←type Find id
      ('Control "',id,'" not found')⎕SIGNAL(0≡b)/11
      b.Click
    ∇

    ∇ {ok}←fromid DragAndDrop toid;from;to
     ⍝ Drag and Drop
      ok←1
      (from to)←Find¨fromid toid
      ACTIONS.Reset
      (ACTIONS.DragAndDrop from to).Perform
    ∇

    ∇ {ok}←fromid DragAndDropToOffset xy;from
     ⍝ Drag
      ok←1
      from←Find fromid
      ACTIONS.Reset
      (ACTIONS.DragAndDropToOffset from,xy).Build.Perform
    ∇

    ∇ {ok}←{action}MoveToElement args;id;target
     ⍝ Move to element with optional x & y offsets
     ⍝ And perform optional action (Click|ClickAndHold|ContextClick|DoubleClick)
      ok←1
      (⊃args)←Find⊃args ⍝ Elements [2 3] optional x & y offsets (integers)
      ACTIONS.Reset
      (ACTIONS.MoveToElement args).Build.Perform
      ⎕DL 0.1
      :If 2=⎕NC'action'
          :If (⊂action)∊'Click' 'ClickAndHold' 'ContextClick' 'DoubleClick'
              ((ACTIONS⍎action)⍬).Build.Perform
          :Else
              ('Unsupported action: ',action)⎕SIGNAL 11
          :EndIf
      :EndIf
    ∇

    ∇ {r}←ExecuteScript script ⍝ cover for awkward syntax and meaningless result
      r←BROWSER.ExecuteScript script ⍬
    ∇

    ∇ r←{level}GetLogs types;lb;e;entry;tit;r∆;type
    ⍝ chould/should take ⍵ to select desired log(s) - once we have some data in them...;)
    ⍝ level ∊ 'Info' 'Severe'
    ⍝ types ∊ 'Browser'
    ⍝ These values depend on the browser that's used!
    ⍝ TODO: Document this!
      r←''
     
      types←types{0=≢⍺:⍵ ⋄ (⊆⍺)∩⍵}⊃⌷¨BROWSER.Manage.Logs.AvailableLogTypes
      :For type :In types
          lb←BROWSER.Manage.Logs.GetLog⊂type
          tit←'Log: ',type,' ('
          r∆←⍬
          :If 0<lb.Count
              :For e :In ⍳lb.Count
                  entry←e⌷lb
                  :If 2=⎕NC'level' ⋄ :AndIf 0<≢level ⋄ :AndIf ~(⊂⍕entry.Level)∊⊆level ⋄ :Continue
                  :EndIf
                  r∆,←⊂' ',' ',⍕entry
              :EndFor
          :EndIf
          :If 0<≢r∆
              r←r,(⊂tit,(⍕≢r∆),' entries)'),r∆
          :Else
              r←r,⊂tit,,'(no entries)'
          :EndIf
      :EndFor
    ∇
    :EndSection ───────────────────────────────────────────────────────────────────────────────────

    :Section USER UTILITIES FOR QA SCRIPTS
    ∇ r←Text element;f
    ⍝ Retrieves (visible) text of element
      :If 9≠⎕NC'element' ⋄ element←Find element ⋄ :EndIf
      :If element.TagName≡'input'
          r←element.GetAttribute⊂'value'
      :Else
          r←element.Text
      :EndIf
    ∇

    ∇ {ok}←selectId Select itemText;sp;se;type
      ⍝ Select an item in a select element
      ok←1
     ⍝ ↓↓↓ Id can be tuple of (type identifier - see Find)
      :If 2=≡selectId ⋄ (type selectId)←selectId
      :Else ⋄ type←'Id'
      :EndIf
      'Select not found'⎕SIGNAL(0≡sp←type Find selectId)/11
      se←⎕NEW OpenQA.Selenium.Support.UI.SelectElement sp
      se.SelectByText⊂,itemText
    ∇

    ∇ {ok}←selectId SelectItemText itemsText;item;se
     ⍝ Select items in a select control
     ⍝ Each item can be deselected by preceding it with '-'.
     ⍝ A single '-' deselects all
      ok←1
      se←⎕NEW SelectElement,⊂Find selectId
      :For item :In eis itemsText
          :If item≡'~'
              se.DeselectAll
          :ElseIf '~'=1↑item
              se.DeselectByText⊂1↓item
          :Else
              se.SelectByText item 1   ⍝ signature changed in WebDriver4 - do we need to distinguish?
          :EndIf
      :EndFor
    ∇

    ∇ r←{type}Find id;f;ok;time;value;attr;search;elms;mask
      :If 9=⎕NC'id'
          r←id ⍝ Already an object
      :Else
          'type'DefaultTo'Id'
          ⍝ See auto-complete on BROWSER.F for a list of possible ways to find things
          (id attr value)←{3↑⍵,(⍴⍵)↓'' '' ''}eis id
          :If search←~0∊⍴attr
              type,←('s'=¯1↑type)↓'s'
          :EndIf
          :If 's'=¯1↑type ⍝ The call FindElements*
              f←BROWSER.FindElements(By.⍎¯1↓type)
          :Else
              f←BROWSER.FindElement(By.⍎type)
          :EndIf
          time←⎕AI[3]
          :Repeat ⍝ Other functions use Retry operator, but we need to collect the result
              :Trap 0
                  r←f⊂id
                  ok←1
              :Else
                  r←0
                  :If RETRYLIMIT>0 ⋄ ⎕DL 0.1 ⋄ ok←0 ⋄ :EndIf
              :EndTrap
          :Until ok∨(⎕AI[3]-time)>1000×RETRYLIMIT ⍝ Try for a second
          :If ok
          :AndIf search
              :If 0<r.Count
                  elms←⌷r
                  :If r←∨/mask←<\(⊂value)≡¨attr∘{⍵.GetAttribute⊂⍺}¨elms
                      r←⊃mask/elms
                  :EndIf
              :Else
                  r←0   ⍝ nothing found!
              :EndIf
          :EndIf
      :EndIf
    ∇

    ∇ {ok}←(fn Retry)arg;time;z
     ⍝ Retry fn for a while
      ok←0 ⋄ time←⎕AI[3]
      :Repeat
          :Trap 0
              ok←fn arg
          :Else
              ⎕DL 0.1
          :EndTrap
      :Until (⊃ok)∨(⎕AI[3]-time)>1000×RETRYLIMIT ⍝ Try for a second
    ∇

    ∇ {ok}←Wait msec
      ok←×⎕DL msec÷1000
    ∇

    ∇ r←larg WaitFor args;f;text;msg;element
    ⍝ Retry until text/value of element begins with text
    ⍝ Return msg on failure, '' on success
      :If 9≠⎕NC'larg' ⋄ larg←Find larg ⋄ :EndIf
      :If larg≡0 ⋄ r←'Did not find element "',(⍕larg),'"' ⋄ →0 ⋄ :EndIf
      element←larg
      args←eis args
      (text msg)←2↑args,(⍴args)↓'Thank You!' 'Expected output did not appear'
      f←'{∨/''',((1+text='''')/text),'''','≡⍷'[1+×⍴,text]
      :If element.TagName≡'input'
          f,←'element.GetAttribute⊂''value''}'
      :Else
          f,←'element.Text}'
      :EndIf
      r←(~(⍎f)Retry ⍬)/msg
    ∇

    IsVisible←{(Find ⍵).Displayed}  ⍝ test if given element is Displayed (useful if combined with Retry to wait till control is accessible)
    :EndSection ───────────────────────────────────────────────────────────────────────────────────

    :Section RIDE-IN-BROWSER QA SCRIPT UTILITIES
    :Namespace Cache ⍝ to be populated by SeRef, EdRef, Lb
    :EndNamespace

    ∇ se←SeRef ⍝ Get ref to Session
      :Trap 2 6 90 ⍝ SYNTAX (not found) VALUE (first use) EXCEPTION (stale - probably won't happen)
          {}Cache.SE.Displayed
      :Else
          Cache.SE←'CssSelector'Find'.ride_win textarea'
      :EndTrap
      se←Cache.SE
    ∇
    Se←{Do:SeRef SendKeys¨⊂⍣(1=≡,⍵)⊢⍵ ⋄ 1}Retry ⍝ SendKeys in Session

    ∇ ed←EdRef ⍝ Get ref to Editor
      :Trap 6 90 ⍝ VALUE (first use) EXCEPTION (stale = new editor)
          {}Cache.ED.Displayed
      :Else
          Cache.ED←'CssSelector'Find'.ride_win_cm textarea'
      :EndTrap
      ed←Cache.ED
    ∇
    Ed←{Do:EdRef SendKeys¨⊂⍣(1=≡,⍵)⊢⍵ ⋄ 1}Retry ⍝ SendKeys in Editor

    ∇ {oks}←Lb glyphs ⍝ Click Language Bar buttons
      :If 0∊Cache.⎕NC'LB' 'LB_Text'
          Cache.LB_Text←(Cache.LB←⌷'CssSelectors'Find'#lb b').Text
      :EndIf
      oks←{Click Cache.LB⊃⍨Cache.LB_Text⍳⊂,⍵}¨glyphs
    ∇

    Tb←{'ClassName'Click'tb_',⍵}Retry ⍝ click toolbar button

    LastIs←{Do:''≡msg,←EndsWith Nested ⍵ ⋄ 1}Retry ⍝ Check last non-empty line in session

      EndsWith←{ ⍝ last session line(s) contain patterns
          h←-≢⍵
          se←h↑¯1↓Session~⊂''
          ∧/2</¯1,∊⍵ Has¨se:'' ⍝ last line is 6-space prompt
          'Session had "',(NlFmt se),'"; expected "',(NlFmt ⍵),'". '
      }

    ∇ r←Session ⍝ Session text
      r←(⌷'CssSelectors'Find'.CodeMirror-line span').Text
    ∇

      Has←{ ⍝ Location of pattern ⍵ in source ⍺
          rot←,¯1⌽⍵
          '$$'≡2↑rot:(2↓rot)⎕S 0⊢⍺
          '$;$'≡3↑rot:('^',(rot[4]~'^'),4↓rot)⎕S 0⊢⍺
          ';'=⊃⍵:0/⍨(1↓rot)≡⍺↑⍨¯1+≢⍵
          loc←⍺⍷⍵
          ∨/loc:loc⍳1
          ¯1
      }

    Fix←{⍺←2 ⋄ Se((⍕⍺),'⎕FIX''file://',⍵,'''')Enter} ⍝ Execute ⎕FIX in Session

    Gives←{Do:r←LastIs¨eis ⍵⊣Se ⍺ Enter ⋄ r←1}

    ∇ r←Do ⍝ Enables skipping to end if a problem has already occured
      :If 0=⎕NC'msg'
          msg←''
      :EndIf
      r←''≡msg
    ∇

    ∇ {r}←RideScript;lines;l;major;minor ⍝ Script processor
      ⍝ To be called before one or more comment lines
      ⍝ each script line may have one, two, or three major sections:
      ⍝     command: results: timeout
      ⍝ : is the major separator and ; is the minor separator for results
      ⍝ command gets typed into the session, and then Enter is pressed
      ⍝ if there is a "results", then (before the timemout) each of these must occur in the given order
      ⍝ the first target in results specifies the beginning of the line (so skip this with :;)
      ⍝ targets are RegEx when enclosed in Dollar signs ($)
      ⍝ the timeout may be temporarily adjusted from the default by specifying a number of seconds
      ⍝     var←6
      ⍝ just enters the assignment in the session
      ⍝     var×7: 42
      ⍝ checks that the expected result is given.
      ⍝     ⊢⎕DL 6:
      lines←{⍵/⍨'⍝'≠⊃¨⍵}{1↓¨⍵/⍨∧\'⍝'=⊃¨⍵}{⍵{((∨\⍵)∧⌽∨\⌽⍵)/⍺}' '≠⍵}¨(1+2⊃⎕LC)↓⎕NR'Test'
      msg←''
      :For l :In lines/⍨'⍝'≠⊃¨lines
          major←1↓¨':'Split l
          :If 1=≢major
              Se(⊃major)Enter
          :Else
              :If 3≤≢major
                  RETRYLIMIT←⊃∊(//⎕VFI⊃2↓major),DEFAULTRETRYLIMIT
              :EndIf
              minor←';'Split 2⊃major
              (⊃minor)↓⍨←1
              r←(⊃major)Gives minor
          :EndIf
          →0/⍨''≢msg
      :EndFor
    ∇
    :EndSection

    :Section UTILS
    Nested←{(+/∨\' '≠⌽⍵)↑¨↓⍵}⊢⍴⍨¯2↑1,⍴ ⍝ Vector of vectors from simple vector or matrix

    NlFmt←{1↓∊'¶',¨⍵} ⍝ Convert VTV to ¶-separated simple vector

    Split←,⊂⍨⊣=, ⍝ Split ⍵ at separator ⍺, but keep the separators as prefixes to each section

    ∇ r←lc R  ⍝ lowercase
      :If 18≤2⊃⎕VFI 2↑2⊃'.'⎕WG'aplversion'
          r←⎕C R
      :Else
          r←0(819⌶)R
      :EndIf
    ∇

    ∇ {ok}←GoTo url;z;base ⍝ Ask the browser to navigate to a URL and check that it did it
      ok←1
      :If 'http'≢lc 4↑url  ⍝ it's probably a relative URL (does this text need be more detailed?)
          base←BROWSER.Url
          :While (≢url)>z←url⍳'/'
              :If z=1
                  base←((2≥+\base='/')/base),'/'
              :ElseIf '../'≡z↑url
                  base←()↑base
              :ElseIf './'≡z↑url  ⍝ do nothing
              :Else
                  base←base,z↑url
              :EndIf
              url←z↓url
          :EndWhile
          url←base,url
      :EndIf
      BROWSER.Navigate.GoToUrl⊂url
      :Trap 90
          ('Could not navigate from ',BROWSER.Url,' to ',url)⎕SIGNAL 11/⍨~UrlIs url
      :Else
          ('Alert running "',url,'": ',⎕EXCEPTION.Message)⎕SIGNAL 11
      :EndTrap
    ∇

    UrlIs←{(⊂BROWSER.Url)∊⍵(⍵,'/')} ⍝ Is the browser currently at ⍵?

    List←0 1⎕NINFO⍠1⊢ ⍝ List names and types in directory ⍵

    Files←⊃(/⍨∘(2∘=))/ ⍝ Filter for files only

    Folders←⊃(/⍨∘(1∘=))/ ⍝ Filter for folders only

    DefaultTo←{0=⎕NC ⍺:⍎⍺,'←⍵' ⋄ _←⍵} ⍝ set ⍺ to ⍵ if undefined

    PathOf←{⍵↓⍨1-⌊/'/\'⍳⍨⌽⍵} ⍝ Extract path from path/filename.ext

    eis←{(≡⍵)∊0 1:,⊂,⍵ ⋄ ⍵} ⍝ Enlose (even scalars) If Simple

    Urlify←{0''⍬∊⍨⊂⍵:∇ PORT ⋄ ⍬≡0⍴⍵:'http://127.0.0.1:',⍕⍵ ⋄ ⍵} ⍝ Ensure URL even if given just port number

    ∇ r←FindAllFiles root ⍝ Recursive
      :If ∨/' '≠root
          root,←'/'/⍨~'/\'∊⍨¯1↑root ⍝ append trailing / if missing
          r←Files List root,'*',EXT
          r,←Files List root,'*',RIDEEXT
          r,←⊃,/FindAllFiles¨Folders List root,'*'
      :Else
          r←0⍴⊂''
      :EndIf
    ∇

    ⍝ ∇ {files}←browser SetUsing path;net ⍝ S)SETTINGS:Newtonpathet the path to the Selenium DLLs
    ⍝   (path Newtonpath)←path
    ⍝   :If path≡'' ⋄ path←SourcePath ⎕THIS
    ⍝   :Else ⋄ path←path,(~'/\'∊⍨⊢/path)/'/' ⋄ :EndIf
    ⍝   ⎕USING←0⍴⎕USING
    ⍝   ⎕USING,←⊂''  ⍝ VC 200513 via mail to MB

    ⍝   :If 4≠System.Environment.Version.Major  ⍝ if not .NET 4, it is likely Core!
    ⍝       net←'netstandard2.0'
    ⍝   :Else
    ⍝       net←'net47'
    ⍝   :EndIf
    ⍝       net,←⎕se.SALTUtils.FS
    ⍝   files←'dll' 'Support.dll',¨⍨⊂path,net,'WebDriver.'
    ⍝   ⎕USING,←⊂'OpenQA,',⊃files ⍝ if we need to dig into deeper into Selenium...
    ⍝   ⎕USING,←⊂'OpenQA.Selenium,',⊃files
    ⍝   ⎕USING,←⊂'OpenQA.Selenium.',browser,',',⊃files
    ⍝   ⎕USING,←⊂'OpenQA.Selenium.Support,',⊃⌽files
    ⍝   ⎕USING,←⊂'Newtonsoft.Json,',(1⊃1 ⎕NPARTS ¯1↓path),Newtonpath,net,'Newtonsoft.Json.dll'
    ⍝   ⍝ make sure we use the correct path-separator (⎕USING)

    ⍝           ⎕USING←{⎕se.SALTUtils.FS@('/'∘=)⍵}¨⎕USING

    ⍝ ∇

      SourceFile←{ ⍝ Get full pathname of sourcefile for ref ⍵
          file←50 ⎕ATX⍕⍵ ⍝ ⎕FIX
          ''≡file~' ':⍵.SALT_Data.SourceFile ⍝ SALT
          file
      }

    SourcePath←{⊃1⎕nparts SourceFile ⍵}  ⍝ just the path of the SourceFile in questions
    :EndSection ───────────────────────────────────────────────────────────────────────────────────

    :section SETTINGS
    ∇ R←GetSettings;v;varnam
      R←1⊃⎕NGET(SourcePath ⎕THIS),'settings.json5'
      R←(⎕JSON⍠'Dialect' 'JSON5')R
      R.Browsers←Flatten R.Browsers
    ∇

    ∇ R←{flavours_vars_mem}Flatten ns;vars;flavours;n;nl;z;AddVar;mem;v;f;f∆;ref
 ⍝ process tree-structures settings into a "flattened" structure
      mem←0
      :If 0=⎕NC'flavours_vars_mem'
          vars←flavours←0 2⍴''
      :ElseIf 2=≢flavours_vars_mem
          (flavours vars)←flavours_vars_mem
      :Else
          (flavours vars mem)←flavours_vars_mem
      :EndIf
     
      vars←vars AddVars ns
     
      :For n :In (ns.⎕NL-9)~⊂'Flavours'
          :If 2=(ns⍎n).⎕NC'isDriverParam'
              ns.⎕EX n,'.isDriverParam'
              vars←vars⍪(n)(⎕JSON ns⍎n)
          :Else
              flavours v←(flavours vars)Flatten ns⍎n
              :If mem
                  flavours[flavours[;1]⍳⊂n;2]←⊂v
              :EndIf
          :EndIf
      :EndFor
     
      :If 9=ns.⎕NC'Flavours'
          z←~(nl←ns.Flavours.⎕NL ¯9)∊flavours[;1]
          z←z∧nl≢¨⊂'Flavours'
          flavours⍪←(,[1.5]z/nl),⊂vars
          flavours←1⊃(flavours vars 1)Flatten ns.Flavours
      :EndIf
     
      :If 0=⎕NC'flavours_vars_mem'    ⍝ top-level
          R←#.⎕NS''
          :For v :In ↓vars
              R.{⍎(1⊃⍵),'←0⎕json 2⊃⍵'}v
          :EndFor
          :For f :In ⍳1↑⍴flavours
              ref←R.⎕NS''
              :For v :In ↓2⊃flavours[f;]
                  ref.{⍎(1⊃⍵),'←0⎕JSON 2⊃⍵'}v
              :EndFor
              ref R.{(1⊃⍵)⎕NS ⍺}flavours[f;]
          :EndFor
      :Else
          R←flavours vars
      :EndIf
    ∇

    ∇ vars←vars AddVars ns;n;i
     
      :For n :In ns.⎕NL-2
          :If (≢vars)<i←vars[;1]⍳⊂n
              vars←vars⍪2↑⊂n
          :EndIf
          vars[i;2]←⊂1 ⎕JSON ns⍎n
      :EndFor
    ∇


    ∇ ApplySettings name;settings;ref;go
      settings←GetSettings
      ref←settings{
          6::''
          d←2 ⎕NQ'.' 'GetEnvironment' 'SELENIUM_DRIVER'
          ⍺.Browsers⍎{(⊃⍸≢¨⍵)⊃⍵}⍵ d ⍺.Browser
      }name
      :If ref≡''
          ('Settings "',name,'" not found!')⎕SIGNAL 11
          ref←settings.{6::'' ⋄ ⍺⍎⍺⍎⍵}'default'
      :EndIf
      SETTINGS←⎕JSON ⎕JSON settings  ⍝ clone it (don't create a ref)
      SETTINGS.Browser←⎕JSON ⎕JSON ref
     
      DEFAULTBROWSER←ref{6::2⊃⍵ ⋄ ⍺⍎1⊃⍵}'Browser'DEFAULTBROWSER
      PORT←ref{6::2⊃⍵ ⋄ ⍺⍎1⊃⍵}'Port'PORT
      BROWSEROPTIONS←⍬  ⍝ no options found...
      :Select ⍬⍴ref.⎕NC'Options'
      :CaseList 2 9 ⋄ BROWSEROPTIONS←ref.Options
      :EndSelect
     
      ⎕USING←'System'
    ∇

    :endsection SETTINGS
:EndNamespace
