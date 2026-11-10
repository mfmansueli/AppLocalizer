//
//  AppStorePreviewShots.swift
//  AppLocalizer
//

import CoreGraphics
import SwiftUI

/// The first screenshots people swipe through in a language: what's live on
/// the App Store, from an iPhone set when there is one. A language without
/// any shows the primary language's, and says so.
struct AppStorePreviewShots: View {
    let services: any ScreenshotsServices
    let app: StoreApp
    /// Each language's version localization, where screenshots live.
    let localizations: [StoreLocale: String]
    let locale: StoreLocale
    /// Whose screenshots a language without any shows.
    let primary: StoreLocale
    var width: CGFloat = 78

    @State private var live: LiveScreenshots?
    @State private var loaded: [LoadedShot] = []
    @State private var isBorrowed = false

    private struct LoadedShot: Identifiable {
        let id: String
        let image: CGImage
    }

    private struct ChosenShots: Hashable {
        var appID: String
        var locale: StoreLocale
        var isLoaded: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                if loaded.isEmpty {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Palette.fill2)
                            .frame(width: width, height: width * 2.16)
                    }
                } else {
                    ForEach(loaded) { shot in
                        Image(decorative: shot.image, scale: 1)
                            .resizable()
                            .scaledToFit()
                            .frame(width: width)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5)
                            }
                    }
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .accessibilityHidden(true)
            if isBorrowed {
                Text("\(LanguageBarModel.shortName(primary)) screenshots until \(LanguageBarModel.shortName(locale)) ones are made")
                    .font(.caption2)
                    .foregroundStyle(Palette.label2)
            }
        }
        .task(id: app.id) {
            live = try? await services.liveScreenshots(for: app, localizations: localizations)
        }
        .task(id: ChosenShots(appID: app.id, locale: locale, isLoaded: live != nil)) {
            await loadImages()
        }
    }

    private func loadImages() async {
        guard let live else { return }
        let own = Self.bestSet(in: live, locale: locale)
        let set = own ?? Self.bestSet(in: live, locale: primary)
        var images: [LoadedShot] = []
        for shot in (set?.screenshots ?? []).prefix(3) {
            if let image = await services.liveImage(shot, pixelWidth: Int(width * 3)) {
                images.append(LoadedShot(id: shot.id, image: image))
            }
        }
        guard !Task.isCancelled else { return }
        isBorrowed = own == nil && set != nil
        loaded = images
    }

    /// An iPhone set first: it's what most people see.
    static func bestSet(in live: LiveScreenshots, locale: StoreLocale) -> LiveScreenshotSet? {
        let sets = live.screenshotSets.filter { $0.locale == locale.code && !$0.screenshots.isEmpty }
        return sets.first { $0.displayType == .iPhone } ?? sets.first
    }
}
