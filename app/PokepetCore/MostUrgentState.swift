import Foundation

/// What the companion shows, from least to most urgent.
public enum DisplayState: Int, Comparable, Sendable {
    case resting, done, working, failed, waiting

    public static func < (a: DisplayState, b: DisplayState) -> Bool { a.rawValue < b.rawValue }
}

/// Where a click can take you: the Desktop conversation, a background job to attach, or the terminal it runs in.
public enum ClickTarget: Equatable, Sendable {
    case desktop(String)
    case job(String)
    case terminal(TerminalApp)
}

/// The state to show, and the conversation to open on click if there is one.
public struct Urgency: Equatable, Sendable {
    public let display: DisplayState
    public let target: ClickTarget?

    public init(display: DisplayState, target: ClickTarget?) {
        self.display = display
        self.target = target
    }

    public static let resting = Urgency(display: .resting, target: nil)
}

public enum MostUrgentState {

    /// `terminalTracking` off: a waiting conversation that is not a Desktop one counts as working.
    public static func compute(_ sessions: [SessionState], terminalTracking: Bool = true) -> Urgency {
        let shown = sessions.map { (display: display(for: $0, terminalTracking: terminalTracking), session: $0) }
        guard let worst = shown.map(\.display).max() else { return .resting }
        guard worst == .waiting else { return Urgency(display: worst, target: nil) }
        let target = shown
            .filter { $0.display == .waiting }
            .max { $0.session.updatedAt < $1.session.updatedAt }
            .flatMap { target(of: $0.session) }
        return Urgency(display: .waiting, target: target)
    }

    /// The link first, then the job, then the terminal.
    static func target(of session: SessionState) -> ClickTarget? {
        if let link = session.link, isAccepted(link) { return .desktop(link) }
        if let job = session.job { return .job(job) }
        if let terminal = session.terminal { return .terminal(terminal) }
        return nil
    }

    /// Any program can write into ~/.pokepet: only this kind of link is ever opened.
    static func isAccepted(_ link: String) -> Bool {
        link.wholeMatch(of: /claude:\/\/code\/continue\?session=local_[A-Za-z0-9-]{1,64}/) != nil
    }

    static func display(for session: SessionState, terminalTracking: Bool) -> DisplayState {
        switch session.status {
        case .waiting:
            if terminalTracking { return .waiting }
            if case .desktop = target(of: session) { return .waiting }
            return .working
        case .failed: return .failed
        case .working: return .working
        case .done: return .done
        case .closed: return .resting
        }
    }
}
