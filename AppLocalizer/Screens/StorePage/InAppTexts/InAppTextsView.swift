//
//  InAppTextsView.swift
//  AppLocalizer
//

import SwiftUI

/// In-App Texts: the subscription group name, each subscription's display
/// name (30) and description (45), and in-app purchase names, per locale.
/// A cell opens a popover to edit it; edits are queued like the listing's.
struct InAppTextsView: View {
    let viewModel: StorePageViewModel

    private static let localeWidth: CGFloat = 180
    private static let minimumColumnWidth: CGFloat = 138
    private static let gap = Spacing.small
    private static let inset = Spacing.medium

    private var model: InAppTextsViewModel { viewModel.inAppTexts }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            content
            Divider()
            Text("Shown on the purchase sheet and in Settings → Subscriptions. Display name 30 characters, description 45. Click a cell to edit.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.large)
                .padding(.vertical, Spacing.small)
        }
        .task { await model.load(listing: viewModel.listing) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.inAppTexts")
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            StorePageTableSkeleton()
        case let .failed(message):
            StorePageErrorView(message: message) {
                Task { await model.load(listing: viewModel.listing, force: true) }
            }
        case let .loaded(loaded):
            if loaded.isEmpty {
                ContentUnavailableView(
                    "No subscriptions or in-app purchases",
                    systemImage: "cart",
                    description: Text("Names and descriptions show here once the app sells something in App Store Connect.")
                )
            } else if let matrix = model.matrix {
                grid(matrix)
            }
        }
    }

    private func grid(_ matrix: InAppTextMatrix) -> some View {
        GeometryReader { proxy in
            let columns = matrix.columns
            let minimum = Self.localeWidth + CGFloat(columns.count) * (Self.minimumColumnWidth + Self.gap) + Self.inset * 2
            let width = max(proxy.size.width, minimum)
            let columnWidth = (width - Self.inset * 2 - Self.localeWidth - CGFloat(columns.count) * Self.gap) / CGFloat(max(columns.count, 1))
            ScrollView([.vertical, .horizontal]) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(matrix.displayLocales) { locale in
                            row(locale, columns: columns, columnWidth: columnWidth)
                            Divider()
                        }
                    } header: {
                        header(columns, columnWidth: columnWidth)
                    }
                }
                .frame(width: width)
            }
        }
    }

    private func header(_ columns: [InAppTextColumn], columnWidth: CGFloat) -> some View {
        HStack(spacing: Self.gap) {
            Text("Locale")
                .frame(width: Self.localeWidth, alignment: .leading)
            ForEach(columns) { column in
                Text("\(column.title) \(Text("· \(column.field.limit.maximum)").foregroundStyle(Palette.label3))")
                    .lineLimit(1)
                    .frame(width: columnWidth, alignment: .leading)
            }
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(Palette.label2)
        .padding(.horizontal, Self.inset)
        .frame(height: 28)
        .background(Palette.content)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityHidden(true)
    }

    private func row(_ locale: StoreLocale, columns: [InAppTextColumn], columnWidth: CGFloat) -> some View {
        HStack(spacing: Self.gap) {
            LocaleLabel(locale: locale, showsTags: false)
                .frame(width: Self.localeWidth, alignment: .leading)
            ForEach(columns) { column in
                InAppTextCell(model: model, column: column, locale: locale)
                    .frame(width: columnWidth)
            }
        }
        .padding(.horizontal, Self.inset)
        .frame(minHeight: 34)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.inAppRow.\(locale.code)")
    }
}
