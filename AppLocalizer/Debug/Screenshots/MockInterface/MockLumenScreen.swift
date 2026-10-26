//
//  MockLumenScreen.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// A whole mock capture of the sample app: status bar, one screen and the
/// tab bar, in the language and direction of `locale`, at the device's
/// logical size (iPhone 440 × 956 pt, iPad landscape 1376 × 1032 pt).
/// DEBUG scenes render it as the captures; the real app never draws an
/// interface.
struct MockLumenScreen: View {
    let kind: MockLumenScreenKind
    let locale: String
    let isTablet: Bool

    static func logicalSize(isTablet: Bool) -> CGSize {
        isTablet ? CGSize(width: 1376, height: 1032) : CGSize(width: 440, height: 956)
    }

    private var strings: MockLumenStrings { .strings(for: locale) }

    var body: some View {
        let size = Self.logicalSize(isTablet: isTablet)
        HStack(spacing: 0) {
            if isTablet { sidebar }
            VStack(spacing: 0) {
                Text(verbatim: "9:41")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MockLumenPalette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    .frame(height: isTablet ? 32 : 60)
                screen
                    .padding(.horizontal, isTablet ? 48 : 22)
                    .padding(.top, 10)
                    .frame(maxWidth: isTablet ? 620 : .infinity, maxHeight: .infinity, alignment: .top)
                tabBar
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: size.width, height: size.height)
        .background(MockLumenPalette.background)
        .environment(\.layoutDirection, StoreLocaleCatalog.locale(code: locale)?.isRTL == true ? .rightToLeft : .leftToRight)
    }

    @ViewBuilder
    private var screen: some View {
        switch kind {
        case .today: MockLumenTodayView(strings: strings)
        case .week: MockLumenWeekView(strings: strings)
        case .search: MockLumenSearchView(strings: strings)
        case .photo: MockLumenPhotoView(strings: strings)
        case .lock: MockLumenLockView(strings: strings)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(verbatim: "Lumen").font(.system(size: 26, weight: .bold)).foregroundStyle(MockLumenPalette.ink)
            ForEach(0..<6, id: \.self) { index in
                MockLumenPlaceholder(width: CGFloat(170 - index * 14), height: 10)
            }
            Spacer()
        }
        .padding(28)
        .frame(width: 300, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(MockLumenPalette.card.opacity(0.7))
    }

    private var tabBar: some View {
        HStack {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6)
                    .fill(index == min(kind.rawValue, 3) ? MockLumenPalette.accent : MockLumenPalette.placeholder)
                    .frame(width: 26, height: 26)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: isTablet ? 64 : 92, alignment: .top)
        .padding(.top, 14)
        .background(MockLumenPalette.card.opacity(0.9))
    }
}
#endif
