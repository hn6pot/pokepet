import Foundation
import Testing
@testable import PokepetCore

@Test("lit un fichier écrit par le mod")
func readsAFileWrittenByTheMod() throws {
    // The same text as in the mod's test (tests/mod/hooks/state.test.ts).
    let text = #"{"etat":"attend","majLe":"2026-10-15T14:02:11Z","pid":68387,"lien":"claude://code/continue?session=local_00000000-0000-4000-8000-000000000000"}"#
    let session = try #require(SessionState.decode(Data(text.utf8)))
    #expect(session.status == .waiting)
    #expect(session.pid == 68387)
    #expect(session.updatedAt == Date(timeIntervalSince1970: 1_792_072_931))
    #expect(session.link == "claude://code/continue?session=local_00000000-0000-4000-8000-000000000000")
}

@Test("le lien est facultatif")
func linkIsOptional() throws {
    let text = #"{"etat":"fini","majLe":"2026-10-15T14:02:11Z","pid":1}"#
    #expect(try #require(SessionState.decode(Data(text.utf8))).link == nil)
}

@Test("un fichier illisible donne nil", arguments: [
    "", "{", #"{"etat":"dort","majLe":"2026-10-15T14:02:11Z","pid":1}"#, #"{"etat":"fini","pid":1}"#,
])
func unreadableFileGivesNil(text: String) {
    #expect(SessionState.decode(Data(text.utf8)) == nil)
}
