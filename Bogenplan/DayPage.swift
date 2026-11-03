// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import EventKit
import SwiftUI

struct DayPage: View {
    let day: CalendarDay
    let isToday: Bool
    let readout: Readout
    let calendars: CalendarStore
    @Binding var pointsPerSpan: Double
    let onSelect: (EKEvent) -> Void

    /// Where a pinch began: the scale then, and the span under the fingers,
    /// which stays under them as the scale changes.
    private struct Zoom {
        let pointsPerSpan: Double
        let span: Double
        let y: CGFloat
    }

    @State private var scroll = ScrollPosition(edge: .top)
    @State private var offset: CGFloat = 0
    @State private var zoom: Zoom?

    var body: some View {
        let axis = DayAxis(day, at: readout.place)
        let civil = day.civilInterval
        let civilNoon = civil.start.addingTimeInterval(civil.duration / 2)
        let events = calendars.events(from: min(axis.start, civil.start), to: max(axis.end, civil.end))
        let allDay = events.filter { $0.isAllDay && $0.startDate <= civilNoon && $0.endDate > civilNoon }
        VStack(spacing: 0) {
            if !allDay.isEmpty {
                allDayStrip(allDay)
            }
            ScrollView {
                DayColumn(axis: axis, pointsPerSpan: pointsPerSpan, events: events, readout: readout, onSelect: onSelect)
            }
            .scrollPosition($scroll)
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in offset = y }
            .simultaneousGesture(pinch)
            .onAppear { scroll.scrollTo(y: initialOffset(axis, events: events)) }
        }
        .background(Palette.night)
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = zoom ?? Zoom(pointsPerSpan: pointsPerSpan,
                                        span: (offset + value.startLocation.y) / pointsPerSpan,
                                        y: value.startLocation.y)
                zoom = start
                let range = DayColumn.pointsPerSpanRange
                pointsPerSpan = min(max(start.pointsPerSpan * value.magnification, range.lowerBound), range.upperBound)
                scroll.scrollTo(y: max(0, start.span * pointsPerSpan - start.y))
            }
            .onEnded { _ in zoom = nil }
    }

    private func allDayStrip(_ events: [EKEvent]) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(events, id: \.self) { event in
                Text(event.title ?? "")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Palette.line)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(cgColor: event.calendar.cgColor).opacity(0.4), in: Capsule())
                    .onTapGesture { onSelect(event) }
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    /// Today opens at the present moment, any other day at its first event,
    /// or at sunrise when it has none.
    private func initialOffset(_ axis: DayAxis, events: [EKEvent]) -> CGFloat {
        let target = isToday
            ? axis.position(of: Demo.now(.now))
            : events.filter { !$0.isAllDay && axis.contains($0.startDate) }.map { axis.position(of: $0.startDate) }.min() ?? 100
        return max(0, CGFloat(target * pointsPerSpan) - 160)
    }
}
