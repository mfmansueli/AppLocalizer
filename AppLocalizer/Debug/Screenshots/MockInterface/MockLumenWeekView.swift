//
//  MockLumenWeekView.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Lumen's week: a mood chart and two highlight photos.
struct MockLumenWeekView: View {
    let strings: MockLumenStrings

    private static let bars: [CGFloat] = [0.45, 0.7, 0.55, 0.95, 0.6, 0.8, 0.5]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(strings.weekTitle).font(.system(size: 32, weight: .bold)).foregroundStyle(MockLumenPalette.ink)
            Text(strings.weekSummary).font(.system(size: 14)).foregroundStyle(MockLumenPalette.secondary)
            MockLumenCard {
                HStack(alignment: .bottom, spacing: 14) {
                    ForEach(Array(Self.bars.enumerated()), id: \.offset) { index, height in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(index == 3 ? MockLumenPalette.accent : MockLumenPalette.accent.opacity(0.45))
                            .frame(width: 22, height: 120 * height)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 130, alignment: .bottom)
                Text(strings.days).font(.system(size: 12, weight: .medium)).foregroundStyle(MockLumenPalette.secondary)
                    .frame(maxWidth: .infinity)
            }
            Text(strings.highlights).font(.system(size: 17, weight: .bold)).foregroundStyle(MockLumenPalette.ink)
            HStack(spacing: 12) {
                photo(MockLumenPalette.teal, caption: strings.highlight1)
                photo(MockLumenPalette.peach, caption: strings.highlight2)
            }
        }
    }

    private func photo(_ fill: LinearGradient, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 12).fill(fill).frame(height: 110)
            Text(caption).font(.system(size: 12, weight: .medium)).foregroundStyle(MockLumenPalette.ink).lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}
#endif
