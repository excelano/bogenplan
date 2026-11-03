// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import EventKit
import SwiftUI

struct SettingsView: View {
    let calendars: CalendarStore
    let place: Place

    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingKey.scale) private var scale = Scale.standard.rawValue
    @AppStorage(SettingKey.precision) private var precision = Precision.standard.rawValue
    @AppStorage(SettingKey.showsCivilTime) private var showsCivilTime = true

    var body: some View {
        NavigationStack {
            Form {
                bogenzeitSection
                ForEach(sources, id: \.title) { source in
                    calendarSection(source.title, source.calendars)
                }
                placeSection
                versionSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Palette.sun)
    }

    private var bogenzeitSection: some View {
        Section {
            Picker("Scale", selection: $scale) {
                ForEach(Scale.allCases) { Text($0.title).tag($0.rawValue) }
            }
            Picker("Precision", selection: $precision) {
                ForEach(Precision.allCases) { Text($0.title).tag($0.rawValue) }
            }
            Toggle("Show civil time", isOn: $showsCivilTime)
        } header: {
            Text("Bogenzeit")
        } footer: {
            Text("Event times read as spans or kiloseconds before or after solar noon or solar midnight where you are. Civil time is shown beside them, for the people who keep the clock.")
        }
    }

    private var sources: [(title: String, calendars: [EKCalendar])] {
        Dictionary(grouping: calendars.calendars) { $0.source?.title ?? "On My iPhone" }
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { (title: $0.key, calendars: $0.value) }
    }

    private func calendarSection(_ title: String, _ list: [EKCalendar]) -> some View {
        Section(title) {
            ForEach(list, id: \.calendarIdentifier) { calendar in
                Toggle(isOn: Binding(
                    get: { calendars.isVisible(calendar) },
                    set: { calendars.setVisible($0, calendar) }
                )) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(cgColor: calendar.cgColor))
                            .frame(width: 10, height: 10)
                        Text(calendar.title)
                    }
                }
            }
        }
    }

    private var placeSection: some View {
        Section {
            LabeledContent("Latitude", value: String(format: "%.2f", place.latitude))
            LabeledContent("Longitude", value: String(format: "%.2f", place.longitude))
        } header: {
            Text("Place")
        } footer: {
            Text("Approximate, read while Bogenplan is open, and kept on this iPhone.")
        }
    }

    private var versionSection: some View {
        Section {
            let info = Bundle.main.infoDictionary
            let version = info?["CFBundleShortVersionString"] as? String ?? "?"
            let build = info?["CFBundleVersion"] as? String ?? "?"
            Text("Version \(version) (build \(build))")
                .font(.footnote.monospaced())
                .foregroundStyle(Palette.label)
                .frame(maxWidth: .infinity)
        }
    }
}
