import AppKit
import Foundation
import os

struct PluginRow: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
}

/// A loaded Lua plugin: metadata + a registry ref to its module table.
final class LuaPlugin: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let path: String
    let ref: Int32
    init(name: String, icon: String, path: String, ref: Int32) {
        self.name = name; self.icon = icon; self.path = path; self.ref = ref
    }
}

/// A sandboxed Lua 5.4 runtime. Opens only base/table/string/math/utf8 (no file,
/// os, or dynamic-library access), exposes a tiny read-only `notch` host API, and
/// runs plugin `render()` functions. Not thread-safe — only touched on the main thread.
final class LuaEngine {
    private let L: OpaquePointer

    init() {
        L = ln_newstate()
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

    /// notch.clipboard() -> string, notch.time() -> number
    private func installHostAPI() {
        lua_createtable(L, 0, 2)

        let clip: lua_CFunction = { l in
            let s = NSPasteboard.general.string(forType: .string) ?? ""
            _ = s.withCString { lua_pushstring(l, $0) }
            return 1
        }
        lua_pushcclosure(L, clip, 0)
        lua_setfield(L, -2, "clipboard")

        let time: lua_CFunction = { l in
            lua_pushnumber(l, Date().timeIntervalSince1970)
            return 1
        }
        lua_pushcclosure(L, time, 0)
        lua_setfield(L, -2, "time")

        lua_setglobal(L, "notch")
    }

    /// Load a plugin file. Returns its metadata, or nil on a syntax/runtime error.
    func load(path: String) -> LuaPlugin? {
        guard luaL_loadfilex(L, path, nil) == LUA_OK else { logError(path); pop(1); return nil }
        guard lua_pcallk(L, 0, 1, 0, 0, nil) == LUA_OK else { logError(path); pop(1); return nil }
        guard lua_type(L, -1) == LUA_TTABLE else { pop(1); return nil }
        let fallback = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        let name = field(-1, "name") ?? fallback
        let icon = field(-1, "icon") ?? "puzzlepiece.extension"
        let ref = luaL_ref(L, ln_registryindex()) // pops the module table, stores a ref
        return LuaPlugin(name: name, icon: icon, path: path, ref: ref)
    }

    func unload(_ plugin: LuaPlugin) {
        luaL_unref(L, ln_registryindex(), plugin.ref)
    }

    /// Call the plugin's render() and collect its rows.
    func render(_ plugin: LuaPlugin) -> [PluginRow] {
        lua_rawgeti(L, ln_registryindex(), lua_Integer(plugin.ref)) // module table
        defer { pop(1) }
        guard lua_type(L, -1) == LUA_TTABLE else { return [] }
        lua_getfield(L, -1, "render")
        guard lua_type(L, -1) == LUA_TFUNCTION else { pop(1); return [] }
        guard lua_pcallk(L, 0, 1, 0, 0, nil) == LUA_OK else { logError(plugin.name); pop(1); return [] }
        defer { pop(1) } // the rows table
        guard lua_type(L, -1) == LUA_TTABLE else { return [] }

        var rows: [PluginRow] = []
        let n = luaL_len(L, -1)
        var i: lua_Integer = 1
        while i <= n {
            lua_geti(L, -1, i)
            if lua_type(L, -1) == LUA_TTABLE {
                rows.append(PluginRow(title: field(-1, "title") ?? "", subtitle: field(-1, "subtitle")))
            } else if let s = string(at: -1) {
                rows.append(PluginRow(title: s, subtitle: nil))
            }
            pop(1)
            i += 1
        }
        return rows
    }

    // MARK: helpers

    private func field(_ tableIndex: Int32, _ key: String) -> String? {
        lua_getfield(L, tableIndex, key)
        defer { pop(1) }
        return string(at: -1)
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
