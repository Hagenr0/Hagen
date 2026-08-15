import Foundation
import SwiftData

// MARK: - Deck (Thema / Lernset)

@Model
final class Deck {
    var name: String
    var createdAt: Date
    var deletedAt: Date?       // nil = aktiv; gesetzt = im Papierkorb seit diesem Zeitpunkt
    var planStartDate: Date?   // Startdatum des Lernplans (nil = kein Plan)
    var planDays: Int          // Anzahl Tage, auf die der Plan verteilt ist (0 = kein Plan)
    // .cascade => löscht man ein Deck, werden seine Karten mitgelöscht
    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card]

    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.deletedAt = nil
        self.planStartDate = nil
        self.planDays = 0
        self.cards = []
    }

    // Tage, die ein gelöschtes Deck aufbewahrt wird
    static let trashRetentionDays = 7

    // Verbleibende Tage im Papierkorb (mind. 0)
    var daysLeftInTrash: Int {
        guard let deletedAt else { return 0 }
        let expiry = Calendar.current.date(byAdding: .day, value: Deck.trashRetentionDays, to: deletedAt) ?? deletedAt
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        return max(days, 0)
    }

    // Anzahl Karten, die jetzt zum Wiederholen anstehen
    var dueCount: Int {
        cards.filter { $0.isDue }.count
    }

    // Lernfortschritt 0...1 (Anteil Karten in hoher Box)
    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        let learned = cards.filter { $0.box >= 4 }.count
        return Double(learned) / Double(cards.count)
    }

    // MARK: - Lernplan

    var hasPlan: Bool {
        planStartDate != nil && planDays > 0
    }

    // Welcher Lerntag ist heute? (1-basiert). Ohne Plan: 0
    var currentPlanDay: Int {
        guard let start = planStartDate, planDays > 0 else { return 0 }
        let startDay = Calendar.current.startOfDay(for: start)
        let today = Calendar.current.startOfDay(for: Date())
        let diff = Calendar.current.dateComponents([.day], from: startDay, to: today).day ?? 0
        // Tag 1 am Starttag; nicht über planDays hinaus
        return min(max(diff + 1, 1), planDays)
    }

    // Karten, die heute laut Plan dran sind:
    // alle aus dem aktuellen Lerntag + frühere Tage, die noch fällig sind.
    var cardsForToday: [Card] {
        guard hasPlan else { return cards.filter { $0.isDue } }
        let day = currentPlanDay
        return cards.filter { card in
            // Karten aus heutigem oder einem vergangenen Lerntag,
            // die noch nicht "gelernt" (hohe Box) oder wieder fällig sind.
            card.studyGroup <= day && (card.isDue || card.box < 4)
        }
    }

    var todayCount: Int {
        cardsForToday.count
    }

    // MARK: - Themen

    // Alle Themen im Deck (eindeutig, alphabetisch). Leer = Deck hat keine Themen.
    var topics: [String] {
        let all = cards.compactMap { card -> String? in
            guard let t = card.topic?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !t.isEmpty else { return nil }
            return t
        }
        return Array(Set(all)).sorted()
    }

    var hasTopics: Bool {
        !topics.isEmpty
    }
}

// MARK: - Card (Karteikarte)

@Model
final class Card {
    var front: String          // Begriff / Vorderseite
    var back: String           // Definition / Rückseite
    var info: String?          // optionale Zusatzinfo (nur angezeigt wenn vorhanden)
    var topic: String?         // optionales Thema/Kapitel (nur wenn vorhanden -> Filter)
    var box: Int               // Leitner-Box 1...5
    var nextReview: Date       // wann wieder fällig
    var createdAt: Date
    var studyGroup: Int        // Lerntag im Plan (1-basiert); 0 = keinem Tag zugeordnet
    var deck: Deck?

    init(front: String, back: String, info: String? = nil, topic: String? = nil, studyGroup: Int = 0, deck: Deck? = nil) {
        self.front = front
        self.back = back
        self.info = info
        self.topic = topic
        self.box = 1
        self.nextReview = Date()
        self.createdAt = Date()
        self.studyGroup = studyGroup
        self.deck = deck
    }

    // true, wenn es sinnvolle Zusatzinfo gibt
    var hasInfo: Bool {
        guard let info else { return false }
        return !info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isDue: Bool {
        nextReview <= Date()
    }

    // Leitner-System: richtig => Box hoch + längeres Intervall,
    // falsch => zurück in Box 1.
    func answer(correct: Bool) {
        if correct {
            box = min(box + 1, 5)
        } else {
            box = 1
        }
        let days: Int
        switch box {
        case 1: days = 0      // gleich nochmal in dieser Session
        case 2: days = 1
        case 3: days = 3
        case 4: days = 7
        default: days = 16
        }
        nextReview = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }
}
