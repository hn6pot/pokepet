import AppKit
import PokepetCore
import SwiftUI

/// The « Récap » tab: today's tokens and responses, the month's messages.
struct RecapTab: View {
    let recap: Recap?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            label("AUJOURD'HUI")
            row("Tokens générés", recap.map { NumberFormat.tokens($0.output) })
            row("Tokens relus (cache)", recap.map { NumberFormat.tokens($0.cacheRead) })
            row("Réponses de Claude", recap.map { NumberFormat.count($0.responses) })
            label(recap?.monthName.uppercased() ?? "CE MOIS-CI").padding(.top, 8)
            row("Messages envoyés", recap.map { NumberFormat.count($0.messages) })
            row("automatiques (à part)", recap.map { NumberFormat.count($0.automaticMessages) }).foregroundStyle(.secondary)
            Divider().padding(.vertical, 6)
            Button("Quitter Poképote") { NSApp.terminate(nil) }.buttonStyle(.plain)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.caption2).foregroundStyle(.secondary).tracking(0.6)
    }

    /// « … » while the transcripts are being read.
    private func row(_ title: String, _ value: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "…").monospacedDigit().fontWeight(.semibold)
        }
    }
}
