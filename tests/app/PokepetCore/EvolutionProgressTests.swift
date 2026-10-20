import Testing
@testable import PokepetCore

@Test("bébé : réponses avant le stade 2")
func baby() {
    #expect(EvolutionProgress(lineage: .dragon, responses: 14)
        == EvolutionProgress(stageName: "Bébé", detail: "14 / 30 réponses avant Draco", fraction: 14.0 / 30))
}

@Test("stade 2 : réponses avant le stade final")
func stageTwo() {
    #expect(EvolutionProgress(lineage: .dragon, responses: 42)
        == EvolutionProgress(stageName: "Stade 2", detail: "42 / 80 réponses avant Dracolosse", fraction: 42.0 / 80))
}

@Test("stade final : barre pleine", arguments: [80, 95])
func finalStage(responses: Int) {
    #expect(EvolutionProgress(lineage: .fire, responses: responses)
        == EvolutionProgress(stageName: "Stade final", detail: "\(responses) réponses", fraction: 1))
}
