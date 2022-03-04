:Class GhostRider

⍝ Headless RIDE client for QA and automation.
⍝ This class will connect to an APL process (or create a new one)
⍝ and synchronously communicate through the RIDE protocol in order to control it.
⍝ This means that when the GhostRider expects a response from the interpreter
⍝ it will block the APL thread until it gets it.
⍝ Dyalog v18.0 Unicode or later required.

⍝ To create a new APL process and connect to it
⍝    R←⎕NEW GhostRider {env}
⍝ - optional {env} is a string giving a list of environment variables to set up for the interpreter
⍝   e.g. 'MAXWS=1G WSPATH=.'
⍝   defaults to ''

⍝ To connect to an existing process
⍝    R←⎕NEW GhostRider (port {host})
⍝ - port is the positive integer port number to connect to.
⍝ - optional {host} is a string giving the ip address to connect to
⍝   {host} defaults to '127.0.0.1' which is the local machine


⍝ RIDE commands usually wait for a response,
⍝ which may be changing the prompt type, or touching a window (edit, tracer, dialog, etc.).
⍝ This is specified by a 2-element vector :
⍝ <wait> ←→ (waitprompts waitwins)
⍝ - waitprompts is a list of prompt types to wait for
⍝ - waitwins is either a number of windows to wait for, or a list of windows to wait for.
⍝ Both conditions are awaited for (the conjunction is AND and not OR),
⍝ excepted when waiting for no prompt and no window : the first prompt or window that happens returns.
⍝ The default is to wait for any prompt to come back (1 2 3 4)
⍝ and to wait for no window (0) because windows generally pop up before the prompt comes back.
⍝
⍝ RIDE commands return a 4-element result :
⍝ <result> ←→ (prompt output wins errors)
⍝ - prompt is the last prompt that was set (each is integer, see below)
⍝ - output is the string of session output (including newlines)
⍝ - wins is list of opened windows (each is a namespace - see below)
⍝ - errors is the list of ⎕SIGNAL-ed errors (there should be one at most)
⍝
⍝ Valid prompt types are :
⍝ - ¯1 = prompt unset
⍝ - 0 = no prompt
⍝ - 1 = the usual 6-space APL prompt (a.k.a. Descalc or "desktop calculator")
⍝ - 2 = Quad(⎕) input
⍝ - 3 = ∇ line editor
⍝ - 4 = Quote-Quad(⍞) input
⍝ - 5 = any prompt type unforeseen here.
⍝
⍝ Each window is a namespace with the following fields:
⍝ - id: integer identifying the window
⍝ - type : one of
⍝          'Editor' 'Tracer' (IDE windows)
⍝          'Notification' 'Html' (message boxes - no reply)
⍝          'Options' 'Task' 'String' (dialog boxes - reply expected)
⍝ - title: name being edited/traced or title of dialog box
⍝ - text: content of the window (list of strings)
⍝ - line (Editor and Tracer only): current line number
⍝ - stop (Editor and Tracer only): list of line numbers that have break points  ⍝ stop
⍝ - saved (Editor and Tracer only): integer specifying the SaveChanges error number, or ⍬ if edit was not saved
⍝ - options (Options and Task only): list of clickable options (list of strings)
⍝ - index (Options and task only): list of index value for each option (list of integers)
⍝ - value (String only): initial value of the text field
⍝ - default (String only): default value of the text field
⍝
⍝ errors is a 4-element vector akin to ⎕DMX fields
⍝ - EN: error number (scalar integer)
⍝ - ENX: extended error number (scalar integer)
⍝ - EM: error message (string)
⍝ - Message: detailed message (string)


⍝ Public API:
⍝
⍝ The following function execute simple APL code that must not pop-up windows (e.g. ⎕ED, 3500⌶) nor produce a non-standard prompt (⎕, ⍞, ∇-editor)
⍝ It will ⎕SIGNAL any error.
⍝ output ← APL expr                     ⍝ Execute a simple APL expression and get session output

