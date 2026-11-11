//
//  AppInformationPageBar.swift
//  AppLocalizer
//

import SwiftUI

/// Under a page's title: where it shows on the App Store, Accept n on This
/// Page, Accept All Pages with the total, Ask, and the ⋯ menu. A page that
/// takes no suggestions only says where it shows.
struct AppInformationPageBar: View {
    @Bindable var viewModel: AppInformationViewModel
    let page: AppInformationPage

    @Environment(MCPServerController.self) private var assistants
    @Environment(AppPreferences.self) private var preferences
    /// Nil in previews and scenes without the app's gate.
    @Environment(ProGate.self) private var pro: ProGate?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            FlowLayout(spacing: Spacing.small) {
                whereShown
                if takesSuggestions {
                    if model.hereCount > 0 {
                        Button(model.acceptHereTitle) { viewModel.acceptSuggestions(onPage: page) }
                            .accessibilityIdentifier("appInformation.acceptHere")
                    }
                    acceptAll
                    Text(model.restText)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                    SuggestionAskButton(
                        appID: viewModel.app.id,
                        area: .appInformation,
                        requestsAsk: $viewModel.requestsAsk,
                        prompt: viewModel.suggestionPrompt,
                        appName: viewModel.app.name,
                        onRequestFinished: { viewModel.suggestionToast = ToastMessage(text: $0) }
                    )
                    moreMenu
                }
            }
            if takesSuggestions, model.acceptsRightAway, model.totalCount > 0 {
                HStack(spacing: Spacing.small) {
                    Pill(text: String(localized: "Accepts right away"), style: .accent)
                        .fixedSize()
                    Text("Accept All Pages doesn’t ask first.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                    Button("Ask First") {
                        preferences.acceptsAllWithoutAsking = false
                        viewModel.suggestionToast = ToastMessage(text: String(localized: "Accept All will show you the suggestions first again."))
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    .accessibilityIdentifier("appInformation.askFirst")
                }
                .padding(.leading, Spacing.xxSmall)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, Spacing.xSmall)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.pageBar")
    }

    private var takesSuggestions: Bool { viewModel.showsSuggestions(on: page) }

    private var model: AppInformationPageBarModel {
        viewModel.pageBarModel(on: page, acceptsRightAway: preferences.acceptsAllWithoutAsking)
    }

    private var whereShown: some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: "info.circle")
                .foregroundStyle(Palette.label2)
                .accessibilityHidden(true)
            Text(page.whereShown(appName: viewModel.app.name))
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
        }
        .frame(minHeight: 24)
    }

    private var acceptAll: some View {
        Button {
            // One page's suggestions are free with Accept Here too.
            let accept = { viewModel.acceptAllPages(withoutAsking: preferences.acceptsAllWithoutAsking) }
            if model.otherPageCount > 0 {
                pro.require(.acceptAllPages(suggestions: model.totalCount, pages: model.otherPageCount + (model.hereCount > 0 ? 1 : 0)), then: accept)
            } else {
                accept()
            }
        } label: {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: "sparkles")
                    .imageScale(.small)
                Text(model.acceptAllTitle)
                if pro.isFree, model.otherPageCount > 0 { ProChip() }
                if model.totalCount > 0 {
                    Text(SuggestionBadge.text(for: model.totalCount))
                        .font(.system(size: 10.5, weight: .bold))
                        .monospacedDigit()
                        .padding(.horizontal, 5)
                        .frame(minWidth: 17, minHeight: 17)
                        .background(.white.opacity(0.26), in: Capsule())
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(model.totalCount == 0)
        .accessibilityLabel(Text(model.acceptAllAccessibilityText))
        .accessibilityIdentifier("appInformation.acceptAll")
    }

    private var scope: SuggestionScope {
        if page == .accessibility, let family = viewModel.shownAccessibilitySuggestionFamily {
            return .accessibility(family)
        }
        return .appInformation(page)
    }

    private var moreMenu: some View {
        Menu {
            SuggestionsMenuItems(
                model: viewModel.suggestionBar(for: scope, assistant: assistants.assistantStatus.clientName),
                filter: $viewModel.suggestionFilter,
                showsOnlyFields: $viewModel.showsOnlySuggestedFields,
                showsFieldsToggle: page != .accessibility,
                onDismissAll: { viewModel.dismissAllSuggestions(in: scope) },
                onRestore: { viewModel.restoreDismissedSuggestions(in: scope) }
            )
        } label: {
            Label("More", systemImage: "ellipsis")
                .labelStyle(.iconOnly)
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityIdentifier("appInformation.more")
    }
}
