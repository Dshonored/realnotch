-- Clock — live world clock with styled rows
local cities = {
  { name = "UTC",      off = 0,  color = "#8E8E93" },
  { name = "New York", off = -4, color = "#0A84FF" },
  { name = "London",   off = 1,  color = "#30D158" },
  { name = "Tokyo",    off = 9,  color = "#FF375F" },
}
return {
  name = "Clock", icon = "clock",
  render = function()
    local rows = {}
    for _, c in ipairs(cities) do
      local s = math.floor(notch.time() + c.off * 3600) % 86400
      rows[#rows + 1] = {
        title = c.name,
        subtitle = string.format("%02d:%02d:%02d", math.floor(s / 3600), math.floor(s % 3600 / 60), s % 60),
        icon = "globe", color = c.color,
      }
    end
    return rows
  end,
}
