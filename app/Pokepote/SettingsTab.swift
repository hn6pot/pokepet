import AppKit
import PokepetCore
import SwiftUI

/// The « Réglages » tab: show or hide the companion, its size, the terminal conversations, and the right-click actions.
struct SettingsTab: View {
    @Bindable var model: PopoverModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Afficher le compagnon", isOn: $model.companionVisible).toggleStyle(.switch)
            HStack {
                Text("Taille")
                Slider(value: $model.size, in: Preferences.minSize...Preferences.maxSize)
            }
            Toggle("Suivre les conversations terminal", isOn: $model.terminalTracking).toggleStyle(.switch)
            Picker("Terminal", selection: $model.terminalApp) {
                ForEach(TerminalApp.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.menu)
            .disabled(!model.terminalTracking)
            Button("Taille normale") {
                model.loops.normalSize()
                model.refresh()
            }
            Button("Un autre Pokémon") {
                model.loops.anotherPokemon()
                model.refresh()
            }
            Button("Position par défaut") { model.loops.defaultPosition() }
            Divider().padding(.vertical, 4)
            Button("Quitter Poképote") { NSApp.terminate(nil) }.buttonStyle(.plain)
        }
    }
}
