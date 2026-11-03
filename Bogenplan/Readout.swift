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
