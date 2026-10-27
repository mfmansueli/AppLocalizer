//
//  RateLimitMeter.swift
//  AppLocalizer
//

import SwiftUI

/// "Requests this hour ▬▬── 457 of 3,600": App Store Connect's hourly
/// quota, so a long push never surprises anyone.
struct RateLimitMeter: View {
    let rateLimit: AppStoreConnectRateLimit

    var body: some View {
        HStack(spacing: Spacing.small) {
            Text("Requests this hour")
                .font(.caption)
                .foregroundStyle(Palette.label2)
            MeterBar(fraction: rateLimit.fractionUsed, tint: tint, height: 4)
            Text("\(rateLimit.used.formatted()) of \(rateLimit.limit.formatted())")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .monospacedDigit()
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Requests this hour"))
        .accessibilityValue(Text("\(rateLimit.used) of \(rateLimit.limit)"))
        .accessibilityIdentifier("push.rateMeter")
    }

    private var tint: Color {
        rateLimit.fractionUsed > 0.9 ? Palette.warningMark : Palette.label3
    }
}

#Preview {
    RateLimitMeter(rateLimit: AppStoreConnectRateLimit(limit: 3600, remaining: 3143))
        .frame(width: 700)
        .padding()
}
