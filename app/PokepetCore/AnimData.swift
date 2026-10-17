import Foundation

/// A PMD animation: the PNG sheet that holds it, the size of one frame, the duration of each frame.
public struct PMDAnimation: Equatable, Sendable {
    public let name: String
    /// The name of the `<sheet>-Anim.png` sheet: its own, or the one of the copied animation (`CopyOf`).
    public let sheet: String
    public let width: Int
    public let height: Int
    /// In 1/60 of a second.
    public let durations: [Int]
}

/// Reads SpriteCollab's `AnimData.xml` file.
public enum AnimData {
    public static func parse(_ data: Data) -> [String: PMDAnimation] {
        let collector = Collector()
        let parser = XMLParser(data: data)
        parser.delegate = collector
        guard parser.parse() else { return [:] }
        var result: [String: PMDAnimation] = [:]
        for raw in collector.raws {
            let source = raw.copyOf.flatMap { name in collector.raws.first { $0.name == name } } ?? raw
            guard let width = source.width, let height = source.height, !source.durations.isEmpty else { continue }
            result[raw.name] = PMDAnimation(
                name: raw.name, sheet: source.name, width: width, height: height, durations: source.durations)
        }
        return result
    }

    private struct RawAnimation {
        var name = ""
        var copyOf: String?
        var width: Int?
        var height: Int?
        var durations: [Int] = []
    }

    private final class Collector: NSObject, XMLParserDelegate {
        var raws: [RawAnimation] = []
        private var current: RawAnimation?
        private var text = ""

        func parser(_ p: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
            if name == "Anim" { current = RawAnimation() }
            text = ""
        }

        func parser(_ p: XMLParser, foundCharacters string: String) {
            text += string
        }

        func parser(_ p: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
            let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            switch name {
            case "Name": current?.name = value
            case "CopyOf": current?.copyOf = value
            case "FrameWidth": current?.width = Int(value)
            case "FrameHeight": current?.height = Int(value)
            case "Duration": if let d = Int(value) { current?.durations.append(d) }
            case "Anim":
                if let current { raws.append(current) }
                current = nil
            default: break
            }
        }
    }
}
