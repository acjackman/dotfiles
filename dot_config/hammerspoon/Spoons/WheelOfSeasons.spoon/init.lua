--- === Wheel of Seasons ===
---
--- A Hammerspoon spoon that rotates desktop wallpapers across multiple screens.
--- Supports automatic rotation at configurable intervals and shuffling of wallpaper order.
--- Automatically matches wallpaper orientation to monitor rotation and supports hot-plugging.
---
--- Features:
--- - Multi-screen wallpaper rotation
--- - Configurable rotation intervals
--- - Optional wallpaper shuffling
--- - Image file filtering (jpg, jpeg, png, gif, bmp, tiff, webp)
--- - Automatic screen change detection
--- - Monitor rotation detection and wallpaper orientation matching
--- - Hot-plugging monitor support
--- - Proper resource cleanup
---
--- Usage:
---   hs.loadSpoon("WheelOfSeasons")
---   spoon.WheelOfSeasons:start("/path/to/wallpapers", 3600, true)
---
--- Additional Methods:
---   spoon.WheelOfSeasons:refresh()           -- Manually refresh wallpapers
---   spoon.WheelOfSeasons:getScreenInfo()     -- Get current screen configuration
---   spoon.WheelOfSeasons:printScreenInfo()   -- Print screen info to console
---   spoon.WheelOfSeasons:updateScreen(id)    -- Update specific screen
---   spoon.WheelOfSeasons:checkDirectory(dir) -- Check if directory exists and is readable
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

