import AppKit
import PokepetCore

/// The right-click menu: name, stage, today's responses, « Un autre Pokémon », « Taille normale », « Quitter ».
@MainActor
enum ContextMenu {
    static func build(
        appearance: Appearance, anotherPokemon: @escaping @MainActor () -> Void,
        defaultPosition: @escaping @MainActor () -> Void, normalSize: @escaping @MainActor () -> Void
    ) -> NSMenu {
        let menu = NSMenu()
        // Without an action, an item is greyed out: these are pieces of information.
        menu.addItem(NSMenuItem(title: appearance.species.name, action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Stade \(appearance.stage.rawValue)/3", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Réponses aujourd'hui : \(appearance.responses)", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: "Un autre Pokémon", action: anotherPokemon))
        menu.addItem(ClosureMenuItem(title: "Position par défaut", action: defaultPosition))
        menu.addItem(ClosureMenuItem(title: "Taille normale", action: normalSize))
        // Quitting exits with code 0: the LaunchAgent does not restart it before the next session.
        menu.addItem(ClosureMenuItem(title: "Quitter Poképote") { NSApp.terminate(nil) })
        return menu
    }
}

/// A menu item that calls a function when it is chosen.
@MainActor
private final class ClosureMenuItem: NSMenuItem {
    private let onChoose: @MainActor () -> Void

    init(title: String, action: @escaping @MainActor () -> Void) {
        onChoose = action
        super.init(title: title, action: #selector(chosen), keyEquivalent: "")
        target = self
    }

    required init(coder: NSCoder) {
        fatalError("unused")
    }

    @objc private func chosen() {
        onChoose()
    }
}
