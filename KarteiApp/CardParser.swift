import Foundation

// Verarbeitet das Importformat:
//   Begriff :: Definition
//   [DeckName] Begriff :: Definition
//
// - Eine Karte pro Zeile
// - Trenner zwischen Vorder- und Rückseite ist " :: " (auch "::" ohne Spaces wird akzeptiert)
// - Optionaler Deckname in eckigen Klammern am Zeilenanfang
// - Leere Zeilen werden ignoriert

struct ParsedCard {
    let deckName: String?
    let front: String
    let back: String
    let info: String?
}

enum CardParser {

    static func parse(_ text: String) -> [ParsedCard] {
        var result: [ParsedCard] = []

        for rawLine in text.components(separatedBy: .newlines) {
            var line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            // Optionalen [Deck] am Anfang herauslösen
            var deckName: String? = nil
            if line.hasPrefix("[") , let close = line.firstIndex(of: "]") {
                let inside = line[line.index(after: line.startIndex)..<close]
                deckName = inside.trimmingCharacters(in: .whitespaces)
                line = String(line[line.index(after: close)...]).trimmingCharacters(in: .whitespaces)
            }

            // In Teile zerlegen: Begriff :: Definition :: (optional) Zusatzinfo
            // " :: " bevorzugt, sonst "::"
            let parts: [String]
            if line.contains(" :: ") {
                parts = line.components(separatedBy: " :: ")
            } else if line.contains("::") {
                parts = line.components(separatedBy: "::")
            } else {
                continue // Zeile ohne Trenner -> überspringen
            }

            let trimmed = parts.map { $0.trimmingCharacters(in: .whitespaces) }
            guard trimmed.count >= 2 else { continue }

            let front = trimmed[0]
            let back = trimmed[1]
            // Alles ab dem dritten Teil ist Zusatzinfo (falls jemand mehrere :: nutzt)
            let info: String? = trimmed.count >= 3
                ? trimmed[2...].joined(separator: " :: ")
                : nil

            guard !front.isEmpty, !back.isEmpty else { continue }
            let cleanInfo = (info?.isEmpty ?? true) ? nil : info
            result.append(ParsedCard(deckName: deckName, front: front, back: back, info: cleanInfo))
        }
        return result
    }

    // Exportiert ein Deck zurück ins Importformat
    static func export(deck: Deck) -> String {
        deck.cards
            .sorted { $0.createdAt < $1.createdAt }
            .map { card in
                if card.hasInfo, let info = card.info {
                    return "\(card.front) :: \(card.back) :: \(info)"
                } else {
                    return "\(card.front) :: \(card.back)"
                }
            }
            .joined(separator: "\n")
    }
}
