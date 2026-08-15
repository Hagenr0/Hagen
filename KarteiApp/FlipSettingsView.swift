import SwiftUI

struct FlipSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("flipStyle") private var flipStyleRaw = FlipStyle.flip3D.rawValue

    @State private var previewFlipped = false

    private var selected: FlipStyle {
        FlipStyle(rawValue: flipStyleRaw) ?? .flip3D
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Live-Vorschau
                    VStack(spacing: 12) {
                        Text("Vorschau – zum Testen antippen")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        previewCard
                            .onTapGesture {
                                withAnimation(selected.animation) {
                                    previewFlipped.toggle()
                                }
                            }
                    }
                    .padding(.top)

                    // Auswahl
                    VStack(spacing: 12) {
                        ForEach(FlipStyle.allCases) { style in
                            Button {
                                flipStyleRaw = style.rawValue
                            } label: {
                                styleRow(style)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Animation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    // MARK: - Vorschau-Karte

    private var previewCard: some View {
        FlipView(
            style: selected,
            flipped: previewFlipped,
            front: previewFace(text: "Vorderseite"),
            back: previewFace(text: "Rückseite")
        )
        .frame(height: 180)
        .padding(.horizontal, 40)
        .contentShape(.rect(cornerRadius: 24))
    }

    private func previewFace(text: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 24))
            Text(text)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(.rect(cornerRadius: 24))
    }

    // MARK: - Auswahl-Zeile

    private func styleRow(_ style: FlipStyle) -> some View {
        HStack(spacing: 14) {
            Image(systemName: style.icon)
                .font(.title3)
                .frame(width: 32)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(style.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(style.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if style == selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            style == selected ? .regular.tint(.blue.opacity(0.4)) : .regular,
            in: .rect(cornerRadius: 18)
        )
        .contentShape(.rect(cornerRadius: 18))
    }
}
