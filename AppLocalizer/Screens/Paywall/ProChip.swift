//
//  ProChip.swift
//  AppLocalizer
//

import SwiftUI

/// The small PRO chip on a feature that's part of Pro, shown in Free
/// before it's clicked so the paywall is never a surprise.
struct ProChip: View {
    var body: some View {
        Text(verbatim: "PRO")
            .font(.system(size: 9, weight: .bold))
            .kerning(0.4)
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .frame(height: 15)
            .background(PaywallStyle.gradient, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .accessibilityLabel(Text("Part of Pro"))
            .accessibilityIdentifier("pro.chip")
    }
}

#Preview {
    ProChip().padding()
}
