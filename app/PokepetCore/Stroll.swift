import CoreGraphics
import Foundation

/// One walking step: a horizontal offset (0 = a pause) and its duration.
public struct Step: Equatable, Sendable {
    public let offset: CGFloat
    public let duration: TimeInterval
}

/// Picks a walking step: every stroll is a round trip. From its place, the pet walks 20 to 80 points
/// left or right without leaving the bounds; the next step brings it exactly back. The pauses between
/// two steps come from the `Rhythm`.
public enum Stroll {
    /// Points per second.
    public static let speed: CGFloat = 30

    /// `x`: the current position; `home`: its place (where it was put); `minimum`/`maximum`: the screen
    /// bounds for the window.
    public static func nextStep(
        x: CGFloat, home: CGFloat, minimum: CGFloat, maximum: CGFloat, using generator: inout some RandomNumberGenerator
    ) -> Step {
        if abs(x - home) >= 0.5 {
            // Back exactly to its place, even if the window pokes out there a little: the place was chosen.
            let offset = home - x
            return Step(offset: offset, duration: TimeInterval(abs(offset) / speed))
        }
        var distance = CGFloat.random(in: 20...80, using: &generator) * (Bool.random(using: &generator) ? 1 : -1)
        if x + distance > maximum || x + distance < minimum { distance = -distance }
        let arrival = min(max(x + distance, minimum), maximum)
        let offset = arrival - x
        return Step(offset: offset, duration: TimeInterval(abs(offset) / speed))
    }
}
