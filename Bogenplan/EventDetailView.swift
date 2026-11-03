// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import EventKit
import SwiftUI

struct EventDetailView: View {
    let event: EKEvent
    let readout: Readout

    @Environment(\.dismiss) private var dismiss
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
                        instantRow("Starts", event.startDate)
                        instantRow("Ends", event.endDate)
                        LabeledContent("Length", value: readout.duration(from: event.startDate, to: event.endDate))
                        if let quarter = readout.reading(at: event.startDate).quarter {
                            LabeledContent("Starts in", value: quarter.name)
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
            .navigationTitle("Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Palette.sun)
    }

    private func instantRow(_ title: String, _ instant: Date) -> some View {
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
