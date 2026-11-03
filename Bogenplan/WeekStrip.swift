// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import SwiftUI

/// The selected day's week, one tap from any of its days, swiped a week at a
/// time.
struct WeekStrip: View {
    @Binding var selection: Int
    let today: Int
    let days: ClosedRange<Int>

    @State private var week: Int

    init(selection: Binding<Int>, today: Int, days: ClosedRange<Int>) {
        _selection = selection
        self.today = today
        self.days = days
        _week = State(initialValue: Self.weekStart(of: selection.wrappedValue))
    }

    var body: some View {
        TabView(selection: $week) {
            ForEach(Array(stride(from: Self.weekStart(of: days.lowerBound), through: days.upperBound, by: 7)), id: \.self) { start in
                HStack(spacing: 0) {
                    ForEach(start..<start + 7, id: \.self) { cell($0) }
                }
                .padding(.horizontal, 8)
                .tag(start)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 60)
        .onChange(of: selection) { _, day in
            let start = Self.weekStart(of: day)
            if start != week { withAnimation { week = start } }
        }
        .onChange(of: week) { _, start in
            let current = Self.weekStart(of: selection)
            guard start != current else { return }
            selection = min(max(start + selection - current, days.lowerBound), days.upperBound)
        }
    }

    private func cell(_ id: Int) -> some View {
        let day = CalendarDay(daysSinceEpoch: id)
        let isSelected = id == selection
        let isToday = id == today
        return Button { selection = id } label: {
            VStack(spacing: 4) {
                Text(Calendar.current.veryShortStandaloneWeekdaySymbols[day.weekday - 1])
                    .font(.caption2)
                    .foregroundStyle(Palette.label)
                Text("\(day.day)")
                    .font(.callout.weight(isToday || isSelected ? .semibold : .regular).monospacedDigit())
                    .foregroundStyle(isSelected ? Palette.night : isToday ? Palette.sun : Palette.line)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(isSelected ? (isToday ? Palette.sun : Palette.line) : .clear))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!days.contains(id))
        .accessibilityLabel(day.civilInterval.start.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private static func weekStart(of id: Int) -> Int {
        CalendarDay(daysSinceEpoch: id).startOfWeek.daysSinceEpoch
    }
}
