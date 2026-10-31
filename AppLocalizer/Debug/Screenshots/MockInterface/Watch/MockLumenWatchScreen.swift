//
//  MockLumenWatchScreen.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// The sample app's watch app, LumenWatch, on an Apple Watch Ultra 3:
/// mood check-in, today's prompt, the week and a watch face with Lumen's
/// streak. Drawn at 211 × 257 points (422 × 514 pixels at 2×).
struct MockLumenWatchScreen: View {
    let kind: MockLumenWatchKind
    let locale: String

    static let logicalSize = CGSize(width: 211, height: 257)

    private var strings: MockLumenStrings { .strings(for: locale) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if kind != .face {
                HStack {
                    Text(verbatim: "Lumen").font(.system(size: 13, weight: .semibold)).foregroundStyle(Self.lavender)
                    Spacer()
                    Text(verbatim: "9:41").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                }
            }
            content
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(width: Self.logicalSize.width, height: Self.logicalSize.height, alignment: .topLeading)
        .background(Color.black)
        .environment(\.layoutDirection, StoreLocaleCatalog.locale(code: locale)?.isRTL == true ? .rightToLeft : .leftToRight)
    }

    private static let lavender = Color(red: 0.62, green: 0.6, blue: 1)
    private static let moodColors: [Color] = [
        Color(red: 0.55, green: 0.5, blue: 0.95), Color(red: 0.35, green: 0.7, blue: 0.6), Color(red: 0.9, green: 0.45, blue: 0.6),
        Color(red: 0.98, green: 0.75, blue: 0.3), Color(red: 0.35, green: 0.6, blue: 0.95), Color(red: 0.95, green: 0.5, blue: 0.4),
    ]
    private static let bars: [CGFloat] = [0.45, 0.7, 0.55, 0.95, 0.6, 0.8, 0.5]

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .mood: mood
        case .prompt: prompt
        case .week: week
        case .face: face
        }
    }

    private var mood: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.mood).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(Self.moodColors.indices, id: \.self) { index in
                    Circle()
                        .fill(Self.moodColors[index])
                        .frame(width: 38, height: 38)
                        .overlay(Circle().strokeBorder(.white, lineWidth: index == 0 ? 3 : 0))
                }
            }
        }
    }

    private var prompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(strings.promptLabel).font(.system(size: 10, weight: .semibold)).foregroundStyle(Self.lavender)
            Text(strings.prompt).font(.system(size: 18, weight: .bold)).foregroundStyle(.white).lineLimit(3)
            Spacer(minLength: 0)
            Capsule()
                .fill(MockLumenPalette.accent)
                .frame(height: 36)
                .overlay(Image(systemName: "mic.fill").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white))
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var week: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.weekTitle).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
            HStack(alignment: .bottom, spacing: 7) {
                ForEach(Array(Self.bars.enumerated()), id: \.offset) { index, height in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(index == 3 ? MockLumenPalette.accent : Self.lavender.opacity(0.75))
                        .frame(width: 16, height: 110 * height)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .bottom)
            Text(strings.days).font(.system(size: 10, weight: .medium)).foregroundStyle(.gray).frame(maxWidth: .infinity)
        }
    }

    private var face: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(strings.date.uppercased()).font(.system(size: 10, weight: .semibold)).foregroundStyle(.orange).lineLimit(1)
            Text(verbatim: "10:09").font(.system(size: 54, weight: .semibold, design: .rounded)).foregroundStyle(.white)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Self.lavender, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "moon.fill").font(.system(size: 12)).foregroundStyle(Self.lavender))
                Text(verbatim: "3").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
#endif
