import Foundation

/// An animation played a few times before going back to the base animation.
public struct Interlude: Equatable, Sendable {
    public let movement: Movement
    public let times: Int

    public init(movement: Movement, times: Int) {
        self.movement = movement
        self.times = times
    }
}

/// What the app must show at a given moment.
public struct Appearance: Equatable, Sendable {
    /// The displayed state, which the `Rhythm` reads to pick actions.
    public let display: DisplayState
    /// The lineage of the day: drawn, or picked with « Un autre Pokémon ».
    public let lineage: Lineage
    public let species: Species
    public let stage: Stage
    public let responses: Int
    /// The base animation, played in a loop.
    public let base: Movement
    /// Played when the state changes: `Rotate` when finishing, `Hurt` when failing, three hops when starting to wait.
    public let interlude: Interlude?
    /// The white flash of an evolution or of a new baby.
    public let flash: Bool
    /// The « ! » bubble when a conversation is waiting.
    public let bubble: Bool
    /// True while it sleeps: it no longer does any action.
    public let asleep: Bool
    /// The conversation to open on click.
    public let link: String?
}

/// The "brain": from the time, the most urgent state and the daily counter,
/// decides which Pokémon to show and how. Called once per second.
public struct Companion: Sendable {
    public static let sleepDelay: TimeInterval = 15 * 60

    private let launchDate: Date
    private var previous: (display: DisplayState, species: Species)?

    public init(launchDate: Date) {
        self.launchDate = launchDate
    }

    /// `lastActivity`: the most recent update (`updatedAt`) among the kept sessions;
    /// `choice`: the lineage picked with « Un autre Pokémon », used only if it belongs to this day.
    public mutating func update(
        now: Date, urgency: Urgency, responses: Int, lastActivity: Date?, choice: DailyChoice? = nil,
        calendar: Calendar = .current
    ) -> Appearance {
        let day = PokepetDay.key(now, calendar: calendar)
        let todaysChoice = choice?.day == day ? choice : nil
        let lineage = todaysChoice?.lineage ?? DailyDraw.lineage(for: day)
        // A Pokémon picked with « Un autre Pokémon » starts from zero.
        let responses = max(0, responses - (todaysChoice?.startResponses ?? 0))
        let stage = Stage(responses: responses)
        let species = lineage.species(at: stage)
        let display = urgency.display

        var interlude: Interlude?
        var flash = false
        if let previous {
            flash = previous.species != species
            if previous.display != display {
                interlude = switch display {
                case .done: Interlude(movement: .rotate, times: 1)
                case .failed: Interlude(movement: .hurt, times: 1)
                case .waiting: Interlude(movement: .hop, times: 3)
                case .resting, .working: nil
                }
            }
        }
        previous = (display, species)

        let resting = [.resting, .done, .failed].contains(display)
        let since = max(lastActivity ?? launchDate, launchDate)
        let asleep = resting && now.timeIntervalSince(since) > Self.sleepDelay
        // Calm on the spot; the Rhythm makes it do actions from time to time.
        let base: Movement = asleep ? .sleep : .idle

        return Appearance(
            display: display, lineage: lineage, species: species, stage: stage, responses: responses, base: base, interlude: interlude,
            flash: flash, bubble: display == .waiting, asleep: asleep, link: urgency.link)
    }
}
