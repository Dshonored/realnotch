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

> App-launch hotkeys are a **built-in** feature now (Settings → App Launcher), not a
> plugin concern — record a shortcut, pick an app, done.

## Install

Nothing is installed by default. Add plugins yourself:
- **Settings → Plugins → Install Plugin (.zip)…**, or
- drop `.lua` files straight into the folder above.

## Styling rows

A row is a table. Beyond `title`/`subtitle`, you can style it — the host owns the
layout (so it stays consistent and skin-friendly), but you control the accents:

| Field | Effect |
|---|---|
| `icon` | a leading [SF Symbol](https://developer.apple.com/sf-symbols/) |
| `color` | hex (`"#FF6B35"`) — tints the icon, badge, and progress bar |
| `badge` | a small trailing pill of text |
| `progress` | `0…1` — a bar under the row |
| `action` | a function; makes the row clickable |

```lua
{ title = "Downloading", subtitle = "42%", icon = "arrow.down.circle.fill",
  color = "#0A84FF", badge = "2", progress = 0.42 }
```

The bundled `showcase.lua` example shows all of these together. A bare string is
also a valid row (just a title).

## Interactive rows

Give a row an `action` function and it becomes clickable in the notch:

```lua
return {
  name = "Quick", icon = "bolt",
  render = function()
    return {
      { title = "Open Finder", action = function() notch.launch("Finder") end },
    }
  end
}
```

## Global hotkeys

Register a system-wide hotkey (no permissions) that runs a Lua function:

```lua
notch.hotkey("cmd+shift+j", function() notch.launch("Ghostty") end)
```

Put it at the top level of your plugin — it's registered when the plugin loads and
re-registered on reload. Modifiers: `cmd` · `option` · `ctrl` · `shift`.

## Host API

A global `notch` table exposes the host:

| Call | Does |
|---|---|
| `notch.clipboard()` | returns the current clipboard text (string) |
| `notch.time()` | returns Unix time in seconds (number) |
| `notch.launch(app)` | launches or focuses an app by name |
| `notch.hotkey(key, fn)` | registers a global hotkey that calls `fn` |

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
