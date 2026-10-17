import Testing
@testable import PokepetCore

private let gestures: [Movement] = [.nod, .pose, .lookUp]

@Test("quand il travaille, une action toutes les 15 à 30 secondes")
func whileWorkingAnActionEvery15To30Seconds() {
    var generator = FixedRandom(state: 1)
    for _ in 0..<200 {
        let delay = Rhythm.delay(.working, asleep: false, using: &generator)
        #expect(delay.map { (15...30).contains($0) } == true)
    }
}

@Test("au repos, une promenade toutes les 45 à 90 secondes")
func atRestAWalkEvery45To90Seconds() {
    var generator = FixedRandom(state: 2)
    for display in [DisplayState.resting, .done, .failed] {
        let delay = Rhythm.delay(display, asleep: false, using: &generator)
        #expect(delay.map { (45...90).contains($0) } == true)
        #expect(Rhythm.action(display, asleep: false, gestures: gestures, using: &generator) == .walk)
    }
}

@Test("quand une conversation attend, un saut toutes les 20 secondes")
func whileAConversationWaitsAHopEvery20Seconds() {
    var generator = FixedRandom(state: 3)
    #expect(Rhythm.delay(.waiting, asleep: false, using: &generator) == 20)
    #expect(Rhythm.action(.waiting, asleep: false, gestures: gestures, using: &generator) == .hop)
}

@Test("quand il travaille, il marche ou fait un geste varié")
func whileWorkingItWalksOrMakesAVariedGesture() {
    var generator = FixedRandom(state: 4)
    let actions = (0..<300).compactMap { _ in Rhythm.action(.working, asleep: false, gestures: gestures, using: &generator) }
    #expect(actions.count == 300)
    #expect(actions.contains(.walk))
    #expect(Set(actions.compactMap { if case .gesture(let m) = $0 { m } else { nil } }) == Set(gestures))
}

@Test("sans geste, il marche")
func withoutGesturesItWalks() {
    var generator = FixedRandom(state: 5)
    for _ in 0..<50 {
        #expect(Rhythm.action(.working, asleep: false, gestures: [], using: &generator) == .walk)
    }
}

@Test("quand il dort, il ne fait rien")
func whileAsleepItDoesNothing() {
    var generator = FixedRandom(state: 6)
    #expect(Rhythm.delay(.resting, asleep: true, using: &generator) == nil)
    #expect(Rhythm.action(.resting, asleep: true, gestures: gestures, using: &generator) == nil)
}
