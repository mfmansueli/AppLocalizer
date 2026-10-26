//
//  MeterBar.swift
//  AppLocalizer
//

import SwiftUI

/// A flat horizontal bar for a share of a whole: locale completeness,
/// equalized vs custom prices, requests used this hour.
struct MeterBar: View {
    /// 0…1.
    let fraction: Double
    var tint: Color = Palette.label3
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.fill2)
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    VStack {
        MeterBar(fraction: 0.88)
        MeterBar(fraction: 0.3, tint: Palette.warningMark)
    }
    .frame(width: 260)
    .padding()
}
