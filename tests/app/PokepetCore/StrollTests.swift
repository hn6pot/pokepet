import CoreGraphics
import Testing
@testable import PokepetCore

/// A reproducible random generator (SplitMix64), for tests that always give the same result.
struct FixedRandom: RandomNumberGenerator {
    nonisolated(unsafe) static var example = FixedRandom(state: 42)
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@Test("on ne sort jamais des bornes")
func neverLeavesTheBounds() {
    var generator = FixedRandom(state: 1)
    var x: CGFloat = 50
    for _ in 0..<1000 {
        let step = Stroll.nextStep(x: x, home: 50, minimum: 0, maximum: 100, using: &generator)
        x += step.offset
        #expect((0...100).contains(x))
    }
}

@Test("chaque pas avance vraiment")
func everyStepReallyMoves() {
    // The pauses now come from the Rhythm: a walking step always moves.
    var generator = FixedRandom(state: 7)
    let steps = (0..<200).map { _ in Stroll.nextStep(x: 500, home: 500, minimum: 0, maximum: 1000, using: &generator) }
    #expect(steps.allSatisfy { (20...80).contains(abs($0.offset)) })
    #expect(steps.contains { $0.offset > 0 } && steps.contains { $0.offset < 0 })
    #expect(steps.allSatisfy { abs($0.duration - Double(abs($0.offset) / Stroll.speed)) < 0.0001 })
}

@Test("une borne étroite donne des pas courts")
func narrowBoundsGiveShortSteps() {
    var generator = FixedRandom(state: 9)
    for _ in 0..<100 {
        let step = Stroll.nextStep(x: 5, home: 5, minimum: 0, maximum: 10, using: &generator)
        #expect((0...10).contains(5 + step.offset))
    }
}

@Test("une promenade est un aller-retour : il revient exactement à sa place")
func everyStrollGoesThereAndBack() {
    var generator = FixedRandom(state: 3)
    for _ in 0..<100 {
        let there = Stroll.nextStep(x: 500, home: 500, minimum: 0, maximum: 1000, using: &generator)
        #expect((20...80).contains(abs(there.offset)))
        let back = Stroll.nextStep(x: 500 + there.offset, home: 500, minimum: 0, maximum: 1000, using: &generator)
        #expect(back.offset == -there.offset)
        #expect(abs(back.duration - Double(abs(back.offset) / Stroll.speed)) < 0.0001)
    }
}

@Test("loin de sa place, il y retourne en un pas")
func awayFromHomeItGoesStraightBack() {
    var generator = FixedRandom(state: 5)
    #expect(Stroll.nextStep(x: 300, home: 520, minimum: 0, maximum: 1000, using: &generator).offset == 220)
}


@Test("il retourne à sa place même si sa fenêtre y dépasse un peu de l'écran")
func itGoesBackHomeEvenPastTheWindowBounds() {
    // The default spot puts the sprite near the edge, so its wider window pokes out past `maximum`.
    var generator = FixedRandom(state: 8)
    #expect(Stroll.nextStep(x: 1491, home: 1553, minimum: 0, maximum: 1512, using: &generator).offset == 62)
}
