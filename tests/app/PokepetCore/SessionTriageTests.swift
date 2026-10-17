import Foundation
import Testing
@testable import PokepetCore

private let now = Date(timeIntervalSince1970: 1_792_072_931)
private func alive(_ pid: Int32) -> Bool { true }

private func session(_ status: SessionStatus, secondsAgo: TimeInterval, pid: Int32 = 1) -> SessionState {
    SessionState(status: status, updatedAt: now.addingTimeInterval(-secondsAgo), pid: pid)
}

@Test("une session récente est gardée")
func aRecentSessionIsKept() {
    #expect(SessionTriage.decide(session(.working, secondsAgo: 60), now: now, isPidAlive: alive) == .keep)
}

@Test("deux heures pile, c'est encore gardé")
func exactlyTwoHoursIsStillKept() {
    #expect(SessionTriage.decide(session(.done, secondsAgo: 7200), now: now, isPidAlive: alive) == .keep)
}

@Test("au-delà de deux heures, c'est ignoré")
func beyondTwoHoursIsIgnored() {
    #expect(SessionTriage.decide(session(.done, secondsAgo: 7201), now: now, isPidAlive: alive) == .ignore)
}

@Test("une session qui attend est gardée, même ancienne")
func aWaitingSessionIsKeptEvenIfOld() {
    #expect(SessionTriage.decide(session(.waiting, secondsAgo: 86_400), now: now, isPidAlive: alive) == .keep)
}

@Test("une session fermée est supprimée")
func aClosedSessionIsDeleted() {
    #expect(SessionTriage.decide(session(.closed, secondsAgo: 1), now: now, isPidAlive: alive) == .delete)
}

@Test("un processus mort fait supprimer, même en attente")
func aDeadProcessDeletesEvenWhileWaiting() {
    func dead(_ pid: Int32) -> Bool { pid != 42 }
    #expect(SessionTriage.decide(session(.waiting, secondsAgo: 1, pid: 42), now: now, isPidAlive: dead) == .delete)
}

@Test("un fichier illisible est ignoré sans être supprimé")
func anUnreadableFileIsIgnoredWithoutBeingDeleted() {
    #expect(SessionTriage.decide(nil, now: now, isPidAlive: alive) == .ignore)
}
