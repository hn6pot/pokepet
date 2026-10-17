import Foundation

/// The timing of an animation: which frame to show after a given time.
public struct FramePlayer: Sendable {
    /// In 1/60 of a second, one duration per frame.
    public let durations: [Int]
    public let looping: Bool

    public init(durations: [Int], looping: Bool) {
        self.durations = durations.map { max($0, 1) }
        self.looping = looping
    }

    private var total: Int { durations.reduce(0, +) }

    /// The index of the frame to show `elapsed` seconds after the start. An animation played once
    /// stays on its last frame.
    public func frame(after elapsed: TimeInterval) -> Int {
        guard !durations.isEmpty else { return 0 }
        var tick = Int(max(elapsed, 0) * 60)
        if looping {
            tick %= total
        } else if tick >= total {
            return durations.count - 1
        }
        for (index, duration) in durations.enumerated() {
            if tick < duration { return index }
            tick -= duration
        }
        return durations.count - 1
    }

    /// True once an animation played once has reached its end; never for a loop.
    public func isFinished(after elapsed: TimeInterval) -> Bool {
        !looping && Int(max(elapsed, 0) * 60) >= total
    }
}
