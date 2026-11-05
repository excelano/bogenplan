// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import SwiftUI

enum MomentError: LocalizedError {
    case noCalendar

    var errorDescription: String? {
        "There is no calendar for new events. Choose a default calendar in Settings, under Calendar."
    }
}

struct MomentSheet: View {
    let axis: DayAxis
    let readout: Readout
    let calendars: CalendarStore

    private static let pointsPerStep: CGFloat = 10

    @Environment(\.dismiss) private var dismiss
    @State private var instant: Date
    @State private var title = ""
    @State private var setsCivilTime = false
    @State private var dragStart: Date?
    @State private var failure: String?

    init(instant: Date, axis: DayAxis, readout: Readout, calendars: CalendarStore) {
        self.axis = axis
        self.readout = readout
        self.calendars = calendars
        _instant = State(initialValue: Self.stepped(instant, by: 0, axis: axis, readout: readout))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
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
                        DatePicker("Time", selection: civilTime, in: axis.start...axis.end, displayedComponents: .hourAndMinute)
                    } else {
                        dial
                    }
                }
                Section {
                    TextField(defaultTitle, text: $title)
                } footer: {
                    Text(footer)
                }
            }
            .navigationTitle("Set a Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", action: add)
                        .disabled(calendars.momentCalendar == nil)
                }
            }
            .alert("Not added", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("OK") { failure = nil }
            } message: {
                Text(failure ?? "")
            }
        }
        .tint(Palette.sun)
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
                        instant = Self.stepped(start, by: steps, axis: axis, readout: readout)
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

    private var civilTime: Binding<Date> {
        Binding {
            instant
        } set: { picked in
            instant = Self.wholeSecond(min(max(picked, axis.start), axis.end))
        }
    }

    private var defaultTitle: String {
        readout.spoken(readout.position(at: instant)).capitalizedFirst
    }

    private var footer: String {
        guard let calendar = calendars.momentCalendar else {
            return "There is no calendar for new events."
        }
        return "Added to \(calendar.title) with an alert at this moment, fixed for where you are now."
    }

    private func step(_ steps: Int) {
        instant = Self.stepped(instant, by: steps, axis: axis, readout: readout)
    }

    private func add() {
        let name = title.trimmingCharacters(in: .whitespaces)
        do {
            try calendars.addMoment(at: instant, title: name.isEmpty ? defaultTitle : name)
            dismiss()
        } catch {
            failure = error.localizedDescription
        }
    }

    private static func stepped(_ instant: Date, by steps: Int, axis: DayAxis, readout: Readout) -> Date {
        let reading = readout.reading(at: instant)
        if readout.scale == .spans, reading.placeInDay != nil {
            let factor = pow(10, Double(readout.precision.decimals(for: .spans)))
            let place = (axis.position(of: instant) * factor).rounded() + Double(steps)
            let clamped = min(max(place, 0), DayAxis.length * factor - 1)
            return wholeSecond(axis.instant(at: clamped / factor))
        }
        let step = pow(10, Double(3 - readout.precision.decimals(for: .kiloseconds)))
        let anchor = instant.addingTimeInterval(-reading.offset)
        let target = anchor.addingTimeInterval(((reading.offset / step).rounded() + Double(steps)) * step)
        return wholeSecond(min(max(target, axis.start), axis.end.addingTimeInterval(-step)))
    }

    private static func wholeSecond(_ instant: Date) -> Date {
        Date(timeIntervalSince1970: (instant.timeIntervalSince1970 + 0.001).rounded(.up))
    }
}

private extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
