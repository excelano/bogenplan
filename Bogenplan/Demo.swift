// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import EventKit
import Foundation
import UIKit

enum Demo {
    #if DEBUG
    static let active = CommandLine.arguments.contains("--demo")
    static let date: Date? = argument(after: "--date").flatMap { try? Date("\($0)T12:00:00-06:00", strategy: .iso8601) }
    static let zoom: Double? = argument(after: "--zoom").flatMap(Double.init)
    static let event: String? = argument(after: "--event")

    private static func argument(after flag: String) -> String? {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }
    #else
    static let active = false
    static let date: Date? = nil
    static let zoom: Double? = nil
    static let event: String? = nil
    #endif

    static let place = Place(latitude: 29.76, longitude: -95.37)
    static let instant = try! Date("2026-11-04T16:20:00Z", strategy: .iso8601)

    static func now(_ date: Date) -> Date {
        active ? instant : date
    }

    static let calendars: [EKCalendar] = [("Work", 0xF0A04B), ("Home", 0x6BC490), ("Family", 0xD27BD8)].map { title, hex in
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = title
        calendar.cgColor = UIColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
                                   blue: CGFloat(hex & 0xFF) / 255, alpha: 1).cgColor
        return calendar
    }

    static func events(from start: Date, to end: Date, in visible: [EKCalendar]) -> [EKEvent] {
        var day = clock.startOfDay(for: start)
        var found: [EKEvent] = []
        while day < end {
            found += events(on: day)
            day = clock.date(byAdding: .day, value: 1, to: day)!
        }
        return found.filter { $0.endDate > start && $0.startDate < end && visible.contains($0.calendar) }
    }

    private struct Entry {
        let weekdays: Set<Int>
        let start: Int?
        let minutes: Int
        let title: String
        let calendar: Int
        var location: String?
        var notes: String?
    }

    private static let work = 0, home = 1, family = 2
    private static let weekdays: Set = [2, 3, 4, 5, 6]

    private static let week: [Entry] = [
        Entry(weekdays: [4], start: nil, minutes: 0, title: "Ava's birthday", calendar: family),
        Entry(weekdays: [2, 4, 6], start: 6 * 60 + 30, minutes: 45, title: "Run", calendar: home, location: "Buffalo Bayou"),
        Entry(weekdays: weekdays, start: 9 * 60, minutes: 15, title: "Stand-up", calendar: work),
        Entry(weekdays: [2], start: 13 * 60, minutes: 60, title: "Client call", calendar: work),
        Entry(weekdays: [3], start: 11 * 60, minutes: 45, title: "One-on-one with Sam", calendar: work),
        Entry(weekdays: [3], start: 19 * 60, minutes: 120, title: "Book club", calendar: home, location: "Brazos Bookstore"),
        Entry(weekdays: [4], start: 10 * 60 + 30, minutes: 90, title: "Design review", calendar: work, location: "Studio 3",
              notes: "Walk through the new layout before it goes to the client."),
        Entry(weekdays: [4], start: 12 * 60 + 15, minutes: 60, title: "Lunch with Maya", calendar: home, location: "Common Bond"),
        Entry(weekdays: [4], start: 14 * 60, minutes: 60, title: "Quarterly planning", calendar: work, location: "Room 4B"),
        Entry(weekdays: [4], start: 14 * 60 + 30, minutes: 30, title: "Call with Lee", calendar: work),
        Entry(weekdays: [4], start: 16 * 60 + 30, minutes: 45, title: "Dentist", calendar: home),
        Entry(weekdays: [4], start: 18 * 60, minutes: 90, title: "Choir rehearsal", calendar: family, location: "St. Paul's"),
        Entry(weekdays: [5], start: 15 * 60, minutes: 90, title: "Workshop", calendar: work),
        Entry(weekdays: [6], start: 18 * 60 + 30, minutes: 120, title: "Dinner with the Riveras", calendar: family),
        Entry(weekdays: [7], start: 9 * 60, minutes: 90, title: "Farmers market", calendar: family),
        Entry(weekdays: [7], start: 16 * 60, minutes: 90, title: "Soccer game", calendar: family),
        Entry(weekdays: [1], start: 10 * 60 + 30, minutes: 90, title: "Brunch", calendar: family),
    ]

    private static let store = EKEventStore()
    private static var made: [Date: [EKEvent]] = [:]

    private static let clock: Calendar = {
        var clock = Calendar(identifier: .gregorian)
        clock.timeZone = TimeZone(identifier: "America/Chicago")!
        return clock
    }()

    private static func events(on day: Date) -> [EKEvent] {
        if let events = made[day] { return events }
        let weekday = clock.component(.weekday, from: day)
        let events = week.filter { $0.weekdays.contains(weekday) }.map { entry in
            let event = EKEvent(eventStore: store)
            event.calendar = calendars[entry.calendar]
            event.title = entry.title
            event.location = entry.location
            event.notes = entry.notes
            if let start = entry.start {
                event.startDate = clock.date(byAdding: .minute, value: start, to: day)!
                event.endDate = clock.date(byAdding: .minute, value: entry.minutes, to: event.startDate)!
            } else {
                event.isAllDay = true
                event.startDate = day
                event.endDate = clock.date(byAdding: .day, value: 1, to: day)!
            }
            return event
        }
        made[day] = events
        return events
    }
}
