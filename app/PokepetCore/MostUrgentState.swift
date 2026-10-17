import Foundation

/// What the companion shows, from least to most urgent.
public enum DisplayState: Int, Comparable, Sendable {
    case resting, done, working, failed, waiting

    public static func < (a: DisplayState, b: DisplayState) -> Bool { a.rawValue < b.rawValue }
}

/// The state to show, and the conversation to open on click if there is one.
public struct Urgency: Equatable, Sendable {
    public let display: DisplayState
    public let link: String?

    public init(display: DisplayState, link: String?) {
        self.display = display
        self.link = link
    }

    public static let resting = Urgency(display: .resting, link: nil)
}

public enum MostUrgentState {

    public static func compute(_ sessions: [SessionState]) -> Urgency {
        guard let worst = sessions.map({ display(for: $0.status) }).max() else { return .resting }
        guard worst == .waiting else { return Urgency(display: worst, link: nil) }
        let link = sessions
            .filter { $0.status == .waiting && $0.link.map(isAccepted) == true }
            .max { $0.updatedAt < $1.updatedAt }?
            .link
        return Urgency(display: .waiting, link: link)
    }

    /// Any program can write into ~/.pokepet: only this kind of link is ever opened.
    static func isAccepted(_ link: String) -> Bool {
        link.wholeMatch(of: /claude:\/\/code\/continue\?session=local_[A-Za-z0-9-]{1,64}/) != nil
    }

    static func display(for status: SessionStatus) -> DisplayState {
        switch status {
        case .waiting: .waiting
        case .failed: .failed
        case .working: .working
        case .done: .done
        case .closed: .resting
        }
    }
}
