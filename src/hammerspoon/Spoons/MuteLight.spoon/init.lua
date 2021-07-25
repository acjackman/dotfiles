--- === MuteLight ===
---
--- Use a blink1 to provide mute status
---

local obj={}
obj.__index = obj

-- Metadata
obj.name = "MuteLight"
obj.version = "0.1"
obj.author = "Adam Jackman <adam@acjackman.com>"
-- obj.homepage = "https://github.com/acjackman/wheelofseasons"
obj.license = "MIT - https://opensource.org/licenses/MIT"


local log = hs.logger.new('MuteLight','info')
-- TODO: use https://github.com/profburke/luablink instead of `pipx blink1`

function wait(seconds)
    local start = os.time()
    repeat until os.time() > start + seconds
end

function setMuteLight()
  local muted = nil
  if (obj.device ~= nil) then
    muted = obj.device:inputMuted()
  end
  -- log.df("muted=%s" , muted)
  if ((muted == nil) or (not obj.lighton)) then
    hs.execute("blink1-shine --color black", true)
  elseif (muted) then
    hs.execute("blink1-shine --color '#500000'", true)
  else
    hs.execute("blink1-shine --color '#003500'", true)
  end
end

function muteLightCallback(uid, name, scope, element)
  log.df("Callback for uid=%s name=%s scope=%s element=%s", uid, name, scope, element)

  if (name == "mute") then
    setMuteLight()
  end
end

function deviceAdded(name)
  log.df("%s Adding...", name)
  local device = nil
  while (device == nil) do
    wait(1)
    device = hs.audiodevice.findInputByName(name)
  end
  obj.device = device
  obj.device:watcherCallback(muteLightCallback)
  obj.device:watcherStart()
  setMuteLight()
  log.df("%s Added", name)
end


function deviceRemoved(name)
  log.df("%s Removing...", name)
  if (obj.device ~= nil) then
    obj.device:watcherStop()
  end
  setMuteLight()
  log.df("%s Removed", name)
end


function usbCallback(data)
  local name = data["productName"]
  if ((name ~= nil) and (name == obj.deviceName)) then
    if (data["eventType"] == "added") then
      deviceAdded(name)
    elseif (data["eventType"] == "removed") then
      deviceRemoved(name)
    end
  end
end

function obj:togglLight()
  obj.lighton = not obj.lighton
  log.f("Toggling mute light to: %s", obj.lighton)
  setMuteLight()
end


function obj:start(deviceName, lighton)
  obj.lighton = lighton
  obj.deviceName = deviceName
  obj.device = nil

  for i, device in ipairs(hs.usb.attachedDevices()) do
    local name = device["productName"]
    if (name ~= nil and name == deviceName) then
      deviceAdded(name)
    end
  end
  setMuteLight()
  obj.usbWatcher = hs.usb.watcher.new(usbCallback)
  obj.usbWatcher:start()
end

return obj
