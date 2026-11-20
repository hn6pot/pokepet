import Foundation
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

// Shoot and Strike are not universal: Pichu has no Shoot, and eight Pokémon have QuickStrike or MultiStrike instead of Strike.
@Test("chaque Pokémon a les attaques communes", arguments: everySpecies)
func everyPokemonHasTheCommonAttacks(species: Species) {
    let source = PMDSprites(directory: spritesDirectory)
    for movement in [Movement.attack, .charge] {
        #expect(source.animation(movement, species: species, direction: .front) != nil, "\(species.name) : \(movement.rawValue)")
    }
}

@Test("chaque lignée a son attaque propre", arguments: [
    (Lineage.electric, Movement.shock), (.ghost, .lick), (.water, .withdraw), (.magikarp, .spAttack),
    (.grass, .dance), (.fire, .kick), (.bagon, .rumble),
])
func everyLineageHasItsSignatureAttack(lineage: Lineage, movement: Movement) {
    let source = PMDSprites(directory: spritesDirectory)
    let baby = lineage.allSpecies[0]
    #expect(source.animation(movement, species: baby, direction: .front) != nil, "\(baby.name) : \(movement.rawValue)")
}

// Rotate, Hop and Hurt mean "done", "waiting" and "failed": a gesture that copies one of them would be a false signal.
@Test("aucun geste ne rejoue une animation de signal", arguments: everySpecies)
func noGestureReplaysASignalAnimation(species: Species) throws {
    let data = try Data(contentsOf: spritesDirectory.appending(path: "\(species.number)/AnimData.xml"))
    let animations = AnimData.parse(data)
    for gesture in Movement.gestures {
        guard let pmd = animations[gesture.rawValue] else { continue }
        #expect(!["Rotate", "Hop", "Hurt"].contains(pmd.sheet), "\(species.name) : \(gesture.rawValue) rejoue \(pmd.sheet)")
    }
}
