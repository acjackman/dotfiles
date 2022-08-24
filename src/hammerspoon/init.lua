-- hammerspoon console script
-- require("hs.ipc")
-- hs.ipc.cliInstall("/usr/local")

-- Easy access variables:
hostname = hs.host.localizedName()

print(hostname)
  -- local log = hs.logger.new('terminalHyper','debug')
--   log.df("name=%s", appname)


control     = {"ctrl"}
option      = {"option"}
meh         = {"alt", "ctrl", "shift"}
hyper       = {"cmd","alt","ctrl"}
shift_hyper = {"cmd","alt","ctrl","shift"}
ctrl_cmd    = {"cmd","ctrl"}

-- Disable hide
hs.hotkey.bind("cmd", 'H', function() end)



--
hs.console.darkMode(true)
if hs.console.darkMode() then
  hs.console.outputBackgroundColor{ white = 0 }
  hs.console.consolePrintColor({green = 1})
  hs.console.consoleCommandColor{ white = 1 }
  hs.console.alpha(1)
end

--
 hs.loadSpoon("RecursiveBinder")

launch_app = function(name)
  return function()
    hs.application.launchOrFocus(name)
  end
end

global_binding = function(modifier, character)
  return function()
    hs.eventtap.keyStroke(modifier, character)
  end
end

app_binding = function(modifiers, character, app)
  return function()
    local app = hs.application.get(app)
    hs.eventtap.keyStroke(modifier, character, app)
  end
end

run_shell = function(cmd)
  return function()
    hs.execute(cmd, true)
  end
end

rotate_screen_clockwise = function()
  screen = hs.screen.mainScreen()
  current_rotation = screen:rotate()
  new_rotation = (current_rotation + 90) % 360
  screen:rotate(new_rotation)
  k.triggered = true
end

rotate_screen_counterclockwise = function()
  screen = hs.screen.mainScreen()
  current_rotation = screen:rotate()
  new_rotation = (current_rotation + 270) % 360
  screen:rotate(new_rotation)
  k.triggered = true
end





-- spoon.RecursiveBinder.escapeKey = {{}, 'escape'}  -- Press escape to abort
local singleKey = spoon.RecursiveBinder.singleKey
local keyMap = {
  [singleKey('o', 'open')] = {
    [singleKey('o', 'omnifocus')] = launch_app("OmniFocus"),
    [singleKey('l', 'linear')] = launch_app("Linear"),
    [singleKey('e', 'emacs')] = launch_app("Emacs"),
    [singleKey('s', 'slack')] = launch_app("Slack"),
    [singleKey('d', 'drafts')] = launch_app("Drafts"),
    [singleKey('f', 'finder')] = launch_app("Finder"),
    [singleKey('=', 'calc')] = launch_app("Soulver 3"),
    [singleKey('t', 'terminal')] = launch_app("iTerm"),
    [singleKey('b', 'browser')] = launch_app("Safari")
  },
  [singleKey('w', 'window+')] = {
    [singleKey('b', 'balance')] = run_shell("yabai -m space --balance"),
    -- [singleKey(',', 'main+1')] = global_binding({"shift", "alt"}, ","),
    -- [singleKey('.', 'main-1')] = global_binding({"shift", "alt"}, "."),
    -- [singleKey('h', 'main+1')] = global_binding({"shift", "alt"}, ","),
    -- [singleKey('l', 'main-1')] = global_binding({"shift", "alt"}, "."),
    [singleKey('l', 'float')] = run_shell("yabai -m window --toggle float"),
    [singleKey('f', 'focus')] = {
      [singleKey('h', 'west')] = run_shell("yabai -m window --focus west"),
      [singleKey('j', 'south')] = run_shell("yabai -m window --focus south"),
      [singleKey('k', 'north')] = run_shell("yabai -m window --focus north"),
      [singleKey('l', 'east')] = run_shell("yabai -m window --focus east"),
    },
    [singleKey('m', 'move')] = {
      [singleKey('1', 'screen-1')] = run_shell("yabai -m window --display 1; yabai -m display --focus 1"),
      [singleKey('2', 'screen-2')] = run_shell("yabai -m window --display 2; yabai -m display --focus 2"),
      [singleKey('3', 'screen-3')] = run_shell("yabai -m window --display 3; yabai -m display --focus 3"),
      [singleKey('4', 'screen-4')] = run_shell("yabai -m window --display 4; yabai -m display --focus 4"),
      [singleKey('m', 'first')] = run_shell("yabai -m window --warp first"),
      [singleKey('n', 'last')] = run_shell("yabai -m window --warp last"),
      [singleKey('h', 'west')] = run_shell("yabai -m window --warp west"),
      [singleKey('j', 'south')] = run_shell("yabai -m window --warp south"),
      [singleKey('k', 'north')] = run_shell("yabai -m window --warp north"),
      [singleKey('l', 'east')] = run_shell("yabai -m window --warp east"),
    },
    [singleKey('n', 'new')] = run_shell("yabai -m space --create"),
  },
  [singleKey('s', 'screen')] = {
    [singleKey('f', 'focus')] = {
      [singleKey('1', 'screen-1')] = run_shell("yabai -m display --focus 1"),
      [singleKey('2', 'screen-2')] = run_shell("yabai -m display --focus 2"),
      [singleKey('3', 'screen-3')] = run_shell("yabai -m display --focus 3"),
      [singleKey('4', 'screen-4')] = run_shell("yabai -m display --focus 4"),
      [singleKey('h', 'west')] = run_shell("yabai -m display --focus west"),
      [singleKey('j', 'south')] = run_shell("yabai -m display --focus south"),
      [singleKey('k', 'north')] = run_shell("yabai -m display --focus north"),
      [singleKey('l', 'east')] = run_shell("yabai -m display --focus east"),
    },
    [singleKey('s', 'space')] = {
      [singleKey('n', 'new')] = run_shell("yabai -m space --create"),
      [singleKey('d', 'delete')] = run_shell("yabai -m space --destroy"),
      [singleKey('h', 'previous')] = run_shell("yabai -m space --focus prev || yabai -m space --focus last"),
      [singleKey('l', 'next')] = run_shell("yabai -m space --focus next || yabai -m space --focus first"),
    },
    [singleKey('r', 'rotate-screen')] = {
      [singleKey('[', "left")] = rotate_screen_counterclockwise,
      [singleKey(']', "right")] = rotate_screen_clockwise,
      [singleKey('0', "0°")] = function() screen:rotate(0) end,
      [singleKey('1', "90°")] = function() screen:rotate(90) end,
      [singleKey('2', "180°")] = function() screen:rotate(180) end,
      [singleKey('3', "270°")] = function() screen:rotate(270) end,
    }
  }
}

