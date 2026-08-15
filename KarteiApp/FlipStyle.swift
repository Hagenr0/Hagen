import SwiftUI

// Die verschiedenen Umdreh-Animationen, zwischen denen man in den Einstellungen wählen kann.
enum FlipStyle: String, CaseIterable, Identifiable {
    case flip3D          // 3D-Drehung um die Y-Achse (sanft)
    case cardFlip        // Umklappen um die X-Achse (wie ein Notizblock)
    case fade            // Überblenden mit leichtem Zoom
    case quickFlip       // Schnelle 3D-Drehung mit Feder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flip3D:    return "3D-Flip"
        case .cardFlip:  return "Karteikarten-Flip"
        case .fade:      return "Überblenden"
        case .quickFlip: return "Schneller Flip"
        }
    }

    var subtitle: String {
        switch self {
        case .flip3D:    return "Sanftes Drehen um die senkrechte Achse"
        case .cardFlip:  return "Klappt nach oben um, wie ein Notizblock"
        case .fade:      return "Ruhiges Ein-/Ausblenden mit Zoom"
        case .quickFlip: return "Kurzes, knackiges Umdrehen mit Feder"
        }
    }

    var icon: String {
        switch self {
        case .flip3D:    return "arrow.left.arrow.right"
        case .cardFlip:  return "arrow.up.arrow.down"
        case .fade:      return "circle.lefthalf.filled"
        case .quickFlip: return "bolt.fill"
        }
    }

    // Passende Animationskurve je Stil
    var animation: Animation {
        switch self {
        case .flip3D:    return .easeInOut(duration: 0.35)
        case .cardFlip:  return .easeInOut(duration: 0.45)
        case .fade:      return .easeInOut(duration: 0.4)
        case .quickFlip: return .spring(response: 0.3, dampingFraction: 0.6)
        }
    }
}
