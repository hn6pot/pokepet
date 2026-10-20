import Foundation

/// The figures of the « Récap » tab: today's (the Poképote day) and the month's.
public struct Recap: Equatable, Sendable {
    /// Today, the user's conversations only.
    public let output: Int
    public let cacheRead: Int
    /// Today's Claude responses, from the mod's counter.
    public let responses: Int
    /// « Octobre ».
    public let monthName: String
    /// This month: messages the user typed, and the automatic runs' messages, apart.
    public let messages: Int
    public let automaticMessages: Int

    private static let monthNames = [
        "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
        "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
    ]

    public static func make(ledger: UsageLedger, responses: Int, now: Date, calendar: Calendar = .current) -> Recap {
        let day = PokepetDay.key(now, calendar: calendar)
        let month = String(day.prefix(7))
        let today = ledger.day(day), thisMonth = ledger.month(month)
        return Recap(
            output: today.you.output, cacheRead: today.you.cacheRead, responses: responses,
            monthName: monthNames[(Int(day.dropFirst(5).prefix(2)) ?? 1) - 1],
            messages: thisMonth.you.messages, automaticMessages: thisMonth.automatic.messages)
    }

    /// The 1st of the Poképote day's month, at 4 a.m. (when that month's first Poképote day starts).
    public static func monthStart(now: Date, calendar: Calendar = .current) -> Date {
        let day = PokepetDay.key(now, calendar: calendar)
        let year = Int(day.prefix(4)) ?? 1970, month = Int(day.dropFirst(5).prefix(2)) ?? 1
        return calendar.date(from: DateComponents(year: year, month: month, day: 1, hour: PokepetDay.rolloverHour))!
    }
}
