import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var deck: Deck
    var topic: String? = nil   // wenn gesetzt, werden nur Karten dieses Themas gelernt

    @State private var queue: [Card] = []
    @State private var index = 0
    @State private var flipped = false
    @State private var correctCount = 0
    @State private var totalAnswered = 0
    @State private var dragOffset: CGSize = .zero

    @AppStorage("flipStyle") private var flipStyleRaw = FlipStyle.flip3D.rawValue
    @State private var showingSettings = false

    private var flipStyle: FlipStyle {
        FlipStyle(rawValue: flipStyleRaw) ?? .flip3D
    }

    // Ab dieser horizontalen Strecke (Punkte) zählt der Swipe als Antwort
    private let swipeThreshold: CGFloat = 120

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.blue.opacity(0.25), Color.purple.opacity(0.20)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header

                if let card = currentCard {
                    Spacer()
                    flashcard(for: card)
                    Spacer()
                    answerButtons(for: card)
                } else {
                    Spacer()
                    finishedView
                    Spacer()
                }
            }
            .padding()
        }
        .onAppear(perform: buildQueue)
        .sheet(isPresented: $showingSettings) {
            FlipSettingsView()
        }
    }

    // MARK: - Computed

    private var currentCard: Card? {
        guard index < queue.count else { return nil }
        return queue[index]
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .padding(12)
            }
            .glassEffect(.regular.interactive(), in: .circle)

            Spacer()

            if !queue.isEmpty {
                Text("\(min(index + 1, queue.count)) / \(queue.count)")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: .capsule)
            }

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.headline)
                    .padding(12)
            }
            .glassEffect(.regular.interactive(), in: .circle)
        }
    }

    private func flashcard(for card: Card) -> some View {
        FlipView(
            style: flipStyle,
            flipped: flipped,
            front: cardFace(content: AnyView(frontContent(for: card))),
            back: cardFace(content: AnyView(backContent(for: card)))
        )
        .frame(maxWidth: .infinity)
        .frame(height: 360)
        .overlay {
            swipeOverlay
        }
        .contentShape(.rect(cornerRadius: 28))
        .offset(x: dragOffset.width, y: dragOffset.height * 0.2)
        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
        .onTapGesture {
            withAnimation(flipStyle.animation) {
                flipped.toggle()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard flipped else { return }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    guard flipped else { return }
                    if value.translation.width > swipeThreshold {
                        swipeAway(correct: true, toRight: true, card: card)
                    } else if value.translation.width < -swipeThreshold {
                        swipeAway(correct: false, toRight: false, card: card)
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }

    // Glas-Hintergrund + zentrierter Inhalt, feste Größe
    private func cardFace(content: AnyView) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 28))
            content
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(.rect(cornerRadius: 28))
    }

    // Vorderseite: nur der Begriff
    @ViewBuilder
    private func frontContent(for card: Card) -> some View {
        VStack(spacing: 16) {
            Text("Begriff")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(card.front)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // Rückseite: Definition + optionale Zusatzinfo
    @ViewBuilder
    private func backContent(for card: Card) -> some View {
        VStack(spacing: 16) {
            Text("Definition")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(card.back)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if card.hasInfo, let info = card.info {
                Divider()
                    .padding(.horizontal, 40)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text(info)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal)
            }

            // Springt in die Claude-App, legt Frage + Antwort in die Zwischenablage
            // und bittet um eine genauere Erklärung.
            Button {
                ClaudeLink.ask(front: card.front, back: card.back)
            } label: {
                Label("Bei Claude nachfragen", systemImage: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.plain)
            .tint(.white)
            .glassEffect(.regular.tint(.purple.opacity(0.6)), in: .capsule)
            .padding(.top, 4)
        }
    }

    // Eingeblendetes Label während des Ziehens
    private var swipeOverlay: some View {
        ZStack {
            // "GEWUSST" rechts
            Text("GEWUSST")
                .font(.title.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .glassEffect(.regular.tint(.green), in: .capsule)
                .opacity(Double(max(dragOffset.width, 0) / swipeThreshold))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(24)

            // "NOCHMAL" links
            Text("NOCHMAL")
                .font(.title.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .glassEffect(.regular.tint(.red), in: .capsule)
                .opacity(Double(max(-dragOffset.width, 0) / swipeThreshold))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(24)
        }
        .allowsHitTesting(false)
    }

    private func answerButtons(for card: Card) -> some View {
        Group {
            if flipped {
                HStack(spacing: 16) {
                    Button {
                        record(card: card, correct: false)
                    } label: {
                        Label("Nochmal", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .tint(.white)
                    .glassEffect(.regular.tint(.red).interactive(), in: .capsule)

                    Button {
                        record(card: card, correct: true)
                    } label: {
                        Label("Gewusst", systemImage: "checkmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .tint(.white)
                    .glassEffect(.regular.tint(.green).interactive(), in: .capsule)
                }
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        flipped = true
                    }
                } label: {
                    Label("Umdrehen", systemImage: "arrow.2.squarepath")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .tint(.white)
                .glassEffect(.regular.tint(.blue).interactive(), in: .capsule)
            }
        }
    }

    private var finishedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Fertig!")
                .font(.largeTitle.bold())
            if totalAnswered > 0 {
                Text("\(correctCount) von \(totalAnswered) gewusst")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Button {
                dismiss()
            } label: {
                Text("Schließen")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
            }
            .glassEffect(.regular.tint(.blue).interactive(), in: .capsule)
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .padding()
    }

    // MARK: - Logic

    private func buildQueue() {
        // Karten-Basis ggf. auf gewähltes Thema einschränken
        func filterTopic(_ cards: [Card]) -> [Card] {
            guard let topic else { return cards }
            return cards.filter { $0.topic == topic }
        }

        // Mit Lernplan: nur die heute fälligen Tageskarten.
        // Ohne Plan: fällige Karten zuerst, sonst alle.
        if deck.hasPlan {
            let today = filterTopic(deck.cardsForToday)
            queue = today.isEmpty ? [] : today.shuffled()
        } else {
            let base = filterTopic(deck.cards)
            let due = base.filter { $0.isDue }
            queue = due.isEmpty ? base.shuffled() : due.shuffled()
        }
        index = 0
        flipped = false
        correctCount = 0
        totalAnswered = 0
    }

    private func record(card: Card, correct: Bool) {
        card.answer(correct: correct)
        totalAnswered += 1
        if correct { correctCount += 1 }

        // Lern-Streak: heute wurde gelernt
        StreakManager.recordStudyToday()

        // Falsch beantwortete Karte ans Ende hängen (gleiche Session nochmal)
        if !correct {
            queue.append(card)
        }

        flipped = false
        index += 1
    }

    // Karte aus dem Bild wischen, dann Antwort registrieren und zurücksetzen
    private func swipeAway(correct: Bool, toRight: Bool, card: Card) {
        withAnimation(.easeIn(duration: 0.25)) {
            dragOffset = CGSize(width: toRight ? 1000 : -1000, height: 0)
        }
        // Nach der Wisch-Animation: Antwort buchen und nächste Karte mittig zurücksetzen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            record(card: card, correct: correct)
            dragOffset = .zero
        }
    }
}
