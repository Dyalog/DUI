:Class HRServer
⍝ This is the core HTMLRenderer-based server class - do not modify it!

    :Field Public Config

    :Field Public TID←¯1                ⍝ Thread ID Server is running under
    :Field Public SessionHandler
    :Field Public Authentication
    :Field Public Logger
    :Field Public Application
    :Field Public PageTemplates←⍬
    :Field Public Datasources←⍬
    :Field Public StartTime←⍬
    :Field Public Overrides
    :Field ServerName
    :Field Public ReadOnly Framework←'HRServer'
    :Field Public _Renderer←''
    :Field Public Shared DEBUG←0

    ⎕TRAP←0/⎕TRAP ⋄ (⎕ML ⎕IO)←1 1

    unicode←80=⎕DR 'A'
    NL←(CR LF)←⎕UCS 13 10
    FindFirst←{(⍺⍷⍵)⍳1}
    setting←{0=⎕NC ⍵:⍺ ⋄ ⍎⍵}
    endswith←{(,⍺){⍵≡⍺↑⍨-⍴⍵},⍵}

      bit←{⎕IO←0  ⍝ used by Log
          0=⍺:0 ⍝ all bits turned off
          ¯1=⍺:1 ⍝ all bits turned on
          (⌈2⍟⍵)⊃⌽((1+⍵)⍴2)⊤⍺}

    :section Override
⍝ ↓↓↓--- Methods which are usually overridden ---

    ∇ {r}←OverrideNiladic
      r←{__fn__←3⊃⎕SI
          0::{{0::0 ⋄ 1 Log ⎕JSON ⎕DMX ⋄ 1}⍵}0 ⍝ log any error
          85::1
          0≠#.⎕NC'Overrides.',__fn__:1⊣0(85⌶)'#.Overrides.',__fn__ ⍝ execute override function if found
          0 ⍝ otherwise nothing done
      }⍬
    ∇

    ∇ {r}←OverrideMonadic w
      r←{__fn__←3⊃⎕SI
          0::{{0::0 ⋄ 1 Log ⎕JSON ⎕DMX ⋄ 1}⍵}0 ⍝ log any error
          85::1
          0≠#.⎕NC'Overrides.',__fn__:1⊣0(85⌶)'#.Overrides.',__fn__,' ⍵' ⍝ execute override function if found
          0 ⍝ otherwise nothing done
      }w
    ∇

    ∇ {r}←a OverrideDyadic w
      r←a{__fn__←3⊃⎕SI
          0::{{0::0 ⋄ 1 Log ⎕JSON ⎕DMX ⋄ 1}⍵}0 ⍝ log any error
          85::1
          0≠#.⎕NC'Overrides.',__fn__:1⊣0(85⌶)'⍺ #.Overrides.',__fn__,' ⍵' ⍝ execute override function if found
          0 ⍝ otherwise nothing done
      }w
    ∇

    ∇ onServerLoad
      :Access Public Overridable
    ⍝ Handle any server initialization prior to starting
      OverrideNiladic
    ∇

    ∇ onServerStart
      :Access Public Overridable
    ⍝ Handle any server startup processing
      OverrideNiladic
    ∇

    ∇ onSessionStart req
      :Access Public Overridable
    ⍝ Process a new session
      OverrideMonadic req
    ∇

    ∇ onSessionEnd session
      :Access Public Overridable
    ⍝ Handle the end of a session
      OverrideMonadic session
    ∇

    ∇ onHandleRequest req
      :Access Public Overridable
    ⍝ Called whenever a new request comes in
      OverrideMonadic req
    ∇

    ∇ onHandleMSP req
      :Access Public Overridable
    ⍝ Called when MiPage invoked
      OverrideMonadic req
    ∇

    ∇ onIdle
      :Access Public Overridable
    ⍝ Idle time handler - called when the server has gone idle for a period of time
      OverrideNiladic
    ∇

    ∇ Error req
      :Access Public Overridable
    ⍝ Handle trapped errors
      :If ~OverrideMonadic req
          req.Response.HTML←'<font face="APL385 Unicode" color="red">',(⊃,/⎕DM,¨⊂'<br/>'),'</font>'
          req.Fail 500 ⍝ Internal Server Error
          1 Log ⎕DM
      :EndIf
    ∇

    ∇ level Log msg
      :Access Public overridable
    ⍝ Logs server messages
    ⍝ levels implemented in MildServer are:
    ⍝ 1-error/important, 2-warning, 4-informational, 8-transaction (GET/POST)
      :If ~level OverrideDyadic msg
          :If Config.LogMessageLevel bit level ⍝ if set to display this level of message
              ⎕←msg ⍝ display it
          :EndIf
      :EndIf
    ∇

    ∇ Cleanup
      :Access Public overridable
    ⍝ Perform any site specific cleanup
      OverrideNiladic
    ∇

