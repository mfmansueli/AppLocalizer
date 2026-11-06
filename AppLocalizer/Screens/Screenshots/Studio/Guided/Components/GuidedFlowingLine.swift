//
//  GuidedFlowingLine.swift
//  AppLocalizer
//

import SwiftUI

/// The stepper's line between two steps while Autopilot works between
/// them (localizing after Choose): a light that runs along it. With Reduce
/// Motion it's a half-filled line.
struct GuidedFlowingLine: View {
    /// One pass, in seconds.
    var period: Double = 1.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.fill2)
                if reduceMotion {
                    Capsule().fill(Palette.accent).frame(width: width / 2)
                } else {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                        let light = max(16, width * 0.4)
                        let progress = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Palette.accent.opacity(0), Palette.accent, Palette.accent.opacity(0)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: light)
                            .offset(x: -light + (width + light) * progress)
                    }
                }
            }
            .clipShape(Capsule())
        }
        .accessibilityHidden(true)
    }
}
