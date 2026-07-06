import AppKit
import Foundation
import os

struct PluginRow: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String?      // SF Symbol name
    let color: String?     // hex, tints icon / badge / progress
    let badge: String?     // trailing pill text
    let progress: Double?  // 0…1 bar under the row
    /// Registry ref of a Lua `action` function to call when the row is clicked.
    let actionRef: Int32?
}

/// A loaded Lua plugin: metadata + a registry ref to its module table.
final class LuaPlugin: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let path: String
    let ref: Int32
    /// Whether the plugin has a render() — i.e. it should get its own notch tab.
    let hasRender: Bool
    init(name: String, icon: String, path: String, ref: Int32, hasRender: Bool) {
        self.name = name; self.icon = icon; self.path = path; self.ref = ref
        self.hasRender = hasRender
    }
}

// Reachable from non-capturing C callbacks via the state's extra space.
private func engine(from L: OpaquePointer?) -> LuaEngine? {
    guard let L, let raw = ln_extraspace(L)?.load(as: UnsafeMutableRawPointer?.self) else { return nil }
    return Unmanaged<LuaEngine>.fromOpaque(raw).takeUnretainedValue()
}

private func hostLaunch(_ name: String) {
    if let running = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name }) {
        running.activate(options: [.activateAllWindows])
    } else {
        NSWorkspace.shared.launchApplication(name)
    }
}

/// A sandboxed Lua 5.4 runtime. Opens only base/table/string/math/utf8 (no file,
/// os, or dynamic-library access), exposes the `notch` host API, and runs plugin
/// render()/action/hotkey functions. Not thread-safe — only touched on the main thread.
final class LuaEngine {
    private let L: OpaquePointer
    private let hotkeys = HotKeyManager()
    private var hotkeyRefs: [Int32] = []
    private var actionRefs: [Int32: [Int32]] = [:] // pluginRef -> row action refs

    init() {
        L = ln_newstate()
        // Stash a pointer to self so C callbacks can reach the engine.
        ln_extraspace(L)?.storeBytes(of: Unmanaged.passUnretained(self).toOpaque(),
                                     as: UnsafeMutableRawPointer.self)
        openSafeLibs()
        installHostAPI()
    }
    deinit { lua_close(L) }

    private func pop(_ n: Int32) { lua_settop(L, -n - 1) }

    private func openSafeLibs() {
        let libs: [(String, lua_CFunction)] = [
            ("_G", luaopen_base), ("table", luaopen_table),
            ("string", luaopen_string), ("math", luaopen_math), ("utf8", luaopen_utf8),
        ]
        for (name, fn) in libs {
            luaL_requiref(L, name, fn, 1)
            pop(1)
        }
    }

    /// The `notch` host table: clipboard(), time(), launch(app), hotkey(key, fn).
    private func installHostAPI() {
        lua_createtable(L, 0, 4)

        func set(_ name: String, _ fn: lua_CFunction) {
            lua_pushcclosure(L, fn, 0)
            lua_setfield(L, -2, name)
        }

        set("clipboard") { l in
            let s = NSPasteboard.general.string(forType: .string) ?? ""
            _ = s.withCString { lua_pushstring(l, $0) }
            return 1
        }
        set("time") { l in
            lua_pushnumber(l, Date().timeIntervalSince1970)
            return 1
        }
        set("launch") { l in
            if let c = lua_tolstring(l, 1, nil) { hostLaunch(String(cString: c)) }
            return 0
        }
        set("hotkey") { l in
            guard let c = lua_tolstring(l, 1, nil), lua_type(l, 2) == LUA_TFUNCTION else { return 0 }
            let key = String(cString: c)
            lua_pushvalue(l, 2)                        // copy fn to top
            let ref = luaL_ref(l, ln_registryindex())  // pops copy, stores ref
            engine(from: l)?.registerHotkey(key: key, fnRef: ref)
            return 0
        }

        lua_setglobal(L, "notch")
    }

    // MARK: loading

    func load(path: String) -> LuaPlugin? {
        guard luaL_loadfilex(L, path, nil) == LUA_OK else { logError(path); pop(1); return nil }
        guard lua_pcallk(L, 0, 1, 0, 0, nil) == LUA_OK else { logError(path); pop(1); return nil }
        guard lua_type(L, -1) == LUA_TTABLE else { pop(1); return nil }
        let fallback = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        let name = field(-1, "name") ?? fallback
        let icon = field(-1, "icon") ?? "puzzlepiece.extension"
        lua_getfield(L, -1, "render")
        let hasRender = lua_type(L, -1) == LUA_TFUNCTION
        pop(1)
        let ref = luaL_ref(L, ln_registryindex())
        return LuaPlugin(name: name, icon: icon, path: path, ref: ref, hasRender: hasRender)
    }

