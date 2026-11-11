//
//  OverviewStorePreview.swift
//  AppLocalizer
//

import SwiftUI

/// The Overview's left column: the App Store page as people see it, in one
/// of the app's languages, with a tag on each part that opens the section
/// editing it.
struct OverviewStorePreview: View {
    let app: StoreApp
    let content: StorePageContent
    let screenshots: any ScreenshotsServices
    let links: AppStorePreviewLinks

    @Environment(AppSummaryStore.self) private var summaries
    @State private var selected: StoreLocale?
    @State private var ratings = StoreRatings.unchecked

    private struct RatingKey: Hashable {
        var appID: String
        var country: String
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text("On the App Store")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxWidth: .infinity, alignment: .leading)
                languagePicker
            }
            AppStorePagePreview(model: model, appName: app.name, icon: app.icon, links: links) {
                AppStorePreviewShots(
                    services: screenshots,
                    app: app,
                    localizations: content.ids.versionLocalizations,
                    locale: locale,
                    primary: content.primaryLocale,
                    width: 84
                )
            }
            Text("Everything on this page, in every language, is edited here. Click a part to open the section that edits it.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 300)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("overview.storePreview")
        .task(id: RatingKey(appID: app.id, country: locale.regionCode)) {
            let loaded = await StoreRatingLookup().ratings(appID: app.id, countries: [locale.regionCode])
            guard !Task.isCancelled else { return }
            ratings = loaded
        }
    }

    /// The primary language, then the next two the page has, and the one
    /// picked from the menu.
    private var shownLocales: [StoreLocale] {
        var locales = [content.primaryLocale] + content.locales.filter { $0 != content.primaryLocale }.prefix(2)
        if !locales.contains(locale) { locales.append(locale) }
        return locales
    }

    private var locale: StoreLocale {
        selected.flatMap { content.locales.contains($0) ? $0 : nil } ?? content.primaryLocale
    }

    private var languagePicker: some View {
        HStack(spacing: Spacing.xxSmall) {
            Picker("Language", selection: Binding(get: { locale }, set: { selected = $0 })) {
                ForEach(shownLocales, id: \.self) { locale in
                    Text(LanguageBarModel.shortName(locale, among: shownLocales)).tag(locale)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.small)
            .fixedSize()
            .accessibilityIdentifier("overview.storePreview.language")
            if content.locales.count > 3 {
                Menu {
                    ForEach(content.locales, id: \.self) { locale in
                        Button(locale.name) { selected = locale }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .buttonStyle(.borderless)
                .fixedSize()
                .help("Another language")
                .accessibilityLabel(Text("Another language"))
            }
        }
    }

    private var model: AppStorePreviewModel {
        var model = AppStorePreviewModel(content: content, locale: locale)
        model.ratings = ratings
        model.addFacts(appInformation: summaries.appInformation[app.id]?.value, pricing: summaries.pricing[app.id]?.value)
        return model
    }
}
