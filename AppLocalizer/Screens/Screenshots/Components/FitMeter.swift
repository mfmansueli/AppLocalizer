//
//  FitMeter.swift
//  AppLocalizer
//

import SwiftUI

/// How full a caption's box is: the bar shows the fill, the first tick
/// what fits at full size, the second the most that fits at the smallest
/// size. Past it the caption overflows. Captions have no character limit;
/// this replaces the counter.
struct FitMeter: View {
    let value: FitMeterValue
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.fill2)
                Capsule().fill(tint).frame(width: width * CGFloat(value.filled))
                tick(at: CGFloat(value.fullSizeTick) * width)
                tick(at: CGFloat(value.smallestSizeTick) * width)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private func tick(at x: CGFloat) -> some View {
        Rectangle()
            .fill(Palette.label3)
            .frame(width: 1, height: height + 6)
            .offset(x: x)
    }

    private var tint: Color {
        switch value.tone {
        case .fits: Palette.label3
        case .shrinks: Palette.warningMark
        case .overflows: Palette.dangerMark
        case .empty: .clear
        }
    }
}