    func unload(_ plugin: LuaPlugin) {
        luaL_unref(L, ln_registryindex(), plugin.ref)
    }

    /// Before reloading all plugins: drop plugin hotkeys and stale action refs so a
    /// plugin's top-level `notch.hotkey(...)` doesn't stack up on every reload.
    func resetForReload() {
        hotkeys.unregisterAll()
        for r in hotkeyRefs { luaL_unref(L, ln_registryindex(), r) }
        hotkeyRefs = []
        for refs in actionRefs.values { for r in refs { luaL_unref(L, ln_registryindex(), r) } }
        actionRefs = [:]
    }

    // MARK: running

    func render(_ plugin: LuaPlugin) -> [PluginRow] {
        // Free last render's action refs for this plugin.
        for r in actionRefs[plugin.ref] ?? [] { luaL_unref(L, ln_registryindex(), r) }
        actionRefs[plugin.ref] = []

        lua_rawgeti(L, ln_registryindex(), lua_Integer(plugin.ref))
        defer { pop(1) }
        guard lua_type(L, -1) == LUA_TTABLE else { return [] }
        lua_getfield(L, -1, "render")
        guard lua_type(L, -1) == LUA_TFUNCTION else { pop(1); return [] }
        guard lua_pcallk(L, 0, 1, 0, 0, nil) == LUA_OK else { logError(plugin.name); pop(1); return [] }
        defer { pop(1) }
        guard lua_type(L, -1) == LUA_TTABLE else { return [] }

        var rows: [PluginRow] = []
        let n = luaL_len(L, -1)
        var i: lua_Integer = 1
        while i <= n {
            lua_geti(L, -1, i)
            if lua_type(L, -1) == LUA_TTABLE {
                let title = field(-1, "title") ?? ""
                let subtitle = field(-1, "subtitle")
                let icon = field(-1, "icon")
                let color = field(-1, "color")
                let badge = field(-1, "badge")
                let progress = number(-1, "progress")
                var actionRef: Int32?
                lua_getfield(L, -1, "action")
                if lua_type(L, -1) == LUA_TFUNCTION {
                    lua_pushvalue(L, -1)
                    let r = luaL_ref(L, ln_registryindex())
                    actionRef = r
                    actionRefs[plugin.ref, default: []].append(r)
                }
                pop(1) // action field
                rows.append(PluginRow(title: title, subtitle: subtitle, icon: icon,
                                      color: color, badge: badge, progress: progress, actionRef: actionRef))
            } else if let s = string(at: -1) {
                rows.append(PluginRow(title: s, subtitle: nil, icon: nil,
                                      color: nil, badge: nil, progress: nil, actionRef: nil))
            }
            pop(1)
            i += 1
        }
        return rows
    }

    /// Call a stored Lua function (a row action or a hotkey callback).
    func callRef(_ ref: Int32) {
        lua_rawgeti(L, ln_registryindex(), lua_Integer(ref))
        if lua_type(L, -1) == LUA_TFUNCTION {
            if lua_pcallk(L, 0, 0, 0, 0, nil) != LUA_OK { logError("action"); pop(1) }
        } else {
            pop(1)
        }
    }

    fileprivate func registerHotkey(key: String, fnRef: Int32) {
        hotkeyRefs.append(fnRef)
        hotkeys.register(key) { [weak self] in self?.callRef(fnRef) }
    }

    // MARK: helpers

    private func field(_ tableIndex: Int32, _ key: String) -> String? {
        lua_getfield(L, tableIndex, key)
        defer { pop(1) }
        return string(at: -1)
    }

    private func number(_ tableIndex: Int32, _ key: String) -> Double? {
        lua_getfield(L, tableIndex, key)
        defer { pop(1) }
        guard lua_type(L, -1) == LUA_TNUMBER else { return nil }
        return lua_tonumberx(L, -1, nil)
    }

    private func string(at index: Int32) -> String? {
        guard let c = lua_tolstring(L, index, nil) else { return nil }
        return String(cString: c)
    }

    private func logError(_ context: String) {
        let msg = string(at: -1) ?? "unknown error"
        Logger(subsystem: "com.realnotch.app", category: "plugins")
            .error("Lua plugin \(context): \(msg)")
    }
}
