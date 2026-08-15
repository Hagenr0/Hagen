import UIKit

// MARK: - Claude-Verknüpfung
//
// Baut aus einer Karteikarte einen Prompt, legt ihn in die Zwischenablage
// und springt in die Claude-App (bzw. claude.ai im Browser als Rückfallebene).
// Der Prompt wird zusätzlich als ?q=-Parameter mitgegeben, damit Claude ihn
// – sofern unterstützt – direkt vorbelegt. Die Zwischenablage dient als
// verlässlicher Fallback: Der Nutzer kann den Text jederzeit einfügen.

enum ClaudeLink {

    /// Erzeugt den Frage-Text für Claude aus Vorder- und Rückseite der Karte.
    static func prompt(front: String, back: String) -> String {
        let lines = [
            "Ich lerne mit Karteikarten und möchte das Thema besser verstehen.",
            "",
            "Frage (Vorderseite): \(front)",
            "Antwort (Rückseite): \(back)",
            "",
            "Bitte erkläre mir das genauer und verständlicher: Hintergrund, "
            + "warum das so ist, und – wenn hilfreich – ein Beispiel oder eine Eselsbrücke."
        ]
        return lines.joined(separator: "\n")
    }

    /// Kopiert den Prompt in die Zwischenablage und öffnet Claude.
    static func ask(front: String, back: String) {
        let text = prompt(front: front, back: back)
        UIPasteboard.general.string = text

        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // Reihenfolge: erst die App per Custom-Scheme, dann der Universal-Link.
        // Ist die App installiert, öffnet der https-Link sie ebenfalls; sonst Safari.
        let candidates: [URL] = [
            URL(string: "claude://new?q=\(encoded)"),
            URL(string: "https://claude.ai/new?q=\(encoded)"),
            URL(string: "https://claude.ai/new")
        ].compactMap { $0 }

        openFirstAvailable(candidates)
    }

    /// Versucht die URLs der Reihe nach zu öffnen, bis eine erfolgreich ist.
    private static func openFirstAvailable(_ urls: [URL]) {
        guard let url = urls.first else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                openFirstAvailable(Array(urls.dropFirst()))
            }
        }
    }
}
