import Testing
@testable import PokepetCore

@Test("les attaques sont des gestes")
func theAttacksAreGestures() {
    let attacks: [Movement] = [.attack, .charge, .shoot, .strike, .shock, .lick, .withdraw, .rumble,
                               .dance, .shake, .spAttack, .kick, .bite]
    for attack in attacks { #expect(Movement.gestures.contains(attack), "\(attack.rawValue)") }
    #expect(Movement.essentials == [.idle, .walk, .hop, .rotate, .hurt, .sleep])
    #expect(Set(Movement.gestures).isDisjoint(with: Movement.essentials))
}

@Test("les noms bruts sont ceux de SpriteCollab")
func theRawNamesAreSpriteCollabs() {
    #expect(Movement.spAttack.rawValue == "SpAttack")
    #expect(Movement.lookUp.rawValue == "LookUp")
}
