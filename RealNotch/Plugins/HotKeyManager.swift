import AppKit
import Carbon

/// Registers global hotkeys via Carbon (system-wide, no Accessibility permission)
/// and launches/focuses an app when one fires. Plugins declare the bindings.
final class HotKeyManager {
    struct Binding { let key: String; let app: String }

    private var refs: [EventHotKeyRef?] = []
    private var appForID: [UInt32: String] = [:]
    private var handler: EventHandlerRef?
    private var nextID: UInt32 = 1

    init() { installHandler() }

    /// Replace all registered hotkeys with this set.
    func setBindings(_ bindings: [Binding]) {
        for r in refs { if let r { UnregisterEventHotKey(r) } }
        refs = []
        appForID = [:]
        for b in bindings {
            guard let (code, mods) = parse(b.key) else { continue }
            let id = nextID; nextID += 1
            let hotID = EventHotKeyID(signature: 0x524E4348 /* 'RNCH' */, id: id)
            var ref: EventHotKeyRef?
            if RegisterEventHotKey(code, mods, hotID, GetApplicationEventTarget(), 0, &ref) == noErr {
                refs.append(ref)
                appForID[id] = b.app
            }
        }
    }

    private func installHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData, let event else { return noErr }
            let mgr = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            var hotID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hotID)
            mgr.launch(id: hotID.id)
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    private func launch(id: UInt32) {
        guard let name = appForID[id] else { return }
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name }) {
            running.activate(options: [.activateAllWindows])
        } else {
            NSWorkspace.shared.launchApplication(name)
        }
    }

    // "option+1", "cmd shift k" -> (keyCode, modifierMask)
    private func parse(_ s: String) -> (UInt32, UInt32)? {
        var mods: UInt32 = 0
        var keyName: String?
        for raw in s.lowercased().split(whereSeparator: { $0 == "+" || $0 == " " }) {
            switch String(raw) {
            case "cmd", "command", "⌘": mods |= UInt32(cmdKey)
            case "opt", "option", "alt", "⌥": mods |= UInt32(optionKey)
            case "ctrl", "control", "⌃": mods |= UInt32(controlKey)
            case "shift", "⇧": mods |= UInt32(shiftKey)
            case let other: keyName = other
            }
        }
        guard let name = keyName, let code = Self.keyCodes[name] else { return nil }
        return (UInt32(code), mods)
    }

    private static let keyCodes: [String: Int] = [
        "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D, "e": kVK_ANSI_E,
        "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H, "i": kVK_ANSI_I, "j": kVK_ANSI_J,
        "k": kVK_ANSI_K, "l": kVK_ANSI_L, "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O,
        "p": kVK_ANSI_P, "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
        "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X, "y": kVK_ANSI_Y,
        "z": kVK_ANSI_Z,
        "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3, "4": kVK_ANSI_4,
        "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7, "8": kVK_ANSI_8, "9": kVK_ANSI_9,
        "space": kVK_Space, "return": kVK_Return, "tab": kVK_Tab,
        "left": kVK_LeftArrow, "right": kVK_RightArrow, "up": kVK_UpArrow, "down": kVK_DownArrow,
    ]
}
