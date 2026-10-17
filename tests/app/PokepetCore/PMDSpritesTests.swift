import Testing
@testable import PokepetCore

private let everySpecies = Lineage.allCases.flatMap(\.allSpecies)

@Test("chaque Pokémon a les mouvements essentiels", arguments: everySpecies)
func everyPokemonHasTheEssentialMovements(species: Species) {
    let source = PMDSprites(directory: spritesDirectory)
    for movement in Movement.essentials {
        let animation = source.animation(movement, species: species, direction: .front)
        #expect(animation != nil, "\(species.name) : \(movement.rawValue)")
        #expect(animation?.images.count == animation?.durations.count)
    }
}

@Test("chaque Pokémon a au moins un geste", arguments: everySpecies)
func everyPokemonHasAtLeastOneGesture(species: Species) {
    let source = PMDSprites(directory: spritesDirectory)
    #expect(Movement.gestures.contains { source.animation($0, species: species, direction: .front) != nil }, "\(species.name)")
}

@Test("les images ont la taille d'une case")
func imagesHaveTheSizeOfAFrame() throws {
    let idle = try #require(PMDSprites(directory: spritesDirectory).animation(.idle, species: Lineage.fire.allSpecies[0], direction: .front))
    #expect(idle.images.allSatisfy { $0.width == 32 && $0.height == 40 })
}

@Test("le sommeil n'a qu'une ligne et marche dans toutes les directions")
func sleepHasOneRowAndWorksInEveryDirection() {
    let source = PMDSprites(directory: spritesDirectory)
    #expect(source.animation(.sleep, species: Lineage.fire.allSpecies[0], direction: .left) != nil)
}

@Test("un Pokémon inconnu n'a ni animation ni repos")
func unknownPokemonHasNoAnimationAndNoIdle() {
    let source = PMDSprites(directory: spritesDirectory)
    #expect(source.animationOrIdle(.hop, species: Species(name: "?", number: "9999"), direction: .front) == nil)
}
