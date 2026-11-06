//
//  GuidedWorkingRing.swift
//  AppLocalizer
//

import SwiftUI

/// An arc that turns around a step's dot or badge while Autopilot works on
/// it. With Reduce Motion it stands still as a full ring.
struct GuidedWorkingRing: View {
    /// The ring's outer size.
    var size: CGFloat
    var lineWidth: CGFloat = 2
    /// One turn, in seconds.
    var period: Double = 1.1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.accent.opacity(0.22), lineWidth: lineWidth)
            if reduceMotion {
                Circle()
                    .stroke(Palette.accent, lineWidth: lineWidth)
            } else {
                // Drawn from the clock, so it keeps turning however often
                // the view around it is redrawn.
                TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Palette.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(angle(at: context.date)))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func angle(at date: Date) -> Double {
        date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period * 360
    }
}
