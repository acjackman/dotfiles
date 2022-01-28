-- Easy access variables:
hostname = hs.host.localizedName()


-- Disable hide
hs.hotkey.bind("cmd", 'H', function() end)

-- A global variable for the Hyper Mode
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
-- pfun = function()t
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
