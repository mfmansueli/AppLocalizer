//
//  PrivacyConfidenceBadge.swift
//  AppLocalizer
//

import SwiftUI

/// Three small bars and High, Medium or Low. Neutral on purpose: it
/// describes the evidence, not whether the answer is good or bad.
struct PrivacyConfidenceBadge: View {
    let confidence: PrivacyConfidence

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            HStack(alignment: .bottom, spacing: 1.5) {
                ForEach(1...3, id: \.self) { bar in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(bar <= confidence.bars ? Palette.label2 : Palette.fill3)
                        .frame(width: 2.5, height: 4 + CGFloat(bar) * 2.5)
                }
            }
            Text(confidence.title)
                .font(.caption)
                .foregroundStyle(Palette.label2)
        }
        .help(String(localized: "\(confidence.title) confidence · \(confidence.meaning)"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(confidence.title) confidence: \(confidence.meaning)"))
    }
}

#Preview {
    VStack(alignment: .leading) {
        ForEach(PrivacyConfidence.allCases) { PrivacyConfidenceBadge(confidence: $0) }
    }
    .padding()
}
