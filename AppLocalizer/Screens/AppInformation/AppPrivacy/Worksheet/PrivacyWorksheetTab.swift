//
//  PrivacyWorksheetTab.swift
//  AppLocalizer
//

import SwiftUI

/// The Worksheet tab: the ways to start, or the worksheet itself (with the
/// disclaimer under it), and the label preview in a column beside it.
struct PrivacyWorksheetTab: View {
    let viewModel: AppPrivacyViewModel

    var body: some View {
        let worksheet = viewModel.worksheet
        HStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        if worksheet.hasContent {
                            PrivacyWorksheetContent(viewModel: viewModel)
                            Text("Suggestions aren’t legal advice. You’re responsible for these answers, including what third-party SDKs in \(viewModel.appShortName) collect. “Collect” means data leaves the device and is kept longer than it takes to serve the request.")
                                .font(.caption)
                                .foregroundStyle(Palette.label2)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("appInformation.appPrivacy.disclaimer")
                        } else {
                            PrivacyStartView(viewModel: viewModel)
                        }
                    }
                    .padding(Spacing.large)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("appInformation.appPrivacy.worksheet")
                .task { await revealEvidence(with: proxy) }
            }
            Divider()
            PrivacyLabelPreviewColumn(preview: worksheet.labelPreview)
                .frame(width: 262)
        }
    }

    /// Evidence asked for before the tab appeared (a DEBUG scene opens the
    /// page that way) may belong to a row below the fold, where its popover
    /// can't show: scrolls the row into view, then opens the popover there.
    private func revealEvidence(with proxy: ScrollViewProxy) async {
        guard let type = viewModel.evidenceType else { return }
        viewModel.evidenceType = nil
        proxy.scrollTo(type.id, anchor: .center)
        await Task.yield()
        viewModel.evidenceType = type
    }
}
