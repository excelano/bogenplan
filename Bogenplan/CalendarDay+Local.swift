// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import Foundation

extension CalendarDay {
    /// 1 for Sunday through 7 for Saturday, as `Calendar` counts them.
    var weekday: Int {
        ((daysSinceEpoch + 4) % 7 + 7) % 7 + 1
    }

    /// The first day of this day's week, starting on the device's first
    /// weekday.
    var startOfWeek: CalendarDay {
        adding(days: -((weekday - Calendar.current.firstWeekday + 7) % 7))
    }

    /// The civil date of the same name in the device's time zone.
    var civilInterval: DateInterval {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? midnightUTC
        return calendar.dateInterval(of: .day, for: start) ?? DateInterval(start: start, duration: 86_400)
    }

    /// The day with the same name as the civil date `date` falls on.
    init(civil date: Date) {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        self = CalendarDay(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
            ?? date.utcDay
    }
}
