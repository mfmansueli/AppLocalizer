//
//  PrivacyWorksheetContent.swift
//  AppLocalizer
//

import SwiftUI

/// The worksheet once it has started: the scan, what changed and what
/// disagrees, the first question, the open questions, then every data type
/// by category.
struct PrivacyWorksheetContent: View {
    let viewModel: AppPrivacyViewModel

    var body: some View {
        let worksheet = viewModel.worksheet
        VStack(alignment: .leading, spacing: Spacing.medium) {
            if viewModel.runningScan != nil || worksheet.lastScan != nil {
                PrivacyScanActivityRow(viewModel: viewModel)
            }
            if viewModel.runningScan == nil, let scan = worksheet.lastScan, let changes = scan.changes, !changes.isEmpty {
                PrivacyRescanBanner(scan: scan, changes: changes, worksheet: worksheet)
            }
            if case let .outOfDate(date) = worksheet.status {
                PrivacyOutOfDateBanner(date: date) { viewModel.tab = .checklist }
            }
            ForEach(worksheet.mismatches) { mismatch in
                PrivacyMismatchBanner(mismatch: mismatch, viewModel: viewModel)
            }
            PrivacyCollectsRow(viewModel: viewModel)
            if !worksheet.questions.isEmpty {
                PrivacyOpenQuestionsBox(viewModel: viewModel)
            }
            if worksheet.collects?.value != false {
                PrivacyWorksheetFilterBar(viewModel: viewModel)
                ForEach(viewModel.visibleCategories, id: \.category) { item in
                    PrivacyCategoryBox(viewModel: viewModel, category: item.category, types: item.types)
                }
                if viewModel.visibleCategories.isEmpty {
                    Text(viewModel.filter == .all ? "Nothing answered yet. Show all 35 data types to answer them." : "Nothing matches this filter.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("appInformation.appPrivacy.emptyFilter")
                }
            }
        }
    }
}
