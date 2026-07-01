import SwiftUI

enum Theme {
    static let bgBase = Color(hex: 0x14171B)
    static let bgSidebar = Color(hex: 0x1A1D22)
    static let bgElevated = Color(hex: 0x20242B)
    static let border = Color(hex: 0x272B32)
    static let borderSoft = Color(hex: 0x1F232A)

    static let accentTeal = Color(hex: 0x2DD8C5)
    static let accentBlue = Color(hex: 0x5C8DF6)
    static let accentAmber = Color(hex: 0xF6B85C)

    static let textPrimary = Color(hex: 0xECEDF1)
    static let textSecondary = Color(hex: 0x868D99)
    static let textTertiary = Color(hex: 0x5A606B)

    static let online = Color(hex: 0x3DDC84)
    static let offline = Color(hex: 0xFF6B6B)
    static let warn = Color(hex: 0xF6B85C)
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
