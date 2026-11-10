// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

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

    @Environment(\.dismiss) private var dismiss
    @State private var instant: Date
    @State private var title = ""
    @State private var failure: String?

    init(instant: Date, axis: DayAxis, readout: Readout, calendars: CalendarStore) {
        self.axis = axis
        self.readout = readout
        self.calendars = calendars
        _instant = State(initialValue: min(readout.stepped(instant, by: 0), readout.stepped(axis.end, by: -1)))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    InstantSetter(instant: $instant, readout: readout, limits: axis.start...axis.end)
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

    private var defaultTitle: String {
        readout.spoken(readout.position(at: instant)).capitalizedFirst
    }

    private var footer: String {
        guard let calendar = calendars.momentCalendar else {
            return "There is no calendar for new events."
        }
        return "Added to \(calendar.title) with an alert at this moment, fixed for where you are now."
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
}

private extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
