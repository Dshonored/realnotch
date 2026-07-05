# RealNotch

A lightweight, open-source notch utility for macOS. Native Swift + SwiftUI, no Electron, no nonsense.

## Features (v1)

- **Clipboard history** in your notch — hover the notch to expand.
  - **Click** an item to copy it.
  - **Shift-click** items to build a *stack*; click the stack chip to copy them all at once (newline-joined).
  - Password managers stay private: concealed/transient pasteboard types are never recorded.
- **Skins** — every color, radius, font, blur, and animation is themeable via simple JSON files. Drop a `.json` skin into the themes folder and it applies **live**, no relaunch. See [docs/THEMES.md](docs/THEMES.md) to build your own.
- Works on Macs **without** a notch too (renders a phantom notch).

### Roadmap

Media playback controls (now playing + artwork), caffeine mode (keep the Mac awake), quick notes.

## Requirements

- macOS 14 (Sonoma) or later

## Building

```sh
git clone https://github.com/you/realnotch.git
cd realnotch
xcodebuild -scheme RealNotch build
```

Or just open `RealNotch.xcodeproj` in Xcode 16+ and hit Run.

Run tests:

```sh
xcodebuild test -scheme RealNotch -destination 'platform=macOS'
```

## Contributing

PRs welcome. The project uses Xcode's filesystem-synchronized groups — add a file to the folder and it's in the target, no `pbxproj` conflicts.

The one hard rule for UI code: **no hardcoded colors, radii, or fonts in views.** Everything visual reads from `@Environment(\.theme)` — that discipline is what makes skins work.

## License

[MIT](LICENSE)
