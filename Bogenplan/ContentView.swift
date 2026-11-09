// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import EventKit
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var calendars = CalendarStore()
    @State private var solarPlace = SolarPlace()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if calendars.access != .fullAccess {
                calendarGate
            } else if let place = Demo.active ? Demo.place : solarPlace.place {
                DayPager(place: place, calendars: calendars)
                    .environment(calendars)
            } else {
                locationGate
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            calendars.refresh()
            solarPlace.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged).receive(on: RunLoop.main)) { _ in
            calendars.reload()
        }
    }

    @ViewBuilder private var calendarGate: some View {
        if calendars.access == .notDetermined {
            AccessGate(
                title: "Your calendars",
                message: "Bogenplan shows the calendars on this iPhone laid out on the Sun's arc, adds the moments you set to them, and saves the changes you make to an event. Your events stay here and are sent nowhere.",
                actionTitle: "Allow Calendar Access"
            ) { calendars.requestAccess() }
        } else {
            AccessGate(
                title: "Calendar access is off",
                message: "Bogenplan needs full access to read your events. Turn it on for Bogenplan in Settings, under Calendars.",
                actionTitle: "Open Settings",
                action: openSettings
            )
        }
    }

    @ViewBuilder private var locationGate: some View {
        switch solarPlace.authorization {
        case .notDetermined:
            AccessGate(
                title: "Where you are",
                message: "Solar noon, sunrise and sunset depend on where you are. Bogenplan uses your approximate location, reads it only while open, and keeps it on this iPhone.",
                actionTitle: "Use Approximate Location"
            ) { solarPlace.request() }
        case .denied, .restricted:
            AccessGate(
                title: "Location access is off",
                message: "Bogenplan needs your approximate location to find the Sun's arc where you are. Turn it on for Bogenplan in Settings, under Location.",
                actionTitle: "Open Settings",
                action: openSettings
            )
        default:
            ProgressView("Finding where you are")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.night)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}

private struct AccessGate: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.line)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.label)
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
                .tint(Palette.sun)
                .foregroundStyle(Palette.night)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.night)
    }
}
