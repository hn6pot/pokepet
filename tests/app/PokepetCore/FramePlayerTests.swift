import Testing
@testable import PokepetCore

// Three frames: 10, 20 and 30 sixtieths of a second, 1 s in all.
private let loop = FramePlayer(durations: [10, 20, 30], looping: true)
private let once = FramePlayer(durations: [10, 20, 30], looping: false)

@Test("en boucle, on repart", arguments: [(0.0, 0), (0.16, 0), (0.17, 1), (0.49, 1), (0.5, 2), (0.99, 2), (1.0, 0), (1.2, 1)])
func loopingStartsOver(elapsed: Double, expected: Int) {
    #expect(loop.frame(after: elapsed) == expected)
}

@Test("une fois, on reste sur la dernière image")
func playedOnceStaysOnTheLastFrame() {
    #expect(once.frame(after: 5) == 2)
}

@Test("une fois, finit après sa durée totale")
func playedOnceFinishesAfterItsTotalDuration() {
    #expect(!once.isFinished(after: 0.99))
    #expect(once.isFinished(after: 1.0))
}

@Test("une boucle ne finit jamais")
func aLoopNeverFinishes() {
    #expect(!loop.isFinished(after: 100))
}

@Test("une durée nulle ne bloque pas")
func aZeroDurationDoesNotBlock() {
    #expect(FramePlayer(durations: [0, 0], looping: true).frame(after: 0.02) == 1)
}

@Test("sans image, on rend zéro")
func noFrameGivesZero() {
    #expect(FramePlayer(durations: [], looping: true).frame(after: 3) == 0)
}
