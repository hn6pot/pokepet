import Foundation
import Testing
@testable import PokepetCore

private let t0 = Date(timeIntervalSince1970: 1_792_072_931)
private let linkA = "claude://code/continue?session=local_aaaa"
private let linkB = "claude://code/continue?session=local_bbbb"

private func s(_ status: SessionStatus, _ offset: TimeInterval = 0, link: String? = nil) -> SessionState {
    SessionState(status: status, updatedAt: t0.addingTimeInterval(offset), pid: 1, link: link)
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
    #expect(u == Urgency(display: .waiting, link: linkB))
}

@Test("entre deux attentes, on prend la plus récente qui a un lien")
func betweenTwoWaitsTheMostRecentWithALinkWins() {
    let u = MostUrgentState.compute([s(.waiting, 10, link: linkA), s(.waiting, 20, link: linkB), s(.waiting, 30)])
    #expect(u.link == linkB)
}

@Test("une attente sans lien donne un lien vide")
func aWaitWithoutLinkGivesNoLink() {
    #expect(MostUrgentState.compute([s(.waiting)]).link == nil)
}

@Test("un lien de forme inattendue n'est jamais ouvert", arguments: [
    "https://exemple.com",
    "claude://code/continue?session=00000000-0000-4000-8000-000000000001",
    "claude://code/continue?session=local_x&autre=1",
    "claude://code/new?q=rm",
])
func unexpectedLinkIsNeverOpened(link: String) {
    #expect(MostUrgentState.compute([s(.waiting, link: link)]).link == nil)
}
