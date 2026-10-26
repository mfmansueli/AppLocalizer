//
//  RateLimitMeter.swift
//  AppLocalizer
//

import SwiftUI

/// "Rate limit ▬▬── 457 of 3,600 requests this hour": App Store Connect's
/// hourly quota, so a long push never surprises anyone.
struct RateLimitMeter: View {
    let rateLimit: AppStoreConnectRateLimit

    var body: some View {
        HStack(spacing: Spacing.small) {
            Text("Rate limit")
                .font(.caption)
                .foregroundStyle(Palette.label2)
            MeterBar(fraction: rateLimit.fractionUsed, tint: tint, height: 4)
            Text("\(rateLimit.used.formatted()) of \(rateLimit.limit.formatted()) requests this hour")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .monospacedDigit()
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Rate limit"))
        .accessibilityValue(Text("\(rateLimit.used) of \(rateLimit.limit) requests this hour"))
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
