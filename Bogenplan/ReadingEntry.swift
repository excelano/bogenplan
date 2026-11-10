// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import BogenzeitUI
import SwiftUI

struct ReadingEntry: View {
    @Binding var instant: Date
    let readout: Readout

    private static let glyphs: [Glyph] = [.midnight, .sunrise, .noon, .sunset]
    private static let unplaced = Color(red: 1, green: 0.54, blue: 0.5)

    @State private var number = ""
    @State private var before = false
    @State private var glyph = Glyph.noon
    @State private var shown: Date?
    @FocusState private var typing: Bool

    var body: some View {
        let axis = DayAxis(bogenzeitDay(of: instant, longitude: readout.place.longitude), at: readout.place)
        let spans = Self.usesSpans(axis, readout)
        let placeable = target(axis, spans: spans) != nil
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("0", text: $number)
                    .keyboardType(.decimalPad)
                    .focused($typing)
                    .multilineTextAlignment(.trailing)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(placeable ? Palette.line : Self.unplaced)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(width: 84)
                    .background(Palette.line.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel(spans ? "Spans" : "Kiloseconds")
                Text(spans ? "spans" : "ks")
                    .font(.subheadline)
                    .foregroundStyle(Palette.label)
                Picker("Side", selection: $before) {
                    Text("before").tag(true)
                    Text("after").tag(false)
                }
                .pickerStyle(.segmented)
            }
            HStack(spacing: 8) {
                ForEach(Self.glyphs, id: \.character) { option in
                    Button { glyph = option } label: {
                        GlyphView(option, radius: 7, lineWidth: 1.7, color: Palette.line)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(glyph == option ? Palette.sun.opacity(0.3) : Palette.line.opacity(0.08),
                                        in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.name)
                    .accessibilityAddTraits(glyph == option ? .isSelected : [])
                }
            }
        }
        .onAppear(perform: show)
        .onChange(of: instant) { _, moved in
            if moved != shown { show() }
        }
        .onChange(of: number) { place() }
        .onChange(of: before) { place() }
        .onChange(of: glyph) { place() }
        .toolbar {
            if typing {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { typing = false }
                }
            }
        }
    }

    private func show() {
        let position = readout.position(at: instant)
        number = position.number ?? "0"
        before = position.side == .before
        glyph = position.glyph
        shown = instant
    }

    private func place() {
        let position = readout.position(at: instant)
        guard number != (position.number ?? "0") || before != (position.side == .before) || glyph != position.glyph
        else { return }
        let axis = DayAxis(bogenzeitDay(of: instant, longitude: readout.place.longitude), at: readout.place)
        guard let target = target(axis, spans: Self.usesSpans(axis, readout)), target != instant else { return }
        shown = target
        instant = target
    }

    private func target(_ axis: DayAxis, spans: Bool) -> Date? {
        guard let value = Double(number.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")),
              value.isFinite, value >= 0 else { return nil }
        return Self.placed(value, before: before, glyph: glyph, spans: spans, on: axis)
    }

    private static func usesSpans(_ axis: DayAxis, _ readout: Readout) -> Bool {
        readout.scale == .spans && axis.solar.sunrise != nil && axis.solar.sunset != nil
    }

    static func placed(_ value: Double, before: Bool, glyph: Glyph, spans: Bool, on axis: DayAxis) -> Date? {
        let signed = before ? -value : value
        let endingMidnight = glyph == .midnight && before && value > 0
        if spans {
            let anchor: Double = switch glyph {
            case .midnight: endingMidnight ? DayAxis.length : 0
            case .sunrise: DayAxis.length / 4
            case .noon: DayAxis.length / 2
            case .sunset: DayAxis.length * 3 / 4
            }
            let place = anchor + signed
            guard (0..<DayAxis.length).contains(place) else { return nil }
            return axis.instant(at: place).wholeSecond
        }
        let anchor: Date? = switch glyph {
        case .midnight: endingMidnight ? axis.end : axis.start
        case .sunrise: axis.solar.sunrise
        case .noon: axis.solar.noon
        case .sunset: axis.solar.sunset
        }
        guard let at = anchor?.addingTimeInterval(signed * 1000), axis.contains(at) else { return nil }
        return at.wholeSecond
    }
}