⍝ ↑↑↑--- End of Overridable methods ---
    :endsection

    :section Start/Stop

    ∇ (r msg)←Run;dyalog;ws;allocated;port;ports
      :Access Public
     
      :If ~0∊⍴TID∩⎕TNUMS
          →EXIT⊣(r msg)←1('Server is already running on thread',⍕TID)
      :EndIf
     
      onServerLoad
     
      TID←RunServer&⍬
      msg←'HRServer started, serving ',Config.AppRoot
      r←0
     EXIT:
    ∇

    ∇ End
    ⍝ Called by destructor
      :Access Public
      {0:: ⋄ Logger.Stop ⍬}⍬
      {0:: ⋄ #.HttpRequest.Server←⍬}⍬
      {0:: ⋄ #.DUI.Server←⍬}⍬
      Cleanup ⍝ overridable
      TID←¯1
      ⎕DL 3 ⍝ pause for cleanup
    ∇
    :endsection

    ∇ RunServer arg;props;rdp
      ⍝ arg: dummy
     
      Stop←0
      StartTime←⎕TS
     
      :If Config.TrapErrors>0
          ⎕TRAP←#.DrA.TrapServer
          #.DrA.NoUser←1+#.DrA.MailRecipient∨.≠' '
      :EndIf ⍝ Trap MiServer Errors. See HandleMSP for Page Errors.
     
      onServerStart ⍝ meant to be overridden
     
      idletime←#.Dates.DateToIDN ⎕TS
      props←{
          0∊⍴n←(⍵.⎕NL ¯2)~⊂'Debug':''
          ⍵{⍵({∧/⊃(m n)←⎕VFI⍕⍵:n ⋄ ⍵}⍺⍎⍵)}¨n
      }Config.HRServer
      props,←⊂'Event'('onHTTPRequest' 'HandleRequest')
      _Renderer←⎕NEW'HTMLRenderer'props
      :If {0::0 ⋄ 1=⊃2⊃⎕VFI⍕Config.HRServer.Debug}⍬
          _Renderer.ShowDevTools 1
      :EndIf
      _Renderer.Wait
     RESUME: ⍝ Error Trapped and logged
      1 Log'HRServer stopped'
      :If Config.CloseOnCrash
          ⎕OFF
      :EndIf
      End
    ∇


    :section Constructor/Destructor

    ∇ Make config;rc
      :Access Public
      :Implements Constructor
      SessionHandler←⎕NS''
      Authentication←⎕NS''
      Logger←⎕NS''
      Application←⎕NS''
      Overrides←⎕NS''
      SessionHandler.Session←⎕NS''
      SessionHandler.GetSession←{⍵.Session←Session}   ⍝ So we can always
      SessionHandler.HouseKeeping←{} ⍝    call these fns
      Authentication.Authenticate←{} ⍝    without worrying
      Logger.Log←{}
      Logger.Stop←{}
      Logger.Start←{}
      Config←config
     
      PageTemplates←#.Pages.⎕NL ¯9.4
      :If 2=#.⎕NC'DEBUG' ⋄ DEBUG←#.DEBUG ⋄ :EndIf
    ∇

    ∇ UnMake
      :Implements Destructor
      End
    ∇

    :endsection

    :section RequestHandling

    ∇ names←pagedata PrepareJSONTargets names;p;m;i;nss;z
     ⍝ See if names contain JSON indexed names like editcell[Name]
     ⍝     and if so convert them to editcell.Name and make sure editcell exists
     ⍝ /// Hack by Morten awaiting cleanup or approval by Brian
     
      :If 0≠⍴i←(¯1=⎕NC names)/⍳⍴names ⍝ all invalid APL names
          names[i]←('%5B' '%5D'⎕R(,¨'[]'))¨names[i]
      :AndIf 0≠⍴i←i/⍨m←(p←names[i]⍳¨'[')≠∘⊃∘⍴¨names[i] ⍝ ... which contain '['
          nss←∪z←(m/p-1)↑¨names[i] ⍝ all namespaces mentions
          nss pagedata.⎕NS¨⊂⍬      ⍝ prepare empty nss
          names[i]←¯1↓¨names[i]    ⍝ drop trailing ']'
          names[i,¨p]←'.'          ⍝ replace '[' by '.'
      :EndIf
    ∇

    ∇ inst MoveRequestData REQ;data;m;i;lcp;props;args;mask
      :Access public shared
      inst._PageData←⎕NS''
      :If 0≠1↑⍴data←{⍵[⍋↑⍵[;1];]}REQ.Arguments⍪REQ.Data
          :If 0∊m←1,2≢/data[;1]
              data←(m/data[;1]),[1.5]m⊂data[;2]
          :EndIf
          i←{⍵/⍳⍴⍵}1=⊃∘⍴¨data[;2]
          data[i;2]←⊃¨data[i;2]
          :If 0≠⍴lcp←props←('_'≠1⊃¨props)/props←(inst.⎕NL-2) ⍝ Get list of public properties (those beginning with '_' are excluded)
          :AndIf 0≠1↑⍴args←(data[;1]∊lcp)⌿data
              args←(2⌈⍴args)⍴args
              i←lcp⍳args[;1]
              ⍎'inst.(',(⍕props[i]),')←args[;2]'
          :EndIf
          :If ∨/mask←'_'≠1⊃¨data[;1]
              args←mask⌿data
              :Trap 0
                  args[;1]←inst._PageData PrepareJSONTargets args[;1]
                  ⍎'inst._PageData.(',(⍕args[;1]),')←(⊃⍣(1=⍬⍴⍴args))args[;2]'
              :EndTrap
          :EndIf
      :EndIf
    ∇

    ∇ r←HandleRequest arg;tn;res;REQ;ext;filename
    ⍝ arg - HTMLRenderer callback data
      r←arg
      :If DEBUG≠0 ⋄ ⎕←∊' ',¨arg[11 8] ⋄ :EndIf
      REQ←⎕NEW #.HttpRequest arg
      res←REQ.Response
      REQ.Host←'dyalog_root'
      REQ.OrigPage←REQ.Page ⍝ capture the original page
     
      :If 200=res.Status
     
          REQ.Page←Config.HomePage{∧/⍵∊'/\':'/',⍺ ⋄ '/\'∊⍨¯1↑⍵:⍵,⍺ ⋄ ⍵}REQ.Page ⍝ no page specified? use the default
          REQ.Page,←(~'.'∊{⍵/⍨⌽~∨\'/'=⌽⍵}REQ.Page)/Config.DefaultExtension ⍝ no extension specified? use the default
          ext←⊃¯1↑#.Files.SplitFilename filename←Config Virtual REQ.Page
     
          SessionHandler.GetSession REQ
          Authentication.Authenticate REQ
          :If REQ.Response.Status≠401 ⍝ Authentication did not fail
              :If Config.AllowedHTTPMethods∊⍨⊂REQ.Method
                  onHandleRequest REQ ⍝ overridable
                  :If REQ.Page endswith Config.DefaultExtension ⍝ MiPage?
                      filename HandleMSP REQ
                  :Else
                      :If REQ.Method≡'get'
                          REQ.ReturnFile filename
                      :Else
                          REQ.Fail 501 ⍝ Service Not Implemented
                      :EndIf
                  :EndIf
              :Else
                  REQ.Fail 405 ⍝ Method Not Allowed
              :EndIf
          :EndIf
      :EndIf
      :If res.(File Status)∧.=1 200
          :Trap 22
              tn←res.HTML ⎕NTIE 0
              res.HTML←⎕NREAD tn,(⎕DR' '),¯1 0
              ⎕NUNTIE tn
          :Else
              REQ.Fail 404
          :EndTrap
      :EndIf
     
     SEND:
      res.Headers⍪←{0∊⍴⍵:'' '' ⋄ 'Server'⍵}Config.Server
      res.MSec-⍨←⎕AI[3]
      res.Bytes←2⍴⍴res.HTML
      r[4]←1
      r[5]←res.Status
      r[6]←⊂res.StatusText
      r[7]←⊂{⍵/⍨∧\⍵≠';'}'text/html'(res.Headers GetFromTableDefault)'content-type'
      r[9]←⊆LF,⍨∊LF,⍨¨⊃¨{⍺,': ',⍕⍵}/¨↓res.Headers
      r[10]←⊂UnicodeToHtml res.HTML
     
      8 Log REQ.PeerAddr REQ.OrigPage(res.((⍕Status)StatusText))
      Logger.Log REQ
    ∇

    ∇ r←UnicodeToHtml txt;u;ucs
      :Access public shared
    ⍝ converts chars ⎕UCS >255 to HTML safe format
      :If ~2|⎕DR txt
          r←,⍕txt
      :EndIf
      :If 0<+/u←255<ucs←⎕UCS r
          (u/r)←(~∘' ')¨↓'G<&#ZZZ9;>'⎕FMT u/ucs
          r←∊r
      :EndIf
    ∇

    ∇ file HandleMSP REQ;⎕TRAP;inst;class;z;props;lcp;args;i;ts;date;n;expired;data;m;oldinst;names;html;sessioned;page;root;MS3;token;mask;resp;t;RESTful;APLJax;flag;path;name;ext;list;fn;msg
    ⍝ Handle a "MiServer Page" request
      path name ext←#.Files.SplitFilename file
     RETRY:
     
      :If 1≠n←⊃⍴list←''#.Files.List file ⍝ does the file exist?
          :If 0=n ⍝ no match
              :If Config.RESTful ⍝ check for RESTful URI
                  (list file)←Config FindRESTfulURI REQ
                  n←⊃⍴list
              :EndIf
          :Else ⍝ multiple matches??
              1 Log'Multiple matching files found for "',file,'"?'
          :EndIf
          :If 1≠n
              :If 0=n
              :AndIf #.Files.DirExists Config.AppRoot,REQ.OrigPage↓⍨'/\'∊⍨⊃REQ.OrigPage
                  →0⍴⍨CheckDirectoryBrowser REQ
              :EndIf
              REQ.Fail 404 ⋄ →0
          :EndIf
      :EndIf
     
      date←∊list[1;3]
     
      MS3←RESTful←expired←0
      APLJax←REQ.isAPLJax
     
      :If sessioned←326=⎕DR REQ.Session ⍝ do we think we have a session handler active?
      :AndIf 0≠⍴REQ.Session.Pages     ⍝ Look for existing Page in Session
      :AndIf (n←⍴REQ.Session.Pages)≥i←REQ.Session.Pages._PageName⍳⊂REQ.Page
          inst←i⊃REQ.Session.Pages ⍝ Get existing instance
          :If expired←inst._PageDate≢date  ⍝ Timestamp unchanged?
          :AndIf expired←(⎕SRC⊃⊃⎕CLASS inst)≢(1 #.Files.ReadText file)~⊂''
              oldinst←inst
              REQ.Session.Pages~←inst
              4 Log'Page: ',REQ.Page,' ... has been updated ...'
          :EndIf
      :AndIf ~expired
          4 Log'Using existing instance of page: ',REQ.Page
          :If 9=⎕NC'#.HtmlPage'
              :If MS3←∨/(∊⎕CLASS inst)∊#.HtmlPage ⋄ inst._Request←REQ ⋄ :EndIf
          :EndIf
          :If 9=⎕NC'#.RESTfulPage'
              :If RESTful←∨/(∊⎕CLASS inst)∊#.RESTfulPage
                  inst._Request←REQ
              :EndIf
          :EndIf
      :Else
          :Trap 11 22 92
              inst←Config.AppRoot LoadMSP file ⍝ ⎕NEW ⎕SE.SALT.Load file,' -target=#.Pages'
          :Case 11 ⋄ REQ.Fail 500 ⋄ 1 Log'Domain Error trying to load "',file,'"' ⋄ →0 ⍝ Domain Error: HTTP Internal Error
          :Case 22 ⋄ REQ.Fail 404 ⋄ 1 Log'File not found - "',file,'"' ⋄ →0 ⍝ File Name Error: HTTP Page not found
          :Case 92 ⋄ REQ.Response.HTML,←'<p>Unable to load page ',REQ.Page,' due to a translation error.<br/>This is typically caused by trying to load a page containing Unicode characters when running MiServer under a Classic (not Unicode) version of Dyalog APL.</p>'
              REQ.Fail 500 ⋄ →0
          :EndTrap
          4 Log'Creating new instance of page: ',REQ.Page
          inst._PageName←REQ.Page
          inst._PageDate←date
          MS3←RESTful←0
          :If 9=⎕NC'#.HtmlPage'
              :If MS3←∨/(∊⎕CLASS inst)∊#.HtmlPage
              :OrIf RESTful←∨/(∊⎕CLASS inst)∊#.RESTfulPage
                  inst.(_Request _PageRef)←REQ inst
                  :If 0≡REQ.RESTfulReq
                      REQ.RESTfulReq←''
                  :EndIf
              :EndIf
          :EndIf
     
              ⍝ ======= Expiration (newer version of page is available) Logic =======
              ⍝ If RESTful or not sessioned, let anything through
              ⍝ If sessioned and expired, let it though
              ⍝ If sessioned but not expired, check if GET
          :If RESTful<sessioned>expired
          :AndIf ~REQ.isGet
              inst._TimedOut←1
          :EndIf
     
          :If sessioned ⋄ REQ.Session.Pages,←inst ⋄ inst.Session←REQ.Session.ID ⋄ :EndIf
      :EndIf
     
      :If sessioned ⋄ token←REQ.(Page,⍕Session.ID)
      :ElseIf ~0∊⍴REQ.PeerAddr ⋄ token←REQ.(Page,PeerAddr)
      :Else ⋄ token←⍕⎕TID
      :EndIf
     
    ⍝!!!BPB!!! Finish Me
      :If 0≠inst.⎕NC'Cacheable'
      :AndIf inst.Cacheable
      :AndIf ~0∊⍴inst._cache
          REQ.Response.HTML←inst._cache
          →0
      :EndIf
     
      :Hold token
          onHandleMSP REQ ⍝ overridable
     
          :If expired∧REQ.isPost ⍝ move old public fields (those beginning with '_' are excluded)
              {0:: ⋄ ⍎'inst.',⍵,'←oldinst.',⍵}¨⊃∩/{⍵/⍨'_'≠⊃¨⍵}¨(inst oldinst).⎕NL ¯2.2
          :EndIf
     
     ⍝ Move arguments / parameters into Public Properties
          inst MoveRequestData REQ
     
          fn←'Render'
          :If APLJax>RESTful ⍝ if it's an APLJax (XmlHttpRequest) request (but not web service)
              REQ.Response.NoWrap←1
              fn←'APLJax' ⍝ default callback function name
              :If MS3
                  inst._what←REQ.GetData'_what'
                  inst._event←REQ.GetData'_event'
                  inst._value←REQ.GetData'_value'
                  inst._selector←REQ.GetData'_selector'
                  inst._target←REQ.GetData'_target'
                  inst._currentTarget←REQ.GetData'_currentTarget'
                  inst._callback←REQ.GetData'_callback'
                  :If ~0∊⍴inst._callback ⍝ does the request specify a callback function?
                      fn←inst._callback
                  :EndIf
              :EndIf
          :ElseIf RESTful
              fn←'Respond'
          :ElseIf MS3
              fn←'Compose'
          :EndIf
     
          :If 3≠⌊|inst.⎕NC⊂fn            ⍝ and is it a public method?
              1 Log msg←'Method "',fn,'" not found (or not public) in page "',REQ.Page,'"'
              REQ.Fail 500 msg
              →0
          :EndIf
     
          :If MS3
              :If APLJax
                  inst._resetAjax
              :Else
                  inst._init ⍝ reset instance's content
              :EndIf
          :EndIf
     
          :If (1=Config.TrapErrors)∧9=⎕NC'#.DrA' ⋄ ⎕TRAP←#.DrA.TrapServer
          :ElseIf (0=Config.Production) ⋄ ⎕TRAP←(800 'C' '→FAIL')(811 'E' '⎕SIGNAL 801')(813 'E' '⎕SIGNAL 803')(812 'S')((85,99+⍳500)'N')(0 'E' '⍎#.DUI.Oops') ⍝ enable development debug framework
          :EndIf
     
          :If flag←APLJax
          :AndIf flag←inst.{6::0 ⋄ _DebugCallbacks}⍬
          :EndIf
     
          :Trap 85   ⍝ we use 85⌶ because "old" MiPages use REQ.Return internally (and don't return a result)...
              resp←flag Debugger'inst.',fn,(MS3⍱RESTful)/' REQ'  ⍝ ... whereas "new" MiPages return the HTML they generate
              resp←(#.JSON.toAPLJAX⍣APLJax)resp
              inst._TimedOut←0
     
              :If RESTful
                  :If ~(⊂'content-type')(∊#.Strings.nocase)REQ.Response.Headers[;1]
                      'Content-Type'REQ.SetHeader'application/json'
                      resp←1 #.JSON.fromAPL resp
                  :EndIf
              :EndIf
              REQ.Return resp
          :Else
              :If APLJax
                  1 Log'No result returned by callback method "',fn,'" in page "',REQ.Page,'"'
                  REQ.Return''
              :EndIf
          :EndTrap
     
          :If APLJax⍱RESTful
              'Content-Type'REQ.SetHeaderIfNotSet'text/html;charset=utf-8'
          :EndIf
     
          :If ~REQ.Response.NoWrap
              :If MS3∨RESTful
                  inst.Wrap
              :Else
                  inst.Wrap REQ
              :EndIf
          :ElseIf MS3>APLJax
              inst.Render
          :EndIf
      :EndHold
      →0
     
     FAIL:
      ⎕←'* Carrying on...'
      ⎕TRAP←0⍴⎕TRAP
      REQ.Fail 500 ⋄ →0
     
     RESUME: ⍝ RESUME is used by DrA
      ⎕TRAP←0/⎕TRAP ⍝ Let framework trapping take over
     
      :If #.DrA.UseHTTP ⋄ REQ.Fail 500 ⋄ →0 ⋄ :EndIf
     
      REQ.Title'Unhandled Execution Error'
      REQ.Style'Styles/error.css'
      html←'<h1>Server Error in ''',REQ.Page,'''.<hr width=100% size=1 color=silver></h1>'
      html,←'<h2><i>Unhandled Exception Error</i></h2>'
      html,←'<b>Description:</b> An unhandled exception occurred during the execution of the current web request.'
      :If #.DrA.Mode=2 ⍝ Allows editing
          html,←'<br><br><b>Edit page: <a href="/Admin/EditPage?FileName=',REQ.Page,'">',REQ.Page,'</a><br>'
      :EndIf
      html,←'<br><br><b>Exception Details:</b><br><br>'
      :If (#.DrA.Mode>0)∧0≠⍴#.DrA.LastFile ⋄ html,←#.DrA.(GenHTML LastFile)
      :Else ⋄ html,←'<code><font face="APL385 Unicode">',(⊃,/#.DrA.LastError,¨⊂'<br>'),'</font></code>'
      :EndIf
      REQ.Return html
    ∇

    ∇ inst←root LoadMSP file;path;name;ext;ns;class
      path name ext←#.Files.SplitFilename file
      ns←root NamespaceForMSP file
      inst←⎕NEW class←⎕SE.SALT.Load file,' -target=',⍕ns
     
      :If ~name(≡#.Strings.nocase)class←⊃¯1↑'.'#.Utils.penclose⍕class
          1 Log'Filename/Classname mismatch: ',file,' ≢ ',class
      :EndIf
    ∇

    ∇ ns←root NamespaceForMSP file;path;name;ext;rpath;tree;created;n;level;node;mask
    ⍝ because a MiSite can have a folder structure where files in different folders may have the same name
    ⍝ we construct a namespace hierarchy which mimics the folder hierarchy to contain MiPage instances
      path name ext←#.Files.SplitFilename file
      rpath←(⍴root)↓path
      ns←#.Pages
      tree←'/'#.Utils.penclose rpath
      created←(n←⍴tree)⍴0
     
      :For level :In ⍳n
          :Select ⊃ns.⎕NC⊂node←level⊃tree
          :Case 0
              :Trap 11
                  ns←⍎node ns.⎕NS''
              :Else
                  1 Log'Unable to create namespace in #.Pages for page in file "',file,'"'
                  ⎕SIGNAL 11
              :EndTrap
              ns⍎'(',(⍕PageTemplates),')←',∊'##.'∘,∘⍕¨PageTemplates
              created[level]←1
          :Case 9.1
              ns←ns⍎node
          :Else
              1 Log'Unable to create namespace in #.Pages for page in file "',file,'" due to name conflict'
              :While ∨/created  ⍝ clean up any created nodes
                  ns←ns.##
                  ns.⎕EX⊃(mask←⌽<\⌽created)/tree
                  created∧/←~mask
              :EndWhile
              ⎕SIGNAL 11
          :EndSelect
      :EndFor
    ∇

    :endsection

    :section Misc

    GetFromTableDefault←{⍺←'' ⋄ ⍺{0∊⍴⍵:⍺ ⋄ ⍵}⍵ {((819⌶⍵[;1])⍳⊆819⌶⍺)⊃⍵[;2],⊂''} ⍺⍺} ⍝ default_value (table ∇) value

    ∇ r←flag Debugger w
      :If flag
          ⎕←'* Callback debugging active on this page, press Ctrl-Enter to trace into Callback function'
          Debug ⎕STOP'Debugger'
      :EndIf
      :Trap 85
     Debug:r←1(85⌶)w
      :Else
          :If flag ⋄ ⍬ ⎕STOP'Debugger' ⋄ :EndIf
          ⎕SIGNAL 85
      :EndTrap
      :If flag ⋄ ⍬ ⎕STOP'Debugger' ⋄ :EndIf
    ∇

    ∇ r←Subst arg;i;m;str;c;rep
      ⍝ Substitute character c in str with rep
      str c rep←arg
      i←c⍳str
      m←i≤⍴c
      (m/str)←rep[m/i]
      r←str
    ∇

    ∇ file←Config Virtual page;mask;f;ind;t;path;root
      :Access public shared
    ⍝ checks for virtual directory
      root←(-'/\'∊⍨¯1↑root)↓root←Config.AppRoot
      page←('/\'∊⍨1↑page)↓page
      file←root,'/',page
      :If 0<⍴Config.Virtual
          ind←Config.Virtual.alias⍳⊂t←{(¯1+⍵⍳'/')⍴⍵}page
          :If ind≤⍴Config.Virtual.alias
              path←ind⊃Config.Virtual.path
              file←#.Files.Normalize path,('/\'∊⍨¯1↑path)↓(⍴t)↓page
          :EndIf
      :EndIf
    ∇

    ∇ (list filename)←Config FindRESTfulURI REQ;page;n;inds;i
    ⍝ RESTful URIs can be ambiguous
    ⍝ For example:  is /Misc/ws/ws
    ⍝    a call to /Misc/ws/ws.mipage
    ⍝    a call to /Misc/ws.mipage    with /ws as a parameter?
    ⍝ or a call to /Misc.mipage       with /ws/ws as a parameter?
    ⍝ This utility attempts to look up the folder structure to find the matching file
     
      inds←⌽{⍵/⍳⍴⍵}'/'=REQ.OrigPage
      :For i :In inds
          page←(i-1)↑REQ.OrigPage
          page,←(~'.'∊{⍵/⍨⌽~∨\'/'=⌽⍵}page)/Config.DefaultExtension ⍝ no extension specified? use the default
          filename←Config Virtual page
          :If 1=⊃⍴list←''#.Files.List filename
              REQ.RESTfulReq←i↓REQ.OrigPage
              REQ.Page←page
              →0
          :EndIf
      :EndFor
    ∇

    ∇ r←CheckDirectoryBrowser REQ;folder;file;F;filter;template;propagate;up;directory;inst;code;page;breadcrumb
    ⍝ checks if the requested URI is a browsable directory
      folder←page←{⍵,'/'/⍨~'/\'∊⍨¯1↑⍵}REQ.OrigPage
      r←up←0
      :Trap 0/0 ⍝!!! remove 0/ after testing
          :While r⍱0∊⍴folder
              :If #.Files.Exists file←Config.AppRoot,folder,'Folder.xml'
                  F←⎕NEW #.DUI.ConfigSpace file
                  :If F.Get'browsable' 1 0
                      filter←F.Get'filter'
                      template←{0∊⍴⍵:'MiPage' ⋄ ⍵}F.Get'template'
                      propagate←F.Get'propagate' 1 0
                      →0⍴⍨up>propagate
                      code←⊂':Class directorybrowser : #.Pages.',template
                      code,←'∇Compose' ':Access Public'
                      code,←⊂'Add #._html.title ''',(1↓⊃⌽('/'∘=⊂⊢)¯1↓page),''''
                      breadcrumb←(∊1∘↓,⍨((,\{'<a class="breadcrumb" href="',⍺,'">',⍵,'</a>'}¨⊢)⊃⊂⍨¯1⌽'/'=⊃))#.Files.SplitFilename page,filter
                      code,←⊂'Add #._html.h2 ''Directory Listing for ',breadcrumb,''''
                      code,←('''dirBrowser'' Add #._DC.DirectoryBrowser ''',page,''' ''',filter,''' ',(⍕propagate),' ',⍕up)'∇' ':EndClass'
                      inst←⎕NEW ⎕FIX code
                      inst._Request←REQ
                      inst.Compose
                      inst.Wrap
                      r←1
                  :EndIf
              :Else
                  up←1
                  folder←{⍵↓⍨-⊥⍨⍵≠'/'}¯1↓folder
              :EndIf
          :EndWhile
      :EndTrap
    ∇
    :endsection

:EndClass
