--- === Wheel of Seasons ===
---
--- A Hammerspoon spoon that rotates desktop wallpapers across multiple screens.
--- Supports automatic rotation at configurable intervals and shuffling of wallpaper order.
--- Automatically matches image orientation to monitor orientation and supports hot-plugging.
---
--- Features:
--- - Multi-screen wallpaper rotation
--- - Configurable rotation intervals
--- - Optional wallpaper shuffling
--- - Image file filtering (jpg, jpeg, png, gif, bmp, tiff, webp)
--- - Automatic image orientation detection and filtering
--- - Monitor orientation matching (landscape/portrait)
--- - Automatic screen change detection
--- - Hot-plugging monitor support
--- - Proper resource cleanup
---
--- Usage:
---   hs.loadSpoon("WheelOfSeasons")
---   spoon.WheelOfSeasons:start("/path/to/wallpapers", 3600, true)
---
--- Additional Methods:
---   spoon.WheelOfSeasons:refresh()                    -- Manually refresh wallpapers
---   spoon.WheelOfSeasons:refreshOrientationFiltering() -- Refresh orientation filtering
---   spoon.WheelOfSeasons:getScreenInfo()              -- Get current screen configuration
---   spoon.WheelOfSeasons:printScreenInfo()            -- Print screen info to console
---   spoon.WheelOfSeasons:getOrientationBreakdown()    -- Get wallpaper orientation statistics
---   spoon.WheelOfSeasons:printOrientationBreakdown()  -- Print orientation breakdown to console
---   spoon.WheelOfSeasons:updateScreen(id)             -- Update specific screen
---   spoon.WheelOfSeasons:checkDirectory(dir)          -- Check if directory exists and is readable
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

--- Get image dimensions using hs.image
--- @param filepath string Full path to the image file
--- @return number|nil width, number|nil height, or nil if failed
local function getImageDimensions(filepath)
  local success, image = pcall(hs.image.imageFromPath, filepath)
  if not success or not image then
    return nil, nil
  end

  local size = image:size()
  if size then
    return size.w, size.h
  end
  return nil, nil
end

--- Determine if an image matches the screen orientation
--- @param filepath string Full path to the image file
--- @param screen hs.screen The screen to check against
--- @return boolean True if image orientation matches screen orientation
local function imageMatchesScreenOrientation(filepath, screen)
  local width, height = getImageDimensions(filepath)
  if not width or not height then
    return false -- Skip images we can't read
  end

  local screenFrame = screen:frame()
  local screenRotation = screen:rotate()

  -- Determine screen orientation based on rotation and frame
  local screenIsLandscape = screenFrame.w > screenFrame.h
  if screenRotation == 90 or screenRotation == 270 then
    screenIsLandscape = not screenIsLandscape -- Rotated screens have swapped dimensions
  end

  -- Determine image orientation
  local imageIsLandscape = width > height

  -- Return true if both are landscape or both are portrait
  return screenIsLandscape == imageIsLandscape
end

