import AppKit
import SwiftUI

/// The panel is a non-activating accessory window; keyboard input requires the app
/// to be active and the panel key. Call this when the user starts editing.
func activateForEditing() {
    NSApplication.shared.activate(ignoringOtherApps: true)
}

struct NotesView: View {
    @Bindable var notes: NotesStore
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 9) {
            ForEach(notes.notes) { note in
                NoteCard(note: note, store: notes)
            }

            Button {
                activateForEditing()
                _ = notes.add()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                    Text("New note").font(theme.font(theme.typography.itemSize))
                }
                .foregroundStyle(Color(hex: theme.colors.textSecondary))
                .frame(maxWidth: .infinity)
                .padding(9)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.shape.itemCornerRadius)
                        .strokeBorder(Color(hex: theme.colors.textSecondary).opacity(0.35),
                                      style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct NoteCard: View {
    let note: Note
    @Bindable var store: NotesStore
    @Environment(\.theme) private var theme
    @State private var title: String
    @State private var noteBody: String
    @State private var hovered = false

    init(note: Note, store: NotesStore) {
        self.note = note
        self.store = store
        _title = State(initialValue: note.title)
        _noteBody = State(initialValue: note.body)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                TextField("Title", text: $title)
                    .textFieldStyle(.plain)
                    .font(theme.font(theme.typography.itemSize, weight: .semibold))
                    .foregroundStyle(Color(hex: theme.colors.textPrimary))
                    .simultaneousGesture(TapGesture().onEnded { activateForEditing() })
                    .onChange(of: title) { persist() }

                Button { store.togglePin(note) } label: {
                    Image(systemName: note.pinned ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundStyle(note.pinned
                            ? Color(hex: theme.colors.pin)
                            : Color(hex: theme.colors.textSecondary).opacity(hovered ? 0.6 : 0))
                }
                .buttonStyle(.plain)

                if hovered {
                    Button { store.delete(note) } label: {
                        Image(systemName: "trash").font(.system(size: 10))
                            .foregroundStyle(Color(hex: theme.colors.textSecondary))
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Note…", text: $noteBody, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .font(theme.font(theme.typography.captionSize))
                .foregroundStyle(Color(hex: theme.colors.textSecondary))
                .simultaneousGesture(TapGesture().onEnded { activateForEditing() })
                .onChange(of: noteBody) { persist() }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: theme.shape.itemCornerRadius)
                .fill(note.pinned
                    ? Color(hex: theme.colors.pin).opacity(0.1)
                    : Color(hex: theme.colors.surface))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.shape.itemCornerRadius)
                .strokeBorder(Color(hex: theme.colors.pin).opacity(note.pinned ? 0.22 : 0))
        )
        .onHover { hovered = $0 }
    }

    private func persist() {
        var updated = note
        updated.title = title
        updated.body = noteBody
        store.update(updated)
    }
}
