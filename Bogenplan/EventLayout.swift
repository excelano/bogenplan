// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import EventKit
import Foundation

struct PlacedEvent: Identifiable {
    let event: EKEvent
    let top: Double
    let bottom: Double
    var column = 0
    var columns = 1

    var id: String { "\(event.calendarItemIdentifier)@\(event.startDate.timeIntervalSince1970)" }
}

enum EventLayout {
    /// The day's timed events placed on the axis, side by side where they
    /// overlap. `minimumSpans` is the least height an event is given, so that
    /// a short one stays readable and its neighbours make room for it.
    static func place(_ events: [EKEvent], on axis: DayAxis, minimumSpans: Double) -> [PlacedEvent] {
        var placed = events
            .filter { !$0.isAllDay && $0.endDate > axis.start && $0.startDate < axis.end }
            .map { event in
                let top = min(axis.position(of: event.startDate), DayAxis.length - minimumSpans)
                let bottom = max(axis.position(of: event.endDate), top + minimumSpans)
                return PlacedEvent(event: event, top: top, bottom: bottom)
            }
            .sorted { ($0.top, -$0.bottom) < ($1.top, -$1.bottom) }

        var columnEnds: [Double] = []
        var clusterStart = 0
        var clusterEnd = -Double.infinity

        func closeCluster(before end: Int) {
            for i in clusterStart..<end { placed[i].columns = max(1, columnEnds.count) }
        }

        for i in placed.indices {
            if placed[i].top >= clusterEnd {
                closeCluster(before: i)
                columnEnds = []
                clusterStart = i
            }
            if let free = columnEnds.firstIndex(where: { $0 <= placed[i].top }) {
                placed[i].column = free
                columnEnds[free] = placed[i].bottom
            } else {
                placed[i].column = columnEnds.count
                columnEnds.append(placed[i].bottom)
            }
            clusterEnd = max(clusterEnd, placed[i].bottom)
        }
        closeCluster(before: placed.count)
        return placed
    }
}
