// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import Foundation

/// How instants and durations are shown: at one place, in the chosen scale
/// and precision, with or without civil time beside them.
struct Readout {
    let place: Place
    let scale: Scale
    let precision: Precision
    let showsCivilTime: Bool

    func reading(at instant: Date) -> Reading {
        Reading(at: instant, latitude: place.latitude, longitude: place.longitude)
    }

    func position(at instant: Date) -> DisplayedPosition {
        DisplayedPosition(reading(at: instant), scale: scale, precision: precision)
    }

    func duration(from start: Date, to end: Date) -> String {
        SolarDuration(from: start, to: end, latitude: place.latitude, longitude: place.longitude).text(scale)
    }

    func stepped(_ instant: Date, by steps: Int) -> Date {
        let reading = reading(at: instant)
        if scale == .spans, let place = reading.placeInDay {
            let factor = pow(10, Double(precision.decimals(for: .spans)))
            let target = ((place * factor).rounded() + Double(steps)) / factor
            if let moved = reading.after(spans: target - place) { return moved.wholeSecond }
        }
        let step = pow(10, Double(3 - precision.decimals(for: .kiloseconds)))
        let anchor = instant.addingTimeInterval(-reading.offset)
        return anchor.addingTimeInterval(((reading.offset / step).rounded() + Double(steps)) * step).wholeSecond
    }

    func spoken(_ position: DisplayedPosition) -> String {
        guard let number = position.number else { return position.glyph.name }
        let unit = position.unit == nil ? "spans" : "kiloseconds"
        let side = position.side == .before ? "before" : "after"
        return "\(number) \(unit) \(side) \(position.glyph.name)"
    }

    func spokenRange(from start: Date, to end: Date) -> String {
        "\(spoken(position(at: start))) to \(spoken(position(at: end)))"
    }
}

extension Date {
    var wholeSecond: Date {
        Date(timeIntervalSince1970: (timeIntervalSince1970 + 0.001).rounded(.up))
    }
}
