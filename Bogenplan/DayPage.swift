// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import EventKit
import SwiftUI

struct DayPage: View {
    let days: [CalendarDay]
    let today: Int
    let readout: Readout
    let calendars: CalendarStore
    @Binding var pointsPerSpan: Double

    private struct Zoom {
        let pointsPerSpan: Double
        let span: Double
        let y: CGFloat
    }

    private struct Column: Identifiable {
        let day: CalendarDay
        let axis: DayAxis
        let events: [EKEvent]
        let allDay: [EKEvent]

        var id: Int { day.daysSinceEpoch }
    }

    @State private var scroll = ScrollPosition(edge: .top)
    @State private var offset: CGFloat = 0
    @State private var zoom: Zoom?
    @State private var visibleHeight: CGFloat = 0

    private var fittingScale: Double {
        max(DayColumn.pointsPerSpanRange.lowerBound, Double(visibleHeight - DayColumn.footer) / DayAxis.length)
    }

    private var scale: CGFloat {
        min(max(pointsPerSpan, fittingScale), DayColumn.pointsPerSpanRange.upperBound)
    }

    var body: some View {
        let columns = days.map(column)
        let isSingle = columns.count == 1
        VStack(spacing: 0) {
            if isSingle {
                if !columns[0].allDay.isEmpty { allDayStrip(columns[0].allDay) }
            } else {
                header(columns)
            }
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    SpanGutter(axis: columns[0].axis, pointsPerSpan: scale,
                               showsCivilTime: isSingle && readout.showsCivilTime)
                    ForEach(columns) { column in
                        DayLane(axis: column.axis, pointsPerSpan: scale, events: column.events, readout: readout,
                                calendars: calendars)
                            .overlay(alignment: .leading) {
                                if !isSingle { Palette.majorTick.opacity(0.25).frame(width: 0.5) }
                            }
                    }
                }
            }
            .refreshable { calendars.refresh() }
            .scrollPosition($scroll)
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in offset = y }
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.containerSize.height }) { _, height in visibleHeight = height }
            .simultaneousGesture(pinch)
            .onAppear { scroll.scrollTo(y: initialOffset(columns)) }
        }
        .background(Palette.night)
    }

    private func column(_ day: CalendarDay) -> Column {
        let axis = DayAxis(day, at: readout.place)
        let civil = day.civilInterval
        let civilNoon = civil.start.addingTimeInterval(civil.duration / 2)
        let events = calendars.events(from: min(axis.start, civil.start), to: max(axis.end, civil.end))
        let allDay = events.filter { $0.isAllDay && $0.startDate <= civilNoon && $0.endDate > civilNoon }
        return Column(day: day, axis: axis, events: events, allDay: allDay)
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = zoom ?? Zoom(pointsPerSpan: scale,
                                        span: (offset + value.startLocation.y) / scale,
                                        y: value.startLocation.y)
                zoom = start
                pointsPerSpan = min(max(start.pointsPerSpan * value.magnification, fittingScale),
                                    DayColumn.pointsPerSpanRange.upperBound)
                scroll.scrollTo(y: max(0, start.span * scale - start.y))
            }
            .onEnded { _ in zoom = nil }
    }

    private func header(_ columns: [Column]) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Color.clear.frame(width: DayColumn.gutter, height: 1)
            ForEach(columns) { column in
                VStack(alignment: .leading, spacing: 4) {
                    dayTitle(column)
                    if readout.showsCivilTime, let sunrise = column.axis.solar.sunrise, let sunset = column.axis.solar.sunset {
                        HStack(spacing: 10) {
                            civilEvent(.sunrise, sunrise)
                            civilEvent(.sunset, sunset)
                        }
                    }
                    AllDayStrip(events: column.allDay, readout: readout)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func dayTitle(_ column: Column) -> some View {
        let isToday = column.id == today
        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(column.day.civilInterval.start.formatted(.dateTime.weekday(.abbreviated)))
                .font(.subheadline)
                .foregroundStyle(isToday ? Palette.sun : Palette.label)
            Text("\(column.day.day)")
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(isToday ? Palette.sun : Palette.line)
        }
    }

    private func civilEvent(_ glyph: Glyph, _ instant: Date) -> some View {
        HStack(spacing: 4) {
            PositionLabel(glyph: glyph, style: .caption2, color: Palette.label)
            Text(instant.formatted(date: .omitted, time: .shortened))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Palette.label)
        }
    }

    private func allDayStrip(_ events: [EKEvent]) -> some View {
        AllDayStrip(events: events, readout: readout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 6)
    }

    /// Today opens at the present moment, other days at their first event,
    /// or at sunrise when they have none.
    private func initialOffset(_ columns: [Column]) -> CGFloat {
        let target: Double
        if let current = columns.first(where: { $0.id == today }) {
            target = current.axis.position(of: Demo.now(.now))
        } else {
            target = columns.flatMap { column in
                column.events.filter { !$0.isAllDay && column.axis.contains($0.startDate) }.map { column.axis.position(of: $0.startDate) }
            }.min() ?? 100
        }
        return max(0, CGFloat(target) * scale - 160)
    }
}

private struct AllDayStrip: View {
    let events: [EKEvent]
    let readout: Readout

    var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach((0...events.count).reversed(), id: \.self) { shown in
                FlowLayout(spacing: 6, rowLimit: 2) {
                    ForEach(events.prefix(shown), id: \.self) { AllDayChip(event: $0, readout: readout) }
                    if shown < events.count {
                        MoreChip(events: events, hidden: events.count - shown, readout: readout)
                    }
                }
            }
        }
    }
}

private struct MoreChip: View {
    let events: [EKEvent]
    let hidden: Int
    let readout: Readout

    @State private var showsList = false

    var body: some View {
        Text("+\(hidden) more")
            .font(.caption.weight(.medium))
            .foregroundStyle(Palette.label)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Palette.line.opacity(0.12), in: Capsule())
            .onTapGesture { showsList = true }
            .popover(isPresented: $showsList) {
                AllDayList(events: events, readout: readout)
                    .frame(idealWidth: 400, idealHeight: 600)
            }
            .accessibilityAddTraits(.isButton)
    }
}

private struct AllDayList: View {
    let events: [EKEvent]
    let readout: Readout

    @State private var selected: EKEvent?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let selected {
            EventDetailView(event: selected, readout: readout)
        } else {
            NavigationStack {
                List(events, id: \.self) { event in
                    Button { selected = event } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(cgColor: event.calendar.cgColor))
                                .frame(width: 10, height: 10)
                            Text(event.title ?? "")
                                .foregroundStyle(Palette.line)
                        }
                    }
                }
                .navigationTitle("All day")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }
}

private struct AllDayChip: View {
    let event: EKEvent
    let readout: Readout

    @State private var showsDetail = false

    var body: some View {
        Text(event.title ?? "")
            .font(.caption.weight(.medium))
            .foregroundStyle(Palette.line)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(cgColor: event.calendar.cgColor).opacity(0.4), in: Capsule())
            .onTapGesture { showsDetail = true }
            .popover(isPresented: $showsDetail) {
                EventDetailView(event: event, readout: readout)
                    .frame(idealWidth: 400, idealHeight: 600)
            }
            .accessibilityAddTraits(.isButton)
    }
}
