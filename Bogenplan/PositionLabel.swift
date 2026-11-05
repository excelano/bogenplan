// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import BogenzeitUI
import SwiftUI

/// A Bogenzeit position with its glyph drawn, the number on the side the
/// positional rule puts it (spec §3.2).
struct PositionLabel: View {
    let glyph: Glyph
    let number: String?
    let before: Bool
    let font: Font
    let color: Color
    @ScaledMetric private var radius: CGFloat

    init(glyph: Glyph, number: String? = nil, before: Bool = false,
         style: Font.TextStyle = .caption, weight: Font.Weight = .regular, color: Color = Palette.line) {
        self.glyph = glyph
        self.number = number
        self.before = before
        self.font = .system(style, weight: weight).monospacedDigit()
        self.color = color
        _radius = ScaledMetric(wrappedValue: Self.baseRadius(style), relativeTo: style)
    }

    init(_ position: DisplayedPosition, style: Font.TextStyle = .caption,
         weight: Font.Weight = .regular, color: Color = Palette.line) {
        let number = position.number.map { number in position.unit.map { "\(number) \($0)" } ?? number }
        self.init(glyph: position.glyph, number: number, before: position.side == .before,
                  style: style, weight: weight, color: color)
    }

    var body: some View {
        HStack(spacing: radius * 0.5) {
            if before, let value { value }
            GlyphView(glyph, radius: radius, lineWidth: radius * 0.24, color: color)
            if !before, let value { value }
        }
        .fixedSize()
    }

    private var value: Text? {
        number.map { Text($0).font(font).foregroundStyle(color) }
    }

    private static func baseRadius(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .caption, .caption2, .footnote: 4.5
        case .largeTitle: 13
        default: 6
        }
    }
}
