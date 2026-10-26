//
//  ConfidenceBars.swift
//  AppLocalizer
//

import SwiftUI

/// Three rising bars, as many filled as the suggestion's confidence.
/// Hidden from VoiceOver: the confidence's text carries the meaning.
struct ConfidenceBars: View {
    let confidence: RecommendationConfidence

    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        HStack(alignment: .bottom, spacing: 1.5) {
            ForEach(1...3, id: \.self) { level in
                RoundedRectangle(cornerRadius: 0.75)
                    .fill(level <= confidence.bars ? filled : Palette.fill3)
                    .frame(width: 2.5, height: CGFloat(3 + level * 2))
            }
        }
        .accessibilityHidden(true)
    }

    private var filled: Color {
        prominence == .increased ? .white : Palette.label2
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(RecommendationConfidence.allCases, id: \.self) { ConfidenceBars(confidence: $0) }
    }
    .padding()
}
