// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import Foundation

/// One Bogenzeit day at a place, laid out as its 400 spans from the starting
/// ○ (spec §3.8), or evenly from ○ to ○ on a day with no sunrise or sunset.
struct DayAxis {
    static let length = 400.0

    struct Mark: Identifiable {
        let position: Double
        let instant: Date
        let glyph: Glyph
        var number: String? = nil
        var before = false

        /// An anchor, a horizon event or an eighth boundary.
        var isEighthBoundary = true

        var id: Double { position }
    }

    let solar: SolarDay
    let place: Place

    init(_ day: CalendarDay, at place: Place) {
        solar = SolarDay(day, latitude: place.latitude, longitude: place.longitude)
        self.place = place
    }

    var start: Date { solar.midnightStart }
    var end: Date { solar.midnightEnd }

    func contains(_ instant: Date) -> Bool {
        start <= instant && instant < end
    }

    /// The instant's place on the axis, clamped to the day.
    func position(of instant: Date) -> Double {
        guard instant > start else { return 0 }
        guard instant < end else { return Self.length }
        if let place = Reading(at: instant, latitude: place.latitude, longitude: place.longitude).placeInDay {
            return place
        }
        return Self.length * instant.timeIntervalSince(start) / end.timeIntervalSince(start)
    }

    /// The part of the day in which the Sun stands above the altitude of
    /// `arc`, or nil when it never does.
    func extent(of arc: Solar.HalfArc) -> ClosedRange<Double>? {
        switch arc {
        case .alwaysAbove:
            return 0...Self.length
        case .alwaysBelow:
            return nil
        case .seconds(let seconds):
            return position(of: solar.noon.addingTimeInterval(-seconds))...position(of: solar.noon.addingTimeInterval(seconds))
        }
    }

    /// A mark every `step` spans, the anchors, horizon events and eighth
    /// boundaries (spec §3.6) among them; on a polar day only ○, ☉ and ○.
    func marks(every step: Int) -> [Mark] {
        guard let sunrise = solar.sunrise, let sunset = solar.sunset, let halfDay = solar.halfDay else {
            return [
                Mark(position: 0, instant: start, glyph: .midnight),
                Mark(position: position(of: solar.noon), instant: solar.noon, glyph: .noon),
                Mark(position: Self.length, instant: end, glyph: .midnight),
            ]
        }
        return stride(from: 0, through: Int(Self.length), by: step).map { span in
            var mark = mark(at: span, sunrise: sunrise, sunset: sunset, halfDay: halfDay)
            mark.isEighthBoundary = span % 50 == 0
            return mark
        }
    }

    private func mark(at span: Int, sunrise: Date, sunset: Date, halfDay: Double) -> Mark {
        let position = Double(span)
        switch span {
        case 0:
            return Mark(position: position, instant: start, glyph: .midnight)
        case ..<100:
            let instant = start.addingTimeInterval(sunrise.timeIntervalSince(start) * position / 100)
            return Mark(position: position, instant: instant, glyph: .midnight, number: "\(span)")
        case 100:
            return Mark(position: position, instant: sunrise, glyph: .sunrise)
        case ..<300:
            let fromNoon = span - 200
            let instant = solar.noon.addingTimeInterval(halfDay * Double(fromNoon) / 100)
            return Mark(position: position, instant: instant, glyph: .noon,
                        number: fromNoon == 0 ? nil : "\(abs(fromNoon))", before: fromNoon < 0)
        case 300:
            return Mark(position: position, instant: sunset, glyph: .sunset)
        case ..<400:
            let instant = sunset.addingTimeInterval(end.timeIntervalSince(sunset) * (position - 300) / 100)
            return Mark(position: position, instant: instant, glyph: .midnight, number: "\(400 - span)", before: true)
        default:
            return Mark(position: position, instant: end, glyph: .midnight)
        }
    }
}
