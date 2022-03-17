-- Easy access variables:
hostname = hs.host.localizedName()

control     = {"ctrl"}
option      = {"option"}
hyper       = {"cmd","alt","ctrl"}
shift_hyper = {"cmd","alt","ctrl","shift"}
ctrl_cmd    = {"cmd","ctrl"}

-- Disable hide
hs.hotkey.bind("cmd", 'H', function() end)

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
local amethyst = hs.application.get("com.amethyst.Amethyst")

print(amethyst:name())
print(amethyst:bundleID())
local keyMap = {
  [singleKey('o', 'open')] = {
    [singleKey('o', 'omnifocus')] = launch_app("OmniFocus"),
    [singleKey('s', 'slack')] = launch_app("Slack"),
    [singleKey('d', 'drafts')] = launch_app("Drafts"),
    [singleKey('f', 'finder')] = launch_app("Finder"),
    [singleKey('=', 'calc')] = launch_app("Soulver 3"),
    [singleKey('t', 'terminal')] = launch_app("iTerm"),
    [singleKey('b', 'browser')] = launch_app("Safari")
  },
  [singleKey('w', 'window+')] = {
    [singleKey('f', 'focus')] = {
      [singleKey('1', 'screen-1')] = global_binding({"shift", "alt"}, "1"),
      [singleKey('2', 'screen-2')] = global_binding({"shift", "alt"}, "2"),
      [singleKey('3', 'screen-3')] = global_binding({"shift", "alt"}, "3"),
      [singleKey('4', 'screen-4')] = global_binding({"shift", "alt"}, "4")
    },
    [singleKey('l', 'layout+')] = {
      [singleKey('d', 'default')] = global_binding({"shift", "alt"}, "a"),
      [singleKey('w', 'wide')] = global_binding({"shift", "alt"}, "s"),
      [singleKey('f', 'fullscreen')] = global_binding({"shift", "alt"}, "d"),
      [singleKey('c', 'column')] = global_binding({"shift", "alt"}, "f"),
      [singleKey('r', 'rows')] = global_binding({"shift", "alt"}, "g")
    }
  },
  [singleKey('r', 'rotate-screen')] = {
    [singleKey('[', "left")] = rotate_screen_counterclockwise,
    [singleKey(']', "right")] = rotate_screen_clockwise

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


if (hs.host.localizedName() == "Frey") then
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

usbWatcher = hs.usb.watcher.new(usbDeviceCallback)
usbWatcher:start()

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

if (hostname == "Frey") then
  hs.loadSpoon("WheelOfSeasons")
  spoon.WheelOfSeasons:start(
    os.getenv("HOME") .. "/Dropbox/Apps/WheelOfSeasons/",
    60*60,
    true
  )
end
if (hostname == "Njord" or hostname == "Jormungandr") then
  hs.loadSpoon("WheelOfSeasons")
  spoon.WheelOfSeasons:start(
    os.getenv("HOME") .. "/Dropbox/Reference/Desktops/FunWallpapers/",
    60*60,
    true
  )
end
