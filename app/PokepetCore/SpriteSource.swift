import CoreGraphics

/// The movements the companion knows, named after the PMD animations.
public enum Movement: String, CaseIterable, Sendable {
    case idle = "Idle", walk = "Walk", hop = "Hop", rotate = "Rotate", hurt = "Hurt", sleep = "Sleep"
    case nod = "Nod", pose = "Pose", lookUp = "LookUp", deepBreath = "DeepBreath", sit = "Sit", swing = "Swing"

    /// Those every Pokémon has.
    public static let essentials: [Movement] = [.idle, .walk, .hop, .rotate, .hurt, .sleep]
    /// The small gestures it makes while working; each Pokémon has some of them (Dracaufeu: Swing).
    public static let gestures: [Movement] = [.nod, .pose, .lookUp, .deepBreath, .sit, .swing]
}

/// The directions used: the rows of a PMD sheet go in this order
/// (down, down-right, right, up-right, up, up-left, left, down-left).
public enum Direction: Int, Sendable {
    case front = 0
    case right = 2
    case left = 6
}

/// An animation ready to draw: its frames and their durations (1/60 s).
public struct LoadedAnimation {
    public let images: [CGImage]
    public let durations: [Int]

    public init(images: [CGImage], durations: [Int]) {
        self.images = images
        self.durations = durations
    }
}

/// The contract of a sprite source. The app only knows this: switching sources
/// (PMD today, something else tomorrow) does not touch the rest.
public protocol SpriteSource: AnyObject {
    /// `nil` if this Pokémon does not have this animation.
    func animation(_ movement: Movement, species: Species, direction: Direction) -> LoadedAnimation?
}

extension SpriteSource {
    /// The requested animation, or else the idle one (`Idle`).
    public func animationOrIdle(_ movement: Movement, species: Species, direction: Direction) -> LoadedAnimation? {
        animation(movement, species: species, direction: direction)
            ?? animation(.idle, species: species, direction: .front)
    }
}
