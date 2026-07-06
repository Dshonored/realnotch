-- Stopwatch — persistent state + actions that mutate it + live time
local start, frozen = nil, 0
return {
  name = "Stopwatch", icon = "stopwatch",
  render = function()
    local elapsed = frozen + (start and (notch.time() - start) or 0)
    return {
      { title = string.format("%.1f s", elapsed), subtitle = start and "running" or "stopped" },
      { title = start and "Stop" or "Start", action = function()
          if start then frozen = frozen + (notch.time() - start); start = nil
          else start = notch.time() end
      end },
      { title = "Reset", action = function() start, frozen = nil, 0 end },
    }
  end,
}
