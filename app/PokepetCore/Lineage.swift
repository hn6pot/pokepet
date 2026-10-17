/// A Pokémon: its displayed name and its SpriteCollab directory.
public struct Species: Equatable, Sendable {
    public let name: String
    public let number: String
}

/// An evolution family, from the baby to the final stage: the baby of the day is drawn among them.
/// The raw values are stored in the preferences (« Un autre Pokémon »): they stay as they are.
/// The order of the cases sets the daily draw: changing it would change the past babies.
public enum Lineage: String, CaseIterable, Sendable {
    case fire = "feu"
    case electric = "electrik"
    case grass = "plante"
    case water = "eau"
    case cyndaquil = "hericendre"
    case totodile = "kaiminus"
    case dragon = "dragon"
    case ghost = "spectre"
    case rock = "roche"
    case bagon = "draby"

    /// The three species, in stage order, with their SpriteCollab directory.
    public var allSpecies: [Species] {
        let trio: [(String, String)] = switch self {
        case .fire: [("Salamèche", "0004"), ("Reptincel", "0005"), ("Dracaufeu", "0006")]
        case .electric: [("Pichu", "0172"), ("Pikachu", "0025"), ("Raichu", "0026")]
        case .grass: [("Bulbizarre", "0001"), ("Herbizarre", "0002"), ("Florizarre", "0003")]
        case .water: [("Carapuce", "0007"), ("Carabaffe", "0008"), ("Tortank", "0009")]
        case .cyndaquil: [("Héricendre", "0155"), ("Feurisson", "0156"), ("Typhlosion", "0157")]
        case .totodile: [("Kaiminus", "0158"), ("Crocrodil", "0159"), ("Aligatueur", "0160")]
        case .dragon: [("Minidraco", "0147"), ("Draco", "0148"), ("Dracolosse", "0149")]
        case .ghost: [("Fantominus", "0092"), ("Spectrum", "0093"), ("Ectoplasma", "0094")]
        case .rock: [("Embrylex", "0246"), ("Ymphect", "0247"), ("Tyranocif", "0248")]
        case .bagon: [("Draby", "0371"), ("Drackhaus", "0372"), ("Drattak", "0373")]
        }
        return trio.map { Species(name: $0.0, number: $0.1) }
    }

    public func species(at stage: Stage) -> Species {
        allSpecies[stage.rawValue - 1]
    }
}
