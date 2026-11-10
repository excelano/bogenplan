// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import SwiftUI

struct InstantSetter: View {
    @Binding var instant: Date
    let readout: Readout
    var limits: ClosedRange<Date>?
    var civilComponents: DatePickerComponents = .hourAndMinute

    private static let pointsPerStep: CGFloat = 10

    @State private var setsCivilTime = false
    @State private var dragStart: Date?

    var body: some View {
        VStack(spacing: 8) {
            PositionLabel(readout.position(at: instant), style: .largeTitle, weight: .semibold)
            if readout.showsCivilTime {
                Text(instant.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Palette.label)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(readout.spoken(readout.position(at: instant)))
        .accessibilityAdjustableAction { direction in
            step(direction == .increment ? 1 : -1)
        }
        if readout.showsCivilTime {
            Picker("Set in", selection: $setsCivilTime) {
                Text("Bogenzeit").tag(false)
                Text("Civil time").tag(true)
            }
            .pickerStyle(.segmented)
        }
        if setsCivilTime {
            if let limits {
                DatePicker("Time", selection: civilTime, in: limits, displayedComponents: civilComponents)
            } else {
                DatePicker("Time", selection: civilTime, displayedComponents: civilComponents)
            }
        } else {
            if limits == nil {
                DatePicker("Day", selection: chosenDay, displayedComponents: .date)
            }
            ReadingEntry(instant: $instant, readout: readout)
            dial
        }
    }

    private var dial: some View {
        HStack(spacing: 12) {
            stepButton("minus", -1)
            ZStack {
                Capsule().fill(Palette.line.opacity(0.08))
                HStack(spacing: Self.pointsPerStep - 1) {
                    ForEach(0..<24, id: \.self) { i in
                        Rectangle()
                            .fill(Palette.label.opacity(i % 5 == 0 ? 0.8 : 0.35))
                            .frame(width: 1, height: i % 5 == 0 ? 18 : 10)
                    }
                }
                .clipped()
            }
            .frame(height: 36)
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        let start = dragStart ?? instant
                        dragStart = start
                        let steps = Int((value.translation.width / Self.pointsPerStep).rounded())
                        instant = stepped(start, by: steps)
                    }
                    .onEnded { _ in dragStart = nil }
            )
            .accessibilityHidden(true)
            stepButton("plus", 1)
        }
        .sensoryFeedback(.selection, trigger: instant)
    }

    private func stepButton(_ symbol: String, _ steps: Int) -> some View {
        Button { step(steps) } label: {
            Image(systemName: symbol)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.bordered)
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(steps < 0 ? "Earlier" : "Later")
    }

    private var chosenDay: Binding<Date> {
        Binding {
            day(of: instant).civilInterval.start
        } set: { picked in
            let axis = DayAxis(day(of: instant), at: readout.place)
            let moved = DayAxis(CalendarDay(civil: picked), at: readout.place)
            instant = moved.instant(at: axis.position(of: instant)).wholeSecond
        }
    }

    private func day(of instant: Date) -> CalendarDay {
        bogenzeitDay(of: instant, longitude: readout.place.longitude)
    }

    private var civilTime: Binding<Date> {
        Binding {
            instant
        } set: { picked in
            instant = clamped(picked).wholeSecond
        }
    }

    private func step(_ steps: Int) {
        instant = stepped(instant, by: steps)
    }

    private func stepped(_ start: Date, by steps: Int) -> Date {
        let moved = readout.stepped(start, by: steps)
        guard let limits else { return moved }
        if moved < limits.lowerBound { return limits.lowerBound.wholeSecond }
        if moved >= limits.upperBound { return readout.stepped(limits.upperBound, by: -1) }
        return moved
    }

    private func clamped(_ picked: Date) -> Date {
        guard let limits else { return picked }
        return min(max(picked, limits.lowerBound), limits.upperBound)
    }
}
