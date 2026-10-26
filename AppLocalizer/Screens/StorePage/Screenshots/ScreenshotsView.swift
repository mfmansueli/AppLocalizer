//
//  ScreenshotsView.swift
//  AppLocalizer
//

import SwiftUI

/// Screenshots, read-only: a strip per locale and device size, missing ones
/// flagged, and locales without iPhone screenshots marked as using the
/// primary locale's. Uploading stays in App Store Connect.
struct ScreenshotsView: View {
    let viewModel: StorePageViewModel

    private static let localeWidth: CGFloat = 180
    private static let minimumColumnWidth: CGFloat = 200
    private static let gap = Spacing.medium
    private static let inset = Spacing.medium

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            content
            Divider()
            Text("Read-only. Upload screenshots and previews in App Store Connect. Locales without iPhone screenshots fall back to \(primaryName).")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.large)
                .padding(.vertical, Spacing.small)
        }
        .task { await viewModel.loadScreenshots() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.screenshots")
    }

    private var primaryName: String { viewModel.listing?.primaryLocale.name ?? StoreLocale.englishUS.name }

    @ViewBuilder
    private var content: some View {
        switch viewModel.screenshots {
        case .idle, .loading:
            StorePageTableSkeleton()
        case let .failed(message):
            StorePageErrorView(message: message) {
                Task { await viewModel.loadScreenshots(force: true) }
            }
        case let .loaded(coverage):
            grid(coverage)
        }
    }

    private func grid(_ coverage: ScreenshotCoverage) -> some View {
        GeometryReader { proxy in
            let devices = ScreenshotDevice.allCases
            let minimum = Self.localeWidth + CGFloat(devices.count) * (Self.minimumColumnWidth + Self.gap) + Self.inset * 2
            let width = max(proxy.size.width, minimum)
            let columnWidth = (width - Self.inset * 2 - Self.localeWidth - CGFloat(devices.count) * Self.gap) / CGFloat(devices.count)
            ScrollView([.vertical, .horizontal]) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(viewModel.listing?.displayLocales ?? []) { locale in
                            row(locale, coverage: coverage, columnWidth: columnWidth)
                            Divider()
                        }
                    } header: {
                        header(columnWidth: columnWidth)
                    }
                }
                .frame(width: width)
            }
        }
    }

    private func header(columnWidth: CGFloat) -> some View {
        HStack(spacing: Self.gap) {
            Text("Locale")
                .frame(width: Self.localeWidth, alignment: .leading)
            ForEach(ScreenshotDevice.allCases) { device in
                Text(device.title)
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

    private func row(_ locale: StoreLocale, coverage: ScreenshotCoverage, columnWidth: CGFloat) -> some View {
        HStack(spacing: Self.gap) {
            LocaleLabel(locale: locale, showsTags: false)
                .frame(width: Self.localeWidth, alignment: .leading)
            ForEach(ScreenshotDevice.allCases) { device in
                ScreenshotStrip(device: device, status: coverage.status(for: locale, on: device))
                    .frame(width: columnWidth, alignment: .leading)
                    .accessibilityLabel(Text("\(locale.name), \(device.title): \(coverage.status(for: locale, on: device).title)"))
                    .accessibilityIdentifier("storePage.shots.\(locale.code).\(device.rawValue)")
            }
        }
        .padding(.horizontal, Self.inset)
        .frame(height: 56)
        .accessibilityElement(children: .contain)
    }
}