-- Constants
local IMAGE_EXTENSIONS = { ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp" }
local DEFAULT_LOG_LEVEL = "info"

-- Screen rotation constants
local ROTATION_0 = 0     -- Normal orientation
local ROTATION_90 = 90   -- Clockwise rotation
local ROTATION_180 = 180 -- Upside down
local ROTATION_270 = 270 -- Counter-clockwise rotation


local function shuffleInPlace(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
end

--- Check if a file has a supported image extension
--- @param filename string The filename to check
--- @return boolean True if the file is a supported image format
local function isImageFile(filename)
  local lowerFilename = string.lower(filename)
  for _, ext in ipairs(IMAGE_EXTENSIONS) do
    if string.match(lowerFilename, ext .. "$") then
      return true
    end
  end
  return false
end

local function loadWallpapers()
  obj.wallpapers = {}
  local n_wallpapers = 0

  -- Try to get directory iterator
  obj.logger.i("Attempting to read directory: %s", obj.wheeldir)
  local iterator = hs.fs.dir(obj.wheeldir)
  if not iterator then
    obj.logger.e("Failed to read directory: %s", obj.wheeldir)
    return false
  end
  obj.logger.i("Successfully obtained directory iterator")

  -- Check if directory is actually readable and contains files
  local hasFiles = false
  local success, err = pcall(function()
    for file in iterator do
      hasFiles = true
      if (file ~= "." and file ~= ".." and file ~= ".DS_Store" and file ~= nil and file ~= '') then
        if isImageFile(file) then
          table.insert(obj.wallpapers, file)
          n_wallpapers = n_wallpapers + 1
        end
      end
    end
  end)

  if not success then
    obj.logger.e("Error iterating directory: %s", err)
    return false
  end

  obj.n_wallpapers = n_wallpapers
  obj.logger.i("Loaded %d image files from %s", n_wallpapers, obj.wheeldir)

  if not hasFiles then
    obj.logger.w("Directory is empty or contains no readable files: %s", obj.wheeldir)
  end

  if (obj.shuffle) then
    shuffleInPlace(obj.wallpapers)
    obj.logger.d("Shuffled wallpaper order")
  end

  return true
end

--- Get the appropriate wallpaper rotation based on screen rotation
--- @param screen hs.screen The screen to check
--- @return number The rotation angle for the wallpaper
local function getWallpaperRotation(screen)
  local screenRotation = screen:rotate()

  -- Map screen rotation to wallpaper rotation
  -- When screen is rotated, we want the wallpaper to rotate in the opposite direction
  -- to maintain the same visual orientation
  if screenRotation == ROTATION_0 then
    return ROTATION_0
  elseif screenRotation == ROTATION_90 then
    return ROTATION_270 -- Counter-rotate to maintain orientation
  elseif screenRotation == ROTATION_180 then
    return ROTATION_180
  elseif screenRotation == ROTATION_270 then
    return ROTATION_90 -- Counter-rotate to maintain orientation
  else
    return ROTATION_0  -- Default fallback
  end
end

function obj:setWallpapers()
  obj.logger.df("Updating wallpapers, selected index: %d", obj.selected)

  -- Prevent division by zero
  if obj.n_wallpapers == 0 then
    obj.logger.w("No wallpapers found in directory")
    return
  end

  local screens = hs.screen.allScreens()
  obj.logger.df("Setting wallpapers for %d screens", #screens)

  for k, screen in pairs(screens) do
    local selected = ((obj.selected + k) % obj.n_wallpapers) + 1
    local pic = obj.wallpapers[selected]
    local wallpaperRotation = getWallpaperRotation(screen)
    local screenRotation = screen:rotate()

    obj.logger.df("Screen %d: wallpaper %d/%d - %s (screen rotation: %d°, wallpaper rotation: %d°)",
      k, selected, obj.n_wallpapers, pic, screenRotation, wallpaperRotation)

    -- Set wallpaper with rotation
    local filePath = "file://" .. obj.wheeldir .. "/" .. pic
    screen:desktopImageURL(filePath, wallpaperRotation)
  end
end

function obj:shiftWallpapers()
  obj.selected = (obj.selected + 1) % obj.n_wallpapers
  obj:setWallpapers()
end

--- Callback for screen changes (hot-plugging, rotation, etc.)
--- @param data table Screen change data
function screensChangedCallback(data)
  obj:handleScreenChange()
end

--- Callback for screen rotation changes
--- @param data table Screen rotation data
function screenRotationCallback(data)
  obj.logger.i("Screen rotation changed, updating wallpapers")
  obj:setWallpapers()
end

--- Debounced screen change handler to prevent excessive updates
local screenChangeTimer = nil
function obj:handleScreenChange()
  if screenChangeTimer then
    screenChangeTimer:stop()
  end

  screenChangeTimer = hs.timer.doAfter(0.5, function()
    obj.logger.i("Screen configuration changed (debounced), updating wallpapers")
    obj:setWallpapers()
    screenChangeTimer = nil
  end)
end

function obj:start(dir, interval, shuffle)
  -- Validate input parameters
  if not dir or type(dir) ~= "string" or dir == "" then
    obj.logger.e("Invalid directory parameter: %s", tostring(dir))
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
  if not dir_attr then
    obj.logger.e("Directory does not exist: %s", dir)
    return false
  end

  if not dir_attr.mode or not dir_attr.mode:find("r") then
    obj.logger.e("Directory is not readable: %s", dir)
    return false
  end

  obj.wheeldir = dir
  obj.interval = interval
  obj.shuffle = shuffle or false

  obj.logger.i("Initializing Wheel of Seasons with directory: %s", obj.wheeldir)

  -- Load wallpapers with error handling
  if not loadWallpapers() then
    obj.logger.e("Failed to load wallpapers from directory: %s", obj.wheeldir)
    obj.logger.e("Please ensure the directory exists and contains image files")
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
  -- Set up screen change watchers for hot-plugging and rotation
  if obj.spacewatch == nil then
    obj.spacewatch = hs.spaces.watcher.new(screensChangedCallback)
    obj.spacewatch:start()
  end

  if obj.screenwatcher == nil then
    obj.screenwatcher = hs.screen.watcher.new(screensChangedCallback)
    obj.screenwatcher:start()
  end

  return true
end

--- Manually refresh wallpapers (useful for testing or manual updates)
function obj:refresh()
  obj.logger.i("Manual wallpaper refresh requested")
  obj:setWallpapers()
end

--- Get current screen configuration information
--- @return table Information about current screens and their rotations
function obj:getScreenInfo()
  local screens = hs.screen.allScreens()
  local info = {
    count = #screens,
    screens = {}
  }

  for i, screen in pairs(screens) do
    local frame = screen:frame()
    local rotation = screen:rotate()
    table.insert(info.screens, {
      id = screen:id(),
      name = screen:name(),
      rotation = rotation,
      frame = frame,
      wallpaper_rotation = getWallpaperRotation(screen)
    })
  end

  return info
end

--- Print current screen configuration to console (useful for debugging)
function obj:printScreenInfo()
  local info = obj:getScreenInfo()
  obj.logger.i("Current screen configuration:")
  obj.logger.i("  Total screens: %d", info.count)

  for i, screen in ipairs(info.screens) do
    obj.logger.i("  Screen %d: %s (ID: %s)", i, screen.name, screen.id)
    obj.logger.i("    Rotation: %d°, Wallpaper rotation: %d°", screen.rotation, screen.wallpaper_rotation)
    obj.logger.i("    Frame: x=%d, y=%d, w=%d, h=%d",
      screen.frame.x, screen.frame.y, screen.frame.w, screen.frame.h)
  end
end

--- Check if wallpaper directory exists and is accessible
--- @param dir string Directory path to check
--- @return boolean True if directory exists and is readable
function obj:checkDirectory(dir)
  if not dir or type(dir) ~= "string" or dir == "" then
    return false
  end

  local attr = hs.fs.attributes(dir)
  if not attr then
    return false
  end

  if not attr.mode or not attr.mode:find("r") then
    return false
  end

  return true
end

--- Force update wallpapers for a specific screen
--- @param screenId string The screen ID to update
function obj:updateScreen(screenId)
  local screens = hs.screen.allScreens()
  for _, screen in pairs(screens) do
    if screen:id() == screenId then
      obj.logger.i("Forcing update for screen: %s", screen:name())
      local selected = ((obj.selected + 1) % obj.n_wallpapers) + 1
      local pic = obj.wallpapers[selected]
      local wallpaperRotation = getWallpaperRotation(screen)
      local filePath = "file://" .. obj.wheeldir .. "/" .. pic
      screen:desktopImageURL(filePath, wallpaperRotation)
      return
    end
  end
  obj.logger.w("Screen with ID %s not found", screenId)
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

  if obj.screenwatcher then
    obj.screenwatcher:stop()
    obj.screenwatcher = nil
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
