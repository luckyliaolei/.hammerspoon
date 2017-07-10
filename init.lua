function down(mods, key) return hs.eventtap.event.newKeyEvent(mods, key, true) end
function up(mods, key) return hs.eventtap.event.newKeyEvent(mods, key, false) end

keymap = {
  {{}, 'help', {}, 'return'},
  {{}, 'f13', {'cmd', 'shift'}, '['},
  {{}, 'f14', {'cmd', 'shift'}, ']'},
  {{}, 'f15', {'cmd'}, 'w'},
  {{'cmd'}, 'home', {}, 'home'},
  {{'cmd'}, 'end', {}, 'end'},
  {{}, 'home', {'cmd'}, 'left'},
  {{}, 'end', {'cmd'}, 'right'},

  {{'ctrl'}, 'e', {}, 'up'},
  {{'ctrl'}, 's', {}, 'left'},
  {{'ctrl'}, 'd', {}, 'down'},
  {{'ctrl'}, 'f', {}, 'right'},

  {{'ctrl'}, 'j', {}, 'return'},
  {{'ctrl'}, ';', {}, 'delete'},

  {{'ctrl'}, 'i', {'cmd', 'shift'}, '['},
  {{'ctrl'}, 'o', {'cmd', 'shift'}, ']'},
  {{'ctrl'}, 'p', {'cmd'}, 'w'},
  
  {{'cmd', 'ctrl'}, 'k', {}, 'home'},
  {{'cmd', 'ctrl'}, ',', {}, 'end'},
  {{'ctrl'}, 'k', {'cmd'}, 'left'},
  {{'ctrl'}, ',', {'cmd'}, 'right'},

  {{'ctrl'}, '.', {'cmd'}, 'c'},
  {{'ctrl'}, '/', {'cmd'}, 'v'},

  {{'alt'}, 'space', {}, '0'},
  {{'alt'}, 'n', {}, '1'},
  {{'alt'}, 'm', {}, '2'},
  {{'alt'}, ',', {}, '3'},
  {{'alt'}, 'h', {}, '4'},
  {{'alt'}, 'j', {}, '5'},
  {{'alt'}, 'k', {}, '6'},
  {{'alt'}, 'y', {}, '7'},
  {{'alt'}, 'u', {}, '8'},
  {{'alt'}, 'i', {}, '9'},
  {{'alt'}, 'o', {}, '-'},
  {{'alt'}, 'l', {'shift'}, '='},
  {{'alt'}, '.', {}, '.'},
  {{'alt'}, '7', {}, '/'},
  {{'alt'}, '8', {'shift'}, '8'},
  {{'alt'}, 'g', {}, 'delete'},
}

hs.hotkey.bind({'cmd'}, ',', function ()
  hs.window.frontmostWindow():toggleFullScreen()
end)
hs.hotkey.bind({'cmd'}, '.', function ()
    local f_scr = hs.window.frontmostWindow():screen():fullFrame()
  if hs.window.frontmostWindow():frame().x == f_scr.x then
    hs.window.frontmostWindow():move({0.1, 0.05, 0.8, 0.8}, 0)
  else
    hs.window.frontmostWindow():setTopLeft(f_scr):setSize(f_scr)
  end
end)
hs.hotkey.bind({'cmd'}, '/', function ()
  local front_w = hs.window.frontmostWindow()
  front_w:moveToScreen(front_w:screen():next(), 0)
end)

last_press = nil
app_press = false
en_type = hs.eventtap.event.types
event = hs.eventtap.new({ en_type.flagsChanged, en_type.middleMouseDown, en_type.scrollWheel, en_type.keyDown, en_type.keyUp }, function(event)
  local eventType = en_type[event:getType()]

  if eventType == 'flagsChanged' then
    if event:getFlags()['ctrl'] and not event:getFlags()['cmd'] then
      return true
    else
      return false
    end
  end

  if eventType == 'middleMouseDown' then
    return true, {down({'ctrl'}, 'up'), up({'ctrl'}, 'up')}
  end

  if eventType == 'scrollWheel' then
    local en_prop = hs.eventtap.event.properties
    if event:getFlags()['ctrl'] and event:getProperty(en_prop.scrollWheelEventIsContinuous) == 0 then
      if event:getProperty(en_prop.scrollWheelEventDeltaAxis1) > 0 then
        return true, {down({'ctrl'}, 'left'), up({'ctrl'}, 'left')}
      elseif event:getProperty(en_prop.scrollWheelEventDeltaAxis1) < 0 then
        return true, {down({'ctrl'}, 'right'), up({'ctrl'}, 'right')}
      end
    else
      return false
    end
  end

  if eventType == 'keyDown' or eventType == 'keyUp' then
    if event:getKeyCode() == 110 then
      if eventType == 'keyDown' then
        app_press = true
      else
        app_press = false
      end
      return true
    end
    if app_press then
      event:setFlags({cmd=true})
    end

    if last_press and hs.keycodes.map[event:getKeyCode()] == last_press[1][2] then
      if eventType == 'keyDown' then
        return true, {down({}, last_press[1][4]):setFlags(last_press[2])}
      else
        local evt = up({}, last_press[1][4]):setFlags(last_press[2])
        last_press = nil
        return true, {evt}
      end
    end
    
    for key, value in pairs(keymap) do
      local match_md = true
      local en_flag = event:getFlags()
      for key, md in pairs(value[1]) do      
        match_md = match_md and en_flag[md]
        en_flag[md] = false
      end
      local match_key = hs.keycodes.map[event:getKeyCode()] == value[2]
      if match_md and match_key then
        for key, md in pairs(value[3]) do      
          en_flag[md] = true
        end
        if eventType == 'keyDown' then
          last_press = {value, en_flag}
          return true, {down({}, value[4]):setFlags(en_flag)}
        else
          return true, {up({}, value[4]):setFlags(en_flag)}
        end
      end
    end
  end
  
  return false
end):start()

-- Window event listen
events = hs.uielement.watcher

function handleGlobalAppEvent(name, event, app)
  if event == hs.application.watcher.launched then
    local watcher = app:newWatcher(win_open)
    watcher:start({events.windowCreated})
    for i, window in pairs(app:allWindows()) do
      win_open(window)
    end
  end
end

function win_open(element)
  if element._frame and element:frame() == element:screen():frame() then
    local f_scr = element:screen():fullFrame()
    element:setTopLeft(f_scr):setSize(f_scr)
  end
end

apps = hs.application.runningApplications()
for i = 1, #apps do
  local watcher = apps[i]:newWatcher(win_open)
  watcher:start({events.windowCreated})
end

app_event = hs.application.watcher.new(handleGlobalAppEvent):start()
