//
//  PrivacyDataTypeReviewLine.swift
//  AppLocalizer
//

import SwiftUI

/// A row's second line: where the answer stands, the assistant's
/// confidence, its evidence, and Reject and Accept while unreviewed.
struct PrivacyDataTypeReviewLine: View {
    @Bindable var viewModel: AppPrivacyViewModel
    let type: PrivacyDataType
    let entry: PrivacyTypeEntry

    var body: some View {
        HStack(spacing: Spacing.small) {
            PrivacyRowStatusPill(status: entry.status)
            if let suggestion = entry.suggestion, entry.status != .yours || entry.conflict == nil {
                PrivacyConfidenceBadge(confidence: suggestion.confidence)
                if !suggestion.evidence.isEmpty {
                    Button(String(localized: "Evidence · \(suggestion.evidence.count)")) {
                        viewModel.evidenceType = type
                    }
                    .controlSize(.small)
                    .popover(isPresented: Binding(
                        get: { viewModel.evidenceType == type },
                        set: { if !$0, viewModel.evidenceType == type { viewModel.evidenceType = nil } }
                    ), arrowEdge: .bottom) {
                        PrivacyEvidencePopover(viewModel: viewModel, type: type, entry: entry)
                    }
                    .accessibilityIdentifier("appInformation.appPrivacy.type.\(type.rawValue).evidence")
                }
            }
            if let question = viewModel.worksheet.openQuestion(about: type) {
                Label(String(localized: "Open question"), systemImage: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(Palette.warning)
                    .help(question.question)
            }
            Spacer(minLength: 0)
            if entry.status == .unreviewed {
                Button(String(localized: "Reject")) { viewModel.reject(type) }
                    .accessibilityIdentifier("appInformation.appPrivacy.type.\(type.rawValue).reject")
                Button(String(localized: "Accept")) { viewModel.accept(type) }
                    .buttonStyle(.borderedProminent)
                    .disabled(entry.answer.isMissingPurpose)
                    .accessibilityIdentifier("appInformation.appPrivacy.type.\(type.rawValue).accept")
            }
        }
        .controlSize(.small)
    }
}
