import SwiftUI

// Ein sauberer Flip-Container: zeigt front oder back und dreht korrekt,
// schaltet die sichtbare Seite exakt bei 90° um (kein zu frühes Wort-Tauschen,
// kein Aufblähen dank perspective + fester Größe).
struct FlipView<Front: View, Back: View>: View {
    let style: FlipStyle
    let flipped: Bool
    let front: Front
    let back: Back

    // Achse je nach Stil
    private var axis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch style {
        case .cardFlip: return (1, 0, 0)   // horizontale Achse -> klappt hoch/runter
        default:        return (0, 1, 0)   // vertikale Achse -> dreht seitlich
        }
    }

    private var angle: Double { flipped ? 180 : 0 }

    var body: some View {
        if style == .fade {
            // Überblenden ohne Drehung
            ZStack {
                front.opacity(flipped ? 0 : 1)
                back.opacity(flipped ? 1 : 0)
            }
        } else {
            ZStack {
                // Vorderseite ist sichtbar, solange < 90° gedreht
                front
                    .opacity(flipped ? 0 : 1)

                // Rückseite ist sichtbar ab 90°, vorgedreht damit sie richtig steht
                back
                    .opacity(flipped ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: axis)
            }
            .rotation3DEffect(.degrees(angle), axis: axis, perspective: 0.3)
        }
    }
}
