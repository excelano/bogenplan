// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import EventKit
import SwiftUI

enum DayColumn {
    static let standardPointsPerSpan = 4.0
    static let pointsPerSpanRange = 1.5...16.0
    static let gutter: CGFloat = 72
    static let markSteps: [(spans: Int, minimumPointsPerSpan: Double)] = [(10, 3.2), (25, 1.8)]
    static let footer: CGFloat = 40

    static func marks(_ axis: DayAxis, pointsPerSpan: CGFloat) -> [DayAxis.Mark] {
        let step = markSteps.first { pointsPerSpan >= $0.minimumPointsPerSpan }?.spans ?? 50
        return axis.marks(every: step)
    }

    static func height(pointsPerSpan: CGFloat) -> CGFloat {
        CGFloat(DayAxis.length) * pointsPerSpan + footer
    }
}

struct DaySky: View {
    let axis: DayAxis
    let pointsPerSpan: CGFloat

    var body: some View {
        let marks = DayColumn.marks(axis, pointsPerSpan: pointsPerSpan)
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Palette.night))
            let bands: [(Solar.HalfArc, Color)] = [
                (axis.solar.astronomical, Palette.astronomicalTwilight),
                (axis.solar.nautical, Palette.nauticalTwilight),
                (axis.solar.civil, Palette.civilTwilight),
                (axis.solar.horizon, Palette.day),
            ]
            for (arc, color) in bands {
                guard let extent = axis.extent(of: arc) else { continue }
                let band = CGRect(x: 0, y: y(extent.lowerBound), width: size.width,
                                  height: y(extent.upperBound) - y(extent.lowerBound))
                context.fill(Path(band), with: .color(color))
            }
            for mark in marks {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y(mark.position)))
                line.addLine(to: CGPoint(x: size.width, y: y(mark.position)))
                let opacity = mark.number == nil ? 0.45 : mark.isEighthBoundary ? 0.2 : 0.08
                context.stroke(line, with: .color(Palette.majorTick.opacity(opacity)), lineWidth: 0.5)
            }
        }
        .frame(height: DayColumn.height(pointsPerSpan: pointsPerSpan))
    }

    private func y(_ position: Double) -> CGFloat {
        CGFloat(position) * pointsPerSpan
    }
}

struct SpanGutter: View {
    let axis: DayAxis
    let pointsPerSpan: CGFloat
    let showsCivilTime: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            DaySky(axis: axis, pointsPerSpan: pointsPerSpan)
            ForEach(DayColumn.marks(axis, pointsPerSpan: pointsPerSpan)) { label($0) }
        }
        .frame(width: DayColumn.gutter)
    }

    private func label(_ mark: DayAxis.Mark) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            if mark.isEighthBoundary {
                PositionLabel(glyph: mark.glyph, number: mark.number, before: mark.before, style: .caption)
            } else {
                PositionLabel(glyph: mark.glyph, number: mark.number, before: mark.before, style: .caption2,
                              color: Palette.label.opacity(0.7))
            }
            if mark.isEighthBoundary && showsCivilTime {
                Text(mark.instant.formatted(date: .omitted, time: .shortened))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Palette.label)
            }
        }
        .padding(.leading, 8)
        .offset(y: CGFloat(mark.position) * pointsPerSpan + 3)
    }
}

struct DayLane: View {
    let axis: DayAxis
    let pointsPerSpan: CGFloat
    let events: [EKEvent]
    let readout: Readout
    let calendars: CalendarStore

    @State private var probe: MomentProbe?
    @State private var draft: MomentDraft?

