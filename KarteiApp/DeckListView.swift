import SwiftUI
import SwiftData

struct DeckListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.createdAt, order: .reverse) private var allDecks: [Deck]

    @State private var showingNewDeck = false
    @State private var showingImport = false
    @State private var showingTrash = false
    @State private var newDeckName = ""
    @State private var streakCurrent = 0
    @State private var streakDidToday = false

    // Nur aktive Decks (nicht im Papierkorb)
    private var decks: [Deck] {
        allDecks.filter { $0.deletedAt == nil }
    }

    private var trashedDecks: [Deck] {
        allDecks.filter { $0.deletedAt != nil }
    }

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    emptyState
                } else {
                    deckList
                }
            }
            .background(backgroundGradient)
            .navigationTitle("Karteikarten")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewDeck = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showingTrash = true
                    } label: {
                        Label("Papierkorb\(trashedDecks.isEmpty ? "" : " (\(trashedDecks.count))")",
                              systemImage: "trash")
                    }
                }
            }
            .sheet(isPresented: $showingImport) {
                ImportView()
            }
            .sheet(isPresented: $showingTrash) {
                TrashView()
            }
            .alert("Neues Deck", isPresented: $showingNewDeck) {
                TextField("Name", text: $newDeckName)
                Button("Abbrechen", role: .cancel) { newDeckName = "" }
                Button("Erstellen") { createDeck() }
            }
            .onAppear {
                purgeExpiredTrash()
                StreakManager.refreshIfBroken()
                streakCurrent = StreakManager.current
                streakDidToday = StreakManager.didStudyToday
            }
        }
    }

    // MARK: - Subviews

    // Sanfter, dezenter Hintergrundverlauf (passt zum Liquid-Glass-Look)
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.18),
                Color.purple.opacity(0.12),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var deckList: some View {
        List {
            streakBanner
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            ForEach(decks) { deck in
                ZStack {
                    DeckCard(deck: deck)
                    NavigationLink {
                        DeckDetailView(deck: deck)
                    } label: {
                        EmptyView()
                    }
                    .opacity(0)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        moveToTrash(deck)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // Streak-Anzeige
    private var streakBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(streakCurrent > 0 ? .orange : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streakCurrent) Tage Streak")
                    .font(.title3.bold())
                Text(streakDidToday
                     ? "Heute schon gelernt – stark!"
                     : (streakCurrent > 0 ? "Lerne heute, um den Streak zu halten" : "Starte heute deinen Streak"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(streakCurrent > 0 ? .orange.opacity(0.25) : .clear),
                     in: .rect(cornerRadius: 22))
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Keine Decks", systemImage: "rectangle.stack")
        } description: {
            Text("Erstelle ein Deck mit + oder importiere Karten über das Download-Symbol.")
        }
    }

    // MARK: - Actions

    private func createDeck() {
        let name = newDeckName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        context.insert(Deck(name: name))
        newDeckName = ""
    }

    // Soft-Delete: ins Papierkorb verschieben
    private func moveToTrash(_ deck: Deck) {
        deck.deletedAt = Date()
    }

    // Abgelaufene Papierkorb-Decks endgültig löschen
    private func purgeExpiredTrash() {
        for deck in allDecks where deck.deletedAt != nil {
            if deck.daysLeftInTrash <= 0 {
                context.delete(deck)
            }
        }
    }
}

// MARK: - Deck-Kachel mit Liquid Glass

struct DeckCard: View {
    let deck: Deck

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(deck.name)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Spacer()
                if deck.hasPlan {
                    Text("Heute: \(deck.todayCount)")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .glassEffect(.regular.tint(.blue).interactive())
                } else if deck.dueCount > 0 {
                    Text("\(deck.dueCount) fällig")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .glassEffect(.regular.tint(.orange).interactive())
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(.secondary)
                Text("\(deck.cards.count) Karten")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if deck.hasPlan {
                    Text("· Tag \(deck.currentPlanDay)/\(deck.planDays)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: deck.progress)
                .tint(.green)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }
}
