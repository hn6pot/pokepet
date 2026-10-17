import Foundation

/// What the companion does from time to time: a few steps, a small gesture, or a hop to remind that it is waiting.
public enum Action: Equatable, Sendable {
    case walk
    case gesture(Movement)
    case hop
}

/// The pace of the actions, so that it lives without fidgeting: spaced out while Claude works, rare at rest,
/// a reminder hop while a conversation is waiting, nothing while it sleeps.
public enum Rhythm {
    public static let working: ClosedRange<TimeInterval> = 15...30
    public static let resting: ClosedRange<TimeInterval> = 45...90
    public static let reminder: TimeInterval = 20

    /// The time before the next action; `nil` while it sleeps.
    public static func delay(_ display: DisplayState, asleep: Bool, using generator: inout some RandomNumberGenerator) -> TimeInterval? {
        guard !asleep else { return nil }
        return switch display {
        case .waiting: reminder
        case .working: TimeInterval.random(in: working, using: &generator)
        case .resting, .done, .failed: TimeInterval.random(in: resting, using: &generator)
        }
    }

    /// The action to do now. `gestures`: those this Pokémon knows how to do.
    public static func action(
        _ display: DisplayState, asleep: Bool, gestures: [Movement], using generator: inout some RandomNumberGenerator
    ) -> Action? {
        guard !asleep else { return nil }
        switch display {
        case .waiting:
            return .hop
        case .working:
            // One third walks, two thirds gestures, at random.
            guard !gestures.isEmpty, Int.random(in: 0..<3, using: &generator) > 0 else { return .walk }
            return .gesture(gestures.randomElement(using: &generator)!)
        case .resting, .done, .failed:
            return .walk
        }
    }
}