    var body: some View {
        let placed = EventLayout.place(events, on: axis, minimumSpans: 24 / pointsPerSpan)
        ZStack(alignment: .topLeading) {
            DaySky(axis: axis, pointsPerSpan: pointsPerSpan)
                .gesture(ProbeGesture(onChange: track))
            GeometryReader { geometry in
                let width = geometry.size.width - 8
                ForEach(placed) { item in
                    let columnWidth = width / CGFloat(item.columns)
                    EventBlock(event: item.event, readout: readout)
                        .frame(width: columnWidth - 2, height: y(item.bottom) - y(item.top) - 1)
                        .offset(x: CGFloat(item.column) * columnWidth, y: y(item.top))
                }
            }
            nowLine
            if let probe {
                ProbeLine(probe: probe, instant: instant(at: probe.y), readout: readout)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: probe != nil) { _, shown in shown }
        .sensoryFeedback(.impact(weight: .heavy), trigger: probe?.armed == true) { _, armed in armed }
        .sheet(item: $draft) { draft in
            MomentSheet(instant: draft.instant, axis: axis, readout: readout, calendars: calendars)
        }
        .accessibilityAction(named: "Set a moment") {
            let now = Demo.now(.now)
            draft = MomentDraft(instant: axis.contains(now) ? now : axis.solar.noon)
        }
    }

    private func instant(at y: CGFloat) -> Date {
        axis.instant(at: Double(y / pointsPerSpan))
    }

    private func track(_ phase: ProbeGesture.Phase, _ point: CGPoint) {
        let y = min(max(point.y, 0), CGFloat(DayAxis.length) * pointsPerSpan)
        switch phase {
        case .began:
            let started = MomentProbe(y: y, still: point)
            probe = started
            arm(started.token)
        case .moved:
            guard var current = probe else { return }
            current.y = y
            if hypot(point.x - current.still.x, point.y - current.still.y) > 6 {
                current.still = point
                current.armed = false
                current.token = UUID()
                probe = current
                arm(current.token)
            } else {
                probe = current
            }
        case .ended:
            if let probe, probe.armed { draft = MomentDraft(instant: instant(at: probe.y)) }
            probe = nil
        case .cancelled:
            probe = nil
        }
    }

    private func arm(_ token: UUID) {
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            if probe?.token == token { probe?.armed = true }
        }
    }

    private func y(_ position: Double) -> CGFloat {
        CGFloat(position) * pointsPerSpan
    }

    private var nowLine: some View {
        TimelineView(.periodic(from: .now, by: 15)) { timeline in
            let now = Demo.now(timeline.date)
            if axis.contains(now) {
                HStack(spacing: 0) {
                    Circle()
                        .fill(Palette.sun)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Palette.sun)
                        .frame(height: 1.5)
                }
                .offset(x: -4, y: y(axis.position(of: now)) - 4)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }
}

private struct EventBlock: View {
    let event: EKEvent
    let readout: Readout

    @State private var showsDetail = false

    var body: some View {
        let color = Color(cgColor: event.calendar.cgColor)
        HStack(alignment: .top, spacing: 0) {
            color.frame(width: 3)
            ViewThatFits(in: .vertical) {
                details(range: true, civil: readout.showsCivilTime)
                details(range: true, civil: false)
                details(range: false, civil: false)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(0.3))
        .background(Palette.night.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture { showsDetail = true }
        .popover(isPresented: $showsDetail) {
            EventDetailView(event: event, readout: readout)
                .frame(idealWidth: 400, idealHeight: 600)
        }
        .onAppear {
            if Demo.event == event.title { showsDetail = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.title ?? ""), \(readout.spokenRange(from: event.startDate, to: event.endDate))")
        .accessibilityAddTraits(.isButton)
    }

    private func details(range: Bool, civil: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.title ?? "")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.line)
                .lineLimit(range ? 2 : 1)
            if range {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 4) {
                        PositionLabel(readout.position(at: event.startDate), style: .caption2)
                        Text("–").font(.caption2).foregroundStyle(Palette.line)
                        PositionLabel(readout.position(at: event.endDate), style: .caption2)
                    }
                    PositionLabel(readout.position(at: event.startDate), style: .caption2)
                }
            }
            if civil {
                Text(civilRange)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Palette.label)
            }
        }
    }

    private var civilRange: String {
        "\(event.startDate.formatted(date: .omitted, time: .shortened)) – \(event.endDate.formatted(date: .omitted, time: .shortened))"
    }
}
