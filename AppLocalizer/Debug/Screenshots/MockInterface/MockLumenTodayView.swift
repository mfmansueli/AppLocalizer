//
//  MockLumenTodayView.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Lumen's Today screen: the prompt card, moods and the week's entries.
struct MockLumenTodayView: View {
    let strings: MockLumenStrings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(strings.date).font(.system(size: 12, weight: .semibold)).foregroundStyle(MockLumenPalette.secondary)
            Text(strings.title).font(.system(size: 32, weight: .bold)).foregroundStyle(MockLumenPalette.ink)
            MockLumenCard {
                Text(strings.promptLabel).font(.system(size: 11, weight: .bold)).foregroundStyle(MockLumenPalette.accent)
                Text(strings.prompt).font(.system(size: 19, weight: .semibold)).foregroundStyle(MockLumenPalette.ink)
                MockLumenPlaceholder(width: 300)
                MockLumenPlaceholder(width: 240)
                MockLumenPlaceholder(width: 160)
            }
            HStack(spacing: 8) {
                Text(strings.mood).font(.system(size: 13, weight: .semibold)).foregroundStyle(MockLumenPalette.secondary)
                ForEach(Array(strings.moods.enumerated()), id: \.offset) { index, mood in
                    Text(mood)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(index == 0 ? Color.white : MockLumenPalette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(index == 0 ? MockLumenPalette.accent : MockLumenPalette.card, in: Capsule())
                }
            }
            Text(strings.earlier).font(.system(size: 17, weight: .bold)).foregroundStyle(MockLumenPalette.ink)
            entry(MockLumenPalette.peach)
            entry(MockLumenPalette.teal)
        }
    }

    private func entry(_ fill: LinearGradient) -> some View {
        MockLumenCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    MockLumenPlaceholder(width: 180)
                    MockLumenPlaceholder(width: 130)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 8).fill(fill).frame(width: 44, height: 44)
            }
        }
    }
}
#endif
