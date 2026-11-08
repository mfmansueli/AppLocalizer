//
//  MockLumenMacDesktop.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// The sample app on a Mac, as a full-screen capture: the desktop, the
/// menu bar with Lumen's menus, and Lumen's window (its iPad layout under
/// a title bar). Drawn at 1440 × 900 points (2880 × 1800 pixels at 2×).
struct MockLumenMacDesktop: View {
    let kind: MockLumenScreenKind
    let locale: String

    static let logicalSize = CGSize(width: 1440, height: 900)

    /// The window's content: the iPad layout, scaled to 1100 points wide.
    private static let contentWidth: CGFloat = 1100
    private static let titleBarHeight: CGFloat = 28
    private static let menuBarHeight: CGFloat = 24

    var body: some View {
        let tablet = MockLumenScreen.logicalSize(isTablet: true)
        let scale = Self.contentWidth / tablet.width
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 0.45, green: 0.5, blue: 0.78), Color(red: 0.2, green: 0.22, blue: 0.45)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 0) {
                menuBar
                Spacer(minLength: 0)
            }
            VStack(spacing: 0) {
                titleBar
                MockLumenScreen(kind: kind, locale: locale, isTablet: true)
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(width: Self.contentWidth, height: tablet.height * scale, alignment: .topLeading)
                    .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
            .padding(.top, Self.menuBarHeight + 12)
        }
        .frame(width: Self.logicalSize.width, height: Self.logicalSize.height)
    }

    private var menuBar: some View {
        let strings = ["File", "Edit", "View", "Window", "Help"]
        return HStack(spacing: 20) {
            Image(systemName: "apple.logo").font(.system(size: 14))
            Text(verbatim: "Lumen").fontWeight(.bold)
            ForEach(strings, id: \.self) { Text(verbatim: $0) }
            Spacer()
            Text(verbatim: "Mon 9:41")
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(MockLumenPalette.ink)
        .padding(.horizontal, 18)
        .frame(height: Self.menuBarHeight)
        .background(Color.white.opacity(0.82))
    }

    private var titleBar: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(red: 1, green: 0.37, blue: 0.34)).frame(width: 12, height: 12)
            Circle().fill(Color(red: 1, green: 0.74, blue: 0.18)).frame(width: 12, height: 12)
            Circle().fill(Color(red: 0.16, green: 0.78, blue: 0.25)).frame(width: 12, height: 12)
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(width: Self.contentWidth, height: Self.titleBarHeight)
        .background(MockLumenPalette.background)
    }
}
#endif
