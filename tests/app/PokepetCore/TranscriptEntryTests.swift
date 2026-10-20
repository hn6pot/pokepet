import Foundation
import Testing
@testable import PokepetCore

private func entry(_ json: String) -> TranscriptEntry? { TranscriptEntry.parse(Data(json.utf8)) }
private func at(_ iso: String) -> Date {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.date(from: iso)!
}

@Test("un message tapé dans Desktop compte pour toi")
func typedDesktopMessage() {
    #expect(entry(#"{"type":"user","uuid":"u1","timestamp":"2026-10-20T13:42:00.123Z","entrypoint":"claude-desktop","message":{"role":"user","content":"salut"}}"#)
        == .typedMessage(uuid: "u1", date: at("2026-10-20T13:42:00.123Z"), origin: .you))
}

@Test("un message tapé en blocs, avec une image, compte aussi")
func typedMessageWithBlocks() {
    #expect(entry(#"{"type":"user","uuid":"u2","timestamp":"2026-10-20T13:42:00.123Z","entrypoint":"cli","message":{"role":"user","content":[{"type":"text","text":"regarde"},{"type":"image","source":{}}]}}"#)
        == .typedMessage(uuid: "u2", date: at("2026-10-20T13:42:00.123Z"), origin: .you))
}

@Test("claude -p, ou pas d'entrypoint : automatique", arguments: [#","entrypoint":"sdk-cli""#, ""])
func automaticOrigin(entrypointField: String) {
    let line = #"{"type":"user","uuid":"u3","timestamp":"2026-10-20T13:42:00.123Z""# + entrypointField + #","message":{"content":"tri du soir"}}"#
    #expect(entry(line) == .typedMessage(uuid: "u3", date: at("2026-10-20T13:42:00.123Z"), origin: .automatic))
}

@Test("ne sont pas des messages tapés", arguments: [
    #"{"type":"user","uuid":"a","timestamp":"2026-10-20T13:42:00.123Z","entrypoint":"cli","message":{"content":[{"type":"tool_result","tool_use_id":"t","content":"ok"}]}}"#,
    #"{"type":"user","uuid":"b","timestamp":"2026-10-20T13:42:00.123Z","entrypoint":"cli","isMeta":true,"message":{"content":"Base directory for this skill"}}"#,
    #"{"type":"user","uuid":"c","timestamp":"2026-10-20T13:42:00.123Z","entrypoint":"cli","isSidechain":true,"message":{"content":"Explore le dépôt"}}"#,
    #"{"type":"user","uuid":"d","timestamp":"2026-10-20T13:42:00.123Z","entrypoint":"cli","message":{"content":"<command-name>/clear</command-name>"}}"#,
    #"{"type":"user","uuid":"e","timestamp":"2026-10-20T13:42:00.123Z","entrypoint":"cli","message":{"content":[{"type":"text","text":"<system-reminder>x</system-reminder>"}]}}"#,
    #"{"type":"user","uuid":"g","timestamp":"2026-10-20T13:42:00.123Z","entrypoint":"cli","message":{"content":[{"type":"text","text":"[Request interrupted by user]"}]}}"#,
    #"{"type":"user","uuid":"h","timestamp":"2026-10-20T13:42:00.123Z","entrypoint":"cli","isCompactSummary":true,"message":{"content":"This session is being continued from a previous conversation."}}"#,
])
func notTypedMessages(line: String) {
    #expect(entry(line) == nil)
}

@Test("une réponse donne ses tokens générés et relus")
func replyTokens() {
    #expect(entry(#"{"type":"assistant","uuid":"r","timestamp":"2026-10-20T13:43:00.000Z","entrypoint":"claude-desktop","message":{"id":"msg_1","usage":{"input_tokens":3,"output_tokens":511,"cache_read_input_tokens":9000,"cache_creation_input_tokens":40}}}"#)
        == .reply(messageID: "msg_1", date: at("2026-10-20T13:43:00.000Z"), origin: .you, output: 511, cacheRead: 9000))
}

@Test("la réponse d'un sous-agent compte, avec l'origine de sa conversation")
func subagentReply() {
    #expect(entry(#"{"type":"assistant","isSidechain":true,"timestamp":"2026-10-20T13:43:00.000Z","entrypoint":"cli","message":{"id":"msg_2","usage":{"output_tokens":7}}}"#)
        == .reply(messageID: "msg_2", date: at("2026-10-20T13:43:00.000Z"), origin: .you, output: 7, cacheRead: 0))
}

@Test("une ligne illisible ou d'un autre genre est ignorée", arguments: [
    "", "{", #"{"type":"attachment"}"#,
    #"{"type":"assistant","timestamp":"2026-10-20T13:43:00.000Z","message":{"id":"msg_3"}}"#,
    #"{"type":"user","uuid":"f","entrypoint":"cli","message":{"content":"sans date"}}"#,
])
func ignoredLines(line: String) {
    #expect(entry(line) == nil)
}
