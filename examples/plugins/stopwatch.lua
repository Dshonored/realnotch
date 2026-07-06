-- Stopwatch — persistent state, styled rows, live progress
local start, frozen = nil, 0
local function elapsed() return frozen + (start and (notch.time() - start) or 0) end

return {
  name = "Stopwatch", icon = "stopwatch",
  render = function()
    local e = elapsed()
    local running = start ~= nil
    return {
      { title = string.format("%d:%02d", math.floor(e / 60), math.floor(e) % 60),
        subtitle = running and "running" or "stopped",
        icon = "stopwatch.fill",
        color = running and "#30D158" or "#8E8E93",
        badge = running and "REC" or nil,
        progress = (e % 60) / 60 },
      { title = running and "Pause" or "Start",
        icon = running and "pause.fill" or "play.fill",
        color = running and "#FF9F0A" or "#30D158",
        action = function()
          if running then frozen = frozen + (notch.time() - start); start = nil
          else start = notch.time() end
        end },
      { title = "Reset", icon = "arrow.counterclockwise", color = "#8E8E93",
        action = function() start, frozen = nil, 0 end },
    }
  end,
}
