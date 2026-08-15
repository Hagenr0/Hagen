import SwiftUI
import SwiftData

@main
struct KarteiApp: App {
    // Eingehende .kartei-Datei als identifizierbares Item (item-basiertes Sheet
    // garantiert, dass die ImportView mit den richtigen Daten gebaut wird).
    @State private var incoming: IncomingImport?

    // Container mit Fallback: schlägt die Migration fehl (z.B. nach Modelländerung
    // während der Entwicklung), wird die Datenbank neu angelegt statt zu blockieren.
    let container: ModelContainer = {
        let schema = Schema([Deck.self, Card.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            // Migration fehlgeschlagen -> alten Store löschen und frisch anlegen
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            do {
                return try ModelContainer(for: schema)
            } catch {
                fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            DeckListView()
                .onAppear {
                    StreakManager.refreshIfBroken()
                }
                // Empfang einer .kartei-Datei (AirDrop, Mail, Dateien-App ...)
                .onOpenURL { url in
                    handleIncoming(url)
                }
                .sheet(item: $incoming) { item in
                    ImportView(incoming: item)
                }
        }
        .modelContainer(container)
    }

    private func handleIncoming(_ url: URL) {
        // Zugriff auf die (ggf. geschützte) Datei
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else { return }

        // Versuch 1: echtes .kartei-JSON (mit Themen, falls vorhanden)
        if let file = try? JSONDecoder().decode(KarteiFile.self, from: data) {
            incoming = IncomingImport(deckName: file.deckName, cards: file.cards)
            return
        }

        // Versuch 2: Fallback – Datei ist einfacher Text im :: -Format
        if let raw = String(data: data, encoding: .utf8), raw.contains("::") {
            let name = url.deletingPathExtension().lastPathComponent
            incoming = IncomingImport(text: raw, deckName: name)
        }
    }
}

// Identifizierbares Item für das item-basierte Sheet.
// Trägt entweder fertige Karten (aus .kartei, inkl. Themen) oder Rohtext (Fallback).
struct IncomingImport: Identifiable {
    let id = UUID()
    let deckName: String
    let cards: [KarteiFile.KarteiCard]?
    let text: String?

    // Aus echter .kartei-Datei (mit Themen)
    init(deckName: String, cards: [KarteiFile.KarteiCard]) {
        self.deckName = deckName
        self.cards = cards
        self.text = nil
    }

    // Aus Rohtext (Fallback)
    init(text: String, deckName: String) {
        self.deckName = deckName
        self.cards = nil
        self.text = text
    }
}
