// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

enum Palette {
    static let night = Color(hex: 0x0A1222)
    static let astronomicalTwilight = Color(hex: 0x121F38)
    static let nauticalTwilight = Color(hex: 0x1B2D50)
    static let civilTwilight = Color(hex: 0x2A4470)
    static let day = Color(hex: 0x33598A)
    static let line = Color(hex: 0xF2F5FA)
    static let minorTick = Color(hex: 0x8FA3BF)
    static let majorTick = Color(hex: 0xDDE6F2)
    static let sun = Color(hex: 0xFFE2A0)
    static let label = Color(hex: 0xA9B8CC)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
