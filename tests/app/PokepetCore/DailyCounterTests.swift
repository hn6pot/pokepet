import Foundation
import Testing
@testable import PokepetCore

@Test("additionne les conversations")
func addsUpTheConversations() {
    let files = [#"{"reponses":5}"#, #"{"reponses":4}"#].map { Data($0.utf8) }
    #expect(DailyCounter.total(files) == 9)
}

@Test("sans fichier, c'est zéro")
func noFileIsZero() {
    #expect(DailyCounter.total([]) == 0)
}

@Test("un fichier cassé ou négatif compte zéro")
func brokenOrNegativeFileCountsZero() {
    let files = ["{", #"{"reponses":-4}"#, #"{"reponses":3}"#].map { Data($0.utf8) }
    #expect(DailyCounter.total(files) == 3)
}
