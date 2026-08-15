import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var deck: Deck

    @State private var showingStudy = false
    @State private var showingAddCard = false
    @State private var showingExport = false
    @State private var showingFileExport = false
    @State private var newFront = ""
    @State private var newBack = ""
    @State private var newInfo = ""
    @State private var selectedTopic: String? = nil   // nil = "Alle"

    // Karten gefiltert nach gewähltem Thema
    private var filteredCards: [Card] {
        let sorted = deck.cards.sorted { $0.createdAt < $1.createdAt }
        guard let topic = selectedTopic else { return sorted }
        return sorted.filter { $0.topic == topic }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Themen-Filter (nur wenn das Deck Themen hat)
                if deck.hasTopics {
                    topicFilter
                }

                if deck.cards.isEmpty {
                    Text("Noch keine Karten. Füge welche mit + hinzu.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    ForEach(filteredCards) { card in
                        CardRow(card: card)
                            .contextMenu {
                                Button(role: .destructive) {
                                    context.delete(card)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.large)
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color.blue.opacity(0.10)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .safeAreaInset(edge: .bottom) {
            if !deck.cards.isEmpty {
                Button {
                    showingStudy = true
                } label: {
                    Label("Lernen starten", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .tint(.white)
                .glassEffect(.regular.tint(.blue.opacity(0.6)).interactive(), in: .capsule)
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddCard = true
                    } label: {
                        Label("Karte hinzufügen", systemImage: "plus")
                    }
                    Button {
                        showingFileExport = true
                    } label: {
                        Label("Als .kartei teilen", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showingExport = true
                    } label: {
                        Label("Als Text exportieren", systemImage: "doc.plaintext")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .fullScreenCover(isPresented: $showingStudy) {
            StudyView(deck: deck, topic: selectedTopic)
        }
        .sheet(isPresented: $showingExport) {
            ExportView(text: CardParser.export(deck: deck))
        }
        .fileExporter(
            isPresented: $showingFileExport,
            document: KarteiDocument(deck: deck),
            contentType: .kartei,
            defaultFilename: deck.name
        ) { result in
            // Ergebnis ignorieren wir hier; iOS zeigt Erfolg/Abbruch selbst
            _ = result
        }
        .alert("Neue Karte", isPresented: $showingAddCard) {
            TextField("Begriff (Vorderseite)", text: $newFront)
            TextField("Definition (Rückseite)", text: $newBack)
            TextField("Zusatzinfo (optional)", text: $newInfo)
            Button("Abbrechen", role: .cancel) { clearNew() }
            Button("Hinzufügen") { addCard() }
        }
    }

    // Horizontale Filterleiste: "Alle" + jedes Thema
    private var topicFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                topicChip(title: "Alle", value: nil)
                ForEach(deck.topics, id: \.self) { topic in
                    topicChip(title: topic, value: topic)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func topicChip(title: String, value: String?) -> some View {
        let isSelected = selectedTopic == value
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTopic = value
            }
        } label: {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
        }
        .tint(isSelected ? .white : .primary)
        .glassEffect(
            isSelected ? .regular.tint(.blue.opacity(0.7)).interactive() : .regular.interactive(),
            in: .capsule
        )
    }

    private func addCard() {
        let f = newFront.trimmingCharacters(in: .whitespaces)
        let b = newBack.trimmingCharacters(in: .whitespaces)
        guard !f.isEmpty, !b.isEmpty else { return }
        let i = newInfo.trimmingCharacters(in: .whitespaces)
        let card = Card(front: f, back: b, info: i.isEmpty ? nil : i, deck: deck)
        context.insert(card)
        clearNew()
    }

    private func clearNew() {
        newFront = ""
        newBack = ""
        newInfo = ""
    }
}

// MARK: - Karten-Zeile

struct CardRow: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(card.front)
                .font(.headline)
            Text(card.back)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= card.box ? Color.green : Color.gray.opacity(0.25))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}
