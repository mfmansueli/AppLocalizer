//
//  CaptureCoverageView.swift
//  AppLocalizer
//

import SwiftUI

/// After an import (design `capt`): every localized locale's raw captures
/// on the current display type, with where they came from and whether the
/// interface is the locale's own.
struct CaptureCoverageView: View {
    @Bindable var viewModel: ScreenshotsViewModel
    let coverage: CaptureCoverage

    static let localeWidth: CGFloat = 190
    static let sourceWidth: CGFloat = 120

    var body: some View {
        VStack(spacing: 0) {
            bar
            Divider()
            ScrollView([.vertical, .horizontal]) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(coverage.groups) { group in
                            groupHeader(group)
                            ForEach(group.rows) { row in
                                CaptureCoverageRowView(row: row, thumbnailWidth: thumbnailWidth, images: viewModel.captureImages)
                                Divider()
                            }
                        }
                    } header: {
                        columns
                    }
                }
                .frame(minWidth: minimumWidth, alignment: .leading)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("captures.coverage")
    }

    private var thumbnailWidth: CGFloat { viewModel.displayType.isTablet ? 74 : 40 }

    private var columnWidth: CGFloat { thumbnailWidth + 24 }

    private var minimumWidth: CGFloat {
        Self.localeWidth + Self.sourceWidth + CGFloat(coverage.slotNames.count) * columnWidth + Spacing.xxLarge
    }

    private var bar: some View {
        HStack(spacing: Spacing.medium) {
            Button("Import More…") { viewModel.captures.isImporterPresented = true }
                .controlSize(.small)
                .accessibilityIdentifier("captures.importMore")
            Text(coverage.summary)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .truncationMode(.tail)
                .accessibilityIdentifier("captures.summary")
            Spacer(minLength: Spacing.medium)
            HStack(spacing: Spacing.xSmall) {
                InterfaceChip()
                Text(coverage.legend)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.xSmall)
    }

    private var columns: some View {
        HStack(spacing: 0) {
            Text("Locale").frame(width: Self.localeWidth, alignment: .leading)
            Text("Source").frame(width: Self.sourceWidth, alignment: .leading)
            ForEach(Array(coverage.slotNames.enumerated()), id: \.offset) { index, name in
                Text("\(Text(verbatim: "\(index + 1)").foregroundStyle(Palette.label)) \(name)")
                    .lineLimit(1)
                    .frame(width: columnWidth, alignment: .leading)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Palette.label3)
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.content)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func groupHeader(_ group: CaptureCoverage.Group) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Text(group.title)
                .textCase(.uppercase)
            Text(verbatim: "\(group.rows.count)")
                .foregroundStyle(Palette.label3)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Palette.label2)
        .padding(.horizontal, Spacing.large)
        .padding(.top, Spacing.medium)
        .padding(.bottom, Spacing.xSmall)
        .accessibilityElement(children: .combine)
    }
}
