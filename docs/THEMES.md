# Building a RealNotch Skin

A skin is a single JSON file. No code, no build step.

## Install

Drop your `.json` file into:

```
~/Library/Application Support/RealNotch/Themes/
```

(Settings → Theme → "Open Themes Folder" takes you there.)

Changes apply **live** — save the file and watch the notch restyle. Pick your skin in Settings → Theme.

> Note: live reload triggers when your editor saves atomically (most do — VS Code, Zed, TextEdit). If your editor writes in place and nothing happens, re-save or touch the file.

## Schema (version 1)

**Every field is optional.** Anything you omit falls back to the default skin, so a skin can be as small as one color override. Invalid JSON is ignored (logged, never crashes the app).

```json
{
  "schemaVersion": 1,
  "name": "My Skin",
  "author": "you",

  "colors": {
    "background": "#0C0C0EE6",
    "surface": "#FFFFFF0D",
    "textPrimary": "#FFFFFFFF",
    "textSecondary": "#FFFFFF80",
    "accent": "#0A84FFFF",
    "stackChip": "#0A84FFFF",
    "success": "#30D158FF",
    "pin": "#FFCF3FFF",
    "border": "#FFFFFF17",
    "divider": "#FFFFFF14"
  },

  "shape": {
    "notchCornerRadius": 16,
    "panelCornerRadius": 22,
    "itemCornerRadius": 11
  },

  "typography": {
    "fontFamily": "",
    "itemSize": 12,
    "captionSize": 10,
    "titleSize": 13
  },

  "material": {
    "blur": "regular",
    "backgroundOpacity": 0.92
  },

  "motion": {
    "springResponse": 0.35,
    "springDamping": 0.8
  }
}
```

### Field notes

| Field | Meaning |
|---|---|
| `colors.background` | Fills the notch and expanded panel. Alpha matters — see `material.backgroundOpacity`. |
| `colors.surface` | Clipboard/notes row background (usually a low-alpha white/black). |
| `colors.textPrimary` | Main text. **Also drives the panel chrome** — tab highlights, the Keep-Awake track, toggles, and progress rails are `textPrimary` at low opacity, so a dark `textPrimary` gives you a working light theme automatically. |
| `colors.textSecondary` | Secondary text, hints, inactive tabs, icons. |
| `colors.accent` | Active/interactive accent — clipboard icon chips, stacked pill. |
| `colors.success` | The "live/active/done" green — status dot, Keep Awake when on, the copy confirmation toast + glow. |
| `colors.stackChip` | The "N stacked" pill. |
| `colors.pin` | The star on pinned clipboard items / notes. |
| `colors.border` | Panel outline. |
| `colors.divider` | The hairline rules between header/body/footer. |
| `shape.notchCornerRadius` | Bottom corner radius of the collapsed notch. |
| `shape.panelCornerRadius` | Bottom corner radius of the expanded panel. |
| `typography.fontFamily` | A font family name installed on the system. Empty string = San Francisco (system font). |
| `material.blur` | `"none"`, `"thin"`, or `"regular"` — background blur behind the expanded panel. |
| `material.backgroundOpacity` | 0–1, applied to `colors.background` when expanded. |
| `motion.springResponse` | Seconds — lower is snappier. |
| `motion.springDamping` | 0–1 — lower is bouncier. |

### Minimal example

```json
{ "name": "Red Accent", "author": "me", "colors": { "accent": "#FF3B30FF" } }
```

`name` doubles as the skin's identity — two skins with the same name override each other (user skins beat bundled ones).

Breaking schema changes bump `schemaVersion`; RealNotch will keep decoding older skins on a best-effort basis (unknown fields are ignored, missing fields default).
