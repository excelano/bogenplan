// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import EventKit
import SwiftUI

/// One Bogenzeit day drawn top to bottom from ○ to ○, every span the same
/// height, with the sky's light behind it and the events placed on it.
struct DayColumn: View {
    static let standardPointsPerSpan = 4.0
    static let pointsPerSpanRange = 1.5...16.0
    static let gutter: CGFloat = 72
    /// The mark steps, finest first, each with the least scale it is drawn
    /// at; below them all, only the quarters are marked.
    static let markSteps: [(spans: Int, minimumPointsPerSpan: Double)] = [(10, 3.2), (25, 1.8)]
    /// Room below the ending ○ for its label.
    static let footer: CGFloat = 40

    let axis: DayAxis
    let pointsPerSpan: CGFloat
    let events: [EKEvent]
    let readout: Readout
    let onSelect: (EKEvent) -> Void

    var body: some View {
        let placed = EventLayout.place(events, on: axis, minimumSpans: 24 / pointsPerSpan)
        let step = Self.markSteps.first { pointsPerSpan >= $0.minimumPointsPerSpan }?.spans ?? 50
        let marks = axis.marks(every: step)
        ZStack(alignment: .topLeading) {
            sky(marks)
            ForEach(marks) { markLabel($0) }
            GeometryReader { geometry in
                let width = geometry.size.width - Self.gutter - 8
                ForEach(placed) { item in
                    let columnWidth = width / CGFloat(item.columns)
                    EventBlock(event: item.event, readout: readout)
                        .frame(width: columnWidth - 2, height: y(item.bottom) - y(item.top) - 1)
                        .offset(x: Self.gutter + CGFloat(item.column) * columnWidth, y: y(item.top))
                        .onTapGesture { onSelect(item.event) }
                }
            }
            nowLine
        }
        .frame(height: y(DayAxis.length) + Self.footer)
    }

    private func y(_ position: Double) -> CGFloat {
        CGFloat(position) * pointsPerSpan
    }

    private func sky(_ marks: [DayAxis.Mark]) -> some View {
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
                let opacity = mark.number == nil ? 0.45 : mark.isQuarter ? 0.2 : 0.08
                context.stroke(line, with: .color(Palette.majorTick.opacity(opacity)), lineWidth: 0.5)
            }
        }
    }

    private func markLabel(_ mark: DayAxis.Mark) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            if mark.isQuarter {
                PositionLabel(glyph: mark.glyph, number: mark.number, before: mark.before, style: .caption)
            } else {
                PositionLabel(glyph: mark.glyph, number: mark.number, before: mark.before, style: .caption2,
                              color: Palette.label.opacity(0.7))
            }
            if mark.isQuarter && readout.showsCivilTime {
                Text(mark.instant.formatted(date: .omitted, time: .shortened))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Palette.label)
            }
        }
        .padding(.leading, 8)
        .offset(y: y(mark.position) + 3)
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
                .padding(.leading, Self.gutter - 4)
                .offset(y: y(axis.position(of: now)) - 4)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }
}

private struct EventBlock: View {
    let event: EKEvent
    let readout: Readout

    var body: some View {
        let color = Color(cgColor: event.calendar.cgColor)
        HStack(alignment: .top, spacing: 0) {
            color.frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.line)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    PositionLabel(readout.position(at: event.startDate), style: .caption2)
                    Text("–").font(.caption2).foregroundStyle(Palette.line)
                    PositionLabel(readout.position(at: event.endDate), style: .caption2)
                }
                if readout.showsCivilTime {
                    Text(civilRange)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Palette.label)
                }
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.title ?? ""), \(readout.spokenRange(from: event.startDate, to: event.endDate))")
        .accessibilityAddTraits(.isButton)
    }

    private var civilRange: String {
        "\(event.startDate.formatted(date: .omitted, time: .shortened)) – \(event.endDate.formatted(date: .omitted, time: .shortened))"
    }
}
