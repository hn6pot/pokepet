import Testing
@testable import PokepetCore

@Test("le stade suit les seuils", arguments: [(0, Stage.one), (29, .one), (30, .two), (79, .two), (80, .three), (200, .three)])
func stageFollowsTheThresholds(responses: Int, expected: Stage) {
    #expect(Stage(responses: responses) == expected)
}

@Test("un nombre négatif reste au premier stade")
func aNegativeNumberStaysAtTheFirstStage() {
    #expect(Stage(responses: -3) == .one)
}
