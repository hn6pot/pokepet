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

@Test("lit le job et le terminal écrits par le mod")
func readsTheJobAndTheTerminalWrittenByTheMod() throws {
    // The same texts as in the mod's test (tests/mod/hooks/state.test.ts).
    let job = try #require(SessionState.decode(Data(#"{"etat":"attend","majLe":"2026-11-03T14:13:34Z","pid":87344,"job":"c5adc286"}"#.utf8)))
    #expect(job.job == "c5adc286" && job.terminal == nil && job.link == nil)
    let term = try #require(SessionState.decode(Data(#"{"etat":"attend","majLe":"2026-11-04T09:00:00Z","pid":12345,"terminal":"iTerm.app"}"#.utf8)))
    #expect(term.terminal == .iterm && term.job == nil)
}

@Test("les nouveaux champs sont facultatifs")
func theNewFieldsAreOptional() throws {
    let s = try #require(SessionState.decode(Data(#"{"etat":"fini","majLe":"2026-10-15T14:02:11Z","pid":1}"#.utf8)))
    #expect(s.job == nil && s.terminal == nil)
}

@Test("un job ou un terminal d'une autre forme est ignoré, le fichier reste lu", arguments: [
    #""job":"../x""#, #""job":"c5adc286; rm -rf ~""#, #""job":"C5ADC286""#, #""job":7"#, #""terminal":"vscode""#, #""terminal":3"#,
])
func aMalformedJobOrTerminalIsIgnored(field: String) throws {
    let text = #"{"etat":"attend","majLe":"2026-10-15T14:02:11Z","pid":1,"# + field + "}"
    let s = try #require(SessionState.decode(Data(text.utf8)))
    #expect(s.status == .waiting && s.job == nil && s.terminal == nil)
}
