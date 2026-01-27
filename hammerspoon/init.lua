-- Hyper key (cmd + alt)
local hyper = {"cmd", "alt"}

-- Left half of screen
hs.hotkey.bind(hyper, "-", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen():frame()
  win:setFrame({
    x = screen.x,
    y = screen.y,
    w = screen.w / 2,
    h = screen.h
  })
end)

-- Right half of screen
hs.hotkey.bind(hyper, "=", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen():frame()
  win:setFrame({
    x = screen.x + screen.w / 2,
    y = screen.y,
    w = screen.w / 2,
    h = screen.h
  })
end)

-- Maximize (not fullscreen)
hs.hotkey.bind(hyper, "m", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen():frame()
  win:setFrame(screen)
end)

-- Reload config
hs.hotkey.bind(hyper, "r", function()
  hs.reload()
end)

-- Track last focused Cursor window
local lastCursorWindowId = nil

-- Update lastCursorWindowId whenever a Cursor window gains focus
local cursorWatcher = hs.window.filter.new("Cursor")
cursorWatcher:subscribe(hs.window.filter.windowFocused, function(win)
  if win then
    lastCursorWindowId = win:id()
  end
end)

-- Cycle through Cursor windows with hyper + arrows
local function cycleCursorWindows(direction)
  local cursor = hs.application.find("Cursor")
  if not cursor then return end

  local allWins = cursor:allWindows()
  local windows = {}
  for _, win in ipairs(allWins) do
    if win:isStandard() and win:isVisible() then
      table.insert(windows, win)
    end
  end

  table.sort(windows, function(a, b) return a:id() < b:id() end)

  if #windows == 0 then return end
  if #windows == 1 then
    windows[1]:focus()
    return
  end

  local currentWin = hs.window.focusedWindow()
  local currentApp = currentWin and currentWin:application()
  local inCursor = currentApp and currentApp:name() == "Cursor"

  if not inCursor and lastCursorWindowId then
    for _, win in ipairs(windows) do
      if win:id() == lastCursorWindowId then
        win:focus()
        return
      end
    end
    windows[1]:focus()
    return
  end

  local currentIndex = 1
  for i, win in ipairs(windows) do
    if win:id() == currentWin:id() then
      currentIndex = i
      break
    end
  end

  local nextIndex
  if direction == "right" then
    nextIndex = currentIndex + 1
    if nextIndex > #windows then nextIndex = 1 end
  else
    nextIndex = currentIndex - 1
    if nextIndex < 1 then nextIndex = #windows end
  end

  windows[nextIndex]:focus()
end

hs.hotkey.bind(hyper, "right", function() cycleCursorWindows("right") end)
hs.hotkey.bind(hyper, "left", function() cycleCursorWindows("left") end)

-- Cycle through Chrome windows with hyper + up
local function cycleAppWindows(appName)
  local app = hs.application.find(appName)
  if not app then return end

  local allWins = app:allWindows()
  local windows = {}
  for _, win in ipairs(allWins) do
    if win:isStandard() and win:isVisible() then
      table.insert(windows, win)
    end
  end

  table.sort(windows, function(a, b) return a:id() < b:id() end)

  if #windows < 2 then
    if #windows == 1 then windows[1]:focus() end
    return
  end

  local currentWin = hs.window.focusedWindow()
  local currentIndex = 1

  for i, win in ipairs(windows) do
    if win:id() == currentWin:id() then
      currentIndex = i
      break
    end
  end

  local nextIndex = currentIndex + 1
  if nextIndex > #windows then nextIndex = 1 end

  windows[nextIndex]:focus()
end

hs.hotkey.bind(hyper, "up", function() cycleAppWindows("Google Chrome") end)
hs.hotkey.bind(hyper, "down", function() cycleAppWindows("Sourcetree") end)

hs.alert.show("Hammerspoon config loaded")
