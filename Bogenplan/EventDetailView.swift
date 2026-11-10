// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import EventKit
import SwiftUI

struct EventDetailView: View {
    let event: EKEvent
    let readout: Readout

    @Environment(CalendarStore.self) private var calendars
    @Environment(\.dismiss) private var dismiss
    @State private var editing = false
    @State private var retiming: EventTimeSheet.Edge?
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(event.title ?? "")
                        .font(.title3.weight(.semibold))
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(cgColor: event.calendar.cgColor))
                            .frame(width: 10, height: 10)
                        Text(event.calendar.title)
                            .foregroundStyle(Palette.label)
                    }
                }
                Section("Time") {
                    if event.isAllDay {
                        LabeledContent("All day", value: allDayDates)
                    } else {
                        instantRow("Starts", event.startDate, edge: .start)
                        instantRow("Ends", event.endDate, edge: .end)
                        LabeledContent("Length", value: readout.duration(from: event.startDate, to: event.endDate))
                        if let eighth = readout.reading(at: event.startDate).eighth {
                            LabeledContent("Starts in", value: eighth.name)
                        }
                    }
                }
                if let location = event.location, !location.isEmpty {
                    Section("Location") { Text(location) }
                }
                if let notes = event.notes, !notes.isEmpty {
                    Section("Notes") { Text(notes) }
                }
                Section {
                    Button("Open in Calendar") {
                        let seconds = Int(event.startDate.timeIntervalSinceReferenceDate)
                        if let url = URL(string: "calshow:\(seconds)") { openURL(url) }
                    }
                }
            }
            .id(calendars.storeChanges)
            .navigationTitle("Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if calendars.editingStore(for: event) != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Edit Details") { editing = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Palette.sun)
        .sheet(item: $retiming) { edge in
            EventTimeSheet(event: event, edge: edge, readout: readout, calendars: calendars)
        }
        .sheet(isPresented: $editing) {
            if let store = calendars.editingStore(for: event) {
                EventEditor(event: event, store: store) { action in
                    editing = false
                    guard action != .canceled else { return }
                    calendars.edited(event)
                    if action == .deleted { dismiss() }
                }
                .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder private func instantRow(_ title: String, _ instant: Date, edge: EventTimeSheet.Edge) -> some View {
        if calendars.editingStore(for: event) != nil {
            Button { retiming = edge } label: {
                HStack(spacing: 8) {
                    instantContent(title, instant)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .tint(Palette.line)
            .accessibilityHint("Set in Bogenzeit")
        } else {
            instantContent(title, instant)
        }
    }

    private func instantContent(_ title: String, _ instant: Date) -> some View {
        LabeledContent {
            VStack(alignment: .trailing, spacing: 2) {
                PositionLabel(readout.position(at: instant), style: .body)
                if readout.showsCivilTime {
                    Text(instant.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Palette.label)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(readout.spoken(readout.position(at: instant)))
        } label: {
            Text(title)
        }
    }

    private var allDayDates: String {
        let last = event.endDate.addingTimeInterval(-1)
        let first = event.startDate.formatted(date: .abbreviated, time: .omitted)
        let final = last.formatted(date: .abbreviated, time: .omitted)
        return first == final ? first : "\(first) – \(final)"
    }
}
