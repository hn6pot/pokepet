import CoreGraphics
import Foundation

/// One walking step: a horizontal offset (0 = a pause) and its duration.
public struct Step: Equatable, Sendable {
    public let offset: CGFloat
    public let duration: TimeInterval
}

/// Picks a walking step, left or right, without leaving the bounds. The pauses between two steps
/// come from the `Rhythm`.
public enum Stroll {
    /// Points per second.
    public static let speed: CGFloat = 30

    /// `x`: the current position; `minimum`/`maximum`: the screen bounds for the window.
    public static func nextStep(
        x: CGFloat, minimum: CGFloat, maximum: CGFloat, using generator: inout some RandomNumberGenerator
    ) -> Step {
        var distance = CGFloat.random(in: 20...80, using: &generator) * (Bool.random(using: &generator) ? 1 : -1)
        if x + distance > maximum || x + distance < minimum { distance = -distance }
        let arrival = min(max(x + distance, minimum), maximum)
        let offset = arrival - x
        return Step(offset: offset, duration: TimeInterval(abs(offset) / speed))
    }
}
