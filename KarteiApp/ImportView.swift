import SwiftUI
import SwiftData

struct ImportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var decks: [Deck]

    @State private var text: String
    @State private var deckName: String
    @State private var resultMessage: String?

    // Lernplan
    @State private var usePlan = false
    @State private var planDays = 5

    // Karten mit Themen (wenn aus .kartei-Datei mit topic empfangen)
    private let incomingCards: [KarteiFile.KarteiCard]?

    // Manueller Import (Text eintippen)
    init(initialText: String? = nil, initialDeckName: String? = nil) {
        _text = State(initialValue: initialText ?? "")
        _deckName = State(initialValue: initialDeckName ?? "")
        self.incomingCards = nil
    }

    // Empfang aus .kartei-Datei
    init(incoming: IncomingImport) {
        _deckName = State(initialValue: incoming.deckName)
        self.incomingCards = incoming.cards
        if let cards = incoming.cards {
            // Vorschau-Text aus den Karten erzeugen (Thema wird separat behalten)
            let lines = cards.map { card -> String in
                if let info = card.info, !info.isEmpty {
                    return "\(card.front) :: \(card.back) :: \(info)"
                } else {
                    return "\(card.front) :: \(card.back)"
                }
            }
            _text = State(initialValue: lines.joined(separator: "\n"))
        } else {
            _text = State(initialValue: incoming.text ?? "")
        }
    }

    private var preview: [ParsedCard] { CardParser.parse(text) }

    // Anzahl Karten in der Vorschau (echte Karten falls vorhanden, sonst geparster Text)
    private var previewCount: Int {
        incomingCards?.count ?? preview.count
    }

    // Themen aus den eingehenden Karten (für die Anzeige)
    private var incomingTopics: [String] {
        guard let cards = incomingCards else { return [] }
        let all = cards.compactMap { $0.topic?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(Set(all)).sorted()
    }

    // Karten pro Tag (aufgerundet), für die Anzeige
    private var cardsPerDay: Int {
        guard usePlan, planDays > 0, previewCount > 0 else { return 0 }
        return Int(ceil(Double(previewCount) / Double(planDays)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Format")
                        .font(.headline)
                    Text("Eine Karte pro Zeile, getrennt durch ::\nBegriff :: Definition\n\nMit optionaler Zusatzinfo (dritter Teil):\nSprint :: Arbeitsphase :: Max. 1 Monat, endet mit Review\n\nMit Deck pro Zeile:\n[Mathe] Ableitung :: Steigung einer Funktion")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))

                    Text("Ziel-Deck (wenn keine [Klammern] genutzt werden)")
                        .font(.headline)
                    TextField("z.B. Projektmanagement", text: $deckName)
                        .padding()
                        .glassEffect(.regular, in: .rect(cornerRadius: 14))

                    Text("Text einfügen")
                        .font(.headline)
                    TextEditor(text: $text)
                        .frame(minHeight: 180)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))

                    if previewCount > 0 {
                        Text("\(previewCount) Karten erkannt")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                    }

                    if !incomingTopics.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text("\(incomingTopics.count) Themen erkannt: \(incomingTopics.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }

                    // MARK: Lernplan
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $usePlan) {
                            Label("Lernplan erstellen", systemImage: "calendar")
                                .font(.headline)
                        }

                        if usePlan {
                            Text("Über wie viele Tage möchtest du lernen?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Stepper(value: $planDays, in: 1...60) {
                                Text("\(planDays) Tage")
                                    .font(.headline)
                            }

                            if cardsPerDay > 0 {
                                Text("≈ \(cardsPerDay) Karten pro Tag")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))

                    if let resultMessage {
                        Text(resultMessage)
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("Importieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Importieren") { performImport() }
                        .disabled(previewCount == 0)
                }
            }
        }
    }

    private func performImport() {
        // Quelle vereinheitlichen: entweder echte Karten (mit Thema) oder geparster Text.
        struct ImportCard {
            let deckName: String?
            let front: String
            let back: String
            let info: String?
            let topic: String?
        }

        let items: [ImportCard]
        if let cards = incomingCards {
            items = cards.map {
                ImportCard(deckName: nil, front: $0.front, back: $0.back, info: $0.info, topic: $0.topic)
            }
        } else {
            items = preview.map {
                ImportCard(deckName: $0.deckName, front: $0.front, back: $0.back, info: $0.info, topic: nil)
            }
        }
        guard !items.isEmpty else { return }

        // Cache existierender Decks nach Name
        var deckByName: [String: Deck] = [:]
        for d in decks { deckByName[d.name] = d }

        let fallbackName = deckName.trimmingCharacters(in: .whitespaces)

        func deck(for name: String) -> Deck {
            if let existing = deckByName[name] { return existing }
            let new = Deck(name: name)
            context.insert(new)
            deckByName[name] = new
            return new
        }

        // Für die Verteilung in Lerntage: Index pro Ziel-Deck zählen
        var indexPerDeck: [String: Int] = [:]
        let total = items.count
        let perDay = usePlan && planDays > 0 ? Int(ceil(Double(total) / Double(planDays))) : 0

        var imported = 0
        for p in items {
            let targetName = p.deckName ?? (fallbackName.isEmpty ? "Import" : fallbackName)
            let d = deck(for: targetName)

            var group = 0
            if usePlan && perDay > 0 {
                let idx = indexPerDeck[targetName, default: 0]
                group = min(idx / perDay + 1, planDays)
                indexPerDeck[targetName] = idx + 1
            }

            let cleanTopic = p.topic?.trimmingCharacters(in: .whitespacesAndNewlines)
            let card = Card(
                front: p.front,
                back: p.back,
                info: p.info,
                topic: (cleanTopic?.isEmpty ?? true) ? nil : cleanTopic,
                studyGroup: group,
                deck: d
            )
            context.insert(card)

            if usePlan {
                if d.planStartDate == nil { d.planStartDate = Date() }
                d.planDays = planDays
            }

            imported += 1
        }

        resultMessage = usePlan
            ? "\(imported) Karten importiert, verteilt auf \(planDays) Tage."
            : "\(imported) Karten importiert."
        text = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            dismiss()
        }
    }
}
