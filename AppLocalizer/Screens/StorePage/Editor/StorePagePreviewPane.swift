//
//  StorePagePreviewPane.swift
//  AppLocalizer
//

import SwiftUI

/// Beside the editor: the language's App Store page, as it is now or with
/// the suggestions on top, with the real rating of that storefront.
struct StorePagePreviewPane: View {
    let viewModel: StorePageViewModel
    let locale: StoreLocale

    @Environment(AppSummaryStore.self) private var summaries
    @State private var showsSuggested = true
    @State private var ratings = StoreRatings.unchecked

    private struct RatingKey: Hashable {
        var appID: String
        var country: String
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text("On the App Store")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("Preview", selection: $showsSuggested) {
                    Text("Now").tag(false)
                    Text("Suggested").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
                .accessibilityIdentifier("storePreview.mode")
            }
            ScrollView {
                AppStorePagePreview(model: model, appName: viewModel.app.name, icon: viewModel.app.icon) {
                    AppStorePreviewShots(
                        services: viewModel.services.screenshots,
                        app: viewModel.app,
                        localizations: viewModel.content?.ids.versionLocalizations ?? [:],
                        locale: locale,
                        primary: viewModel.listing?.primaryLocale ?? locale
                    )
                }
                .padding(2)
                .padding(.bottom, 18)
            }
            .scrollIndicators(.never)
        }
        .frame(width: 290)
        .task(id: RatingKey(appID: viewModel.app.id, country: locale.regionCode)) {
            let loaded = await StoreRatingLookup().ratings(appID: viewModel.app.id, countries: [locale.regionCode])
            guard !Task.isCancelled else { return }
            ratings = loaded
        }
    }

    private var model: AppStorePreviewModel {
        var model = viewModel.previewModel(in: locale, showsSuggested: showsSuggested)
        model.ratings = ratings
        model.addFacts(appInformation: summaries.appInformation[viewModel.app.id]?.value, pricing: summaries.pricing[viewModel.app.id]?.value)
        return model
    }
}
