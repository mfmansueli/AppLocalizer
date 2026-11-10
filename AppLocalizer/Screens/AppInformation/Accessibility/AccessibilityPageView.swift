//
//  AccessibilityPageView.swift
//  AppLocalizer
//

import SwiftUI

/// Accessibility: suggested answers for one device at a time, one card per
/// device family the app supports, loading and error states, the
/// never-declared explanation, Other Devices and the accessibility URL.
struct AccessibilityPageView: View {
    @Bindable var viewModel: AppInformationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            AppInformationPageHeader(
                title: AppInformationPage.accessibility.title,
                subtitle: AppInformationPage.accessibility.summary(appName: viewModel.app.name, version: nil)
            ) {
                Pill(text: String(localized: "Voluntary for now · required later"))
                ExternalLinkButton(title: String(localized: "About the Labels"), url: AccessibilityFeature.overviewURL)
                    .controlSize(.small)
                    .accessibilityIdentifier("appInformation.accessibility.about")
            }
            .padding(.bottom, Spacing.xxSmall)
            AppInformationPageBar(viewModel: viewModel, page: .accessibility)
            switch viewModel.accessibility {
            case .idle, .loading:
                grid(Array(0..<4)) { _ in AccessibilitySkeletonCard() }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Loading accessibility declarations"))
                    .accessibilityIdentifier("appInformation.accessibility.loading")
            case let .failed(message):
                AccessibilityLoadErrorView(message: message, requestLine: viewModel.accessibilityErrorLine) {
                    Task { await viewModel.loadAccessibility() }
                }
            case .loaded:
                loaded
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.accessibility")
    }

    @ViewBuilder
    private var loaded: some View {
        let cards = viewModel.accessibilityCards
        AccessibilitySuggestionsSection(viewModel: viewModel)
        if viewModel.isNeverDeclared, let first = cards.first {
            AccessibilityEmptyState(appName: viewModel.app.name, firstFamily: first.family) {
                viewModel.openEditor(first.family)
            }
        }
        grid(cards) { card in AccessibilityCardView(card: card, viewModel: viewModel) }
        if !viewModel.otherFamilies.isEmpty {
            otherDevices
        }
        AccessibilityURLCard(url: viewModel.accessibilityURL, problem: viewModel.accessibilityURLProblem) {
            viewModel.setAccessibilityURL($0)
        }
    }

    /// Two cards per row; cards in a row share its height.
    private func grid<Item: Hashable>(_ items: [Item], @ViewBuilder cell: @escaping (Item) -> some View) -> some View {
        let rows = stride(from: 0, to: items.count, by: 2).map { Array(items[$0..<min($0 + 2, items.count)]) }
        return Grid(horizontalSpacing: Spacing.medium, verticalSpacing: Spacing.medium) {
            ForEach(rows, id: \.self) { row in
                GridRow(alignment: .top) {
                    ForEach(row, id: \.self) { item in cell(item) }
                    if row.count == 1 { Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]) }
                }
            }
        }
    }

    /// Families App Store Connect doesn't say the app runs on, e.g. Apple
    /// Watch for an iOS app: declaring one adds its card.
    private var otherDevices: some View {
        Menu(String(localized: "Other Devices")) {
            ForEach(viewModel.otherFamilies) { family in
                Button(String(localized: "Declare for \(family.name)…")) { viewModel.openEditor(family) }
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help(String(localized: "Declare for a device App Store Connect doesn’t list for this app"))
        .accessibilityIdentifier("appInformation.accessibility.otherDevices")
    }
}
