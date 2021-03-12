--- === ReloadConfiguration ===
---
--- Setup Rotating desktops
---

local obj={}
obj.__index = obj

-- Metadata
obj.name = "Wheel of Seasons"
obj.version = "0.1"
obj.author = "Adam Jackman <adam@acjackman.com>"
-- obj.homepage = "https://github.com/acjackman/wheelofseasons"
obj.license = "MIT - https://opensource.org/licenses/MIT"


local function loadWallpapers()
    obj.wallpapers = {}
    local n_wallpapers = 0
    for file in hs.fs.dir(obj.wheeldir) do
      if (file ~= "." and file ~= ".." and file ~= ".DS_Store" and file ~= nil and file ~= '') then
        table.insert(obj.wallpapers, file)
        n_wallpapers = n_wallpapers + 1
      end
    end
    obj.n_wallpapers = n_wallpapers
end

function obj:shiftWallpapers()
  -- print("obj.selected = " .. obj.selected)
  for k, screen in pairs(hs.screen.allScreens()) do
    local selected = (obj.selected + k) % obj.n_wallpapers
    local pic = obj.wallpapers[selected]
    -- print(selected .. ": " .. pic)
    screen:desktopImageURL("file://" .. obj.wheeldir .. pic)
  end
  obj.selected = (obj.selected + 1) % obj.n_wallpapers
end

function obj:start(dir, interval)
  print(dir)
  obj.wheeldir = dir
  obj.interval = interval
  loadWallpapers()
  obj.selected = math.random(obj.n_wallpapers)
  if obj.timer == nil then
      obj.timer = hs.timer.doEvery(obj.interval, function() obj:shiftWallpapers() end)
      obj.timer:setNextTrigger(5)
  else
      obj.timer:start()
  end
end

return obj
