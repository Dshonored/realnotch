-- Launch — global hotkeys (notch.hotkey), clickable rows (action), notch.launch
local apps = {
  { key = "control+option+1", app = "Finder" },
  { key = "control+option+2", app = "Safari" },
}
for _, a in ipairs(apps) do
  notch.hotkey(a.key, function() notch.launch(a.app) end)
end
return {
  name = "Launch", icon = "bolt.fill",
  render = function()
    local rows = {}
    for _, a in ipairs(apps) do
      rows[#rows + 1] = { title = a.app, subtitle = "tap, or " .. a.key,
                          action = function() notch.launch(a.app) end }
    end
    return rows
  end,
}
