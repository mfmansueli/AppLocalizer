//
//  PrivacyWorksheetFilterBar.swift
//  AppLocalizer
//

import SwiftUI

/// The filters with their counts, Accept All High-Confidence (which
/// skips conflicts and types with an open question; hidden when there's
/// nothing to accept), and Show All 35 Data Types.
struct PrivacyWorksheetFilterBar: View {
    @Bindable var viewModel: AppPrivacyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Picker(String(localized: "Show"), selection: $viewModel.filter) {
                ForEach(PrivacyWorksheetFilter.allCases) { filter in
                    Text(viewModel.title(of: filter)).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.small)
            .fixedSize()
            .accessibilityIdentifier("appInformation.appPrivacy.filter")
            HStack(spacing: Spacing.small) {
                let count = viewModel.highConfidenceCount
                if count > 0 {
                    Button(String(localized: "Accept All High-Confidence · \(count)")) {
                        viewModel.acceptAllHighConfidence()
                    }
                    .accessibilityIdentifier("appInformation.appPrivacy.acceptHighConfidence")
                }
                Button(viewModel.showsAllTypes
                    ? String(localized: "Hide Untouched Types")
                    : String(localized: "Show All \(PrivacyDataType.allCases.count) Data Types"))
                {
                    viewModel.showsAllTypes.toggle()
                    viewModel.filter = .all
                }
                .accessibilityIdentifier("appInformation.appPrivacy.showAll")
            }
            .controlSize(.small)
        }
    }
}
