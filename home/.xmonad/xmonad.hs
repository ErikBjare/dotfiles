-- XMonad config by Erik Bjäreholt
-- Inspired by: http://thinkingeek.com/2011/11/21/simple-guide-configure-xmonad-dzen2-conky/

-- Imports {{{
    import XMonad
    import XMonad.Util.Run
    import Data.Monoid

    -- Prompt
    import XMonad.Prompt
    import XMonad.Prompt.RunOrRaise (runOrRaisePrompt)
    import XMonad.Prompt.AppendFile (appendFilePrompt)

    import System.IO
    import System.Exit

    -- Used to order xinerama displays properly
    import XMonad.Actions.PhysicalScreens

    -- Hooks
    import XMonad.Hooks.ManageDocks
    import XMonad.Hooks.ManageHelpers
    import XMonad.Hooks.DynamicLog
    import XMonad.Hooks.FadeInactive

    -- Layouts
    import XMonad.Layout.Spacing
    import XMonad.Layout.NoBorders
    import XMonad.Layout.Named
    import XMonad.Layout.Fullscreen

    import qualified XMonad.StackSet as W
    import qualified Data.Map        as M

--}}}


-- Config {{{
    -- Sets super as mod key
    myModMask       = mod4Mask

    -- Sets default terminal
    myTerminal = "terminator"
    
    -- Sets name of the workspaces
    myWorkspaces    = ["1:term","2:web","3:dev","4:chat","5:music","6:fullscrn"] ++ map show [7..9]
    
    -- dzen2 bar
    myXmonadBar = "dzen2 -xs '1' -w '1200' -h '24' -ta 'l' -sa 'r' -fg '#FFFFFF' -bg '#1B1D1E'"
    myStatusBar = "conky -c ~/.xmonad/.conky_dzen | dzen2 -xs '1' -h '24' -ta 'r' -sa 'r' -bg '#1B1D1E' -fg '#FFFFFF' "
    myBitmapsDir = "/home/erb/.xmonad/dzen"
--}}}

