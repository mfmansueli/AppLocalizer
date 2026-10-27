//
//  Palette.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// Every color the UI uses, by role (design handoff, "Tokens"). Surfaces and
/// separators are the system's; the rest carry the handoff's values for
/// light, dark and both Increase Contrast appearances. Swap values here,
/// never at the call site.
///
/// Color carries meaning only: increase (orange), decrease (teal), error,
/// warning, machine-translated (purple) and unsaved (accent dot).
enum Palette {
    // MARK: - Accent

    static let accent = Color.accentColor
    /// Links and accent-colored text, deepened under Increase Contrast.
    static let accentText = dynamic(light: 0x0066CC, dark: 0x4DA3FF, lightHC: 0x0040DD, darkHC: 0x8CC4FF)
    static let accentTint = dynamic(light: 0x0071E3, dark: 0x4DA3FF, lightHC: 0x0040DD, darkHC: 0x8CC4FF, alpha: [0.12, 0.18, 0.14, 0.22])

    // MARK: - Text

    static let label = Color.primary
    /// Darker than the system's secondary label so 11 pt grey still passes 4.5:1.
    static let label2 = dynamic(light: 0x6B6B70, dark: 0xA3A3AA, lightHC: 0x3D3D42, darkHC: 0xD4D4DA)
    static let label3 = dynamic(light: 0x9A9AA0, dark: 0x6E6E75, lightHC: 0x5F5F66, darkHC: 0xA8A8B0)

    // MARK: - Surfaces

    /// Behind the sidebar pane.
    static let window = Color(nsColor: .windowBackgroundColor)
    /// Tables and editors.
    static let content = Color(nsColor: .textBackgroundColor)
    /// Cards, popovers and sheets.
    static let raised = Color(nsColor: .controlBackgroundColor)
    static let separator = Color(nsColor: .separatorColor)
    /// Control edges and stronger dividers.
    static let separator2 = dynamic(light: 0x000000, dark: 0xFFFFFF, lightHC: 0x000000, darkHC: 0xFFFFFF, alpha: [0.16, 0.16, 0.55, 0.55])
    /// Chips, tokens and flag tiles, from faint to strong.
    static let fill1 = dynamic(light: 0x000000, dark: 0xFFFFFF, lightHC: 0x000000, darkHC: 0xFFFFFF, alpha: [0.04, 0.05, 0.07, 0.09])
    static let fill2 = dynamic(light: 0x000000, dark: 0xFFFFFF, lightHC: 0x000000, darkHC: 0xFFFFFF, alpha: [0.07, 0.09, 0.11, 0.14])
    static let fill3 = dynamic(light: 0x000000, dark: 0xFFFFFF, lightHC: 0x000000, darkHC: 0xFFFFFF, alpha: [0.12, 0.15, 0.18, 0.22])
    /// Placeholder blocks while something loads.
    static let skeleton = dynamic(light: 0x000000, dark: 0xFFFFFF, lightHC: 0x000000, darkHC: 0xFFFFFF, alpha: [0.07, 0.08, 0.11, 0.14])

    // MARK: - Meaning

    /// Price increase: text, mark (arrows, bars) and pill tint.
    static let increase = dynamic(light: 0xA84800, dark: 0xFFA552, lightHC: 0x7F3500, darkHC: 0xFFC490)
    static let increaseMark = dynamic(light: 0xE86E00, dark: 0xFF9F40, lightHC: 0xC25A00, darkHC: 0xFFB060)
    static let increaseTint = dynamic(light: 0xE86E00, dark: 0xFF963C, lightHC: 0xE86E00, darkHC: 0xFF963C, alpha: [0.13, 0.17, 0.18, 0.24])

    /// Price decrease.
    static let decrease = dynamic(light: 0x00727C, dark: 0x5CD6E0, lightHC: 0x005660, darkHC: 0x95EAF0)
    static let decreaseMark = dynamic(light: 0x0096A5, dark: 0x46CDDC, lightHC: 0x007A87, darkHC: 0x70DEE8)
    static let decreaseTint = dynamic(light: 0x0096A5, dark: 0x46CDDC, lightHC: 0x0096A5, darkHC: 0x46CDDC, alpha: [0.12, 0.16, 0.18, 0.24])

    /// Errors and values over a limit.
    static let danger = dynamic(light: 0xC8102E, dark: 0xFF7A70, lightHC: 0x9E0020, darkHC: 0xFFA8A2)
    static let dangerMark = dynamic(light: 0xE0182D, dark: 0xFF5A50, lightHC: 0xB80020, darkHC: 0xFF7A70)
    static let dangerTint = dynamic(light: 0xD70015, dark: 0xFF5A50, lightHC: 0xD70015, darkHC: 0xFF5A50, alpha: [0.09, 0.16, 0.14, 0.24])

    /// Warnings, fallbacks and stale data.
    static let warning = dynamic(light: 0x7A5600, dark: 0xFFD34D, lightHC: 0x5A3F00, darkHC: 0xFFE28A)
    static let warningMark = dynamic(light: 0xF5B400, dark: 0xFFCC33, lightHC: 0xD99A00, darkHC: 0xFFD84D)
    static let warningTint = dynamic(light: 0xFFBE00, dark: 0xFFCD3C, lightHC: 0xFFBE00, darkHC: 0xFFCD3C, alpha: [0.20, 0.15, 0.30, 0.22])

    /// Machine-translated text that nobody has reviewed yet.
    static let machineTranslated = dynamic(light: 0x7A35B0, dark: 0xD4A3FF, lightHC: 0x5C1E91, darkHC: 0xE6C8FF)
    static let machineTranslatedMark = dynamic(light: 0x9B4FD6, dark: 0xC48CFF, lightHC: 0x7E36B8, darkHC: 0xD4A8FF)
    static let machineTranslatedTint = dynamic(light: 0x9646D2, dark: 0xC88CFF, lightHC: 0x9646D2, darkHC: 0xC88CFF, alpha: [0.11, 0.17, 0.17, 0.24])

    /// The 8 pt dot on anything that isn't pushed yet.
    static let unsaved = dynamic(light: 0x0071E3, dark: 0x4DA3FF, lightHC: 0x0040DD, darkHC: 0x8CC4FF)

    /// Kept for older call sites: a positive confirmation (done, succeeded).
    static let positive = Color.green

    /// Fill behind app-icon placeholders and empty tiles.
    static let tile = fill2
    /// Dashed outline of drop zones.
    static let dropOutline = separator2
    /// The neutral stage screenshot renders sit on (viewer, template
    /// canvas), so their own colors read true.
    static let stage = dynamic(light: 0xE7E7EC, dark: 0x0E0E10, lightHC: 0xDADAE0, darkHC: 0x000000)

    // MARK: - Building

    /// A color that resolves per appearance: light, dark, and their Increase
    /// Contrast variants. `alpha` lists the four opacities in the same order.
    private static func dynamic(
        light: UInt32,
        dark: UInt32,
        lightHC: UInt32,
        darkHC: UInt32,
        alpha: [Double] = [1, 1, 1, 1]
    ) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [
                .aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua,
            ])
            switch match {
            case .darkAqua: return rgb(dark, alpha: alpha[1])
            case .accessibilityHighContrastAqua: return rgb(lightHC, alpha: alpha[2])
            case .accessibilityHighContrastDarkAqua: return rgb(darkHC, alpha: alpha[3])
            default: return rgb(light, alpha: alpha[0])
            }
        })
    }

    private static func rgb(_ hex: UInt32, alpha: Double) -> NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
