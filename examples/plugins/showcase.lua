-- Showcase — the styling limits: icon (SF Symbol) · color (hex) · badge · progress
return {
  name = "Showcase", icon = "sparkles",
  render = function()
    local pulse = (math.sin(notch.time()) + 1) / 2   -- animated 0…1
    return {
      { title = "Colored icon",  subtitle = "icon + color", icon = "flame.fill",        color = "#FF6B35" },
      { title = "With a badge",  subtitle = "trailing pill", icon = "bell.badge.fill",  color = "#0A84FF", badge = "3" },
      { title = "All good",      subtitle = "green accent",  icon = "checkmark.seal.fill", color = "#30D158", badge = "OK" },
      { title = "Live progress", subtitle = string.format("%d%%", math.floor(pulse * 100)),
        icon = "gauge.with.dots.needle.67percent", color = "#BF5AF2", progress = pulse },
      { title = "Tap me",        subtitle = "clickable row", icon = "hand.tap.fill",     color = "#FFD60A",
        action = function() notch.launch("Finder") end },
    }
  end,
}
