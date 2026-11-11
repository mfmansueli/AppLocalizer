//
//  ScreenshotsLanguagePage.swift
//  AppLocalizer
//

import SwiftUI

/// Screenshots, one language at a time: the header, the language bar, the
/// device, the template and Now | Suggested, the language's screenshots
/// large (a suggested caption drawn on its screenshot with a purple ring),
/// and each suggested caption to accept or dismiss. All Languages lists
/// every language instead.
struct ScreenshotsLanguagePage: View {
    @Bindable var viewModel: ScreenshotsViewModel

    @Environment(AppPreferences.self) private var preferences
    /// Nil in previews and scenes without the app's gate.
    @Environment(ProGate.self) private var pro: ProGate?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                ScreenshotsPageHeader(viewModel: viewModel)
                languageBar
                if viewModel.pageShowsAll {
                    ScreenshotsLanguageList(viewModel: viewModel)
                } else {
                    controls
                    shots
                    suggestions
                }
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("screenshots.page")
    }

    private var locale: StoreLocale { viewModel.currentPageLocale }

    private var languageBar: some View {
        let model = viewModel.languageBarModel(acceptsRightAway: preferences.acceptsAllWithoutAsking)
        return LanguageBar(model: model, showsProChip: pro.isFree && model.withSuggestions.count > 1) { locale in
            viewModel.pageLocale = locale
            viewModel.pageShowsAll = false
        } onAcceptAll: {
            let languages = model.withSuggestions.count
            let accept = {
                _ = Task { await viewModel.acceptAllCaptions(withoutAsking: preferences.acceptsAllWithoutAsking) }
            }
            if languages > 1 {
                pro.require(.acceptAllLanguages(suggestions: model.totalCount, languages: languages), then: accept)
            } else {
                accept()
            }
        } onAcceptHere: {
            Task { await viewModel.acceptCaptionsHere() }
        } onAskFirst: {
            preferences.acceptsAllWithoutAsking = false
            viewModel.captionToast = ToastMessage(text: String(localized: "Accept All Languages will show you the suggestions first again."))
        } trailing: {
            EmptyView()
        }
    }

    private var controls: some View {
        FlowLayout(spacing: Spacing.small) {
            if viewModel.pageDisplays.count > 1 {
                Picker("Device", selection: $viewModel.displayType) {
                    ForEach(viewModel.pageDisplays, id: \.self) { display in
                        Text(display.title).tag(display)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("screenshots.page.device")
            }
            if let line = viewModel.templateLine {
                Text(line)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
            }
            Picker("Captions", selection: $viewModel.showsSuggestedCaptions) {
                Text("Now").tag(false)
                Text("Suggested").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.small)
            .fixedSize()
            .accessibilityIdentifier("screenshots.page.mode")
        }
    }

    @ViewBuilder
    private var shots: some View {
        let cells = viewModel.matrix.row(locale: locale.code, displayType: viewModel.displayType)
        if cells.isEmpty, viewModel.isLoading {
            // Not "no screenshots yet" while the live ones are still read:
            // Alba's six live screenshots showed as none for seconds.
            HStack(spacing: Spacing.small) {
                ProgressView().controlSize(.small)
                Text("Reading the screenshots on the App Store…")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("screenshots.page.loading")
        } else if cells.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("No \(viewModel.displayType.title) screenshots in \(locale.name) yet.")
                    .font(.callout)
                Text("Start Autopilot… makes them from the app, or import captures in Captures.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .accessibilityIdentifier("screenshots.page.empty")
        } else {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.medium) {
                    ForEach(cells) { cell in
                        LanguagePageThumbnail(viewModel: viewModel, cell: cell, localeName: locale.name, width: thumbnailWidth)
                    }
                }
                .padding(.vertical, Spacing.xxSmall)
                .environment(\.layoutDirection, locale.isRTL ? .rightToLeft : .leftToRight)
            }
            .scrollIndicators(.automatic)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("screenshots.page.shots")
        }
    }

    /// iPhone 142 pt wide; the wider devices' screenshots a bit wider.
    private var thumbnailWidth: CGFloat {
        switch viewModel.displayType {
        case .iPhone, .iPhoneDuo: 142
        case .watch: 110
        default: 210
        }
    }

    @ViewBuilder
    private var suggestions: some View {
        let captions = viewModel.proposedCaptions(in: locale)
        if captions.isEmpty {
            Text("Nothing to review in \(locale.name).")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .accessibilityIdentifier("screenshots.page.nothing")
        } else {
            VStack(alignment: .leading, spacing: Spacing.small) {
                ForEach(captions) { caption in
                    ProposedCaptionCard(
                        caption: caption,
                        current: viewModel.currentHeadline(locale: caption.locale, slot: caption.slot),
                        isRightToLeft: locale.isRTL,
                        onDismiss: { Task { await viewModel.dismissCaption(caption) } },
                        onUseAndEdit: { Task { await viewModel.useAndEditCaption(caption) } },
                        onAccept: { Task { await viewModel.acceptCaption(caption) } }
                    )
                }
            }
        }
    }
}
