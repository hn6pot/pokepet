import Foundation

/// Who started the conversation: the user (terminal or Desktop) or an automatic run (`claude -p`…).
public enum Origin: String, Codable, Sendable {
    case you
    case automatic
}

/// What one line of a Claude Code transcript (`~/.claude/projects/**/*.jsonl`) counts for.
public enum TranscriptEntry: Equatable, Sendable {
    /// A message the user typed.
    case typedMessage(uuid: String, date: Date, origin: Origin)
    /// One line of a Claude reply: a reply spans several lines sharing the same `messageID`.
    case reply(messageID: String, date: Date, origin: Origin, output: Int, cacheRead: Int)

    /// `nil` for anything else: tool results, system lines, unreadable lines.
    public static func parse(_ line: Data) -> TranscriptEntry? {
        guard let json = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
              let date = (json["timestamp"] as? String).flatMap(parseDate)
        else { return nil }
        let origin: Origin = ["cli", "claude-desktop"].contains(json["entrypoint"] as? String) ? .you : .automatic
        let message = json["message"] as? [String: Any]
        switch json["type"] as? String {
        case "user":
            guard json["isMeta"] as? Bool != true, json["isSidechain"] as? Bool != true,
                  let uuid = json["uuid"] as? String, isTyped(message?["content"])
            else { return nil }
            return .typedMessage(uuid: uuid, date: date, origin: origin)
        case "assistant":
            guard let id = message?["id"] as? String, let usage = message?["usage"] as? [String: Any] else { return nil }
            return .reply(
                messageID: id, date: date, origin: origin,
                output: usage["output_tokens"] as? Int ?? 0, cacheRead: usage["cache_read_input_tokens"] as? Int ?? 0)
        default:
            return nil
        }
    }

    /// Typed text: not a tool result, and not a system wrapper (`<command-name>`, `<system-reminder>`…).
    private static func isTyped(_ content: Any?) -> Bool {
        if let text = content as? String { return !text.hasPrefix("<") }
        guard let blocks = content as? [[String: Any]] else { return false }
        if blocks.contains(where: { $0["type"] as? String == "tool_result" }) { return false }
        return blocks.contains { $0["type"] as? String == "text" && !(($0["text"] as? String) ?? "<").hasPrefix("<") }
    }

    private static func parseDate(_ text: String) -> Date? {
        let withFractions = ISO8601DateFormatter()
        withFractions.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFractions.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }
}
