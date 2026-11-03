// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import EventKit
import SwiftUI

/// The days side by side, swiped one at a time, opening on today.
struct DayPager: View {
    let place: Place
    let calendars: CalendarStore

    /// Days on either side of the centre that can be swiped to; going to a
    /// date further away moves the centre.
    private static let reach = 366

    @AppStorage(SettingKey.scale) private var scale = Scale.standard.rawValue
    @AppStorage(SettingKey.precision) private var precision = Precision.standard.rawValue
    @AppStorage(SettingKey.showsCivilTime) private var showsCivilTime = true
    @AppStorage(SettingKey.pointsPerSpan) private var pointsPerSpan = DayColumn.standardPointsPerSpan
    @Environment(\.scenePhase) private var scenePhase

    @State private var today: Int
    @State private var center: Int
    @State private var selection: Int
    @State private var showsSettings = false
    @State private var showsDatePicker = false
    @State private var selectedEvent: SelectedEvent?

    init(place: Place, calendars: CalendarStore) {
        self.place = place
        self.calendars = calendars
        let today = Self.today(at: place)
        let opening = Demo.date.map { CalendarDay(civil: $0).daysSinceEpoch } ?? today
        _today = State(initialValue: today)
        _center = State(initialValue: opening)
        _selection = State(initialValue: opening)
        if Demo.active {
            UserDefaults.standard.set(Demo.zoom ?? DayColumn.standardPointsPerSpan, forKey: SettingKey.pointsPerSpan)
        }
    }

    private var days: ClosedRange<Int> {
        center - Self.reach...center + Self.reach
    }

    var body: some View {
        let readout = Readout(
            place: place,
            scale: Scale(rawValue: scale) ?? .standard,
            precision: Precision(rawValue: precision) ?? .standard,
            showsCivilTime: showsCivilTime
        )
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $selection) {
                    ForEach(days, id: \.self) { id in
                        DayPage(day: CalendarDay(daysSinceEpoch: id), isToday: id == today, readout: readout,
                                calendars: calendars, pointsPerSpan: $pointsPerSpan) {
                            selectedEvent = SelectedEvent(event: $0)
                        }
                        .tag(id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .id(center)
                Divider()
                WeekStrip(selection: $selection, today: today, days: days)
                    .id(center)
            }
            .background(Palette.night)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Today") { go(to: today) }
                        .disabled(selection == today)
                }
                ToolbarItem(placement: .principal) {
                    Button { showsDatePicker = true } label: {
                        HStack(spacing: 4) {
                            Text(CalendarDay(daysSinceEpoch: selection).civilInterval.start
                                .formatted(.dateTime.weekday(.abbreviated).day().month(.wide)))
                                .font(.headline)
                                .foregroundStyle(Palette.line)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Palette.label)
                        }
                    }
                    .accessibilityHint("Go to a date")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showsSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
        }
        .tint(Palette.sun)
        .sheet(isPresented: $showsSettings) {
            SettingsView(calendars: calendars, place: place)
        }
        .sheet(isPresented: $showsDatePicker) {
            DateJumpSheet(initial: CalendarDay(daysSinceEpoch: selection).civilInterval.start) {
                go(to: CalendarDay(civil: $0).daysSinceEpoch)
            }
        }
        .sheet(item: $selectedEvent) { selected in
            EventDetailView(event: selected.event, readout: readout)
        }
        .onAppear(perform: openDemoEvent)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            let now = Self.today(at: place)
            guard now != today else { return }
            if selection == today { go(to: now) }
            today = now
        }
    }

    private func openDemoEvent() {
        guard let title = Demo.event else { return }
        let axis = DayAxis(CalendarDay(daysSinceEpoch: selection), at: place)
        if let event = calendars.events(from: axis.start, to: axis.end).first(where: { $0.title == title }) {
            selectedEvent = SelectedEvent(event: event)
        }
    }

    private func go(to id: Int) {
        if !days.contains(id) { center = id }
        selection = id
    }

    private static func today(at place: Place) -> Int {
        bogenzeitDay(of: Demo.now(.now), longitude: place.longitude).daysSinceEpoch
    }
}

private struct SelectedEvent: Identifiable {
    let event: EKEvent

    var id: ObjectIdentifier { ObjectIdentifier(event) }
}

private struct DateJumpSheet: View {
    let onPick: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date: Date

    init(initial: Date, onPick: @escaping (Date) -> Void) {
        self.onPick = onPick
        _date = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .onChange(of: date) { _, picked in
                    onPick(picked)
                    dismiss()
                }
                .navigationTitle("Go to Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        .tint(Palette.sun)
        .presentationDetents([.medium, .large])
    }
}