-- Main {{{
    main = do
        dzenLeftBar  <- spawnPipe myXmonadBar
        dzenRightBar <- spawnPipe myStatusBar
        xmonad $ defaultConfig {
              -- General section
              terminal           = myTerminal
            , modMask            = myModMask
            , logHook            = myLogHook dzenLeftBar >> fadeInactiveLogHook 0xdddddddd
            , manageHook         = myManageHook
            -- , startupHook        = myStartupHook
            -- Keyboard
            , keys               = myKeys
            -- Style and appearance
            , workspaces         = myWorkspaces
            , borderWidth        = myBorderWidth
            , layoutHook         = myLayout
            , handleEventHook    = fullscreenEventHook
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
        [ [resource     =? r    --> doIgnore            |   r   <- myIgnores] -- ignore desktop
        , [className    =? c    --> doShift  "1:main"   |   c   <- myTerm   ] -- move term to main
        , [className    =? c    --> doShift  "2:web"    |   c   <- myWebs   ] -- move webs to web
        , [className    =? c    --> doShift  "3:dev"    |   c   <- myDevs   ] -- move devs to dev
        , [className    =? c    --> doShift  "4:chat"   |   c   <- myChat   ] -- move chat to chat
        , [className    =? c    --> doShift  "5:music"  |   c   <- myMusic  ] -- move music to music
        , [className    =? c    --> doCenterFloat       |   c   <- myFloats ] -- float my floats
        , [name         =? n    --> doCenterFloat       |   n   <- myNames  ] -- float my names
        , [isFullscreen         --> myDoFullFloat                           ]
        ]) 
        
        where
        
            role      = stringProperty "WM_WINDOW_ROLE"
            name      = stringProperty "WM_NAME"
        
            -- classnames
            myTerm    = ["Terminator"]
            myWebs    = ["Firefox", "Google-chrome", "Chromium", "Chromium-browser"]
            myDevs    = ["jetbrains-pycharm"]
            myChat    = ["Pidgin", "Buddy List"]
            myMusic   = ["Rhythmbox", "Spotify"]
            myFloats  = ["Vlc", "VirtualBox", "Xmessage",
                         "XFontSel", "Downloads", "Nm-connection-editor", "Alarmclock"]
        
            -- resources
            myIgnores = ["desktop","desktop_window","notify-osd","stalonetray","trayer"]
        
            -- names
            myNames   = ["bashrun","Google Chrome Options","Chromium Options"]
        
            -- a trick for fullscreen but stil allow focusing of other WSs
            myDoFullFloat :: ManageHook
            myDoFullFloat = doF W.focusDown <+> doFullFloat
    --}}}
    
    -----------------------------------------------------------------------------------
    -- Appearance and layout
    
    -- myLayout = spacing 2 $ Tall 1 (3/100) (1/2)
    --
    myLayout = avoidStruts (
        named "Tiled" $ smartSpacing 2 $ Tall 1 (3/100) (1/2) |||
        -- Mirror (Tall 1 (3/100) (1/2))) |||
        noBorders (named "Full" $ fullscreenFull Full)) 

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
        , ((modm,               xK_l     ), spawn "slock")
        -- close focused window
        , ((modm,               xK_q     ), kill)
    
         -- Rotate through the available layout algorithms
        , ((modm,               xK_space ), sendMessage NextLayout)
    
        --  Reset the layouts on the current workspace to default
        , ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)

        -- Resize viewed windows to the correct size
        , ((modm,               xK_n     ), refresh)
    
        -- Move focus to the next/prev/master window
        , ((modm,               xK_Tab   ), windows W.focusDown)
        , ((modm,               xK_j     ), windows W.focusDown)
        , ((modm,               xK_k     ), windows W.focusUp  )
        , ((modm,               xK_m     ), windows W.focusMaster  )
        
        -- Swap the focused window with the next/prev window
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
        , ((modm              , xK_x     ), spawn "killall conky dzen2; xmonad --recompile && xmonad --restart")
        ]
        ++
        --
        -- mod-[1..9], Switch to workspace N
        --
        -- mod-[1..9], Switch to workspace N
        -- mod-shift-[1..9], Move client to workspace N
        --
        [((m .|. modm, k), windows $ f i)
            | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
            , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
        ++
        --
        -- mod-{a,s,d}, Switch to physical/Xinerama screens 1, 2, or 3
        -- mod-shift-{a,s,d}, Move client to screen 1, 2, or 3
        --
        [((m .|. modm, key), f sc)
            | (key, sc) <- zip [xK_a, xK_s, xK_d] [0..]
            , (f, m) <- [(viewScreen, 0), (sendToScreen, shiftMask)]]
    
    
    ------------------------------------------------------------------------
    -- Status bars and logging
     
    -- Perform an arbitrary action on each internal state change or X event.
    -- See the 'XMonad.Hooks.DynamicLog' extension for example
    
    myLogHook :: Handle -> X ()
    myLogHook h = dynamicLogWithPP $ defaultPP
        {
            ppCurrent           =   dzenColor "#30ffff" "#1B1D1E" . pad
          , ppVisible           =   dzenColor "#f050ff" "#1B1D1E" . pad
          , ppHidden            =   dzenColor "white" "#1B1D1E" . pad
          , ppHiddenNoWindows   =   dzenColor "#7b7b7b" "#1B1D1E" . pad
          , ppUrgent            =   dzenColor "#ff0000" "#1B1D1E" . pad
          , ppWsSep             =   " "
          , ppSep               =   "  |  "
          , ppLayout            =   dzenColor "#00b0ff" "#1B1D1E" .
                                    (\x -> case x of
                                        "ResizableTall"             ->      "^i(" ++ myBitmapsDir ++ "/tall.xbm)"
                                        "Mirror ResizableTall"      ->      "^i(" ++ myBitmapsDir ++ "/mtall.xbm)"
                                        "Full"                      ->      "^i(" ++ myBitmapsDir ++ "/full.xbm)"
                                        "Simple Float"              ->      "~"
                                        _                           ->      x
                                    )
          , ppTitle             =   (" " ++) . dzenColor "white" "#1B1D1E" . dzenEscape
          , ppOutput            =   hPutStrLn h
        }
--}}}

