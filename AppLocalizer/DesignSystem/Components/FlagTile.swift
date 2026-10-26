//
//  FlagTile.swift
//  AppLocalizer
//

import SwiftUI

/// A territory's or locale's flag: the system's regional-indicator glyph for
/// an ISO 3166 alpha-2 code (`BR` → 🇧🇷), or the code on a small tile when
/// there's no flag for it. Decorative: the name next to it is what VoiceOver
/// reads.
struct FlagTile: View {
    /// ISO 3166-1 alpha-2, e.g. `BR`.
    let regionCode: String
    var size: CGFloat = 14

    var body: some View {
        Group {
            if let flag = Self.flag(for: regionCode) {
                Text(flag)
                    .font(.system(size: size))
            } else {
                Text(regionCode.uppercased())
                    .font(.system(size: size * 0.55, weight: .semibold).monospaced())
                    .foregroundStyle(Palette.label2)
                    .frame(width: size * 1.4, height: size)
                    .background(Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.flag))
            }
        }
        .accessibilityHidden(true)
    }

    /// The flag emoji for a two-letter region code, or nil when it isn't one.
    nonisolated static func flag(for regionCode: String) -> String? {
        let letters = regionCode.uppercased().unicodeScalars
        guard letters.count == 2, letters.allSatisfy({ ("A"..."Z").contains($0) }) else { return nil }
        let scalars = letters.compactMap { UnicodeScalar(0x1F1E6 + $0.value - 65) }
        return String(String.UnicodeScalarView(scalars))
    }
}

#Preview {
    HStack {
        FlagTile(regionCode: "BR")
        FlagTile(regionCode: "JP")
        FlagTile(regionCode: "EU1")
    }
    .padding()
}