⍝ The following functions execute code: they take a 3-element <wait> argument and return a 4-element <result>
⍝ <result> ← {<wait>} Execute expr      ⍝ Execute an arbitrary session expression
⍝ <result> ← {<wait>} Trace expr        ⍝ Start tracing an expression
⍝ <result> ← {<wait>} TraceRun win      ⍝ Run current line and move to next line (step over)
⍝ <result> ← {<wait>} TraceInto win     ⍝ Run current line and trace into callees (step into)
⍝ <result> ← {<wait>} TraceResume win   ⍝ Resume execution of current thread
⍝ <result> ← {<wait>} TraceReturn win   ⍝ Run current function until return to next line of caller
⍝ <result> ← Resume <wait>              ⍝ Resume all threads
⍝ <result> ← Wait <wait>                ⍝ Just wait for something to happen, without sending any message
⍝
⍝ The following functions change the state of the tracer without executing code (and don't return anything)
⍝ TraceCutback win                      ⍝ Cut back to caller
⍝ TraceNext win                         ⍝ Jump to next line
⍝ TracePrev win                         ⍝ Jump to previous line
⍝
⍝ src←Reformat src                      ⍝ Reformat code
⍝ win←EditOpen name                     ⍝ Start editing a name (may create a new window or jump to an existing one)
⍝ res←win EditFix src {stops}           ⍝ Fix new source (and optional stops) in given window - may succeed, fail, or pop-up a dialog window
⍝ win←{type}ED name                     ⍝ Cover for ⎕ED that returns the created windows
⍝ win SetStops stops                    ⍝ Change stop points (edit or trace window)
⍝ (traces stops monitors) ← ClearTraceStopMonitor   ⍝ Clear all races, stops, and monitors in the active workspace. The reply says how many of each thing were cleared.
⍝ {type} Edit (name src {stops})        ⍝ Open a name with the editor, fix the new source, and close the window. Will force overwriting the file if the interpreter asks.
⍝
⍝ wins←Windows                          ⍝ List all open windows
⍝ CloseWindow win                       ⍝ Close a window
⍝ CloseWindows                          ⍝ Close all windows (including message and dialog boxes)
⍝ CloseAllWindows                       ⍝ Close all edit/tracer windows with special RIDE protocol message
⍝ {response} Reply win                  ⍝ Reply to a dialog window - may resume execution in which case a Wait might be necessary

⍝ Notes:
⍝ - Edit/trace windows are represented as namespaces with fields for window attributes
⍝   (see the WINS field of this class)

⍝ Not supported:
⍝ - Multi-threading, Interrupts, Auto-completion, Value Tips
⍝ - SIStack, Threads, Status, Workspace Explorer, Process Manager





    :Field Public Shared ReadOnly Version←'1.3.11'
    ⍝ v1.3.11 - Nic 2021
    ⍝   - force reading the whole buffer on TCP error
    ⍝ v1.3.10 - Nic 2021
    ⍝   - changed editor task question in v18.1
    ⍝ v1.3.9 - Nic 2021
    ⍝   - Added support to fix to mantis 18408 in v18.1 (no trace and monitor points)
    ⍝ v1.3.8 - Nic 2021
    ⍝   - Added MULTITHREADING flag to ignore spurious SetPrompt(1) from threads displaying stuff
    ⍝   - Added Output function to get pending output
    ⍝ v1.3.7 - Nic 2020
    ⍝   - fixed the 1400⌶ issue that was preventing garbage collection
    ⍝ v1.3.6 - Nic 2020
    ⍝   - force Conga to load into GhostRider class parent rather than in # so that )clear works when GhostRider resides in ⎕SE
    ⍝ v1.3.5 - Nic 2020
    ⍝   - added support for Edit to cope with TaskDialog (asking to load from file) before opening editor window
    ⍝ v1.3.4 - Nic 2020
    ⍝   - added APL method for simple APL evaluation (no prompt, no window)
    ⍝   - added Edit method for simple Editor fixing (forcing save if dialog window appears)
    ⍝ v1.3.3 - Nic 2020
    ⍝   - changed default wait to (waitprompts waitwindows←(1 2 3 4) 0) because windows pop up before the prompt comes back
    ⍝ v1.3.2 - Nic 2020
    ⍝   - avoid waiting the whole TIMEOUT in constructor
    ⍝   - fixed QA, added bug repros
    ⍝ v1.3.1 - Nic 2020
    ⍝   - avoid waiting the whole TIMEOUT for messages, which is slow AND unreliable
    ⍝ v1.3.0 - Nic 2020
    ⍝   - API to control dialog boxes
    ⍝ v1.2.0 - Nic 2020
    ⍝   - API to control tracer
    ⍝   - Added GetTcpPort to avoid re-using the same port number and failing the constructor
    ⍝ v1.1.0 - Nic 2020
    ⍝   - API to control editor
    ⍝ v1.0.1 - Nic 2020
    ⍝   - Using Tool.New to initialise Conga
    ⍝   - Using APLProcess to launch interpreter
    ⍝   - Unicode edition only
    ⍝ v1.0.0 - Unknown author, unknown date


    ⎕IO←⎕ML←1

    :Field Public INFO←0                    ⍝ set to 1 to log debug information
    :Field Public TRACE←0                   ⍝ set to 1 to fully trace the RIDE protocol
    :Field Public DEBUG←0                   ⍝ set to 1 to maximise the likelihood of finding a bug

    :Field Public Shared ReadOnly IS181←18.1≤1 .1+.×2↑⊃(//)'.'⎕VFI 2⊃'.'⎕WG'AplVersion'
    :Field Public MULTITHREADING←IS181      ⍝ allow other threads to spuriously SetPrompt(1) - seems unavoidable since Dyalog v18.1

    :Field Public TIMEOUT←200               ⍝ maximum Conga timeout in milliseconds for responses that don't require significant computation
    :Field Public BUFSIZE←2*15 4            ⍝ Conga buffer size for DEBUG=0 and DEBUG=1 - use small value for harsh QA that may miss messages

    :Field Private Shared ReadOnly LF←⎕UCS 10
    :Field Private Shared ReadOnly CR←⎕UCS 13
    :Field Public NL←CR                 ⍝ newline character for output : (CR) is APL-friendly, (LF) is system-friendly

    :Field Private Shared ReadOnly ERRNO←309        ⍝ error number signaled by this class
    :Field Private Shared ReadOnly CONGA_ERRNO←999  ⍝ error number signaled by Conga
    :Field Private BUFFER←0⍴⊂''                 ⍝ list of received chunks
    :Field Public PROCESS←⎕NULL                 ⍝ APLProcess to launch RIDE (if required)
    :field Public CLIENT←⎕NULL                  ⍝ Conga connection

    :Field Public Shared MyDRC←⎕NULL            ⍝ Conga namespace - loaded from conga workspace - must not be called Conga nor DRC because we load Conga into this class and Tool.(New→Prepare→LoadConga) will test where.⎕NC'Conga' 'DRC' which return ¯2.2 if DRC is a Shared Field, even though it is unassigned.
    :Field Public Shared APLProcess←⎕NULL       ⍝ APLProcess namespace - loaded from APLProcess.dyalog

    :Field Public Shared ReadOnly ERROR_OK←0 0 '' ''  ⍝ error←(EN ENX EM Message)
    :Field Public Shared ReadOnly ERROR_STOP←1001 0 '' ''  ⍝ error returned when hitting a breakpoint
    :Field Public Shared ReadOnly NO_ERROR←0⍴⊂ERROR_OK       ⍝ no error produces this list of errors
    :Field Public Shared ReadOnly ERROR_BREAK←,⊂ERROR_STOP   ⍝ simple breakpoint produces this list of errors
    :Field Public Shared ReadOnly NO_WIN←0⍴⎕NULL   ⍝ empty list of windows (force prototype to ⎕NULL)

    :Field Private WINS←NO_WIN                  ⍝ list of editor/tracer windows currently opened


    Resignal←⎕SIGNAL∘{⍵/⊂⎕DMX.(('EN'EN)('ENX' ENX)('EM'EM)('Message'Message))}
    Signal←⎕SIGNAL∘{(en enx em msg)←⍵ ⋄ ⊂('EN' en)('ENX' enx)('EM' em)('Message'msg)}

    Error←{IsInteger ⍺: ((⍺+2)⊃⎕SI)∇⍵ ⋄ ((⍕⎕THIS),' ',⍺,' failed: ',⍕⍵)⎕SIGNAL ERRNO}
    Log←{⎕←(⍕⎕THIS),' ',⍺,': ',,⍕⍵ ⋄ 1:_←⍵}
    LogWarn←{⍺←'' ⋄ 1:_←('Warning',(~0∊⍴⍺)/' ',⍺)Log ⍵}   ⍝ always warn
    LogInfo←{⍺←'' ⋄ INFO:_←('Info',(~0∊⍴⍺)/' ',⍺)Log ⍵ ⋄ 1:_←⍵}
    TrimReplyGetLog←{pre←'["ReplyGetLog",{"result":[' ⋄ post←']}]' ⋄ (pre,post)≡((≢pre)↑⍵),((-≢post)↑⍵):pre,'...',post ⋄ ⍵}  ⍝ this one is too large to trace
    LogTrace←{TRACE:_←⍵⊣('Trace ',⍺)Log TrimReplyGetLog ⍵ ⋄ 1:_←⍵}

    GetLength←{256⊥⎕UCS 4↑⍵}
    AddHeader←{((⎕UCS (4/256)⊤8+≢⍵),'RIDE'),⍵}
    ToUtf8←{⎕UCS 'UTF-8'⎕UCS ⍵}
    FromUtf8←{'UTF-8'⎕UCS ⎕UCS ⍵}
    Stringify←{'''',((1+⍵='''')/⍵),''''}

    IsStops←{(1≡≢⍴⍵)∧(1≡≡⍵)∧(⍬≡0⍴⍵)}
    IsPrompts←{1≡∧/⍵∊(~⍺)↓¯1 0 1 2 3 4 5}  ⍝ ⍺←1 to allow ¯1 (prompt unset)
    PromptIs←{⍺∊⍵,MULTITHREADING/1}
    IsSource←{(1≡≢⍴⍵)∧(2≡≡⍵)∧(∧/''∘≡¨0⍴¨⍵)}
    IsWin←{⍵∊WINS}
    IsString←{(1≡≢⍴⍵)∧(1≡≡⍵)∧(''≡0⍴⍵)}
    IsInteger←{(0=≡⍵)∧(⍬≡0⍴⍵):⍵≡⌊⍵ ⋄ 0}


    ∇ ok←LoadLibraries;Tool;where
    ⍝ Failure to load library will cause ⎕SE.SALT.Load to error
      :Access Shared
      :If MyDRC≡⎕NULL
          Tool←⎕SE.SALT.Load'Tool'
          ⍝ where←#  ⍝ will prevent )clear if GhostRider resides in ⎕SE
          ⍝ where←⎕THIS  ⍝ can't load here because refix produces a DLL ALREADY LOADED error
          where←(⊃⊃⎕CLASS ⎕THIS)  ⍝ load in the GhostRider class
          ⍝where←(⊃⊃⎕CLASS ⎕THIS).##  ⍝ use the parent of the class to avoid reinitialising DRC on refix
          MyDRC←Tool.New'Conga' '' ''(0 0 0)where
          {}MyDRC.SetProp'' 'EventMode' 1
      :EndIf
⍝      :If ⍝APLProcess≡⎕NULL
⍝          APLProcess←⎕SE.SALT.Load(1⊃⎕nparts #.GhostRider.SALT_Data.SourceFile),'APLProcess -target=',⍕⊃⊃⎕CLASS ⎕THIS  ⍝ ensure we load it in the shared class and not in the instance
⍝      :EndIf
    ∇

    ∇ port←GetTcpPort;addr;rc;srv
    ⍝ find a free TCP port by starting and closing a conga server (pretty heavy weight...)
      :Access Public
      (rc srv)←MyDRC.Srv'' '127.0.0.1' 0 'Text'
      :If rc≠0 ⋄ 'GetTcpPort'Error'Failed to start server' ⋄ :EndIf
      (rc addr)←MyDRC.GetProp srv'LocalAddr'
      :If rc≠0 ⋄ 'GetTcpPort'Error'Failed to get local TCP/IP address' ⋄ :EndIf
      port←4⊃addr
      CloseConga srv
    ∇

    ∇ Constructor0
      :Access Public
      :Implements Constructor
      Constructor ⍬
    ∇

    ∇ Constructor args;RIDE_INIT;_;env;host;port;r;runtime;tm1;tm2;logfile
      :Access Public
      :Implements Constructor
      ⎕RL←⍬ 1  ⍝ for ED and _RunQA
      LoadLibraries
      :If (0∊⍴args)∨(''≡0⍴args)  ⍝ spawn a local Ride - args is {env}
          host←'127.0.0.1' ⋄ port←GetTcpPort
          env←,⍕args ⋄ RIDE_INIT←'serve::',⍕port ⍝ only accept local connections
          runtime←0  ⍝ otherwise we'd need to keep the interpreter busy
          :If 0∊⍴('\sDYAPP='⎕S 0)env  ⍝ don't inherit some environment variables
              env,←' DYAPP='
          :EndIf
          ⍝:If 0∊⍴('\sSESSION_FILE='⎕S 0)env  ⍝ don't inherit some environment variables
          ⍝    env,←' SESSION_FILE='
          ⍝:EndIf
          logfile←(1⊃⎕nparts {0::(1⊃1⎕nparts''),⍵ ⋄ 0<≢⍵:⍵⋄SALT_Data.SourceFile}50⎕atx 1⊃⎕si),'ghostriderlog.txt'
          ⍝ ⎕←'grlogfile=',logfile
          PROCESS←⎕NEW #.APLProcess(''env runtime RIDE_INIT logfile)
          ⎕DL 0.3  ⍝ ensure process doesn't exit early
          :If PROCESS.HasExited
              'Constructor'Error'Failed to start APLProcess: RIDE_INIT=',RIDE_INIT,' env=',env
          :EndIf
      :Else  ⍝ connect to an existing Ride - args is (port {host})
          (port host)←2↑args,⊂''  ⍝ port is integer and must be specified
          :If ⍬≢⍴port ⋄ :OrIf ⍬≢0⍴port ⋄ :OrIf port≠⌊port ⋄ :OrIf 0≠11○port ⋄ :OrIf port≤0
              'Constructor'Error'Port number must be positive integer: ',⍕port
          :EndIf
          :If 0∊⍴host ⋄ host←'127.0.0.1' ⋄ :EndIf  ⍝ default to local machine
          args←''
          PROCESS←⎕NULL  ⍝ no process started
      :EndIf
      tm1←'SupportedProtocols=2' ⋄ tm2←'UsingProtocol=2'
      ⎕DF('@',host,':',⍕port){(¯1↓⍵),⍺,(¯1↑⍵)}⍕⎕THIS
      :If 0≠⊃(_ CLIENT)←2↑r←MyDRC.Clt''host port'Text'((1+DEBUG)⊃BUFSIZE)
          'Constructor'Error'Could not connect to server ',host,':',⍕port
      :ElseIf 1=≢('Constructor'WaitFor 0)tm1  ⍝ first message is not JSON
      :AndIf Send tm1
      :AndIf 1=≢('Constructor'WaitFor 0)tm2  ⍝ second message is not JSON
      :AndIf Send tm2
      :AndIf EmptyQueue'Identify'
      ⍝ from this point on, Windows interpreter may or may not send zero or more FocusThread or SetPromptType at different points in time
      :AndIf Send'["Identify",{"identity":1}]'
      :AndIf 2≤≢'FocusThread' 'SetPromptType'('Constructor'WaitFor 1)'Identify' 'UpdateDisplayName'  ⍝ interpreter sends one 'Identify' and one 'UpdateDisplayName'
      :AndIf Send'["Connect",{"remoteId":2}]'
      :AndIf 1≤≢'FocusThread' 'ReplyGetLog'('Constructor'WaitFor 1)'SetPromptType'  ⍝ interpreter sends zero or more 'ReplyGetLog'  and one 'SetPromptType'
      :AndIf Send'["CanSessionAcceptInput",{}]'
      
:AndIf 1≤≢'FocusThread' 'SetPromptType' 'AppendSessionOutput'('Constructor'WaitFor 1)'CanAcceptInput'
      :AndIf Send'["GetWindowLayout",{}]'  ⍝ what's this for ????
      :AndIf EmptyQueue'GetWindowLayout'  ⍝ no response to GetWindowLayout ????
      :AndIf Send'["SetPW",{"pw":32767}]'
      :AndIf EmptyQueue'SetPW'
      ⍝:AndIf 1('⍫⌽⍋⍒<¯¨',NL)(NO_WIN)(NO_ERROR)≡Execute'⌽''¨¯<⍒⍋⍉⍫'''  ⍝ try and execute APL
          LogInfo'Connection established'
      :Else
          Terminate
          'Constructor'Error'RIDE handshake failed'
      :EndIf
    ∇

    ∇ CloseConga obj
      :Trap CONGA_ERRNO   ⍝ )clear can un-initialise Conga, making MyDRC.Close ⎕SIGNAL 999 instead of returning error code 1006 - ERR_ROOT_NOT_FOUND - Please re-initialise
          {}MyDRC.Close obj
      :EndTrap
    ∇

    ∇ Terminate
      :Implements Destructor
      :If PROCESS≢⎕NULL  ⍝ we did spawn an interpreter
      :AndIf ~PROCESS.HasExited  ⍝ APLProcess destructor generally triggers before this one
          {}LogInfo'Shutting down spawned interpreter'
          :Trap CONGA_ERRNO  ⍝ Conga may throw error 1006 - ERR_ROOT_NOT_FOUND - Please re-initialise
              {}0 Send'["Exit",{"code":0}]'  ⍝ attempt to shut down cleanly - APLProcess will kill it anyways
          :EndTrap
      :EndIf
      :If CLIENT≢⎕NULL
          {}LogInfo'Closing connection'
          CloseConga CLIENT
      :EndIf
      CLIENT←⎕NULL
      PROCESS←⎕NULL
    ∇

    ∇ terminated←Terminated
      terminated←CLIENT≡⎕NULL
    ∇

    ∇ {ok}←{error}Send msg;r
    ⍝ Send a message to the RIDE
      :Access Public
      :If 0=⎕NC'error' ⋄ error←1 ⋄ :EndIf
      ok←0=⊃r←MyDRC.Send CLIENT(AddHeader ToUtf8'Send'LogTrace msg)
      :If error∧~ok
          'Send'Error⍕r
          Terminate
      :EndIf
    ∇

    ∇ messages←{timeout}Read json;buffer;bufok;done;len;ok;r;start
    ⍝ Read message queue from the RIDE
      :Access Public
      :If 0=⎕NC'timeout' ⋄ timeout←TIMEOUT ⋄ :EndIf
      :Repeat
          :If ok←0=⊃r←MyDRC.Wait CLIENT timeout
              :If r[3]∊'Block' 'BlockLast'   ⍝ we got some data
                  BUFFER,←⊂4⊃r
              :EndIf
              done←r[3]∊'BlockLast' 'Closed' 'Timeout'  ⍝ only a timeout is normal behaviour because RIDE connection is never closed in normal operation
              ok←~r[3]∊'BlockLast' 'Closed'  ⍝ interpreter closed connection (should not happen)
          :Else ⋄ done←1 ⍝ ok←0
          :EndIf
      :Until done
      messages←0⍴⊂''
      buffer←∊BUFFER ⋄ bufok←1
      :While (len←GetLength buffer)≤≢buffer
      :AndIf bufok∧←('RIDE'≡4↓8↑buffer)∧(8<len)
          messages,←⊂0 ⎕JSON⍣json⊢'Receive'LogTrace FromUtf8 8↓len↑buffer
          buffer←len↓buffer
      :EndWhile
      :If bufok ⋄ BUFFER←,⊂buffer
      :Else ⋄ BUFFER←0⍴⊂'' ⋄ 'Read'Error'Invalid buffer: ',buffer
      :EndIf
      :If ~ok∧bufok
          'Read'LogWarn'Connection failed: ',⍕r
          Terminate  ⍝ consider connection dead for good (avoid trying to read more)
      :EndIf
    ∇

    ∇ {messages}←{ignored}(fn WaitFor json)awaited;commands;messages;timeout
    ⍝ simple waiting of messages, without grabbing any result
      :If 0=⎕NC'ignored' ⋄ ignored←'' ⋄ :EndIf
      :If 0∊⍴ignored ⋄ ignored←0⍴⊂'' ⋄ :Else ⋄ ignored←,⊆,ignored ⋄ :EndIf
      awaited←,⊆,awaited ⋄ messages←commands←⍬ ⋄ timeout←0
      :Repeat
          :If ~DEBUG ⋄ timeout←TIMEOUT⌊timeout+10 ⋄ :EndIf
          commands,←⊃¨⍣json⊢messages,←timeout Read json  ⍝ if json, just care about the message header
          :If ~0∊⍴commands~awaited∪ignored ⍝ unexpected messages
              fn Error'Received unexpected messages: ',⍕commands~awaited∪ignored
          :EndIf
      :Until Terminated∨(∧/awaited∊commands)
    ∇

    ∇ {ok}←{timeout}EmptyQueue msg;messages
    ⍝ empty message queue, expecting it to be empty
      :If 0=⎕NC'timeout' ⋄ timeout←0 ⋄ :EndIf  ⍝ do not wait for new messages
      messages←timeout Read 1
      :If ~ok←0∊⍴messages ⋄ msg LogInfo'Message queue not empty: ',⍕⊃¨messages ⋄ :EndIf
    ∇






    ∇ wins←Windows
      :Access Public
      wins←WINS
    ∇
    ∇ win←new GetWindow id;inx
      :If (~0∊⍴WINS) ⋄ :AndIf (≢WINS)≥(inx←WINS.id⍳id) ⋄ win←inx⊃WINS       ⍝ found
      :ElseIf new ⋄ win←⎕NS ⍬ ⋄ win.id←id ⋄ WINS,←win   ⍝ create new window
      :Else ⋄ win←NO_WIN                               ⍝ not found
      :EndIf
    ∇
    ∇ id←NextId
    ⍝ Generate a local id that cannot be submitted by the interpreter (negative)
      :If 0∊⍴WINS ⋄ id←¯1
      :Else ⋄ id←¯1+⌊/0,WINS.id
      :EndIf
    ∇
    ∇ (prompt output wins errors)←fn ProcessMessages messages;arguments;command;em;en;enx;msg;win
      prompt←¯1             ⍝ ¯1 = prompt unset, 0 = no prompt, 1 = the usual 6-space APL prompt (a.k.a. Descalc or "desktop calculator"), 2 = Quad(⎕) input, 3 = ∇ line editor, 4 = Quote-Quad(⍞) input, 5 = any prompt type unforeseen here.
      output←''             ⍝ session output (string with newlines)
      wins←NO_WIN           ⍝ saved/modified windows (list of namespaces from WINS)
      errors←NO_ERROR       ⍝ list of ⎕DMX.(EN EM Message)
      :For command arguments :In messages
          win←NO_WIN
          :Select command
          :CaseList 'CanAcceptInput' 'FocusThread' 'EchoInput' 'UpdateDisplayName' 'StatusOutput' ⍝ these are ignored
          :Case 'SetPromptType'
              prompt←arguments.type
          :Case 'AppendSessionOutput'
              output,←⊂{LF=⊃⌽⍵:NL@(≢⍵)⊢⍵ ⋄ ⍵}arguments.result
          :Case 'HadError'  ⍝ ⎕SIGNAL within APL execution
              errors,←⊂(en enx em msg)←arguments.(error dmx'' '') ⍝ arguments.dmx gives ⎕DMX.ENX
          :Case 'InternalError'  ⍝ Error within RIDE message processing
              errors,←⊂(en enx em msg)←arguments.(error error_text dmx) ⍝ arguments.message gives the failing RIDE command
          :CaseList 'OpenWindow' 'UpdateWindow'
              win←1 GetWindow arguments.token
              :If 0=arguments.⎕NC'trace' ⋄ arguments.trace←⍬ ⋄ :EndIf  ⍝ no trace points up to v18.1
              :If 0=arguments.⎕NC'monitor' ⋄ arguments.monitor←⍬ ⋄ :EndIf ⍝ no monitor points up to v18.1
              win.(title text line stop trace monitor saved)←arguments.(name text currentRow stop trace monitor ⍬)
              win.type←(1+arguments.debugger)⊃'Editor' 'Tracer'
          :Case 'GotoWindow'
              :If 0∊⍴win←0 GetWindow arguments.win
                  'GotoWindow'Error'Unknown window: ',⍕arguments.win
              :EndIf
          :Case 'WindowTypeChanged'
              :If 0∊⍴win←0 GetWindow arguments.win
                  'WindowTypeChanged'Error'Unknown window: ',⍕arguments.win
              :EndIf
              win.type←(1+arguments.tracer)⊃'Editor' 'Tracer'
          :Case 'SetHighlightLine'
              :If 0∊⍴win←0 GetWindow arguments.win
                  'SetHighlightLine'Error'Unknown window: ',⍕arguments.win
              :EndIf
              win.line←arguments.line
          :Case 'SetLineAttributes'
              :If 0∊⍴win←0 GetWindow arguments.win
                  'SetLineAttributes'Error'Unknown window: ',⍕arguments.win
              :EndIf
              win.stop←arguments.stop
          :Case 'ReplySaveChanges'
              :If 0∊⍴win←0 GetWindow arguments.win
                  'ReplySaveChanges'Error'Unknown window: ',⍕arguments.win
              :EndIf
              win.saved←arguments.err
          :Case 'ReplyFormatCode'
              :If 0∊⍴win←0 GetWindow arguments.win
                  'ReplyFormatCode'Error'Unknown window: ',⍕arguments.win
              :EndIf
              win.(text saved)←arguments.(text 0)
          :Case 'CloseWindow'
              :If 0∊⍴win←0 GetWindow arguments.win
                  'CloseWindow'Error'Unknown window: ',⍕arguments.win
              :EndIf
              RemoveWindows win
          :Case 'NotificationMessage'
              win←1 GetWindow NextId
              win.(title type text)←'' 'Notification'(,⊂arguments.message)
          :Case 'ShowHTML'
              win←1 GetWindow NextId
              win.(title type text)←'' 'Html'(,⊂arguments.html)
          :Case 'OptionsDialog'
              win←1 GetWindow arguments.token
              win.(title type text options index)←arguments.(title'Options'text options(¯1+⍳≢options))
          :Case 'TaskDialog'
              win←1 GetWindow arguments.token
              win.(title type text options index)←arguments.(title'Task'text(options,buttonText)((¯1+⍳≢options),(99+⍳≢buttonText)))
          :Case 'StringDialog'
              win←1 GetWindow arguments.token
              win.(title type text value default)←arguments.(title'String'text initialValue defaultValue)
          :Case 'SysError'
              LogInfo'SysError: ',⍕arguments.(text stack)
              Terminate
              done←1
              fn Error'Interpreter system error',arguments.(text,': ',stack)
          :Case 'Disconnect'
              LogInfo'Disconnected: ',arguments.message
              Terminate
              done←1
              fn Error'Interpreter unexpectedly disconnected'
          :Else
              fn LogWarn'Unexpected RIDE command: ',command
          :EndSelect
          wins,←win
      :EndFor
      output←⊃,/output
    ∇




    ∇ (prompt output wins errors)←{wait}(fn WaitSub)waitmessages;done;messages;nothing;numwins;timeout;waitmessages;waitprompts;waitwins
    ⍝ Process incoming messages until all wait conditions are fulfilled
    ⍝ Exceptions when waiting no prompt and no window : the first event that happens returns
      :If 0=⎕NC'wait' ⋄ :OrIf 0∊⍴wait ⋄ (waitprompts waitwins)←(1 2 3 4)0 ⍝ wait for prompt to come back by default - windows generally pop up before that
      :Else ⋄ (waitprompts waitwins)←wait  ⍝ wait for both conditions
      :EndIf
      ⍝ waitmessages is a depth-3 list of RIDE protocol messages, at least one of the lists must have all its messages received
      :If 0∊⍴waitmessages ⋄ waitmessages←0⍴⊂0⍴⊂''
      :Else ⋄ waitmessages←,¨¨{,⊆,⍵}¨{⊂⍣(2≥|≡⍵)⊢⍵}{,⊆,⍵}waitmessages
      :EndIf
      :If 2>|≡waitmessages ⋄ waitmessages←{,⊆,⍵}¨waitmessages ⋄ :EndIf
      :If 3>|≡waitmessages ⋄ waitmessages←,⊂waitmessages ⋄ :EndIf
      prompt←⍬ ⋄ output←'' ⋄ wins←NO_WIN ⋄ errors←NO_ERROR ⋄ numwins←0 ⋄ timeout←0 ⋄ messages←0⍴⊂''
      :If ~0 IsPrompts waitprompts←,waitprompts ⋄ fn Error'Invalid awaited prompt types: ',⍕waitprompts
      :ElseIf IsInteger waitwins ⋄ :AndIf waitwins≥0 ⋄ numwins←1  ⍝ target number of windows
      :ElseIf 0∊⍴waitwins←,waitwins ⋄ :OrIf ∧/IsWin¨waitwins ⋄ numwins←0  ⍝ list of windows to touch
      :Else ⋄ fn Error'Invalid awaited windows: ',⍕waitwins
      :EndIf
      :If numwins ⋄ nothing←waitwins=0 ⋄ :Else ⋄ nothing←0∊⍴waitwins ⋄ :EndIf
      nothing∧←0∊⍴waitprompts
      :Repeat
          :If ~DEBUG ⋄ timeout←TIMEOUT⌊timeout+10 ⋄ :EndIf  ⍝ crank up timeout 10 ms at a time to avoid consuming too much CPU
          (prompt output wins errors),←fn ProcessMessages messages,←timeout Read 1
          :If nothing ⋄ done←(∨/~prompt∊¯1 0)∨(~0∊⍴wins)
          :Else
              :If numwins ⋄ done←waitwins≤≢wins ⋄ :Else ⋄ done←∧/waitwins∊wins ⋄ :EndIf
              done∧←(0∊⍴waitprompts)∨(∨/prompt∊waitprompts)
          :EndIf
          done∧←(0∊⍴waitmessages)∨(∨/∧/¨waitmessages∊¨⊂⊃¨messages)
      :Until Terminated∨done
      prompt←⊃⌽¯1,prompt~¯1  ⍝ only the last prompt set is interesting
      wins←∪wins  ⍝ window may get several messages e.g. UpdateWindow+SetHighlightLine
      :If ~0∊⍴errors ⋄ errors←,⊂GetError ⋄ :EndIf
    ∇



    ∇ (prompt output wins errors)←Wait wait
    ⍝ Get last prompt type, session output, touched windows and thrown errors
    ⍝ wait may be empty or specify (waitprompts waitwins)
      :Access Public
      (prompt output wins errors)←wait('Wait'WaitSub)⍬
    ∇
    ∇ result←Resume wait
    ⍝ Resume execution of all threads
      :Access Public
      Send'["RestartThreads",{}]'
      result←wait('Resume'WaitSub)⍬
    ∇
    ∇ result←{wait}Execute expr;wins
    ⍝ Execute an APL expression.
      :Access Public
      :If 0=⎕NC'wait' ⋄ wait←⊢ ⋄ :EndIf
      :If ~IsString expr←,expr ⋄ 'Execute'Error'Expression must be a string' ⋄ :EndIf
      EmptyQueue'Execute'
      Send'["Execute",{"text":',(1 ⎕JSON expr,LF),',"trace":0}]'  ⍝ DOC error : trace is 0|1 not true|false
      result←wait('Execute'WaitSub)'EchoInput'
    ∇
    ∇ result←{wait}Trace expr;wins
    ⍝ Trace into an APL expression.
      :Access Public
      :If 0=⎕NC'wait' ⋄ wait←⊢ ⋄ :EndIf
      :If ~IsString expr←,expr ⋄ 'Trace'Error'Expression must be a string' ⋄ :EndIf
      EmptyQueue'Trace'
      Send'["Execute",{"text":',(1 ⎕JSON expr,LF),',"trace":1}]'  ⍝ DOC error : trace is 0|1 not true|false
      result←wait('Trace'WaitSub)'EchoInput'
    ∇
    ∇ result←{wait}TraceRun win
    ⍝ Run current line and move to next (step over)
      :Access Public
      :If 0=⎕NC'wait' ⋄ wait←⊢ ⋄ :EndIf
      Send'["RunCurrentLine",{"win":',(1 ⎕JSON win.id),'}]'
      result←wait('TraceRun'WaitSub)⍬
    ∇
    ∇ result←{wait}TraceInto win
    ⍝ Run current line and trace callees (step into)
      :Access Public
      :If 0=⎕NC'wait' ⋄ wait←⊢ ⋄ :EndIf
      Send'["StepInto",{"win":',(1 ⎕JSON win.id),'}]'
      result←wait('TraceInto'WaitSub)⍬
    ∇
    ∇ result←{wait}TraceResume win
    ⍝ Resume execution of current thread
      :Access Public
      :If 0=⎕NC'wait' ⋄ wait←⊢ ⋄ :EndIf
      Send'["Continue",{"win":',(1 ⎕JSON win.id),'}]'
      result←wait('TraceResume'WaitSub)⍬
    ∇
    ∇ result←{wait}TraceReturn win
    ⍝ Run current function until return to next line of caller
      :Access Public
      :If 0=⎕NC'wait' ⋄ wait←⊢ ⋄ :EndIf
      Send'["ContinueTrace",{"win":',(1 ⎕JSON win.id),'}]'
      result←wait('TraceReturn'WaitSub)⍬
    ∇

    ∇ output←APL expr;errors;prompt;wins
    ⍝ Execution of a simple APL expression and get session output
      :Access Public
      (prompt output wins errors)←1 0 Execute expr  ⍝ wait for prompt=1 and no window
      :If ~prompt PromptIs 1 ⋄ 'APL'Error'Expression produced non-standard prompt: ',expr
      :ElseIf wins≢NO_WIN ⋄ 'APL'Error'Expression produced a window: ',expr
      :ElseIf errors≢NO_ERROR ⋄ Signal⊃errors
      :EndIf
    ∇
    ∇ output←Output;errors;prompt;wins
    ⍝ Read pending output to session - no wait
      :Access Public
      (prompt output wins errors)←'Output'ProcessMessages 0 Read 1
      :If ~prompt PromptIs ¯1 ⋄ 'Output'Error'Interpreter changed prompt'
      :ElseIf wins≢NO_WIN ⋄ 'Output'Error'Interpreter produced a window'
      :ElseIf errors≢NO_ERROR ⋄ Signal⊃errors
      :EndIf
    ∇

    ∇ num←fn VFI txt;ok
    ⍝ convert a single number
      (ok num)←⎕VFI txt
      :If (ok≡,1) ⋄ num←⊃num
      :Else ⋄ fn Error'Could not parse number: ',txt
      :EndIf
    ∇
    ∇ (en enx em msg)←GetError;r
    ⍝ Get last APL error information
      :Access Public
      r←Execute¨'⎕DMX.EN' '⎕DMX.ENX' '⎕DMX.EM' '⎕DMX.Message'  ⍝ would infinitely loop on error
      :If (1∨.≠1⊃¨r) ⋄ :OrIf (NL∨.≠{⊃⌽⍵}¨2⊃¨r) ⋄ :OrIf 0∨.<⊃∘⍴¨3⊃¨r ⋄ :OrIf 0∨.<⊃∘⍴¨4⊃¨r
          'GetError'Error'Failed to retrieve ⎕DMX information'
      :EndIf
      (en enx em msg)←¯1↓¨2⊃¨r  ⍝ keep output only
      (en enx)←'GetError'∘VFI¨en enx
    ∇

    ∇ {response}Reply win;result
    ⍝ response must be one of win.options or win.index for Options and Task dialogs
    ⍝ response must be a string for String dialogs
    ⍝ No response means close the window
    ⍝ Because replying to a dialog window will resume execution, the result is a full execution result
      :Access Public
      :Select win.type
      :CaseList 'Options' 'Task'
          :If 0=⎕NC'response' ⋄ response←¯1  ⍝ just close the window
          :ElseIf (⊂response)∊win.options ⋄ response←(win.options⍳⊂response)⊃win.index
          :ElseIf (⊂response)∊win.index ⍝ response is ok
          :Else ⋄ 'Reply'Error'Invalid response for a ',win.type,' dialog'
          :EndIf
          Send'["Reply',win.type,'Dialog",{"index":',(1 ⎕JSON response),',"token":',(1 ⎕JSON win.id),'}]'  ⍝ DOC index is a string ???
      :Case 'String'
          :If 0=⎕NC'reponse' ⋄ response←win.value ⋄ :EndIf  ⍝ edit field untouched
          Send'["Reply',win.type,'Dialog",{"value":',(1 ⎕JSON response),',"token":',(1 ⎕JSON win.id),'}]'
      :EndSelect
      RemoveWindows win
    ∇

    ∇ {list}←{list}RemoveWindows wins;default
    ⍝ ensure prototype of empty list (changing WINS by default)
      :If default←0=⎕NC'list' ⋄ list←WINS ⋄ :EndIf
      list~←wins ⋄ :If 0∊⍴list ⋄ list←NO_WIN ⋄ :EndIf
      :If default ⋄ WINS←list ⋄ :EndIf
    ∇
    ∇ CloseWindow win;done;errors;line;message;messages;ok;output;prompt;wins
    ⍝ Close an edit or tracer window
      :Access Public
      :If ~IsWin win ⋄ 'CloseWindow'Error'Argument must be a window' ⋄ :EndIf
      :Select win.type
      :CaseList 'Editor' 'Tracer'
          Send message←'["CloseWindow",{"win":',(1 ⎕JSON win.id),'}]'
          :Repeat
              (prompt output wins errors)←⍬ win('CloseWindow'WaitSub)('CloseWindow')('WindowTypeChanged' 'SetHighlightLine')  ⍝ turning editor into tracer requires two messages : WindowTypeChanged, SetHighlightLine
              ok←(prompt PromptIs ¯1)∧(output≡'')∧(errors≡NO_ERROR)∧(wins≡,⊂win)
              :If ok∧(~IsWin win) ⋄ done←1 ⍝ actually closed the window
              :ElseIf ok∧(IsWin win) ⋄ :AndIf 'Tracer'≡win.type ⋄ done←1  ⍝ edit turned back into a tracer
              :Else ⋄ done←win∊wins ⍝
              :EndIf
          :Until Terminated∨done
          :If ~ok ⋄ 'CloseWindow'Error'Failed to close window ',⍕win.id ⋄ :EndIf
      :CaseList 'Options' 'Task' 'String'
          Reply win
      :CaseList 'Notification' 'Html'
          RemoveWindows win  ⍝ message boxes are discarded without response
      :Else ⋄ 'CloseWindow'Error'Invalid window type'
      :EndSelect
    ∇
    ∇ CloseWindows
    ⍝ Close all existing windows
      :Access Public
      :If ~0∊⍴WINS ⋄ CloseWindow¨WINS ⋄ :EndIf
    ∇
    ∇ CloseAllWindows;errors;messages;output;prompt;toclose;wins
    ⍝ Close all edit/tracer windows with special RIDE protocol message
      :Access Public
      Send'["CloseAllWindows",{}]'
      :If 0∊⍴WINS ⋄ toclose←WINS
      :Else ⋄ toclose←(WINS.type∊'Editor' 'Tracer')/WINS
      :EndIf
      :If 0∊⍴toclose ⋄ TIMEOUT EmptyQueue'CloseAllWindows' ⋄ :Return ⋄ :EndIf  ⍝ ensure no response
      ⍝:While ~0∊⍴toclose
      (prompt output wins errors)←⍬ toclose('CloseAllWindows'WaitSub)⍬
      :If ~prompt PromptIs ¯1 1 ⋄ 'CloseAllWindows'Error'Produced unexpected prompt: ',⍕prompt
      :ElseIf errors≢NO_ERROR ⋄ 'CloseAllWindows'Error'Produced unexpected errors: ',⍕errors
      :ElseIf output≢'' ⋄ 'CloseAllWindows'Error'Produced unexpected output: ',⍕output
      :ElseIf {1∨.≠(+/⍵),(+⌿⍵)}toclose∘.≡wins ⋄ 'CloseAllWindows'Error'Did not produce close all windows'
      :EndIf
      ⍝    toclose~←wins
      ⍝:EndWhile
    ∇





    ∇ win←{type}ED name;errors;expr;output;prompt;types;wins
    ⍝ Cover for ⎕ED to open one editor window, allowing to specify its type if name is undefined
    ⍝ The window might be a TaskDialog asking whether we should read from file
      :Access Public
      :If 0=⎕NC'type' ⋄ type←''
      :ElseIf ~IsString name ⋄ 'ED'Error'Right argument must be a string'
      :ElseIf ¯1=⎕NC name ⋄ 'ED'Error'Invalid name: ',name   ⍝ ⎕ED silently fails but we don't
      :ElseIf ~type∊types←'∇→∊-⍟○∘' ⋄ 'ED'Error'Left argument must be a character amongst ',types
      :Else ⋄ type←Stringify type
      :EndIf
      expr←type,'⎕ED',⍕Stringify name
      EmptyQueue'ED'
      Send'["Execute",{"text":',(1 ⎕JSON expr,LF),',"trace":false}]'
      (prompt output wins errors)←⍬ 1('ED'WaitSub)⍬
      :If ~0∊⍴errors ⋄ 'ED'Error'Produced unexpected errors: ',⍕errors
      :ElseIf ~0∊⍴output ⋄ 'ED'Error'Produced unexpected output: ',⍕output
      :ElseIf 1≠≢wins ⋄ 'ED'Error'Did not produce 1 window'
      :ElseIf wins.type≡,⊂'Editor'
          :If wins.title≢,⊂{(⌽∧\⌽⍵≠'.')/⍵}name ⋄ 'ED'Error'Did not edit expected name' ⋄ :EndIf
          :If ~prompt PromptIs 1 ⋄ :AndIf (1 ''NO_WIN NO_ERROR)≡1 0('ED'WaitSub)⍬ ⋄ 'ED'Error'Failed to come back to prompt' ⋄ :EndIf
      :ElseIf ~(wins.type)∊'Options' 'Task' ⋄ 'ED'Error'Opened something else than an Options/Task window: ',(⊃wins).type
      :ElseIf ~prompt PromptIs 0 ⋄ 'ED'Error'Produced unexpected prompt: ',⍕prompt
      :EndIf
      win←⊃wins
    ∇

    ∇ win←EditOpen name;errors;ok;output;prompt;wins
    ⍝ Edit a name, get a window.
    ⍝ To specify the type of entity to edit, use ED instead.
      :Access Public
      :If ~IsString name←,name ⋄ :OrIf ¯1=⎕NC name ⋄ 'EditOpen'Error'Right argument must be a valid APL name' ⋄ :EndIf  ⍝ otherwise EditOpen '' loops forever
      ⍝:If 0=⎕NC'type' ⋄ type←'∇' ⋄ :EndIf
      ⍝:If ~type∊'∇→∊-⍟○∘' ⋄ 'EditOpen'Error'Left argument must be one of: ∇: fn/op ⋄ →: string ⋄ ∊: vector of strings ⋄ -: character matrix ⋄ ⍟: namespace ⋄ ○: class ⋄ ∘: interface' ⋄ :EndIf
      ⍝type←1 128 16 2 256 512 1024['∇→∊-⍟○∘'⍳type]  ⍝ Constants for entityType: 1 defined function, 2 simple character array, 4 simple numeric array, 8 mixed simple array, 16 nested array, 32 ⎕OR object, 64 native file, 128 simple character vector, 256 APL namespace, 512 APL class, 1024 APL interface, 2048 APL session, 4096 external function.
      win←NO_WIN  ⍝ failed to open anything
      EmptyQueue'EditOpen'
      Send'["Edit",{"win":0,"text":',(1 ⎕JSON name),',"pos":1,"unsaved":{}}]'  ⍝ ⎕BUG doesn't work if unsaved not specified ? ⎕DOC : win must be 0 to create a new window
      (prompt output wins errors)←⍬ 1('EditOpen'WaitSub)⍬  ⍝ Edit does not touch the prompt - wait for window to pop up
      :If ~prompt PromptIs ¯1 ⋄ 'EditOpen'Error'Produced unexpected prompt: ',⍕prompt
      :ElseIf NO_ERROR≢errors ⋄ 'EditOpen'Error'Produced unexpected error: ',⍕errors
      :ElseIf ''≢output ⋄ 'EditOpen'Error'Produced unexpected output: ',⍕output
      :ElseIf 1≠≢wins ⋄ 'EditOpen'Error'Failed to open 1 window'
      :ElseIf wins.type≡,⊂'Editor'
          :If wins.title≢,⊂{(⌽∧\⌽⍵≠'.')/⍵}name ⋄ 'EditOpen'Error'Did not edit expected name' ⋄ :EndIf
      :ElseIf ~(wins.type)∊'Options' 'Task' ⋄ 'EditOpen'Error'Opened something else than an Options/Task window: ',(⊃wins).type
      :EndIf
      win←⊃wins
    ∇

    ∇ res←win EditFix src;arguments;command;errors;messages;monitor;output;prompt;stop;trace;wins
    ⍝ Fix source in a given edit window
    ⍝ result is boolean if fixing was completed (1 for OK, 0 for error)
    ⍝ otherwise it's an OptionsDialog popped up by the editor
      :Access Public
      :If 2=|≡src←,⊆,src ⋄ src←⊂src ⋄ :EndIf  ⍝ source only, no stop/trace/monitor defined
      (src stop trace monitor)←src,(≢src)↓4⍴⎕NULL
      :If ⎕NULL≡stop ⋄ stop←win.stop ⋄ :EndIf
      :If ⎕NULL≡trace ⋄ trace←win.trace ⋄ :EndIf
      :If ⎕NULL≡monitor ⋄ monitor←win.monitor ⋄ :EndIf
      :If ~IsStops stop ⋄ 'EditFix'Error'Stop points must be numeric vector: ',⍕stop ⋄ :EndIf
      :If ~IsStops trace ⋄ 'EditFix'Error'Trace points must be numeric vector: ',⍕trace ⋄ :EndIf
      :If ~IsStops monitor ⋄ 'EditFix'Error'Monitor points must be numeric vector: ',⍕monitor ⋄ :EndIf
      ⍝stop∩←trace∩←monitor∩←0,⍳⍴src  ⍝ only legitimate line numbers
      :If ~IsSource src←,¨src ⋄ 'EditFix'Error'Source must be a string or a vector of strings: ',⍕src ⋄ :EndIf
      :If ~IsWin win ⋄ 'EditFix'Error'Left argument must be a window' ⋄ :EndIf
      win.saved←⍬
      EmptyQueue'EditFix'
      Send'["SaveChanges",{"win":',(1 ⎕JSON win.id),',"text":',(1 ⎕JSON src),',"stop":',(1 ⎕JSON stop),',"trace":',(1 ⎕JSON trace),',"monitor":',(1 ⎕JSON monitor),'}]'   ⍝ providing no stop is like explicitly setting stops to ⍬
      (prompt output wins errors)←⍬ 1('EditFix'WaitSub)⍬  ⍝ EditFix may not touch the prompt - wait for window to be touched
      :If ~prompt PromptIs ¯1 1 ⋄ 'EditFix'Error'Produced unexpected prompt: ',⍕prompt  ⍝ ⎕BUG ? Even though promptype was already 1, SaveChanges may trigger two SetPromptType(1) messages before the ReplySaveChanges, and may trigger one before an OptionsDialog
      :ElseIf NO_ERROR≢errors ⋄ 'EditFix'Error'Produced unexpected error: ',⍕errors
      :ElseIf ''≢output ⋄ 'EditFix'Error'Produced unexpected output: ',⍕output
      :ElseIf 1≠≢wins ⋄ 'EditFix'Error'Failed to fix 1 window'
      :ElseIf wins≡,⊂win ⋄ res←0≡win.saved  ⍝ fixed
      :ElseIf ~(wins.type)∊'Options' 'Task' ⋄ 'EditFix'Error'Opened something else than an Options/Task window: ',(⊃wins).type
      :Else ⋄ res←⊃wins  ⍝ a wild dialog window appears
      :EndIf
      win.(text stop trace monitor)←src stop trace monitor
    ∇


    ∇ {type}Edit args;errors;monitor;name;ok;opt;output;prompt;res;src;stop;trace;win;wins
    ⍝ {type} Edit (name src {stop} {trace} {monitor})
      :Access Public
      ⍝ args←,⊆,args  ⍝ single name won't work - source is required
      (name src stop trace monitor)←args,(≢args)↓''(0⍴⊂'')⎕NULL ⎕NULL ⎕NULL
      :If 0=⎕NC'type' ⋄ type←⊢ ⋄ :EndIf
      win←type ED name
      :If IS181 ⋄ opt←'Use the contents of the modified file'  ⍝ added around Dyalog 18.1.40300
      :Else ⋄ opt←'Get the text from the modified file'
      :EndIf
      :If win.type≡'Task' ⋄ :AndIf (⊂opt)∊win.options
          opt Reply win
          (prompt output wins errors)←Wait 1 1  ⍝ prompt must come back to 1
          :If ~prompt PromptIs 1 ⋄ :AndIf (output errors)≢''NO_ERROR ⋄ 'Edit'Error'Failed to reply to TaskDialog' ⋄ :EndIf
          win←⊃wins
      :EndIf
      :If win.type≢'Editor' ⋄ 'Edit'Error'Failed to open editor' ⋄ :EndIf
      :If ~ok←1≡res←win EditFix src stop trace monitor  ⍝ 1 is OK - 0 is failure to fix - namespace is a dialog box
          opt←('Fix as code in the workspace',(⎕UCS 10),'Create objects in the workspace, and update the file')
          :If ok←9=⎕NC'res'  ⍝ dialog box
              :If res.type≡'Task' ⋄ :AndIf (⊂opt)∊res.options  ⍝ ask to overwrite file
                  opt Reply res  ⍝ say yes
                  win.saved←⍬
                  (prompt output wins errors)←Wait 1 win  ⍝ wait for save changes on the editor window
                  ok←(prompt∊0 1)∧(''≡output)∧(0≡win.saved)∧(wins≡,win)∧(errors≡NO_ERROR)
              :Else
                  Reply res ⋄ ok←0  ⍝ cancel
              :EndIf
          :EndIf
      :EndIf
      CloseWindow win
      :If ~ok ⋄ 'Edit'Error'Could not fix name ',name,' with source: ',⍕src ⋄ :EndIf
    ∇

    ∇ src←Reformat src;arguments;command;errors;messages;ns;ok;output;prompt;script;trad;type;win;wins
    ⍝ Reformat source as vectors of strings
      :Access Public
      :If ~IsSource src←,¨,⊆,src ⋄ 'EditFix'Error'Source must be a string or a vector of strings: ',⍕src ⋄ :EndIf
      ns←⎕NS ⍬ ⋄ trad←script←ok←0
      ⍝ BUG: Mantis 18310: on windows, the interpreter sends ReplyFormatCode with incorrect format if type is '∇' and source is that of a :Namespace, rather than send OptionsDialog like linux does. Similarly when trying to format a function with type '○'
      ⍝ This is why we detect the type first hand by fixing it locally
      :Trap 0 ⋄ trad←IsString ns.⎕FX src ⋄ :EndTrap
      :Trap 0 ⋄ {}ns.⎕FIX src ⋄ script←1 ⋄ :EndTrap
      :For type :In script trad/'○∇'  ⍝ Either a function or a script
          win←type ED ⎕A[?50⍴26]  ⍝ use only 50 chars because of mantis 18309 - 1.8E¯71 chance of existing name
          :If 1≠≢win ⋄ 'Reformat'Error'Failed to edit a new name' ⋄ :EndIf
          win←⊃win ⋄ win.saved←⍬ ⋄ EmptyQueue'Reformat'
          Send'["FormatCode",{"win":',(1 ⎕JSON win.id),',"text":',(1 ⎕JSON src),'}]'
          (prompt output wins errors)←⍬ 1('Reformat'WaitSub)⍬
          :If ~prompt∊¯1 0 1 ⋄ 'Reformat'Error'Produced unexpected prompt: ',⍕prompt
          :ElseIf NO_ERROR≢errors ⋄ 'Reformat'Error'Produced unexpected error: ',⍕errors
          :ElseIf ''≢output ⋄ 'Reformat'Error'Produced unexpected output: ',⍕output
          :ElseIf 1≠≢wins ⋄ 'Reformat'Error'Failed to open 1 window'
          :ElseIf wins≡,⊂win ⋄ :AndIf win.saved≡0 ⋄ src←win.text ⋄ ok←1  ⍝ success
          ⍝ :ElseIf wins.type≡,⊂'Options' ⋄ ∘∘∘ ⋄ CloseWindow⊃wins ⋄ ok←0 ⍝ OptionsDialog to inform of the failure to reformat - can't happen because with attempted to fix it locally beforehand
          :Else ⋄ 'Reformat'Error'Unexpected windows'
          :EndIf
          CloseWindow win
          :If ok ⋄ :Leave ⋄ :EndIf
      :EndFor
      :If ~ok ⋄ 'Reformat'Error'Failed to reformat: ',⍕src ⋄ :EndIf
    ∇







    ∇ fn _TraceChangedLine win;errors;ok;output;prompt;wins
    ⍝ Wait for tracer to change its line - will wait forever if it doesn't happen
      (prompt output wins errors)←⍬ win(fn WaitSub)'SetHighlightLine'
      ok←(prompt∊¯1 0 1)∧(output≡'')∧(errors≡NO_ERROR)∧(wins≡,⊂win)
      ok∧←(IsWin win)∧('Tracer'≡win.type)  ⍝ edit turned back into a tracer
      :If ~ok ⋄ fn Error'Failed to changed Tracer line' ⋄ :EndIf
    ∇

    ∇ TraceCutback win;errors;output;wins
    ⍝ Cut back to caller (no code execution)
      :Access Public
      Send'["Cutback",{"win":',(1 ⎕JSON win.id),'}]'
      'TraceCutback'_TraceChangedLine win
    ∇
    ∇ TraceNext win
    ⍝ Jump to next tracer line (no code execution)
      :Access Public
      Send'["TraceForward",{"win":',(1 ⎕JSON win.id),'}]'
      'TraceNext'_TraceChangedLine win
    ∇
    ∇ TracePrev win
    ⍝ Jump to previous tracer line (no code execution)
      :Access Public
      Send'["TraceBackward",{"win":',(1 ⎕JSON win.id),'}]'
      'TracePrev'_TraceChangedLine win
    ∇
    ∇ win SetStops stops
    ⍝ Change stop points of trace or edit window
      :Access Public
      :If ~IsStops stops←,stops ⋄ 'SetStops'Error'Right argument must be numeric vector: ',⍕stops ⋄ :EndIf
      :If ~IsWin win ⋄ 'SetStops'Error'Left argument must be a window' ⋄ :EndIf
      EmptyQueue'SetStops'
      Send'["SetLineAttributes",{"win":',(1 ⎕JSON win.id),',"stop":',(1 ⎕JSON stops),'}]'
      TIMEOUT EmptyQueue'SetStops' ⍝ no response to this message
      win.stop←stops
    ∇
    ∇ (traces stops monitors)←ClearTraceStopMonitor;messages
    ⍝ Clear all traces/stops/monitors in active workspace
      :Access Public
      EmptyQueue'ClearTraceStopMonitor'
      Send'["ClearTraceStopMonitor",{"token":0}]'
      messages←('ClearTraceStopMonitor'WaitFor 1)'ReplyClearTraceStopMonitor'
      (traces stops monitors)←(2⊃⊃messages).(traces stops monitors)
    ∇







    ∇ ok←_RunQA stop;BUG;_Reformat;debug;dup;dup2;dupstops;dupwin;error;foo;foowin;goo;goowin;html;ok;ondisk;ondisk2;output;r;src;src1;src2;stops;tmp;tmpdir;tmpfile;win;win2;∆
      :Access Public
      ∆←stop{⍺←'' ⋄ ⍵≡1:⍵ ⋄ ⍺⍺:0⊣'QA'Error ⍺ ⋄ 0⊣'QA'LogWarn ⍺}
      ok←1
      debug←DEBUG ⋄ DEBUG←1  ⍝ maximise the likelihood of missing messages
     
      ok∧←'Execute )CLEAR'∆ 1('clear ws',NL)(NO_WIN)(NO_ERROR)≡Execute')CLEAR'
      ok∧←'Execute ]rows on'∆(r[2]∊'Was ON' 'Was OFF',¨NL)∧(1(NO_WIN)(NO_ERROR)≡(⊂1 3 4)⌷r←Execute']rows on')
     
      ⍝ Execution : APL, session, error
      ok∧←'Execute meaning of life'∆ 1('42',NL)(NO_WIN)(NO_ERROR)≡Execute'⍎⊖⍕⊃⊂|⌊-*+○⌈×÷!⌽⍉⌹~⍴⍋⍒,⍟?⍳0'
      output←∊'DOMAIN ERROR: Divide by zero' '      ÷0' '      ∧',¨NL
      error←11 1 'DOMAIN ERROR' 'Divide by zero'
      ok∧←'Execute ÷0'∆ 1(output)(NO_WIN)(,⊂error)≡Execute'÷0'
      ok∧←error≡GetError
     
      ⍝ Reformat
     
      src←'    res  ←   format   arg   ' ':if arg' '⎕←      ''yes''' ':endif'
      ok∧←'Reformat function'∆({(⎕NS ⍬).(⎕NR ⎕FX ⍵)}src)≡(Reformat src)
      src1←'    :Namespace   ' '∇   tradfn   ' '⎕ ← 1 2 3   ' '∇' 'VAR  ←   4 5  6  ' 'dfn  ←   {  ⍺ +  ⍵   }   ' '      :EndNamespace    '
      src2←':Namespace' '    ∇ tradfn' '      ⎕←1 2 3' '    ∇' '    VAR  ←   4 5  6' '    dfn  ←   {  ⍺ +  ⍵   }' ':EndNamespace'
      ok∧←'Reformat namespace'∆ src2≡Reformat src1
     
      dup←' res←dup arg' ' ⎕←''this is dup''' ' res←arg arg'
      foo←' res←foo arg' ' ⎕←''this is foo''' ' res←dup arg'
      goo←' res←goo arg' ' ⎕←''this is goo''' ' res←foo arg'
      win←EditOpen'dup'
      ok∧←'EditOpen on same window'∆ win≡EditOpen'dup'
      ok∧←'ED on same window'∆ win≡ED'dup'
      ok∧←'EditFix from scratch'∆ win EditFix dup
      ok∧←'EditFix from scratch effect'∆ 1(,(↑dup),NL)(NO_WIN)(NO_ERROR)≡Execute' ⎕CR''dup'' '
      CloseWindow win
     
      win←EditOpen'dup'
      ok∧←'EditOpen source'∆ dup≡win.text
      ok∧←'EditFix changing name'∆ win EditFix foo
      ok∧←'EditFix changing name effect'∆ 1(,(↑foo),NL)(NO_WIN)(NO_ERROR)≡Execute' ⎕CR''foo'' '
      ok∧←'EditOpen on previous name'∆ win≡dupwin←EditOpen'dup'  ⍝ mantis 18291 - opens the window where foo was fixed because the interpreter thinks it's still dup
      ok∧←'EditOpen on fixed name'∆ win≢foowin←EditOpen'foo'  ⍝ mantis 18291 - opens a new window rather than go to window where foo was fixed
      CloseAllWindows  ⍝ close two windows - would error on failure
      CloseAllWindows  ⍝ close zero window - would error on failure
      ok∧←'Execute ⎕FX goo'∆ 1('goo',NL)(NO_WIN)(NO_ERROR)≡Execute'+⎕FX ',⍕Stringify¨goo   ⍝ goo → foo → dup
     
      ⍝ Tracer
     
      ok∧←'Trace foo'∆ 1('')(WINS)(NO_ERROR)≡Trace'foo ''argument'' '
      win←⊃WINS
      ok∧←'TraceResume foo'∆ 1('this is foo',NL,'this is dup',NL,' argument  argument ',NL)(,⊂win)(NO_ERROR)≡TraceResume win ⍝ will close window
      ok∧←'TraceResume effect'∆ WINS≡NO_WIN
     
      ok∧←'Execute ⎕STOP goo'∆ 1('1',NL)(NO_WIN)(NO_ERROR)≡Execute'+1 ⎕STOP ''goo'''       ⍝ set breakpoint
      ok∧←'Execute goo'∆ 1(NL,'goo[1]',NL)(WINS)(ERROR_BREAK)≡Execute'goo ''hello'''  ⍝ pop up tracer on breakpoint
      win←⊃WINS
      ok∧←'Tracing goo[1]'∆('goo' 1 'Tracer'goo(,1))(,win)≡win.(title line type text stop)WINS
      ok∧←'Editing while tracing goo[1]'∆ win≡EditOpen'goo'
      ok∧←'Editing goo[1]'∆('goo' 1 'Editor'goo(,1))(,win)≡win.(title line type text stop)WINS
      CloseWindow win
      ok∧←'Closing goo[1] editor back into tracer'∆('goo' 1 'Tracer'goo(,1))(,win)≡win.(title line type text stop)WINS
     
      ok∧←'TraceInto goo[1]'∆ 1('this is goo',NL)(,win)(NO_ERROR)≡TraceInto win  ⍝ goo[1]
      ok∧←'Tracing goo[2]'∆('goo' 2 'Tracer'goo(,1))(,win)≡win.(title line type text stop)WINS
      ok∧←'TraceInto goo[2]'∆ 1('')(,win)(NO_ERROR)≡TraceInto win  ⍝ goo[2] → foo[1]
      ok∧←'Tracing foo[1]'∆('foo' 1 'Tracer'foo ⍬)(,win)≡win.(title line type text stop)WINS
      TraceCutback win ⍝ → goo[2]
      ok∧←'Tracing goo[2]'∆('goo' 2 'Tracer'goo(,1))(,win)≡win.(title line type text stop)WINS
     
      win2←EditOpen'dup'
      ok∧←'Tracing goo[2] and editing dup'∆('goo' 2 'Tracer'goo(,1))('dup' 0 'Editor'dup ⍬)(win win2)≡win.(title line type text stop)win2.(title line type text stop)WINS
      ok∧←'Fixing dup + stops'∆ win2 EditFix(dup2←' dup' ' dup1' ' dup2')(0 1 2)
      ok∧←'Tracing goo[2] and fixed dup + stops'∆('goo' 2 'Tracer'goo(,1))('dup' 0 'Editor'dup2(0 1 2))(win win2)≡win.(title line type text stop)win2.(title line type text stop)WINS
      ok∧←'Fixing dup source effect'∆ 1(,(↑dup2),NL)(NO_WIN)(NO_ERROR)≡Execute' ⎕CR''dup'' '
      ok∧←'Fixing dup stops effect'∆ 1('0 1 2',NL)(NO_WIN)(NO_ERROR)≡Execute' ⎕STOP''dup'' '
      ok∧←'Unfixing dup + stops'∆ win2 EditFix dup ⍬
      ok∧←'Tracing goo[2] and unfixed dup + stops'∆('goo' 2 'Tracer'goo(,1))('dup' 0 'Editor'dup ⍬)(win win2)≡win.(title line type text stop)win2.(title line type text stop)WINS
      ok∧←'Unfixing dup source effect'∆ 1(,(↑dup),NL)(NO_WIN)(NO_ERROR)≡Execute' ⎕CR''dup'' '
      ok∧←'Unfixing dup stops effect'∆ 1(,NL)(NO_WIN)(NO_ERROR)≡Execute' ⎕STOP''dup'' '
      ok∧←'Execute ⎕STOP dup'∆ 1('0 1 2',NL)(NO_WIN)(NO_ERROR)≡Execute' +0 1 2 ⎕STOP ''dup'' '
      dupstops←⍬ ⍝ Mantis 18308 : ⎕STOP does not update opened windows - dupstops should be (0 1 2)
      ok∧←'Tracing goo[2] and unfixed dup + stops'∆('goo' 2 'Tracer'goo(,1))('dup' 0 'Editor'dup dupstops)(win win2)≡win.(title line type text stop)win2.(title line type text stop)WINS
     
      win SetStops 2
      ok∧←'Tracing goo[2] and changed stops'∆('goo' 2 'Tracer'goo(,2))('dup' 0 'Editor'dup dupstops)(win win2)≡win.(title line type text stop)win2.(title line type text stop)WINS
      TracePrev win ⋄ TracePrev win ⋄ TraceNext win
      ok∧←'Tracing back to goo[1]'∆('goo' 1 'Tracer'goo(,2))('dup' 0 'Editor'dup dupstops)(win win2)≡win.(title line type text stop)win2.(title line type text stop)WINS
      ok∧←'TraceRetrun goo[1]'∆ 1('this is goo',NL NL,'goo[2]',NL)(,win)(ERROR_BREAK)≡TraceReturn win   ⍝ hitting stop point on goo[2]
      ok∧←'Stopping at goo[2]'∆('goo' 2 'Tracer'goo(,2))('dup' 0 'Editor'dup dupstops)(win win2)≡win.(title line type text stop)win2.(title line type text stop)WINS
     
      ok∧←'Execute ⎕STOP foo'∆ 1('1',NL)(NO_WIN)(NO_ERROR)≡Execute' +1 ⎕STOP ''foo'' '
      ok∧←'TraceRun goo[2]'∆ 1(NL,'foo[1]',NL)(,win)(ERROR_BREAK)≡TraceRun win  ⍝ hitting stop point on foo[1]
      ok∧←'Tracing foo[1]'∆('foo' 1 'Tracer'foo(,1))('dup' 0 'Editor'dup dupstops)(win win2)≡win.(title line type text stop)win2.(title line type text stop)WINS
      ok∧←'TraceRun foo[1]'∆ 1('this is foo',NL)(,win)(NO_ERROR)≡TraceRun win  ⍝ foo[1] → foo[2]
      ok∧←'Tracing foo[2]'∆('foo' 2 'Tracer'foo(,1))('dup' 0 'Editor'dup dupstops)(win win2)≡win.(title line type text stop)win2.(title line type text stop)WINS
      ok∧←'TraceRun foo[2]'∆ 1(NL,'dup[1]',NL)(,win)(ERROR_BREAK)≡TraceRun win
      ok∧←'Tracing dup[1]'∆('dup' 1 'Tracer'dup(0 1 2))('dup' 0 'Editor'dup dupstops)(win win2)≡win.(title line type text stop)win2.(title line type text stop)WINS
     
      ok∧←'TraceResume dup[1]'∆ 1('this is dup',NL NL,'dup[2]',NL)(win,⊃⌽WINS)(ERROR_BREAK)≡TraceResume win
      win←⊃⌽WINS  ⍝ resume has closed the previous window and opens a new one
      ok∧←'Tracing dup[2]'∆('dup' 2 'Tracer'dup(0 1 2))('dup' 0 'Editor'dup dupstops)(win2 win)≡win.(title line type text stop)win2.(title line type text stop)WINS
      ok∧←'TraceResume dup[2]'∆ 1(NL,'dup[0]',NL)(win,⊃⌽WINS)(ERROR_BREAK)≡TraceResume win
      win←⊃⌽WINS  ⍝ resume has closed the previous window and opens a new one
      ok∧←'Tracing dup[0]'∆('dup' 0 'Tracer'dup(0 1 2))('dup' 0 'Editor'dup dupstops)(win2 win)≡win.(title line type text stop)win2.(title line type text stop)WINS
     
      ok∧←'EditFix dup'∆ win2 EditFix dup ⍬  ⍝ reset stops
      CloseWindow win2
      ok∧←'Closed dup editor'∆('dup' 0 'Tracer'dup(0 1 2))('dup' 0 'Editor'dup ⍬)(,win)≡win.(title line type text stop)win2.(title line type text stop)WINS  ⍝ win2 is now close but we check that its fields were updated
      ok∧←'⎕STOP dup'∆ 1(,NL)(NO_WIN)(NO_ERROR)≡Execute'+⎕STOP ''dup'' '
     
      ok∧←'TraceReturn dup[0]'∆ 1('')(,win)(NO_ERROR)≡TraceReturn win  ⍝ expect prompt to come back and window to be updated
      ok∧←'Tracing foo[0]'∆('foo' 0 'Tracer'foo(,1))(,win)≡win.(title line type text stop)WINS
      ok∧←'TraceResume'∆ 1(' hello  hello ',NL)(,win)(NO_ERROR)≡TraceResume win  ⍝ resume execution of current thread - expect tracer window to close and prompt to come back
      ok∧←'No code running after TraceResume'∆ 1('1',NL)(NO_WIN)(NO_ERROR)≡Execute'(0∊⍴⎕SI)∧(0∊⍴⎕TNUMS~0)'
      ok∧←'Closed all windows after TraceResume'∆ WINS≡NO_WIN
     
      ⍝ Trace/Stop/Monitors
     
      ok∧←'⎕TRACE'∆ 1(' 0 2  1 2 ',NL)(NO_WIN)(NO_ERROR)≡Execute'+(0 2) (1 2) ⎕TRACE¨ ''foo'' ''goo'''
      ok∧←'⎕MONITOR'∆ 1(' 0 2  1 ',NL)(NO_WIN)(NO_ERROR)≡Execute'+(0 2) 1 ⎕MONITOR¨ ''foo'' ''goo'''
      ok∧←'⎕STOP'∆ 1(' 1  2   ',NL)(NO_WIN)(NO_ERROR)≡Execute'+ ⎕STOP¨ ''foo'' ''goo'' ''dup'' '
      stops←5 ⍝ Mantis 18372 : interpreter thinks it has 5 stops whereas it has only 2
      ok∧←'ClearTraceStopMonitor'∆ 4 stops 3≡ClearTraceStopMonitor
     
      ⍝ Trace again for a Resume
      ok∧←'Tracing foo again'∆ 1('')(WINS)(NO_ERROR)≡Trace'foo ''world'' '  ⍝ expect a window and a prompt
      ok∧←'Stepping over foo[1]'∆ 1('this is foo',NL)(,win)(NO_ERROR)≡TraceRun win←⊃WINS
      ok∧←'Resume'∆ 1('this is dup',NL,' world  world ',NL)(,win)(NO_ERROR)≡Resume ⍬  ⍝ mantis 18335/18371: RestartThreads doesn't resume execution on linux
      ok∧←'No code running after Resume'∆ 1('1',NL)(NO_WIN)(NO_ERROR)≡Execute'(0∊⍴⎕SI)∧(0∊⍴⎕TNUMS~0)'
      ok∧←'Closed all windows after Resume'∆ WINS≡NO_WIN
     
      ⍝ Dialog boxes
     
      html←'<!DOCTYPE html> <html> <body> hello </body> </html>'
      ok∧←'3500⌶'∆ 1('0',NL)(WINS)(NO_ERROR)≡Execute'3500⌶''',html,''''
      ok∧←'3500⌶ contents'∆(⊃WINS).text≡,⊂html
      CloseWindow⊃WINS
      ok∧←'Closed 3500⌶ window'∆ WINS≡NO_WIN
     
      ⍝styles←'Msg' 'Info' 'Query' 'Warn'  'Error'
      ⍝buttons←(,⊂'OK')('OK' 'CANCEL')('RETRY' 'CANCEL')('YES' 'NO')('YES' 'NO' 'CANCEL')('ABORT' 'RETRY' 'IGNORE')  ⍝ valid buttons
      ok∧←'3503⌶'∆ 0 ''(WINS)(NO_ERROR)≡0 1 Execute'3503⌶''Caption'' (''Text 1'' ''Text 2'') ''Info'' (''abort'' ''RETRY'' ''IgNoRe'')'  ⍝ sets prompt type to 0 and pops up a window
      ok∧←'3503⌶ window'∆'Caption'('Text 1',CR LF,'Text 2')'Options'('Abort' 'Retry' 'Ignore')(0 1 2)≡(⊃WINS).(title text type options index)  ⍝ ⎕BUG newline is CR+LF !!!
      Reply⊃WINS  ⍝ ⎕BUG : closing abort/retry/ignore selects retry
      ok∧←'Monadic Reply'∆ 1('62',NL)NO_WIN NO_ERROR≡Wait ⍬  ⍝ returns to prompt - does not touch a window
      ok∧←'Monadic Reply effect'∆ WINS≡NO_WIN
      ok∧←'3503⌶'∆ 0 ''(WINS)(NO_ERROR)≡0 1 Execute'3503⌶''Caption'' (''Text 1'' ''Text 2'') ''Error'' (''Yes'' ''No'' ''Cancel'')'   ⍝ sets prompt type to 0 and pops up a window
      ok∧←'3503⌶ window'∆'Caption'('Text 1',CR LF,'Text 2')'Options'('Yes' 'No' 'Cancel')(0 1 2)≡(⊃WINS).(title text type options index)  ⍝ ⎕BUG newline is CR+LF !!!
      'Yes'Reply⊃WINS
      ok∧←'Dyadic Reply'∆ 1('61',NL)NO_WIN NO_ERROR≡Wait ⍬  ⍝ does not touch a window
      ok∧←'Dyadic Reply effect'∆ WINS≡NO_WIN
     
      ok∧←'739⌶0'∆ 1 NO_WIN NO_ERROR≡(⊂1 3 4)⌷r←Execute'739⌶0' ⍝ get temporary directory
      ok∧←'739⌶0 results'∆(NL=2⊃r)≡(1↑⍨-≢2⊃r)
      tmpfile←(tmpdir←¯1↓2⊃r),'/',⎕A[?50⍴26],'.tmp'
      ondisk←' res←OnDisk arg' '⍝ this function is fixed on disk' ' res←arg arg'
      ondisk2←ondisk,'' '⍝ one last comment'
     
      ok∧←'Creating temp file'∆ 1('1',NL)NO_WIN NO_ERROR≡Execute'× (⊂',(⍕Stringify¨ondisk),') ⎕NPUT ''',tmpfile,''' 0'
      ok∧←'Fixing temp file'∆ 1(' OnDisk ',NL)NO_WIN NO_ERROR≡Execute'⎕←2 ⎕FIX ''file://',tmpfile,''''
      ok∧←'EditOpen temp file'∆ WINS≡,⊂win←EditOpen'OnDisk'
      ok∧←'Deleting temp file'∆ 1('1',NL)NO_WIN NO_ERROR≡Execute'⎕←⎕NDELETE ''',tmpfile,''''
      ok∧←'EditFix temp file'∆(⊃⌽WINS)≡win2←win EditFix ondisk2  ⍝ will pop up a window to complain that file has disappeared
      ok∧←'EditFix temp file effect'∆ WINS≡win win2
      100 Reply win2   ⍝ fix and write back to file
      ok∧←'EditFix Reply fix&write'∆ 1 ''(,win)NO_ERROR≡Wait 1 1  ⍝ BUG? returns to prompt BEFORE touching window
      ok∧←'EditFix Reply fix&write effect'∆(0≡win.saved)∧(WINS≡,⊂win)
      ok∧←'EditFix fix effect'∆ 1(,(↑ondisk2),NL)(NO_WIN)(NO_ERROR)≡Execute' ⎕CR ''OnDisk'' '  ⍝ function has changed
      ok∧←'EditFix write effect'∆ 1(,(↑ondisk2),NL)(NO_WIN)(NO_ERROR)≡Execute' ↑⊃ ⎕NGET ''',tmpfile,''' 1'  ⍝ file on disk has changed
     
      ok∧←'Deleting temp file'∆ 1('1',NL)NO_WIN NO_ERROR≡Execute'⎕←⎕NDELETE ''',tmpfile,''''
      ok∧←'EditFix temp file'∆(⊃⌽WINS)≡win2←win EditFix ondisk  ⍝ will pop up a window to complain that file has disappeared
      103 Reply win2   ⍝ discard changes
      ok∧←'EditFix Reply'∆ ¯1 ''(,win)NO_ERROR≡Wait ⍬ 1  ⍝ updates window but prompt is unchanged
      CloseWindow win
      ok∧←'CloseWindow'∆ WINS≡NO_WIN
      ok∧←'EditFix effect'∆ 1(,(↑ondisk2),NL)(NO_WIN)(NO_ERROR)≡Execute' ⎕CR ''OnDisk'' '  ⍝ function hasn't changed
      ok∧←'EditFix effect'∆ 1('0',NL)(NO_WIN)(NO_ERROR)≡Execute' ⎕NEXISTS ''',tmpfile,''' '  ⍝ file is still deleted
      ok∧←'2 ⎕FIX ⎕NR OnDisk'∆ 1(' OnDisk ',NL)(NO_WIN)(NO_ERROR)≡Execute' +2 ⎕FIX ',⍕Stringify¨ondisk  ⍝ untie from file and put back original definition
     
      DEBUG←debug
    ∇


    ∇ ok←{where}_QA stop
    ⍝ stop is boolean flag to suspend execution on QA failure
      :Access Public Shared
      :If 0=⎕NC'where' ⋄ where←⊢ ⋄ :EndIf
      ok←(where New ⍬)._RunQA stop
    ∇

    ∇ ok←_RunBug1 bug;errors;output;win;wins;prompt
    ⍝ Repro for Mantis 18371
      :Access Public
      ok←1
      (prompt output wins errors)←Execute'+⎕FX ''foo'' ''⎕←1 2 3'' ''⎕←4 5 6'''
      ok∧←prompt output wins errors≡1('foo',NL)(NO_WIN)(NO_ERROR)
      (prompt output wins errors)←Trace'foo'
      ok∧←prompt output wins errors≡1('')(WINS)(NO_ERROR)
      win←⊃wins
      (prompt output wins errors)←TraceRun win←⊃WINS
      ok∧←prompt output wins errors≡1('1 2 3',NL)(,win)(NO_ERROR)
      ⍝ BUG : RestartThreads doesn't work
      :If bug ⋄ (prompt output wins errors)←Resume ⍬  ⍝ resume execution of all threads - does NOT work in some circumstances
      :Else ⋄ (prompt output wins errors)←TraceResume win  ⍝ resume execution of current thread - DOES always work
      :EndIf
      ok∧←prompt output wins errors≡1('4 5 6',NL)(,win)(NO_ERROR)
    ∇

    ∇ ok←_RunBug2 bug;ed;errors;foo;goo;output;prompt;tracer;wins
    ⍝ Repro for Mantis 18372 and 18308
    ⍝ 18372 may possibly require the bug Mantis 18308 NOT to be fixed (⎕STOP does not update opened windows)
      :Access Public
      ok←1
      foo←' foo' ' ⎕←1 2 3' ' ⎕←4 5 6'
      goo←' goo' ' foo'
      (prompt output wins errors)←Execute'+⎕FX ',⍕Stringify¨foo
      ok∧←prompt output wins errors≡1('foo',NL)(NO_WIN)(NO_ERROR)
      (prompt output wins errors)←Execute'+⎕FX ',⍕Stringify¨goo
      ok∧←prompt output wins errors≡1('goo',NL)(NO_WIN)(NO_ERROR)
      ed←EditOpen'foo'
      ok∧←WINS≡,ed
      (prompt output wins errors)←Execute'+0 1 2 ⎕STOP ''foo'' '
      ok∧←prompt output wins errors≡1('0 1 2',NL)(NO_WIN)(NO_ERROR)
      (prompt output wins errors)←Trace'goo'
      ok∧←prompt output wins errors≡1('')(,⊃⌽WINS)(NO_ERROR)  ⍝ foo has no more stops according to interpreter
      tracer←⊃wins
      (prompt output wins errors)←TraceResume tracer  ⍝ run foo which will stop at foo[1]
      ok∧←prompt output wins errors≡1(NL,'foo[1]',NL)(tracer,⊃⌽WINS)(ERROR_BREAK)
      ok∧←(2=≢WINS)∧(ed≡⊃WINS)∧(tracer≢⊃⌽WINS)
      tracer←⊃⌽WINS
      ok∧←tracer.stop≡0 1 2
      ok∧←ed EditFix foo ⍬  ⍝ reset stops
      CloseWindow ed
      :If bug  ⍝ Mantis 18308: interpreter ought to send a UpdateWindow on the tracer window
          ok∧←tracer.stop≡⍬
      :EndIf
      ok∧←WINS≡,tracer
      (prompt output wins errors)←Execute'+⎕STOP ''foo'' '
      ok∧←prompt output wins errors≡1('',NL)(NO_WIN)(NO_ERROR)  ⍝ foo has no more stops according to interpreter
      (prompt output wins errors)←TraceResume tracer
      ok∧←prompt output wins errors≡1('1 2 3',NL,'4 5 6',NL)(,tracer)(NO_ERROR)
      :If bug  ⍝ Mantis 18372:  clears 3 stops (from foo), whereas the interpreter thinks foo has no stops
          ok∧←0 0 0≡ClearTraceStopMonitor
      :EndIf
    ∇

    ∇ ok←_RunBug3 file;class;classbad;ed;res
      :Access Public
      ok←1
      class←':Class class' '∇ foo' '∇' ':EndClass'
      classbad←(¯1↓class),⊂':EndNamespace'
      ⍝ fix class and tie it to file
      ok∧←('35',NL)≡APL'+ (⊂',(⍕Stringify¨class),') ⎕NPUT ',(Stringify file),' 1'
      ok∧←(' class ',NL)≡APL'+ 2 ⎕FIX ',Stringify'file://',file
      ⍝ now edit class and put classbad instead
      ed←EditOpen'class'
      res←ed EditFix classbad
      ok∧←(9=⎕NC'res')∧('Task'≡res.type)∧('Save file content'≡res.text)∧('Fix as code in the workspace'≡28↑(res.index⍳100)⊃res.options)
      100 Reply res
      res←Wait ⍬ 1
      ok∧←(res[1 2 4]≡¯1 ''NO_ERROR)∧(1=≢3⊃res)
      res←⊃3⊃res
      ok∧←(9=⎕NC'res')∧('Options'≡res.type)∧('Can''t Fix'≡res.text)
      Reply res  ⍝ just close the error message
      ed.saved←⍬
      res←Wait ⍬ 1  ⍝ should ReplySaveChanges with error
      ok∧←res≡¯1 ''(,ed)NO_ERROR
      ok∧←ed.saved≡1  ⍝ fix failed (saved≠0)
      CloseWindow ed
      ok∧←(,(↑classbad),NL)≡APL' ↑⎕SRC class '
      ok∧←(,(↑classbad),NL)≡APL'↑⊃⎕NGET ',(Stringify file),' 1'
      ∘∘∘
     
      Edit'class'class  ⍝ put back original class
      'link issue #143'assert'(,(↑class),NL)≡ride.APL'' ↑⎕SRC ',name,'.class '' '
      'link issue #143'assert'class≡⊃⎕NGET(folder,''/class.aplc'')1'
      Edit'class'class
    ∇

    ∇ instance←{where}New env
    ⍝ Spawn a new interpreter, giving an environment string e.g. 'MAXWS=1G' or ''
      :Access Public Shared
      :If 0=⎕NC'where' ⋄ where←⊃⎕RSI ⋄ :EndIf
      instance←where.⎕NEW ⎕THIS env
    ∇
    ∇ instance←Connect arg;where
    ⍝ Connect to an listening interpreter at arg≡(port {host}) e.g. Connect (4600 '127.0.0.1')
      :Access Public Shared
      'Empty arg would spawn a new interpreter - use New instead'⎕SIGNAL(0∊⍴arg)/11
      :If 0=⎕NC'where' ⋄ where←⊃⎕RSI ⋄ :EndIf
      instance←where.⎕NEW ⎕THIS arg
    ∇




:EndClass
