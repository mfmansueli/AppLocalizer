//
//  CoverageRing.swift
//  AppLocalizer
//

import SwiftUI

/// A tiny progress ring for store-page locale coverage, with the locale
/// count next to it (sidebar rows).
struct CoverageRing: View {
    /// Locales with a store page.
    let count: Int
    /// Every App Store locale (39).
    var total = 39

    var body: some View {
        HStack(spacing: 3) {
            ZStack {
                Circle()
                    .stroke(Palette.fill3, lineWidth: 1.6)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(Palette.label2, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 9, height: 9)
            Text(count, format: .number)
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(Palette.label2)
        }
        .accessibilityElement()
        .accessibilityLabel(Text("\(count) of \(total) locales"))
    }

    private var fraction: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(min(count, total)) / CGFloat(total)
    }
}

#Preview {
    VStack(alignment: .trailing) {
        CoverageRing(count: 2)
        CoverageRing(count: 18)
        CoverageRing(count: 39)
    }
    .padding()
}
