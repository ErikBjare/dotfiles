--
-- An example, simple ~/.xmonad/xmonad.hs file.
-- It overrides a few basic settings, reusing all the other defaults.
--
import XMonad
import Data.Monoid
import System.Exit
import XMonad.Hooks.DynamicLog
import XMonad.Layout.Spacing
import XMonad.Layout.NoBorders
import XMonad.Layout.Named
import XMonad.Layout.Fullscreen
import XMonad.Hooks.ManageDocks

import qualified XMonad.StackSet as W
import qualified Data.Map        as M

-- Sets super as mod key
myModMask       = mod4Mask

-- Sets default terminal
myTerminal = "terminator"


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

-- put a 2px space around every window
myBorderWidth = 1 
-- Sets window border width to 1px
myNormalBorderColor = "#000000"
myFocusedBorderColor = "#2222bb"

myWorkspaces    = ["Term","Www","Prog","Music","Social","Fullscrn","7","8"]
-- Sets name of the workspaces


----------------------------------------------------------------------------------
-- Keyboard shortcuts

myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    -- launch a terminal
    [ ((modm,               xK_Return), spawn $ XMonad.terminal conf)
    -- launch dmenu
    , ((modm,               xK_r     ), spawn "dmenu_run")
    -- close focused window
    , ((modm,               xK_q     ), kill)
     -- Rotate through the available layout algorithms
    , ((modm,               xK_space ), sendMessage NextLayout)
    --  Reset the layouts on the current workspace to default
    , ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)
    -- Resize viewed windows to the correct size
    , ((modm,               xK_n     ), refresh)
    -- Move focus to the next window
    , ((modm,               xK_Tab   ), windows W.focusDown)
    -- Move focus to the next window
    , ((modm,               xK_j     ), windows W.focusDown)
    -- Move focus to the previous window
    , ((modm,               xK_k     ), windows W.focusUp  )
    -- Move focus to the master window
    , ((modm,               xK_m     ), windows W.focusMaster  )
    -- Swap the focused window with the next window
    , ((modm .|. shiftMask, xK_j     ), windows W.swapDown  )
    -- Swap the focused window with the previous window
    , ((modm .|. shiftMask, xK_k     ), windows W.swapUp    )
    -- Shrink the master area
    , ((modm,               xK_h     ), sendMessage Shrink)
    -- Expand the master area
    , ((modm,               xK_l     ), sendMessage Expand)
    -- Push window back into tiling
    , ((modm,               xK_t     ), withFocused $ windows . W.sink)
    -- Increment the number of windows in the master area
    , ((modm              , xK_comma ), sendMessage (IncMasterN 1))
    -- Deincrement the number of windows in the master area
    , ((modm              , xK_period), sendMessage (IncMasterN (-1)))
    ,((modm, xK_f     ), sendMessage ToggleStruts)
    -- Toggle the status bar gap
    -- Use this binding with avoidStruts from Hooks.ManageDocks.
    -- See also the statusBar function from Hooks.DynamicLog.
    --
    -- , ((modm              , xK_b     ), sendMessage ToggleStruts)
    -- Quit xmonad
    , ((modm .|. shiftMask, xK_x     ), io (exitWith ExitSuccess))
    -- Restart xmonad
    , ((modm              , xK_x     ), spawn "xmonad --recompile; xmonad --restart")
    , ((0, 0x1008ff11), spawn "/home/johan/.xmonad/scripts/volume.sh lower")
    , ((0, 0x1008ff13), spawn "/home/johan/.xmonad/scripts/volume.sh raise")
    , ((0, 0x1008ff12), spawn "/home/johan/.xmonad/scripts/volume.sh toggle")
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
    -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{a,s,d}, Move client to screen 1, 2, or 3
    --
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_a, xK_s, xK_d] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]


------------------------------------------------------------------------
-- Status bars and logging
 
-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for example

myLogHook = return ()


------------------------------------------------------------------------
-- Managehook

-- stuff to do when a new window is opened
myManageHook = composeAll [manageDocks]


------------------------------------------------------------------------
-- Event handling

-- | Defines a custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards.
-- To combine event hooks, use mappend or mconcat from Data.Monoid.
handleEventHook :: Event -> X All
handleEventHook _ = return (All True)

------------------------------------------------------------------------
-- Startup hook
 
-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.

-- myStartupHook = return ()


------------------------------------------------------------------------
-- Apply

main = xmonad =<< xmobar defaultConfig {
      -- General section
      terminal           = myTerminal
    , modMask            = myModMask
    , logHook            = myLogHook
    , manageHook         = myManageHook
    -- , startupHook        = myStartupHook
    -- Keyboard
    , keys               = myKeys
    -- Style and appearance
    , workspaces         = myWorkspaces
    , borderWidth        = myBorderWidth
    , layoutHook         = myLayout
    , normalBorderColor  = myNormalBorderColor
    , focusedBorderColor = myFocusedBorderColor }