spoon.RecursiveBinder.helperFormat = {
    -- atScreenEdge = 2,  -- Bottom edge (default value)
    strokeColor =  { white = 0, alpha = 0 },
    textStyle = {  -- An hs.styledtext object
        font = {
            name = "JetBrainsMono Nerd Font",
            size = 18
        }
    }
}


hs.hotkey.bind({'ctrl'}, 'space', spoon.RecursiveBinder.recursiveBind(keyMap))

-- A global variable for the Hyper Mode
k = hs.hotkey.modal.new({}, "F18")

-- Old Application
old_hyper = {
  'a', -- Zoom Global Mute Shortcut
  'SPACE', -- OmniFocus Quick Capture
  'c', -- Fantastical Keyboard Shortcut
  'i', -- iTerm interactive
  'z', -- Alfred Clipboard
  'k', -- Keyboard Maestro
  'b', -- Cardhop
  'h', -- Global Dash
  ';', -- Text Expander
  'RETURN', -- Drafts
  'y', -- Menuwhere
  -- Keyboard Maestro
  'v', -- Paste by typing
  -- Rating Music with Alfred
  '`', -- Remove rating
  '1', -- one star
  '2', -- two stars
  '3', -- three stars
  '4', -- four stars
  '5', -- five stars
}
for i,key in ipairs(old_hyper) do
  k:bind({}, key, nil, function() k.triggered = true hs.eventtap.keyStroke({"cmd","alt","shift","ctrl"}, key) end)
end


-- Alternate hyper
alt_hyper = {
  'l', -- Hook Link
  -- 'm', -- Hook markdown Lonk
}
for i,key in ipairs(alt_hyper) do
  k:bind({}, key, nil, function() k.triggered = true hs.eventtap.keyStroke({"cmd","shift","ctrl"}, key) end)
end


--
function savewindows()
  hs.execute("yabai -m query --windows > ~/dump/windows-$(date '+%Y-%m-%dT%H-%M-%S').json; noti -t 'Saved Windows' -m ''", true)
  -- hs.execute("yabai -m query --windows > ~/dump/windowsstate.json", true)
  k.triggered = true