local function loadWallpapers()
  obj.wallpapers = {}
  obj.wallpapersByScreen = {} -- Store wallpapers filtered by screen orientation
  local n_wallpapers = 0

  -- Try to get directory iterator
  obj.logger.f("Attempting to read directory: %s", obj.wheeldir)

  -- Use a more robust approach to handle directory iteration
  local success, result = pcall(function()
    local files = {}
    for file in hs.fs.dir(obj.wheeldir) do
      if (file ~= "." and file ~= ".." and file ~= ".DS_Store" and file ~= nil and file ~= '') then
        if isImageFile(file) then
          table.insert(files, file)
        end
      end
    end
    return files
  end)

  if not success then
    obj.logger.ef("Error reading directory: %s", result)
    return false
  end

  if not result then
    obj.logger.ef("Failed to read directory: %s", obj.wheeldir)
    return false
  end

  obj.wallpapers = result
  obj.n_wallpapers = #result
  obj.logger.f("Loaded %d image files from %s", obj.n_wallpapers, obj.wheeldir)

  if obj.n_wallpapers == 0 then
    obj.logger.wf("Directory is empty or contains no readable image files: %s", obj.wheeldir)
  else
    -- Analyze orientation distribution
    local horizontalCount = 0
    local verticalCount = 0
    local unreadableCount = 0

    for _, file in ipairs(result) do
      local filepath = obj.wheeldir .. "/" .. file
      local width, height = getImageDimensions(filepath)
      if width and height then
        if width > height then
          horizontalCount = horizontalCount + 1
        else
          verticalCount = verticalCount + 1
        end
      else
        unreadableCount = unreadableCount + 1
      end
    end

    obj.logger.f("Image orientation breakdown: %d horizontal, %d vertical, %d unreadable",
      horizontalCount, verticalCount, unreadableCount)
  end

  -- Filter images by orientation for each screen
  local screens = hs.screen.allScreens()
  for i, screen in pairs(screens) do
    local screenId = screen:id()
    local matchingImages = {}

    obj.logger.f("Filtering images for screen %d (%s)", i, screen:name())

    for _, file in ipairs(result) do
      local filepath = obj.wheeldir .. "/" .. file
      if imageMatchesScreenOrientation(filepath, screen) then
        table.insert(matchingImages, file)
      end
    end

    obj.wallpapersByScreen[screenId] = matchingImages
    obj.logger.f("Screen %d: %d matching images out of %d total", i, #matchingImages, #result)

    -- If no matching images for this screen, use all images as fallback
    if #matchingImages == 0 then
      obj.logger.wf("No orientation-matching images for screen %d, using all images as fallback", i)
      obj.wallpapersByScreen[screenId] = result
    end
  end

  if (obj.shuffle) then
    shuffleInPlace(obj.wallpapers)
    obj.logger.d("Shuffled wallpaper order")

    -- Also shuffle the screen-specific lists
    for screenId, images in pairs(obj.wallpapersByScreen) do
      shuffleInPlace(images)
    end
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

  local screens = hs.screen.allScreens()
  obj.logger.df("Setting wallpapers for %d screens", #screens)

  for k, screen in pairs(screens) do
    local screenId = screen:id()
    local screenWallpapers = obj.wallpapersByScreen[screenId] or obj.wallpapers

    if #screenWallpapers == 0 then
      obj.logger.wf("No wallpapers available for screen %d", k)
      goto continue
    end

    local selected = ((obj.selected + k) % #screenWallpapers) + 1
    local pic = screenWallpapers[selected]
    local screenRotation = screen:rotate()

    obj.logger.df("Screen %d: wallpaper %d/%d - %s (screen rotation: %d°)",
      k, selected, #screenWallpapers, pic, screenRotation)

    -- Set wallpaper (rotation is handled automatically by the system)
    local filePath = "file://" .. obj.wheeldir .. "/" .. pic
    screen:desktopImageURL(filePath)

    ::continue::
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
    obj.logger.i("Screen configuration changed (debounced), refreshing orientation filtering and updating wallpapers")
    obj:refreshOrientationFiltering()
    obj:setWallpapers()
    screenChangeTimer = nil
  end)
end

function obj:start(dir, interval, shuffle)
  -- Validate input parameters
  if not dir or type(dir) ~= "string" or dir == "" then
    obj.logger.ef("Invalid directory parameter: %s", tostring(dir))
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
    obj.logger.ef("Directory does not exist: %s", dir)
    return false
  end

  if not dir_attr.mode or not dir_attr.mode:find("r") then
    obj.logger.ef("Directory is not readable: %s", dir)
    return false
  end

  obj.wheeldir = dir
  obj.interval = interval
  obj.shuffle = shuffle or false

  obj.logger.f("Initializing Wheel of Seasons with directory: %s", obj.wheeldir)

  -- Load wallpapers with error handling
  if not loadWallpapers() then
    obj.logger.ef("Failed to load wallpapers from directory: %s", obj.wheeldir)
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

--- Refresh orientation filtering for all screens
function obj:refreshOrientationFiltering()
  obj.logger.i("Refreshing orientation filtering for all screens")
  if obj.wallpapers and #obj.wallpapers > 0 then
    -- Re-filter images by orientation for each screen
    local screens = hs.screen.allScreens()
    for i, screen in pairs(screens) do
      local screenId = screen:id()
      local matchingImages = {}

      obj.logger.f("Re-filtering images for screen %d (%s)", i, screen:name())

      for _, file in ipairs(obj.wallpapers) do
        local filepath = obj.wheeldir .. "/" .. file
        if imageMatchesScreenOrientation(filepath, screen) then
          table.insert(matchingImages, file)
        end
      end

      obj.wallpapersByScreen[screenId] = matchingImages
      obj.logger.f("Screen %d: %d matching images out of %d total", i, #matchingImages, #obj.wallpapers)

      -- If no matching images for this screen, use all images as fallback
      if #matchingImages == 0 then
        obj.logger.wf("No orientation-matching images for screen %d, using all images as fallback", i)
        obj.wallpapersByScreen[screenId] = obj.wallpapers
      end
    end

    -- Re-shuffle if needed
    if obj.shuffle then
      for screenId, images in pairs(obj.wallpapersByScreen) do
        shuffleInPlace(images)
      end
    end
  end
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
      frame = frame
    })
  end

  return info
end

--- Print current screen configuration to console (useful for debugging)
function obj:printScreenInfo()
  local info = obj:getScreenInfo()
  obj.logger.i("Current screen configuration:")
  obj.logger.f("  Total screens: %d", info.count)

  for i, screen in ipairs(info.screens) do
    obj.logger.f("  Screen %d: %s (ID: %s)", i, screen.name, screen.id)
    obj.logger.f("    Rotation: %d°", screen.rotation)
    obj.logger.f("    Frame: x=%d, y=%d, w=%d, h=%d",
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

--- Get orientation breakdown of wallpapers
--- @return table Information about wallpaper orientations
function obj:getOrientationBreakdown()
  if not obj.wallpapers or #obj.wallpapers == 0 then
    return {
      total = 0,
      horizontal = 0,
      vertical = 0,
      unreadable = 0,
      horizontal_percent = 0,
      vertical_percent = 0,
      unreadable_percent = 0
    }
  end

  local horizontalCount = 0
  local verticalCount = 0
  local unreadableCount = 0

  for _, file in ipairs(obj.wallpapers) do
    local filepath = obj.wheeldir .. "/" .. file
    local width, height = getImageDimensions(filepath)
    if width and height then
      if width > height then
        horizontalCount = horizontalCount + 1
      else
        verticalCount = verticalCount + 1
      end
    else
      unreadableCount = unreadableCount + 1
    end
  end

  local total = #obj.wallpapers
  return {
    total = total,
    horizontal = horizontalCount,
    vertical = verticalCount,
    unreadable = unreadableCount,
    horizontal_percent = total > 0 and math.floor((horizontalCount / total) * 100) or 0,
    vertical_percent = total > 0 and math.floor((verticalCount / total) * 100) or 0,
    unreadable_percent = total > 0 and math.floor((unreadableCount / total) * 100) or 0
  }
end

--- Print orientation breakdown to console
function obj:printOrientationBreakdown()
  local breakdown = obj:getOrientationBreakdown()
  obj.logger.i("Wallpaper orientation breakdown:")
  obj.logger.f("  Total images: %d", breakdown.total)
  obj.logger.f("  Horizontal: %d (%d%%)", breakdown.horizontal, breakdown.horizontal_percent)
  obj.logger.f("  Vertical: %d (%d%%)", breakdown.vertical, breakdown.vertical_percent)
  obj.logger.f("  Unreadable: %d (%d%%)", breakdown.unreadable, breakdown.unreadable_percent)
end

--- Force update wallpapers for a specific screen
--- @param screenId string The screen ID to update
function obj:updateScreen(screenId)
  local screens = hs.screen.allScreens()
  for _, screen in pairs(screens) do
    if screen:id() == screenId then
      obj.logger.f("Forcing update for screen: %s", screen:name())
      local screenWallpapers = obj.wallpapersByScreen[screenId] or obj.wallpapers

      if #screenWallpapers == 0 then
        obj.logger.wf("No wallpapers available for screen: %s", screen:name())
        return
      end

      local selected = ((obj.selected + 1) % #screenWallpapers) + 1
      local pic = screenWallpapers[selected]
      local filePath = "file://" .. obj.wheeldir .. "/" .. pic
      screen:desktopImageURL(filePath)
      return
    end
  end
  obj.logger.wf("Screen with ID %s not found", screenId)
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
  obj.wallpapersByScreen = {}
  obj.n_wallpapers = 0
  obj.selected = 0
  obj.wheeldir = nil
  obj.interval = nil
  obj.shuffle = nil
end

return obj
