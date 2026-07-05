import Foundation
import Observation

@Observable
final class NotesStore {
    private(set) var notes: [Note] = []

    private let url: URL
    private var saveWork: DispatchWorkItem?

    init(storageDirectory: URL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appending(path: "RealNotch")
    ) {
        url = storageDirectory.appending(path: "notes.json")
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        load()
    }

    func add() -> Note {
        let note = Note()
        notes.insert(note, at: 0)
        scheduleSave()
        return note
    }

    func update(_ note: Note) {
        guard let i = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[i] = note
        scheduleSave()
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        scheduleSave()
    }

    func togglePin(_ note: Note) {
        guard let i = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[i].pinned.toggle()
        notes.sort { $0.pinned && !$1.pinned }
        scheduleSave()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode([Note].self, from: data) else { return }
        notes = saved
    }

    private func scheduleSave() {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveNow() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func saveNow() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
