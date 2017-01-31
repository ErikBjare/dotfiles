-- XMonad config by Erik Bjäreholt
-- Inspired by: http://thinkingeek.com/2011/11/21/simple-guide-configure-xmonad-dzen2-conky/

-- Imports {{{
    import XMonad
    import XMonad.Util.Run
    import XMonad.Util.Loggers
    import Data.Monoid

    -- Prompt
    import XMonad.Prompt
    import XMonad.Prompt.RunOrRaise (runOrRaisePrompt)
    import XMonad.Prompt.AppendFile (appendFilePrompt)

    import System.IO
    import System.Exit
    import System.Directory
    import System.IO.Unsafe
    import Codec.Binary.UTF8.String

    -- Actions
    import XMonad.Actions.PhysicalScreens -- Used to order xinerama displays properly
    import XMonad.Actions.Volume
    import XMonad.Actions.GridSelect
    import XMonad.Actions.CycleWS
    import Graphics.X11.ExtraTypes.XF86

    -- Hooks
    import XMonad.Hooks.ManageDocks
    import XMonad.Hooks.ManageHelpers
    import XMonad.Hooks.DynamicLog
    import XMonad.Hooks.FadeInactive
    import XMonad.Hooks.EwmhDesktops

    -- Layouts
    import XMonad.Layout.Spacing
    import XMonad.Layout.NoBorders
    import XMonad.Layout.Named
    import XMonad.Layout.PerWorkspace (onWorkspace, onWorkspaces)
    import XMonad.Layout.IM
    import XMonad.Layout.Grid
    import XMonad.Layout.SimpleFloat
    import XMonad.Layout.ResizableTile

    import Data.Ratio ((%))

    import qualified XMonad.StackSet as W
    import qualified Data.Map        as M

--}}}


-- Config {{{
    -- Sets super as mod key
    myModMask       = mod4Mask

    -- Sets default terminal
    myTerminal = "urxvt"

    -- Sets name of the workspaces
    myWorkspaces    = map show [1..10]

    myHomeDir = "/home/erb"
    myBitmapsDir = myHomeDir ++ "/.xmonad/dzen2"

    -- Conky config for status bar
    dzenConkyColor color    = "^fg(\\\\" ++ color ++ ")"
    imageBarColor   = "#2070FF"
    textBarColor    = "#70B0FF"
    sepBarColor     = "#FFA050"

    -- dcic & dctz, dzenConkyImageBarColor and dzenConkyTextBarColor
    dcic = dzenConkyColor imageBarColor
    dctc = dzenConkyColor textBarColor
    dcsc = dzenConkyColor sepBarColor

    sepBar = "|" -- "┃", "\x2503"

    dzenSegment image text = concat [dcic, " ^i(", myBitmapsDir, "/", image, ") ", dctc, text, " ", dcsc, sepBar]

    hasBattery = unsafePerformIO $ doesDirectoryExist "/sys/class/power_supply/BAT0"

    audioController = if hasBattery then "-c 1" else "-c 0"

    cpuSeg = dzenSegment "cpu.xbm" "${loadavg}"
    memSeg = dzenSegment "mem.xbm" "${memperc}%"
    volSeg = dzenSegment "volume.xbm" $ "${exec amixer " ++ audioController ++ " get Master | egrep -o \"[0-9]+%\" | head -1 | egrep -o \"[0-9]*\"}%"
    batSeg = if hasBattery
                    then dzenSegment "battery.xbm" "${battery_percent BAT0}%"
                    else ""
    traySeg = dzenSegment "info_01.xbm" "{                    }"
    clkSeg = dzenSegment "clock.xbm" "${time %Y/%m/%d} ${time %R:%S}"

    conkyText = init $ concat [ dcsc, "[", cpuSeg, memSeg, volSeg, batSeg, traySeg, clkSeg ]

    -- Bar
    barFont     = "-*-terminus-*-*-*-*-*-*-*-*-*-*-iso10646-*"
    -- barFont     = "-*-clean-*-*-*-*-15-*-*-*-*-*-iso10646-*"

    barHeight   = "16"
    barColor    = "#303030"
    wsBarStartX = "60"
    wsBarStartY   = "5"
    wsBarWidth = "1000"
    barSplitX = "500"
    myXmonadBar = "dzen2 -xs '1' -x " ++ wsBarStartX ++ " -y " ++ wsBarStartY ++ " -w '" ++ wsBarWidth ++ "' -h '" ++ barHeight ++ "' -ta 'l' -sa 'r' -fg '#FFFFFF' -bg '" ++ barColor ++ "' -fn '" ++ barFont ++ "'"
    myStatusBar = concat ["conky -c ~/.xmonad/.conky_dzen -t '", conkyText , "' | dzen2 -xs '1' -x '", barSplitX, "' -h '", barHeight, "' -ta 'r' -bg '", barColor, "' -fg '#FFFFFF' -fn '", barFont, "'"]
    myTray      = "trayer --monitor 'primary' --edge top --align right --margin 197 --distancefrom top --distance 2 --widthtype pixel --width 200 --transparent true --alpha 0 --tint 0x" ++ tail barColor ++ " --heighttype pixel --height " ++ (show $ (read barHeight :: Int)-4 :: String)
--}}}

