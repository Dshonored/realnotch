# Writing a RealNotch plugin (Lua)

A plugin is a single **Lua** file. A plugin with a `render()` gets **its own tab** in
the notch, right alongside Clipboard / Music / Notes. A plugin can also declare
**hotkeys** to launch apps. No build step — drop it in and it loads live.

## Install

Put your `.lua` file in:

```
~/Library/Application Support/RealNotch/Plugins/
```

RealNotch watches that folder — save the file and the notch reloads it instantly.
A starter `example.lua` is seeded there on first run; copy it to begin.

## Shape of a plugin

Return a table with `name`, `icon` (an [SF Symbol](https://developer.apple.com/sf-symbols/) name),
and a `render()` function. `render()` returns a list of rows.

```lua
return {
  name = "My Plugin",
  icon = "bolt.fill",
  render = function()
    return {
      { title = "A row", subtitle = "with a subtitle" },
      { title = "Just a title" },
      "a bare string is also a row",
    }
  end
}
```

`render()` is called every couple of seconds, so a plugin can show live data.
`render` is optional — a plugin with only `bindings` (below) runs in the background
without a tab.

## Hotkeys — launch apps

Declare a `bindings` list and RealNotch registers those as **global** hotkeys
(system-wide, no Accessibility permission). Each fires launches or focuses an app.

```lua
local binds = {
  { key = "option+1", app = "Google Chrome" },
  { key = "cmd+shift+k", app = "Ghostty" },
}
return {
  name = "Launcher", icon = "keyboard",
  bindings = binds,
  render = function()               -- optional: a tab listing the bindings
    local rows = {}
    for _, b in ipairs(binds) do rows[#rows+1] = { title = b.app, subtitle = b.key } end
    return rows
  end
}
```

Modifiers: `cmd` · `option` (or `alt`) · `ctrl` · `shift`. Keys: letters, digits,
`space`, `return`, `tab`, arrows. The **app** is its display name ("Google Chrome").
This is the seeded `example.lua` — edit it to bind your own apps.

## Host API

A global `notch` table exposes a small, read-only set of helpers:

| Call | Returns |
|---|---|
| `notch.clipboard()` | the current clipboard text (string) |
| `notch.time()` | current Unix time in seconds (number) |

Example — a live clock and clipboard peek:

```lua
return {
  name = "Peek",
  icon = "eye",
  render = function()
    local clip = notch.clipboard()
    return {
      { title = "Clipboard", subtitle = clip:sub(1, 48) },
      { title = "Chars", subtitle = tostring(#clip) },
    }
  end
}
```

## Sandbox

Plugins run in a **sandboxed** Lua 5.4 runtime. The safe standard libraries are
available — `string`, `table`, `math`, `utf8`, and the base functions. The `io`,
`os`, and `package`/`require` libraries are **not** loaded, so a plugin cannot read
or write files, run commands, or load native code. If a plugin errors, it's logged
and skipped — it never crashes the app.

Want an API that isn't there yet (notes, now-playing, agents…)? Open an issue —
the host surface is intentionally small and grows by request.
