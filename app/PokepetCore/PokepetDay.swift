import Foundation

/// The pokepet day starts at 4 a.m., local time: at 3:59 on the 16th, it is still the 15th.
public enum PokepetDay {
    public static let rolloverHour = 4

    /// The current day at `date`, written "YYYY-MM-DD".
    public static func key(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        var day = calendar.date(from: DateComponents(year: c.year, month: c.month, day: c.day))!
        if c.hour! < rolloverHour {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        let d = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", d.year!, d.month!, d.day!)
    }
}