-- Main {{{
    main = do
        dzenLeftBar  <- spawnPipe myXmonadBar
        ---dzenRightBar <- spawnPipe myStatusBar
        ---trayBar      <- spawnPipe myTray
        ---hPutStrLn dzenRightBar conkyText
        xmonad $ ewmh defaultConfig {
              -- General section
              terminal           = myTerminal
            , modMask            = myModMask
            , logHook            = myLogHook dzenLeftBar
            , layoutHook         = myLayoutHook
            , handleEventHook    = fullscreenEventHook
            --, handleEventHook    = ewmhDesktopsEventHook <+> fullscreenEventHook
            , manageHook         = manageDocks <+> myManageHook
            --, startupHook        = ewmhDesktopsStartup

            -- Keyboard
            , keys               = myKeys
            , mouseBindings      = myMouseBindings

            -- Style and appearance
            , workspaces         = myWorkspaces
            , borderWidth        = myBorderWidth
            , normalBorderColor  = myNormalBorderColor
            , focusedBorderColor = myFocusedBorderColor
        }
--}}}
--
-- Hooks {{{
    -- ManageHook {{{
    -- stuff to do when a new window is opened
    myManageHook :: ManageHook
    myManageHook = (composeAll . concat $
        [ [resource     =? r    --> doIgnore            |   r   <- myIgnoreResources ] -- ignore desktop
        , [className    =? c    --> doShift  "1:main"   |   c   <- myTerm   ] -- move term to main
        , [className    =? c    --> doShift  "2:web"    |   c   <- myWebs   ] -- move webs to web
        , [className    =? c    --> doShift  "3:dev"    |   c   <- myDevs   ] -- move devs to dev
        , [className    =? c    --> doShift  "4:chat"   |   c   <- myChat   ] -- move chat to chat
        , [className    =? c    --> doShift  "5:music"  |   c   <- myMusic  ] -- move music to music
        , [className    =? c    --> doCenterFloat       |   c   <- myFloatClasses ] -- float these classes
        , [name         =? n    --> doCenterFloat       |   n   <- myFloatNames  ] -- float these names
        , [isFullscreen         --> myDoFullFloat                           ]
        ])

        where

            role      = stringProperty "WM_WINDOW_ROLE"
            name      = stringProperty "WM_NAME"

            -- classnames
            myTerm    = ["Terminator"]
            myWebs    = ["Firefox", "Google-chrome", "Chromium", "Chromium-browser"]
            myDevs    = ["Sublime_text", "jetbrains-pycharm", "jetbrains-idea-ce"]
            myChat    = ["Pidgin", "Buddy List"]
            myMusic   = ["Rhythmbox", "Spotify"]

            -- floats
            myFloatClasses = ["Vlc", "VirtualBox", "Xmessage", "Steam", "Kalarm",
                              "XFontSel", "Downloads", "Nm-connection-editor", "Alarmclock", "Xfce4-panel"]
            myFloatNames   = ["bashrun","Google Chrome Options","Chromium Options"]

            -- resources, a list of roles, not names
            myIgnoreResources = ["desktop", "desktop_window", "notify-osd", "stalonetray",
                         "trayer", "xfce4-notifyd", "xfce4-desktop"]

            -- a trick for fullscreen but stil allow focusing of other WSs
            myDoFullFloat :: ManageHook
            myDoFullFloat = doF W.focusDown <+> doFullFloat

    --}}}

    -----------------------------------------------------------------------------------
    -- Appearance and layout

    -- myLayout = spacing 2 $ Tall 1 (3/100) (1/2)
    --
    myLayoutHook  = onWorkspaces ["1:term"]   termLayout $
                    onWorkspaces ["2:web"]    webLayout  $
                    onWorkspaces ["4:term2"]  termLayout $
                    onWorkspaces ["5:sys"]    termLayout $
                    defaultLayout

    defaultLayout = avoidStruts $ tiled ||| Grid ||| noBorders Full ||| simpleFloat
        where
            tiled = ResizableTall 1 (2/100) (1/2) []
            -- Mirror (Tall 1 (3/100) (1/2))) |||
            -- noBorders  = (named "Full" $ fullscreenFull Full)

    termLayout    = avoidStruts $ noBorders Full ||| tiled ||| Grid
        where
            tiled = ResizableTall 1 (2/100) (1/2) []

    webLayout     = avoidStruts $ noBorders Full ||| tiled
        where
            tiled = ResizableTall 1 (2/100) (1/2) []

    -- avoidStruts (
        -- mode (master add/max) (default proportion occupied by master)
        -- Tall (3/100) (1/2) |||
        -- Mirror tile (3/100) (1/2)) |||
        -- noBorders Full |||
        -- noBorders (fullscreenFull Full)

    -- Window border
    myBorderWidth = 1
    myNormalBorderColor = "#000000"
    myFocusedBorderColor = "#2222bb"



    ----------------------------------------------------------------------------------
    -- Keyboard shortcuts

    myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
        [
        -- launch terminal
        ((modm,               xK_Return), spawn $ XMonad.terminal conf)
        -- launch dmenu
        , ((modm,               xK_r     ), spawn "dmenu_run")
        -- lock with slock
        , ((modm,               xK_l     ), spawn "sleep 0.5; xset dpms force off; slock")
        -- lock with slock and suspend
        , ((modm .|. shiftMask, xK_l     ), spawn "sleep 0.5; systemctl suspend; slock")
        -- close focused window
        , ((modm,               xK_q     ), kill)

        -- Volume
        , ((modm,               xK_Print ), lowerVolumeChannels ["Master"] 5 >> return ())
        , ((modm,         xK_Scroll_Lock ), lowerVolumeChannels ["Master"] 100 >> return ())
        , ((modm,               xK_Pause ), raiseVolumeChannels ["Master"] 5 >> return ())
        , ((0,   xF86XK_AudioLowerVolume ), lowerVolumeChannels ["Master"] 5 >> return ())
        , ((0,          xF86XK_AudioMute ), lowerVolumeChannels ["Master"] 100 >> return ())
        , ((0,   xF86XK_AudioRaiseVolume ), raiseVolumeChannels ["Master"] 5 >> return ())

        -- Screen brightness
        , ((0,  xF86XK_MonBrightnessUp   ), spawn "xbacklight +5")
        , ((0,  xF86XK_MonBrightnessDown ), spawn "xbacklight -5")

        -- Screen temperature & software brightness
        , ((modm,               xK_F11   ), spawn "systemctl --user stop redshift; redshift -O 7000 -b 1.0")
        , ((modm,               xK_F12   ), spawn "systemctl --user start redshift")

        -- Used in testing
        , ((modm,               xK_t     ), spawn ("echo -e \"" ++ sepBar ++ "\" >> /home/erb/.xmonad/test.txt"))

        -- Printscreen
        , ((0,                  xK_Print ), spawn "gnome-screenshot")

        -- Rotate through the available layout algorithms
        , ((modm,               xK_space ), sendMessage NextLayout)
        --, ((modm,               xK_apostrophe ), gridselectWorkspace defaultGSConfig (\ws -> W.greedyView ws))
        --, ((modm,               xK_apostrophe ), goToSelected defaultGSConfig)

        --  Reset the layouts on the current workspace to default
        , ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)

        -- Resize viewed windows to the correct size
        , ((modm,               xK_n     ), refresh)

        -- Move focus to the next/prev/master window
        , ((modm,               xK_Tab   ), windows W.focusDown    )
        , ((modm,               xK_j     ), windows W.focusDown    )
        , ((modm,               xK_k     ), windows W.focusUp      )
        , ((modm,               xK_m     ), windows W.focusMaster  )

        -- Swap the focused window with the next/prev window
        , ((modm .|. shiftMask, xK_Tab   ), windows W.swapDown  )
        , ((modm .|. shiftMask, xK_j     ), windows W.swapDown  )
        , ((modm .|. shiftMask, xK_k     ), windows W.swapUp    )

        -- Shrink/expand the master area
        , ((modm,               xK_minus ), sendMessage Shrink)
        , ((modm,               xK_plus  ), sendMessage Expand)

        -- Push window back into tiling
        , ((modm,               xK_t     ), withFocused $ windows . W.sink)

        -- Increment/deincrement the number of windows in the master area
        , ((modm              , xK_comma ), sendMessage (IncMasterN 1))
        , ((modm              , xK_period), sendMessage (IncMasterN (-1)))

        -- Toggle the status bar gap
        -- Use this binding with avoidStruts from Hooks.ManageDocks.
        -- See also the statusBar function from Hooks.DynamicLog.
        , ((modm              , xK_b     ), sendMessage ToggleStruts)

        -- Quit xmonad
        , ((modm .|. shiftMask, xK_x     ), io (exitWith ExitSuccess))
        -- Restart xmonad
        , ((modm              , xK_x     ), spawn "killall conky dzen2 trayer; xmonad --recompile && xmonad --restart")
        ]
        ++
        --
        -- mod-[1..9], Switch to workspace N
        --
        -- mod-[1..9], Switch to workspace N
        -- mod-shift-[1..9], Move client to workspace N
        --
        [((m .|. modm, k), windows $ f i)
            | (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9] ++ [xK_0])
            , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
        ++
        --
        -- mod-{a,s,d}, Switch to physical/Xinerama screens 1, 2, or 3
        -- mod-shift-{a,s,d}, Move client to screen 1, 2, or 3
        --
        [((m .|. modm, key), f sc)
            | (key, sc) <- zip [xK_a, xK_s, xK_d] [0..]
            , (f, m) <- [(viewScreen, 0), (sendToScreen, shiftMask)]]

    -- | Mouse bindings: default actions bound to mouse events
    myMouseBindings :: XConfig Layout -> M.Map (KeyMask, Button) (Window -> X ())
    myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList
        -- mod-button1 %! Set the window to floating mode and move by dragging
        [ ((modm, button1), \w -> focus w >> mouseMoveWindow w
                                              >> windows W.shiftMaster)
        -- mod-button2 %! Raise the window to the top of the stack
        , ((modm .|. shiftMask, button3), \ws -> gridselectWorkspace defaultGSConfig (\ws -> W.greedyView ws))
        -- mod-button3 %! Set the window to floating mode and resize by dragging
        , ((modm, button3), \w -> focus w >> mouseResizeWindow w
                                             >> windows W.shiftMaster)
        -- you may also bind events to the mouse scroll wheel (button4 and button5)
        , ((modm, button4), \w -> prevWS)
        , ((modm, button5), \w -> nextWS)
        ]

    ------------------------------------------------------------------------
    -- Status bars and logging

    -- Perform an arbitrary action on each internal state change or X event.
    -- See the 'XMonad.Hooks.DynamicLog' extension for example

    --myStatusHook :: Handle -> X ()
    --myStatusHook h = dynamicLogWithPP $ PP
    --    {
    --          ppExtras    = [myStatusLogger]
    --       , ppOutput    = hPutStrLn h
    --    }

    myLogHook :: Handle -> X ()
    myLogHook h = dynamicLogWithPP $ defaultPP
        {
            ppCurrent           =   dzenColor "#50FF5F" barColor . wrap "(" ")"
          , ppVisible           =   dzenColor "#FF50FF" barColor . wrap "[" "]"
          , ppHidden            =   dzenColor "#AAAAAA" barColor . pad
          , ppHiddenNoWindows   =   dzenColor "#505050" barColor . pad
          , ppUrgent            =   dzenColor "#FF0000" barColor . pad
          , ppWsSep             =   ""
          , ppSep               =   "^fg(" ++ sepBarColor ++ ") "++sepBar++" "
          , ppLayout            =   dzenColor imageBarColor barColor .
                                    (\x -> case x of
                                        "ResizableTall"             ->      "^i(" ++ myBitmapsDir ++ "/tall.xbm)"
                                        "Mirror ResizableTall"      ->      "^i(" ++ myBitmapsDir ++ "/mtall.xbm)"
                                        "Full"                      ->      "^i(" ++ myBitmapsDir ++ "/full.xbm)"
                                        "Simple Float"              ->      "~"
                                        "IM Grid"                   ->      "IM"
                                        _                           ->      x
                                    )
          , ppTitle             =   dzenColor "white" barColor . dzenEscape
          , ppExtras            =   []
          , ppOutput            =   hPutStrLn h
        }
--}}}

