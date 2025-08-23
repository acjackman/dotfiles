--- === Wheel of Seasons ===
---
--- Setup Rotating desktops
---

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Wheel of Seasons"
obj.version = "0.1"
obj.author = "Adam Jackman <adam@acjackman.com>"
-- obj.homepage = "https://github.com/acjackman/wheelofseasons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Initialize logger
obj.logger = hs.logger.new("WheelOfSeasons", "info")

-- Initialize random seed (scoped to module)
local function initRandomSeed()
  math.randomseed(os.time())
end
initRandomSeed()


local function shuffleInPlace(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
end

local function isImageFile(filename)
  local imageExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp" }
  local lowerFilename = string.lower(filename)
  for _, ext in ipairs(imageExtensions) do
    if string.match(lowerFilename, ext .. "$") then
      return true
    end
  end
  return false
end

local function loadWallpapers()
    obj.wallpapers = {}
    local n_wallpapers = 0
    
    local success, iterator = pcall(hs.fs.dir, obj.wheeldir)
    if not success then
      obj.logger.e("Failed to read directory: %s", obj.wheeldir)
      return false
    end
    
    for file in iterator do
      if (file ~= "." and file ~= ".." and file ~= ".DS_Store" and file ~= nil and file ~= '') then
        if isImageFile(file) then
          table.insert(obj.wallpapers, file)
          n_wallpapers = n_wallpapers + 1
        end
      end
    end
    
    obj.n_wallpapers = n_wallpapers
    obj.logger.i("Loaded %d image files from %s", n_wallpapers, obj.wheeldir)

    if (obj.shuffle) then
      shuffleInPlace(obj.wallpapers)
      obj.logger.d("Shuffled wallpaper order")
    end
    
    return true
end

function obj:setWallpapers()
  obj.logger.df("Updating wallpapers, selected index: %d", obj.selected)

  -- Prevent division by zero
  if obj.n_wallpapers == 0 then
    obj.logger.w("No wallpapers found in directory")
    return
  end

  for k, screen in pairs(hs.screen.allScreens()) do
    local selected = ((obj.selected + k) % obj.n_wallpapers) + 1
    local pic = obj.wallpapers[selected]
    obj.logger.df("Screen %d: wallpaper %d/%d - %s", k, selected, obj.n_wallpapers, pic)
    screen:desktopImageURL("file://" .. obj.wheeldir .. pic)
  end
end

function obj:shiftWallpapers()
  obj.selected = (obj.selected + 1) % obj.n_wallpapers
  obj:setWallpapers()
end

function screensChangedCallback(data)
  obj:setWallpapers()
end

function obj:start(dir, interval, shuffle)
  -- Validate input parameters
  if not dir or type(dir) ~= "string" then
    obj.logger.e("Invalid directory parameter")
    return false
  end

  if not interval or type(interval) ~= "number" or interval <= 0 then
    obj.logger.e("Invalid interval parameter (must be positive number)")
    return false
  end

  if shuffle ~= nil and type(shuffle) ~= "boolean" then
    obj.logger.e("Invalid shuffle parameter (must be boolean)")
    return false
  end

  -- Check if directory exists and is readable
  local dir_attr = hs.fs.attributes(dir)
  if not dir_attr or not dir_attr.mode:find("r") then
    obj.logger.e("Directory does not exist or is not readable: %s", dir)
    return false
  end

    obj.wheeldir = dir
  obj.interval = interval
  obj.shuffle = shuffle or false
  
  -- Load wallpapers with error handling
  if not loadWallpapers() then
    return false
  end
  
  -- Initialize selected index to 0 for consistent behavior
  obj.selected = 0

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

  return true
end

function obj:stop()
  obj.logger.i("Stopping Wheel of Seasons")

  if obj.timer then
    obj.timer:stop()
    obj.timer = nil
  end

  if obj.spacewatch then
    obj.spacewatch:stop()
    obj.spacewatch = nil
  end

  -- Clear state
  obj.wallpapers = {}
  obj.n_wallpapers = 0
  obj.selected = 0
  obj.wheeldir = nil
  obj.interval = nil
  obj.shuffle = nil
end

return obj
