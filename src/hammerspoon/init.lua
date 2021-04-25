-- Disable hide
hs.hotkey.bind("cmd", 'H', function() end)

-- -- A global variable for the Hyper Mode
k = hs.hotkey.modal.new({}, "F18")


-- Old Application

old_hyper = {
  'a', -- Zoom Global Mute Shortcut
  'SPACE', -- OmniFocus Quick Capture
  'c', -- Fantastical Keyboard Shortcutvh
  'i', -- iTerm interactive
  'z', -- Alfred Clipboard
  'k', -- Keyboard Maestro
  'b', -- Cardhop
  'h', -- Global Dash
  ';', -- Text Expander
  'RETURN', -- Drafts
  -- Keyboard Maestro
  'v', -- Paste by typing
  'o', -- Sends cmd-o to OmniFocus
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
  'm', -- Hook markdown Lonk
}
for i,key in ipairs(alt_hyper) do
  k:bind({}, key, nil, function() k.triggered = true hs.eventtap.keyStroke({"cmd","shift","ctrl"}, key) end)
end

-- Reimplement new notes file
new_inx = function()
  hs.execute('/usr/local/bin/subl -n "~/Notes/$(date +\'%Y%m%d%H%M%S\').md"', false)
  k.triggered = true
end
k:bind({}, '\\', nil, new_inx)

-- Daily Log file
daily_file = function()
  hs.execute('/usr/local/bin/subl -n "~/Notes/$(date +\'%Y%m%d060000\').md"', false)
  k.triggered = true
end
k:bind({}, '-', nil, daily_file)
-- Daily Log file

weekly_plan = function()
  local now = os.date("*t")
  local plan_date = os.date("%Y%m%d", os.time(now) - ((now.wday + 5) % 7) * 86400)
  local command = string.format('/usr/local/bin/subl -n "~/Notes/%s050000.md"', plan_date)
  hs.execute(command, false)
  k.triggered = true
end
k:bind({}, '0', nil, weekly_plan)

-- iTunes controls
function playpause()
  hs.osascript.applescript('tell application "Music" to playpause')
  k.triggered = true
end
function backtrack()
  hs.osascript.applescript('tell application "Music" to back track')
  k.triggered = true
end
function nexttrack()
  hs.osascript.applescript('tell application "Music" to next track')
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
  {'e', 'Sublime Text'},
  {'r', 'Safari'},
  {'t', 'iTerm'},
  {'f', 'Finder'},
  {'n', 'Obsidian'},
  {'=', 'Soulver 3'},
}
for i, app in ipairs(singleapps) do
  k:bind({}, app[1], function() launch(app[2]); k:exit(); end)
end

-- -- Sequential keybindings, e.g. Hyper-a,f for Finder
-- a = hs.hotkey.modal.new({}, "F16")
-- apps = {
--   {'a', 'Messages'},
--   {'z', 'zoom.us'},
--   {'e', 'Boxy for Gmail'}
-- }
-- for i, app in ipairs(apps) do
--   a:bind({}, app[1], function() launch(app[2]); a:exit(); k.triggered = true; end)
-- end
-- a:bind({}, 'm', nil, function() hs.eventtap.keyStroke({"cmd","alt","shift","ctrl"}, 'm') end) -- New Email with Kiwi

-- pressedA = function() a:enter() end
-- releasedA = function() end
-- k:bind({}, 'a', nil, pressedA, releasedA)


-- Shortcut to reload config
-- pfun = function()
--   hs.reload()
--   hs.alert.show("Config loaded")
--   k.triggered = true
-- end
-- k:bind({}, '=', nil, pfun)

-- Rotate secondary displays

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

k:bind({}, ']', nil, rotate_screen_clockwise)
k:bind({}, '[', nil, rotate_screen_counterclockwise)


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


-- directions = {"Left", "Right", "Up", "Down"}
-- -- Setup Window Movement (Spectacle replacement)
-- -- Window (1/2, 2/3, 1/3) for (←, →, ↑, ↓)

-- -- hs.window.animationDuration = 0

-- win_size = function(win_current, max)
--   half_screen = max / 2
--   two_thirds = max / 3 * 2
--   if win_current == half_screen then
--     return two_thirds
--   elseif win_current == two_thirds then
--     return max / 3
--   else
--      return half_screen
--   end
-- end

-- for i, direction in ipairs(directions) do
--   hs.hotkey.bind({"cmd", "alt", "ctrl"}, direction, function()
--     local win = hs.window.focusedWindow()
--     local f = win:frame()
--     local screen = win:screen()
--     local max = screen:frame()

--     if direction == "Left"  then
--       f.h = max.h
--       f.w = win_size(f.w, max.w)
--       f.x = max.x
--       f.y = max.y
--     elseif direction == "Right" then
--       f.h = max.h
--       f.w = win_size(f.w, max.w)
--       f.x = max.x + (max.w - f.w)
--       f.y = max.y
--     elseif direction == "Up" then
--       f.h = win_size(f.h, max.h)
--       f.w = max.w
--       f.x = max.x
--       f.y = max.y
--     elseif direction == "Down" then
--       f.h = win_size(f.h, max.h)
--       f.w = max.w
--       f.x = max.x
--       f.y = max.y + (max.y - f.h)
--     end

--     win:setFrame(f, 0)
--   end)
-- end

-- for i, direction in ipairs(directions) do
--   hs.hotkey.bind({"ctrl", "alt"}, direction, function()
--     local win = hs.window.focusedWindow()

--     if direction == "Left" then
--       win:moveOneScreenWest(false, true, 0)
--     elseif direction == "Right" then
--       win:moveOneScreenEast(false, true, 0)
--     elseif direction == "Up" then
--       win:moveOneScreenNorth(false, true, 0)
--     elseif direction == "Down" then
--       win:moveOneScreenSouth(false, true, 0)
--     end
--   end)
-- end



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

if (hs.host.localizedName() == "Frey") then
  hs.loadSpoon("WheelOfSeasons")
  spoon.WheelOfSeasons:start(
    os.getenv("HOME") .. "/Dropbox/Apps/WheelOfSeasons/",
    60*60,
    true
  )
end
if (hs.host.localizedName() == "Njord") then
  hs.loadSpoon("WheelOfSeasons")
  spoon.WheelOfSeasons:start(
    os.getenv("HOME") .. "/Dropbox/Reference/Desktops/FunWallpapers/",
    60*60,
    true
  )
end
