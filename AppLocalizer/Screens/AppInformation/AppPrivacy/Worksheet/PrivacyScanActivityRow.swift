//
//  PrivacyScanActivityRow.swift
//  AppLocalizer
//

import SwiftUI

/// The scan at the top of the worksheet: running, with what it has read
/// and sent so far, or done, with Scan Summary.
struct PrivacyScanActivityRow: View {
    @Bindable var viewModel: AppPrivacyViewModel

    var body: some View {
        HStack(spacing: Spacing.small) {
            if let running = viewModel.runningScan {
                AssistantChip(name: running.assistant)
                ProgressView()
                    .controlSize(.small)
                    .accessibilityHidden(true)
                Text(viewModel.progressText(of: running))
                    .font(.callout)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("appInformation.appPrivacy.scan.progress")
            } else if let scan = viewModel.worksheet.lastScan {
                AssistantChip(name: scan.assistant)
                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.doneText(of: scan))
                        .font(.callout)
                        .lineLimit(1)
                    Text(viewModel.metaText(of: scan))
                        .font(.caption.monospaced())
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(viewModel.doneText(of: scan))
                Button(String(localized: "Scan Summary")) {
                    viewModel.showsScanSummary = true
                }
                .controlSize(.small)
                .popover(isPresented: $viewModel.showsScanSummary, arrowEdge: .bottom) {
                    PrivacyScanSummaryPopover(scan: scan)
                }
                .accessibilityIdentifier("appInformation.appPrivacy.scan.summary")
            }
        }
        .padding(Spacing.medium)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.scan")
    }
}
