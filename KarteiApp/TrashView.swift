import SwiftUI
import SwiftData

struct TrashView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Deck.deletedAt, order: .reverse) private var allDecks: [Deck]

    private var trashedDecks: [Deck] {
        allDecks.filter { $0.deletedAt != nil }
    }

    var body: some View {
        NavigationStack {
            Group {
                if trashedDecks.isEmpty {
                    ContentUnavailableView {
                        Label("Papierkorb leer", systemImage: "trash")
                    } description: {
                        Text("Gelöschte Decks landen hier und werden nach \(Deck.trashRetentionDays) Tagen automatisch entfernt.")
                    }
                } else {
                    list
                }
            }
            .navigationTitle("Papierkorb")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { dismiss() }
                }
                if !trashedDecks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            emptyTrash()
                        } label: {
                            Text("Alle löschen")
                        }
                    }
                }
            }
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(trashedDecks) { deck in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deck.name)
                                .font(.headline)
                            Text("\(deck.cards.count) Karten · noch \(deck.daysLeftInTrash) Tage")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            restore(deck)
                        } label: {
                            Text("Wiederherstellen")
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            context.delete(deck)
                        } label: {
                            Label("Endgültig löschen", systemImage: "trash")
                        }
                    }
                }
            } footer: {
                Text("Decks werden \(Deck.trashRetentionDays) Tage aufbewahrt und dann automatisch endgültig gelöscht. Nach links wischen löscht sofort.")
            }
        }
    }

    private func restore(_ deck: Deck) {
        deck.deletedAt = nil
    }

    private func emptyTrash() {
        for deck in trashedDecks {
            context.delete(deck)
        }
    }
}
