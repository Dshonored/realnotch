-- Clip — reads the clipboard (notch.clipboard) and reports on it, live
return {
  name = "Clip", icon = "doc.on.clipboard",
  render = function()
    local c = notch.clipboard()
    local words = 0
    for _ in c:gmatch("%S+") do words = words + 1 end
    return {
      { title = "Characters", subtitle = tostring(#c) },
      { title = "Words",      subtitle = tostring(words) },
      { title = "Preview",    subtitle = (c:gsub("%s+", " ")):sub(1, 40) },
    }
  end,
}
