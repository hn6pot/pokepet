/// The evolution stage, derived from the number of Claude responses in the day.
public enum Stage: Int, Comparable, Sendable {
    case one = 1
    case two = 2
    case three = 3

    public static let twoThreshold = 30
    public static let threeThreshold = 80

    public init(responses: Int) {
        if responses >= Self.threeThreshold {
            self = .three
        } else if responses >= Self.twoThreshold {
            self = .two
        } else {
            self = .one
        }
    }

    public static func < (a: Stage, b: Stage) -> Bool { a.rawValue < b.rawValue }
}
