import Foundation
import Testing
@testable import PokepetCore

private let t0 = Date(timeIntervalSince1970: 1_792_072_931)
private let linkA = "claude://code/continue?session=local_aaaa"
private let linkB = "claude://code/continue?session=local_bbbb"

private func s(
    _ status: SessionStatus, _ offset: TimeInterval = 0, link: String? = nil, job: String? = nil, terminal: TerminalApp? = nil
) -> SessionState {
    SessionState(status: status, updatedAt: t0.addingTimeInterval(offset), pid: 1, link: link, job: job, terminal: terminal)
}

@Test("sans session, c'est le repos")
func noSessionMeansResting() {
    #expect(MostUrgentState.compute([]) == .resting)
}

@Test("l'ordre d'urgence est respecté", arguments: [
    ([SessionStatus.done, .working], DisplayState.working),
    ([.working, .failed], .failed),
    ([.failed, .waiting, .done], .waiting),
    ([.done], .done),
    ([.closed], .resting),
])
func urgencyOrderIsRespected(statuses: [SessionStatus], expected: DisplayState) {
    #expect(MostUrgentState.compute(statuses.map { s($0) }).display == expected)
}

@Test("le lien vient de la session qui attend")
func linkComesFromTheWaitingSession() {
    let u = MostUrgentState.compute([s(.working, link: linkA), s(.waiting, link: linkB)])
    #expect(u == Urgency(display: .waiting, target: .desktop(linkB)))
}

@Test("entre plusieurs attentes, la plus récente gagne, quelle que soit sa cible")
func betweenSeveralWaitsTheMostRecentWins() {
    let u = MostUrgentState.compute([s(.waiting, 10, link: linkA), s(.waiting, 30, job: "c5adc286"), s(.waiting, 20, terminal: .iterm)])
    #expect(u.target == .job("c5adc286"))
    #expect(MostUrgentState.compute([s(.waiting, 10, job: "c5adc286"), s(.waiting, 20)]).target == nil)
}

@Test("la cible se lit dans l'ordre lien, job, terminal")
func theLinkWinsOverTheJob() {
    #expect(MostUrgentState.target(of: s(.waiting, link: linkA, job: "c5adc286", terminal: .iterm)) == .desktop(linkA))
    #expect(MostUrgentState.target(of: s(.waiting, link: "https://exemple.com", job: "c5adc286", terminal: .iterm)) == .job("c5adc286"))
    #expect(MostUrgentState.target(of: s(.waiting, terminal: .terminal)) == .terminal(.terminal))
}

@Test("une attente sans cible donne une cible vide")
func aWaitWithoutTargetGivesNoTarget() {
    #expect(MostUrgentState.compute([s(.waiting)]).target == nil)
}

@Test("un lien de forme inattendue n'est jamais ouvert", arguments: [
    "https://exemple.com",
    "claude://code/continue?session=00000000-0000-4000-8000-000000000001",
    "claude://code/continue?session=local_x&autre=1",
    "claude://code/new?q=rm",
])
func unexpectedLinkIsNeverOpened(link: String) {
    #expect(MostUrgentState.compute([s(.waiting, link: link)]).target == nil)
}

@Test("suivi désactivé : une attente terminal compte comme travail")
func withTrackingOffATerminalWaitCountsAsWork() {
    #expect(MostUrgentState.compute([s(.waiting, job: "c5adc286")], terminalTracking: false) == Urgency(display: .working, target: nil))
    #expect(MostUrgentState.compute([s(.waiting, terminal: .iterm)], terminalTracking: false).display == .working)
    #expect(MostUrgentState.compute([s(.waiting)], terminalTracking: false).display == .working)
}

@Test("suivi désactivé : une attente Desktop garde sa bulle")
func withTrackingOffADesktopWaitStillWins() {
    let u = MostUrgentState.compute([s(.waiting, 10, link: linkA), s(.waiting, 20, job: "c5adc286")], terminalTracking: false)
    #expect(u == Urgency(display: .waiting, target: .desktop(linkA)))
}
