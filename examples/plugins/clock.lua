-- Clock — live re-render (every ~2s) + math on notch.time()
local function hhmm(tzOffsetHours)
  local secs = math.floor(notch.time() + tzOffsetHours * 3600) % 86400
  return string.format("%02d:%02d", math.floor(secs / 3600), math.floor(secs % 3600 / 60))
end
return {
  name = "Clock", icon = "clock",
  render = function()
    return {
      { title = "UTC",      subtitle = hhmm(0) },
      { title = "New York", subtitle = hhmm(-4) },
      { title = "London",   subtitle = hhmm(1) },
      { title = "Tokyo",    subtitle = hhmm(9) },
    }
  end,
}
