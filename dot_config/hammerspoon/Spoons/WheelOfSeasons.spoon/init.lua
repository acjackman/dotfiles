--- === Wheel of Seasons ===
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

math.randomseed(os.time())


local function shuffleInPlace(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(obj.n_wallpapers)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
end

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

    if (obj.shuffle) then
      shuffleInPlace(obj.wallpapers)
    end
end

function obj:setWallpapers()
  print("Updating Wallpapers obj.selected=" .. obj.selected)
  for k, screen in pairs(hs.screen.allScreens()) do

    local selected = ((obj.selected + k) % obj.n_wallpapers) + 1
    print("  finding item " .. selected .. " of " .. obj.n_wallpapers)
    local pic = obj.wallpapers[selected]
    print("  " .. selected .. ": " .. pic)
    screen:desktopImageURL("file://" .. obj.wheeldir .. pic)
  end
end

function obj:shiftWallpapers()
  -- print("obj.selected = " .. obj.selected)
  obj.selected = (obj.selected + 1) % obj.n_wallpapers
  obj:setWallpapers()
end

function screensChangedCallback(data)
  obj:setWallpapers()
end


function obj:start(dir, interval, shuffle)
  -- print(dir)
  obj.wheeldir = dir
  obj.interval = interval
  obj.shuffle = shuffle
  loadWallpapers()
  -- obj.selected = math.random(obj.n_wallpapers)
  obj.selected = -2
  if obj.timer == nil then
      obj.timer = hs.timer.doEvery(obj.interval, function() obj:shiftWallpapers() end)
      obj.timer:setNextTrigger(5)
  else
      obj.timer:start()
  end
  if obj.spacewatch == nil then
    obj.spacewatch = hs.spaces.watcher.new(screensChangedCallback)
    obj.spacewatch:start()
  end
end

return obj
