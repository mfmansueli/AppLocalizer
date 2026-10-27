//
//  AppPrivacyHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The page's title with its status, the three tabs, Export…, and the
/// line that says this is a worksheet, not a sync.
struct AppPrivacyHeader: View {
    @Bindable var viewModel: AppPrivacyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .center, spacing: Spacing.small) {
                Text(AppInformationPage.appPrivacy.title)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                AppPrivacyStatusPill(status: viewModel.status)
                    .layoutPriority(-1)
                Spacer(minLength: Spacing.small)
                Picker(String(localized: "App Privacy view"), selection: $viewModel.tab) {
                    ForEach(AppPrivacyTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
                .accessibilityIdentifier("appInformation.appPrivacy.tabs")
                Button(String(localized: "Export…")) {
                    viewModel.isExportSheetPresented = true
                }
                .controlSize(.small)
                .disabled(viewModel.worksheet.reviewedAnswers.collects == nil)
                .accessibilityIdentifier("appInformation.appPrivacy.export")
            }
            notASync
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.top, Spacing.large)
        .padding(.bottom, Spacing.medium)
    }

    private var notASync: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: "lock")
                .foregroundStyle(Palette.label2)
                .accessibilityHidden(true)
            Text("""
            **A worksheet, not a sync.** App Store Connect has no API for App Privacy, so AppLocalizer can’t read or change the answers \
            there. Build them here, then copy them in with the checklist. The privacy URLs do sync, through Review & Push.
            """)
            .font(.callout)
            .foregroundStyle(Palette.label2)
            .layoutPriority(1)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("appInformation.appPrivacy.notASync")
    }
}
