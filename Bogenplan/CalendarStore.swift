// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import EventKit
import Foundation

/// The calendars on this iPhone, read through EventKit, and which of them
/// the person has chosen to hide.
@Observable
final class CalendarStore {
    private(set) var access = EKEventStore.authorizationStatus(for: .event)
    private(set) var calendars: [EKCalendar] = []
    private(set) var hiddenIDs: Set<String>
    private(set) var storeChanges = 0

    @ObservationIgnored private let store = EKEventStore()

    init() {
        hiddenIDs = Set(UserDefaults.standard.stringArray(forKey: SettingKey.hiddenCalendars) ?? [])
        reload()
    }

    func requestAccess() {
        store.requestFullAccessToEvents { @Sendable _, _ in
            Task { @MainActor in self.reload() }
        }
    }

    func refresh() {
        if !Demo.active { store.refreshSourcesIfNecessary() }
        reload()
    }

    func reload() {
        storeChanges += 1
        if Demo.active {
            access = .fullAccess
            calendars = Demo.calendars
            return
        }
        access = EKEventStore.authorizationStatus(for: .event)
        guard access == .fullAccess else {
            calendars = []
            return
        }
        calendars = store.calendars(for: .event)
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    func edited(_ event: EKEvent) {
        if !Demo.active { event.refresh() }
        reload()
    }

    func isVisible(_ calendar: EKCalendar) -> Bool {
        !hiddenIDs.contains(calendar.calendarIdentifier)
    }

    func setVisible(_ visible: Bool, _ calendar: EKCalendar) {
        if visible {
            hiddenIDs.remove(calendar.calendarIdentifier)
        } else {
            hiddenIDs.insert(calendar.calendarIdentifier)
        }
        UserDefaults.standard.set(Array(hiddenIDs), forKey: SettingKey.hiddenCalendars)
    }

    func editingStore(for event: EKEvent) -> EKEventStore? {
        Demo.active || !event.calendar.allowsContentModifications ? nil : store
    }

    var momentCalendar: EKCalendar? {
        Demo.active ? nil : store.defaultCalendarForNewEvents
    }

    func addMoment(at instant: Date, title: String) throws {
        guard let calendar = momentCalendar else { throw MomentError.noCalendar }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = instant
        event.endDate = instant
        event.calendar = calendar
        event.addAlarm(EKAlarm(relativeOffset: 0))
        try store.save(event, span: .thisEvent, commit: true)
    }

    func events(from start: Date, to end: Date) -> [EKEvent] {
        _ = storeChanges
        let visible = calendars.filter(isVisible)
        guard !visible.isEmpty else { return [] }
        if Demo.active { return Demo.events(from: start, to: end, in: visible) }
        return store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: visible))
    }
}
