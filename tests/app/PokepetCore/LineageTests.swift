import Testing
@testable import PokepetCore

@Test("la lignée feu va de Salamèche à Dracaufeu")
func fireLineageGoesFromCharmanderToCharizard() {
    #expect(Lineage.fire.allSpecies.map(\.name) == ["Salamèche", "Reptincel", "Dracaufeu"])
    #expect(Lineage.fire.allSpecies.map(\.number) == ["0004", "0005", "0006"])
}

@Test("la lignée électrik va de Pichu à Raichu")
func electricLineageGoesFromPichuToRaichu() {
    #expect(Lineage.electric.allSpecies.map(\.name) == ["Pichu", "Pikachu", "Raichu"])
    #expect(Lineage.electric.allSpecies.map(\.number) == ["0172", "0025", "0026"])
}

@Test("chaque stade donne son espèce")
func eachStageGivesItsSpecies() {
    #expect(Lineage.fire.species(at: .one).name == "Salamèche")
    #expect(Lineage.electric.species(at: .three).name == "Raichu")
}

@Test("il y a dix lignées de trois Pokémon")
func thereAreTenLineagesOfThreePokemon() {
    let expected: [Lineage: [String]] = [
        .fire: ["Salamèche", "Reptincel", "Dracaufeu"],
        .electric: ["Pichu", "Pikachu", "Raichu"],
        .grass: ["Bulbizarre", "Herbizarre", "Florizarre"],
        .water: ["Carapuce", "Carabaffe", "Tortank"],
        .cyndaquil: ["Héricendre", "Feurisson", "Typhlosion"],
        .totodile: ["Kaiminus", "Crocrodil", "Aligatueur"],
        .dragon: ["Minidraco", "Draco", "Dracolosse"],
        .ghost: ["Fantominus", "Spectrum", "Ectoplasma"],
        .rock: ["Embrylex", "Ymphect", "Tyranocif"],
        .bagon: ["Draby", "Drackhaus", "Drattak"],
    ]
    #expect(Lineage.allCases.count == 10)
    for lineage in Lineage.allCases {
        #expect(lineage.allSpecies.map(\.name) == expected[lineage], "\(lineage)")
    }
}

@Test("les numéros sont ceux de SpriteCollab")
func numbersAreSpriteCollabs() {
    #expect(Lineage.dragon.allSpecies.map(\.number) == ["0147", "0148", "0149"])
    #expect(Lineage.rock.allSpecies.map(\.number) == ["0246", "0247", "0248"])
    #expect(Set(Lineage.allCases.flatMap(\.allSpecies).map(\.number)).count == 30)
}

@Test("les valeurs enregistrées des lignées ne changent pas")
func storedLineageValuesDoNotChange() {
    // Stored in the preferences (« Un autre Pokémon ») and ordered for the daily draw: both must stay put.
    #expect(Lineage.allCases.map(\.rawValue) == [
        "feu", "electrik", "plante", "eau", "hericendre", "kaiminus", "dragon", "spectre", "roche", "draby",
    ])
}
