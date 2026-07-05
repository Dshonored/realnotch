import AppKit
import Foundation
import Observation

@Observable
final class ClipboardStore {
    private(set) var items: [ClipboardItem] = []
    private(set) var stack: [ClipboardItem] = []

    var maxItems: Int {
        get { max(1, UserDefaults.standard.object(forKey: "maxItems") as? Int ?? 200) }
        set { UserDefaults.standard.set(newValue, forKey: "maxItems"); trim() }
    }

    /// Set before writing to the pasteboard ourselves so the monitor skips that change.
    var ignoreNextChange = false

    private let historyURL: URL
    let imagesDirectory: URL
    private var saveWork: DispatchWorkItem?

    init(storageDirectory: URL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appending(path: "RealNotch")
    ) {
        historyURL = storageDirectory.appending(path: "history.json")
        imagesDirectory = storageDirectory.appending(path: "Images")
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        load()
    }

    // MARK: - History

    func add(_ item: ClipboardItem) {
        // Dedupe: same content anywhere in history moves to the top instead of duplicating.
        items.removeAll { $0.content == item.content }
        items.insert(item, at: 0)
        trim()
        scheduleSave()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        stack.removeAll { $0.id == item.id }
        scheduleSave()
    }

    func clear() {
        items = []
        stack = []
        scheduleSave()
    }

    private func trim() {
        guard items.count > maxItems else { return }
        // Evict oldest unpinned items first; pinned items are kept regardless of cap.
        var overflow = items.count - maxItems
        for i in stride(from: items.count - 1, through: 0, by: -1) where overflow > 0 {
            if !items[i].pinned {
                items.remove(at: i)
                overflow -= 1
            }
        }
    }

    func togglePin(_ item: ClipboardItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        // Just marks it and protects it from the cap — position is preserved.
        items[i].pinned.toggle()
        scheduleSave()
    }

    // MARK: - Copying

    func copy(_ item: ClipboardItem) {
        ignoreNextChange = true
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.content {
        case .text(let s):
            pb.setString(s, forType: .string)
        case .image(let path):
            if let image = NSImage(contentsOfFile: path) {
                pb.writeObjects([image])
            }
        case .fileURLs(let urls):
            pb.writeObjects(urls as [NSURL])
        }
        add(item) // bump to top
    }

    // MARK: - Stack (shift-click)

    func toggleStack(_ item: ClipboardItem) {
        if stack.contains(where: { $0.id == item.id }) {
            stack.removeAll { $0.id == item.id }
        } else {
            stack.append(item)
        }
    }

    func isStacked(_ item: ClipboardItem) -> Bool {
        stack.contains { $0.id == item.id }
    }

    /// Joined text of the stack in the order items were stacked.
    /// ponytail: text-only join; images/files in a stack contribute their preview text.
    var stackedText: String {
        stack.map { item in
            if case .text(let s) = item.content { return s }
            return item.preview
        }.joined(separator: "\n")
    }

    func copyStack() {
        guard !stack.isEmpty else { return }
        ignoreNextChange = true
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(stackedText, forType: .string)
        stack = []
    }

    func clearStack() {
        stack = []
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: historyURL),
              let saved = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        items = saved
    }

    private func scheduleSave() {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveNow() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    func saveNow() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }
}
