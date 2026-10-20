import PokepetCore
import SwiftUI

/// The window's content: the Pokémon of the day, its progress, and the « Récap » / « Réglages » tabs.
struct PopoverView: View {
    @Bindable var model: PopoverModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let appearance = model.appearance {
                header(appearance)
            }
            Picker("", selection: $model.tab) {
                Text("Récap").tag(PopoverModel.Tab.recap)
                Text("Réglages").tag(PopoverModel.Tab.settings)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(14)
        .frame(width: 300)
    }

    private func header(_ appearance: Appearance) -> some View {
        let progress = EvolutionProgress(lineage: appearance.lineage, responses: appearance.responses)
        return HStack(spacing: 12) {
            TimelineView(.periodic(from: .now, by: 1.0 / 30)) { context in
                if let image = model.headerImage(at: context.date) {
                    Image(nsImage: image).interpolation(.none)
                }
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(appearance.species.name).font(.headline)
                Text("\(progress.stageName) · \(progress.detail)").font(.caption).foregroundStyle(.secondary)
                ProgressView(value: progress.fraction)
            }
        }
    }
}
