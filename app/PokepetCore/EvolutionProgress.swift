/// The way to the next evolution, as shown at the top of the menu bar window:
/// « Bébé · 14 / 30 réponses avant Draco », and a bar.
public struct EvolutionProgress: Equatable, Sendable {
    public let stageName: String
    public let detail: String
    /// From 0 to 1, full at the final stage.
    public let fraction: Double

    init(stageName: String, detail: String, fraction: Double) {
        self.stageName = stageName
        self.detail = detail
        self.fraction = fraction
    }

    /// `responses`: the Pokémon's own count (reset by « Un autre Pokémon »).
    public init(lineage: Lineage, responses: Int) {
        let stage = Stage(responses: responses)
        let threshold: Int? = switch stage {
        case .one: Stage.twoThreshold
        case .two: Stage.threeThreshold
        case .three: nil
        }
        guard let threshold, let next = Stage(rawValue: stage.rawValue + 1) else {
            self.init(stageName: "Stade final", detail: "\(responses) réponses", fraction: 1)
            return
        }
        self.init(
            stageName: stage == .one ? "Bébé" : "Stade \(stage.rawValue)",
            detail: "\(responses) / \(threshold) réponses avant \(lineage.species(at: next).name)",
            fraction: Double(responses) / Double(threshold))
    }
}
