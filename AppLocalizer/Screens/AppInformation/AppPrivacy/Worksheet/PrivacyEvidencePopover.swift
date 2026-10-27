//
//  PrivacyEvidencePopover.swift
//  AppLocalizer
//

import SwiftUI

/// Why the assistant answered as it did: the answer, its reason, each
/// piece of evidence (an SDK manifest entry, a file and line with an
/// excerpt), an open question about the type, and Reject and Accept.
struct PrivacyEvidencePopover: View {
    let viewModel: AppPrivacyViewModel
    let type: PrivacyDataType
    let entry: PrivacyTypeEntry

    var body: some View {
        let suggestion = entry.suggestion
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(type.category.name) · \(type.name)")
                    .font(.headline)
                Spacer(minLength: Spacing.small)
                if let suggestion {
                    PrivacyConfidenceBadge(confidence: suggestion.confidence)
                }
            }
            Text((suggestion?.answer ?? entry.answer).longSummary)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            if let rationale = suggestion?.rationale, !rationale.isEmpty {
                Text(rationale)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Evidence")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Palette.label2)
                .padding(.top, Spacing.xxSmall)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    ForEach(Array((suggestion?.evidence ?? []).enumerated()), id: \.offset) { _, evidence in
                        PrivacyEvidenceCard(evidence: evidence)
                    }
                }
            }
            .frame(maxHeight: 320)
            .fixedSize(horizontal: false, vertical: true)
            if let question = viewModel.worksheet.openQuestion(about: type) {
                Text("Open question: \(question.question)")
                    .font(.caption)
                    .foregroundStyle(Palette.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: Spacing.small) {
                Spacer()
                if entry.status == .unreviewed {
                    Button(String(localized: "Reject")) { viewModel.reject(type) }
                        .accessibilityIdentifier("appInformation.appPrivacy.evidence.reject")
                    Button(String(localized: "Accept")) { viewModel.accept(type) }
                        .buttonStyle(.borderedProminent)
                        .disabled(entry.answer.isMissingPurpose)
                        .accessibilityIdentifier("appInformation.appPrivacy.evidence.accept")
                }
                Button(String(localized: "Close")) { viewModel.evidenceType = nil }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("appInformation.appPrivacy.evidence.close")
            }
            .controlSize(.small)
        }
        .padding(Spacing.large)
        .frame(width: 400)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.evidencePopover")
    }
}
