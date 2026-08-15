import Foundation
import SwiftUI

// Verwaltet den Lern-Streak (aufeinanderfolgende Tage mit Lernaktivität).
// Speichert in UserDefaults, gilt global über alle Decks.
struct StreakManager {

    private static let currentKey = "streak.current"
    private static let longestKey = "streak.longest"
    private static let lastDayKey = "streak.lastDay"   // gespeichert als yyyy-MM-dd

    private static var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }

    private static func dayString(_ date: Date) -> String {
        dayFormatter.string(from: Calendar.current.startOfDay(for: date))
    }

    static var current: Int {
        UserDefaults.standard.integer(forKey: currentKey)
    }

    static var longest: Int {
        UserDefaults.standard.integer(forKey: longestKey)
    }

    // Wurde heute schon gelernt?
    static var didStudyToday: Bool {
        UserDefaults.standard.string(forKey: lastDayKey) == dayString(Date())
    }

    // Beim Lernen aufrufen. Aktualisiert den Streak abhängig vom letzten Lerntag.
    static func recordStudyToday() {
        let defaults = UserDefaults.standard
        let today = dayString(Date())
        let last = defaults.string(forKey: lastDayKey)

        // Heute schon gezählt? Nichts tun.
        guard last != today else { return }

        let yesterday = dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())

        var streak = defaults.integer(forKey: currentKey)
        if last == yesterday {
            streak += 1            // gestern gelernt -> Streak fortsetzen
        } else {
            streak = 1             // Lücke (oder erster Tag) -> neu beginnen
        }

        defaults.set(streak, forKey: currentKey)
        defaults.set(today, forKey: lastDayKey)

        if streak > defaults.integer(forKey: longestKey) {
            defaults.set(streak, forKey: longestKey)
        }
    }

    // Prüft beim App-Start, ob der Streak abgelaufen ist
    // (länger als gestern nicht gelernt) und setzt ihn ggf. zurück.
    static func refreshIfBroken() {
        let defaults = UserDefaults.standard
        guard let last = defaults.string(forKey: lastDayKey) else { return }
        let today = dayString(Date())
        let yesterday = dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        // Wenn der letzte Lerntag weder heute noch gestern war -> Streak gebrochen
        if last != today && last != yesterday {
            defaults.set(0, forKey: currentKey)
        }
    }
}
