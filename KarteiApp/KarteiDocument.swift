import SwiftUI
import UniformTypeIdentifiers

// MARK: - Eigener Dateityp .kartei

extension UTType {
    static let kartei = UTType(exportedAs: "com.haagen.kartei")
}

// MARK: - Datenstruktur, die in der Datei landet (JSON)
// nonisolated, damit die Codable-Konformität nicht an den Main-Actor gebunden ist.

nonisolated struct KarteiFile: Codable {
    var version: Int = 1
    var deckName: String
    var cards: [KarteiCard]

    nonisolated struct KarteiCard: Codable {
        var front: String
        var back: String
        var info: String?
        var topic: String?
    }
}

// MARK: - FileDocument für Export/Import über das Share-Sheet

struct KarteiDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.kartei] }
    static var writableContentTypes: [UTType] { [.kartei] }

    var file: KarteiFile

    init(deckName: String, cards: [KarteiFile.KarteiCard]) {
        self.file = KarteiFile(deckName: deckName, cards: cards)
    }

    // Beim Öffnen einer .kartei-Datei
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.file = try JSONDecoder().decode(KarteiFile.self, from: data)
    }

    // Beim Speichern/Teilen
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(file)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Helfer: Deck -> Document

extension KarteiDocument {
    init(deck: Deck) {
        let cards = deck.cards
            .sorted { $0.createdAt < $1.createdAt }
            .map { KarteiFile.KarteiCard(front: $0.front, back: $0.back, info: $0.info, topic: $0.topic) }
        self.init(deckName: deck.name, cards: cards)
    }
}
