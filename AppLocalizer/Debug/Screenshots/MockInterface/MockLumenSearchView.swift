//
//  MockLumenSearchView.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Lumen's search: a query and the entries that match it.
struct MockLumenSearchView: View {
    let strings: MockLumenStrings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(strings.searchTitle).font(.system(size: 32, weight: .bold)).foregroundStyle(MockLumenPalette.ink)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(MockLumenPalette.secondary)
                Text(strings.query).font(.system(size: 16)).foregroundStyle(MockLumenPalette.ink)
                Rectangle().fill(MockLumenPalette.accent).frame(width: 2, height: 20)
                Spacer()
            }
            .padding(12)
            .background(MockLumenPalette.placeholder.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            Text(strings.results).font(.system(size: 12, weight: .semibold)).foregroundStyle(MockLumenPalette.secondary)
            ForEach(0..<4, id: \.self) { index in
                MockLumenCard {
                    MockLumenPlaceholder(width: 110)
                    HStack(spacing: 8) {
                        MockLumenPlaceholder(width: 50)
                        Text(strings.query)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(MockLumenPalette.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MockLumenPalette.accentSoft, in: RoundedRectangle(cornerRadius: 4))
                        MockLumenPlaceholder(width: CGFloat(150 - index * 12))
                    }
                    MockLumenPlaceholder(width: 220)
                }
            }
        }
    }
}
#endif