end


k:bind({}, 'w', nil, savewindows)


-- iTunes controls
function playpause()
  hs.itunes.playpause()
  k.triggered = true
end
function backtrack()
  hs.itunes.previous()
  k.triggered = true
end
function nexttrack()
  hs.itunes.next()
  k.triggered = true
end
function musicvolup()
  hs.osascript.applescript('tell application "Music" to set sound volume to ((get sound volume) + 3)')
  k.triggered = true
end
function musicvoldown()
  hs.osascript.applescript('tell application "Music" to set sound volume to ((get sound volume) - 3)')
  k.triggered = true
end
k:bind({}, 'p', nil, playpause)
k:bind({}, 'left', nil, backtrack)
k:bind({}, 'right', nil, nexttrack)
k:bind({}, 'up', nil, musicvolup)
k:bind({}, 'down', nil, musicvoldown)


-- Single keybinding for app launch
launch = function(appname)
  hs.application.launchOrFocus(appname)
  k.triggered = true
end

singleapps = {
  {'q', 'OmniFocus'},
  {'s', 'Slack'},
  {'d', 'Drafts'},
  -- {'e', 'Sublime Text'},
  {'r', 'Safari'},
  {'t', 'iTerm'},
  {'f', 'Finder'},
  {'n', 'Obsidian'},
  {'o', 'The Archive'},
  {'=', 'Soulver 3'},
}
for i, app in ipairs(singleapps) do
  k:bind({}, app[1], function() launch(app[2]); end)
end

-- function terminalHyper()
--   local app = hs.application.frontmostApplication()
--   local appname = app:name()
--   local log = hs.logger.new('terminalHyper','debug')
--   log.df("name=%s", appname)

--   if (appname == "Code") then
--     hs.eventtap.keyStroke({"ctrl"}, "`")
--   else
--     launch("iTerm")
--   end
--   k.triggered = true
--   --k:exit()
-- end
-- k:bind({}, "t", nil, terminalHyper)


if (hs.host.localizedName() == "MacBook Pro") then
  k:bind({}, "e", function() launch('Visual Studio Code'); end)
else
  k:bind({}, "e", function() launch('Emacs'); end)
end


-- hs.loadSpoon("MuteLight")
-- spoon.MuteLight:start("Jabra Link 380", false)

-- k:bind({}, 'm', nil, function() k.triggered = true; spoon.MuteLight:togglLight() end)

-- Enter Hyper Mode when F19 (Hyper/Capslock) is pressed
pressedF19 = function()
  k.triggered = false
  k:enter()
end

-- Leave Hyper Mode when F19 (Hyper/Capslock) is pressed,
--   send ESCAPE if no other keys are pressed.
releasedF19 = function()
  k:exit()
  if not k.triggered then

    hs.eventtap.keyStroke({}, 'ESCAPE')
  end
end

-- Bind the Hyper key
f19 = hs.hotkey.bind({}, 'F19', pressedF19, releasedF19)

-- Launch and quit ScanSnap Manager
-- usbWatcher = nil
function usbDeviceCallback(data)
    if (data["productName"] == "ScanSnap S1300i") then
        if (data["eventType"] == "added") then
            hs.application.launchOrFocus("ScanSnap Manager")
        elseif (data["eventType"] == "removed") then
            app = hs.appfinder.appFromName("ScanSnap Manager")
            app:kill()
        end
    end
end

if (hs.host.localizedName() == "Jormungandr") then
  usbWatcher = hs.usb.watcher.new(usbDeviceCallback)
  usbWatcher:start()
end

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

if (hostname == "MacBook Pro") then
  hs.loadSpoon("WheelOfSeasons")
  spoon.WheelOfSeasons:start(
    os.getenv("HOME") .. "/WheelOfSeasons/",
    60*60,
    true
  )
end

if (hostname == "Ingvar" or hostname == "Jormungandr") then
  hs.loadSpoon("WheelOfSeasons")
  spoon.WheelOfSeasons:start(
    os.getenv("HOME") .. "/Dropbox/Reference/Desktops/FunWallpapers/",
    60*60,
    true
  )
end


function yabaiRestarter()
  -- hs.notify.show("HS-> Yabai", "", "restarting yabai")
  hs.execute("noti brew services restart yabai", true)
end

yabaiWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.config/yabai/", yabaiRestarter):start()
