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
    "background": "#000000FF",
    "surface": "#1C1C1EFF",
    "textPrimary": "#FFFFFFFF",
    "textSecondary": "#98989DFF",
    "accent": "#0A84FFFF",
    "stackChip": "#FF9F0AFF"
  },

  "shape": {
    "notchCornerRadius": 12,
    "panelCornerRadius": 20,
    "itemCornerRadius": 8
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
| `colors.*` | Hex `#RRGGBB` or `#RRGGBBAA`. `background` fills the notch/panel; `surface` is item rows; `stackChip` is the shift-click stack badge. |
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
