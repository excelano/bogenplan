// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import SwiftUI

/// The days side by side, swiped one at a time, opening on today.
struct DayPager: View {
    let place: Place
    let calendars: CalendarStore

    /// Days on either side of the centre that can be swiped to; going to a
    /// date further away moves the centre.
    private static let reach = 366
    private static let laneWidth: CGFloat = 200
    private static let weekLaneWidth: CGFloat = 150

    @AppStorage(SettingKey.scale) private var scale = Scale.standard.rawValue
    @AppStorage(SettingKey.precision) private var precision = Precision.standard.rawValue
    @AppStorage(SettingKey.showsCivilTime) private var showsCivilTime = true
    @AppStorage(SettingKey.pointsPerSpan) private var pointsPerSpan = DayColumn.standardPointsPerSpan
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var today: Int
    @State private var center: Int
    @State private var selection: Int
    @State private var showsSettings = false
    @State private var showsDatePicker = false

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
        GeometryReader { geometry in
            content(count: dayCount(width: geometry.size.width))
        }
    }

    private func dayCount(width: CGFloat) -> Int {
        guard sizeClass == .regular else { return 1 }
        let lanes = width - DayColumn.gutter
        if lanes / 7 >= Self.weekLaneWidth { return 7 }
        return min(max(Int(lanes / Self.laneWidth), 1), 4)
    }

    @ViewBuilder private func content(count: Int) -> some View {
        let readout = Readout(
            place: place,
            scale: Scale(rawValue: scale) ?? .standard,
            precision: Precision(rawValue: precision) ?? .standard,
            showsCivilTime: showsCivilTime
        )
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: page(count: count)) {
                    ForEach(pageStarts(count: count), id: \.self) { start in
                        DayPage(days: (start..<start + count).map { CalendarDay(daysSinceEpoch: $0) }, today: today,
                                readout: readout, calendars: calendars, pointsPerSpan: $pointsPerSpan)
                            .tag(start)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .id("\(center) \(count)")
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
                            Text(title(count: count))
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
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            let now = Self.today(at: place)
            guard now != today else { return }
            if selection == today { go(to: now) }
            today = now
        }
    }

    private func pageStart(of id: Int, count: Int) -> Int {
        let origin = count == 7 ? CalendarDay(daysSinceEpoch: center).startOfWeek.daysSinceEpoch : center
        let offset = id - origin
        let page = offset >= 0 ? offset / count : -((count - 1 - offset) / count)
        return origin + page * count
    }

    private func pageStarts(count: Int) -> [Int] {
        Array(stride(from: pageStart(of: days.lowerBound, count: count), through: days.upperBound, by: count))
    }

    private func page(count: Int) -> Binding<Int> {
        Binding {
            pageStart(of: selection, count: count)
        } set: { start in
            let current = pageStart(of: selection, count: count)
            guard start != current else { return }
            selection = min(max(start + selection - current, days.lowerBound), days.upperBound)
        }
    }

    private func title(count: Int) -> String {
        let first = CalendarDay(daysSinceEpoch: count == 1 ? selection : pageStart(of: selection, count: count))
        guard count > 1 else {
            return first.civilInterval.start.formatted(.dateTime.weekday(.abbreviated).day().month(.wide))
        }
        let last = first.adding(days: count - 1).civilInterval.start
        return (first.civilInterval.start..<last).formatted(.interval.day().month(.wide))
    }

    private func go(to id: Int) {
        if !days.contains(id) { center = id }
        selection = id
    }

    private static func today(at place: Place) -> Int {
        bogenzeitDay(of: Demo.now(.now), longitude: place.longitude).daysSinceEpoch
    }
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
        .presentationDetents([.large])
    }
}
