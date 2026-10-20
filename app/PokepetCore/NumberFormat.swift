import Foundation

/// French number display: « 401 k », « 1,2 M », « 1 042 », with narrow no-break spaces.
public enum NumberFormat {
    private static let space = "\u{202F}"

    /// Below 1 000 as is; above, in k, M or G, with one decimal below 10.
    public static func tokens(_ n: Int) -> String {
        let units: [(Double, String)] = [(1e9, "G"), (1e6, "M"), (1e3, "k")]
        guard let index = units.firstIndex(where: { Double(n) >= $0.0 }) else { return String(n) }
        var unit = units[index]
        var value = Double(n) / unit.0
        // 999 960 would round to « 1 000 k »: say « 1,0 M ».
        if value.rounded() >= 1000, index > 0 {
            unit = units[index - 1]
            value = Double(n) / unit.0
        }
        let oneDecimal = (value * 10).rounded() / 10
        let text = oneDecimal >= 10
            ? String(Int(value.rounded()))
            : String(format: "%.1f", oneDecimal).replacingOccurrences(of: ".", with: ",")
        return text + space + unit.1
    }

    /// Thousands separated: « 1 234 567 ».
    public static func count(_ n: Int) -> String {
        let digits = String(abs(n))
        var groups: [Substring] = []
        var end = digits.endIndex
        while end > digits.startIndex {
            let start = digits.index(end, offsetBy: -3, limitedBy: digits.startIndex) ?? digits.startIndex
            groups.insert(digits[start..<end], at: 0)
            end = start
        }
        return (n < 0 ? "-" : "") + groups.joined(separator: space)
    }
}
