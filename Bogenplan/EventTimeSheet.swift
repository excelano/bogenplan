// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import EventKit
import SwiftUI

struct EventTimeSheet: View {
    enum Edge: Identifiable {
        case start
        case end

        var id: Self { self }
    }

    let event: EKEvent
    let readout: Readout
    let calendars: CalendarStore

    @Environment(\.dismiss) private var dismiss
    @State private var edge: Edge
    @State private var start: Date
    @State private var end: Date
    @State private var choosesSpan = false
    @State private var failure: String?

    init(event: EKEvent, edge: Edge, readout: Readout, calendars: CalendarStore) {
        self.event = event
        self.readout = readout
        self.calendars = calendars
        _edge = State(initialValue: edge)
        _start = State(initialValue: event.startDate)
        _end = State(initialValue: event.endDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Set", selection: $edge) {
                        Text("Starts").tag(Edge.start)
                        Text("Ends").tag(Edge.end)
                    }
                    .pickerStyle(.segmented)
                    InstantSetter(instant: edge == .start ? startKeepingLength : endAfterStart, readout: readout,
                                  civilComponents: [.date, .hourAndMinute])
                }
                Section {
                    LabeledContent("Starts") { PositionLabel(readout.position(at: start), style: .body) }
                    LabeledContent("Ends") { PositionLabel(readout.position(at: end), style: .body) }
                    LabeledContent("Length", value: readout.duration(from: start, to: end))
                } footer: {
                    Text("Moving the start keeps the event's length.")
                }
            }
            .navigationTitle(event.title ?? "Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if event.hasRecurrenceRules { choosesSpan = true } else { save(.thisEvent) }
                    }
                    .disabled(start == event.startDate && end == event.endDate)
                }
            }
            .confirmationDialog("This is a repeating event.", isPresented: $choosesSpan, titleVisibility: .visible) {
                Button("Save for This Event Only") { save(.thisEvent) }
                Button("Save for Future Events") { save(.futureEvents) }
            }
            .alert("Not saved", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("OK") { failure = nil }
            } message: {
                Text(failure ?? "")
            }
        }
        .tint(Palette.sun)
    }

    private var startKeepingLength: Binding<Date> {
        Binding {
            start
        } set: { moved in
            end = moved.addingTimeInterval(end.timeIntervalSince(start))
            start = moved
        }
    }

    private var endAfterStart: Binding<Date> {
        Binding {
            end
        } set: { moved in
            end = max(moved, start)
        }
    }

    private func save(_ span: EKSpan) {
        do {
            try calendars.retime(event, start: start, end: end, span: span)
            dismiss()
        } catch {
            failure = error.localizedDescription
        }
    }
}
