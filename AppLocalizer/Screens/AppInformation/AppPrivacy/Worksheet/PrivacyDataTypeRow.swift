//
//  PrivacyDataTypeRow.swift
//  AppLocalizer
//

import SwiftUI

/// One data type: collected or not, who answered and how sure, the
/// evidence, Accept and Reject for a suggestion nobody reviewed (tinted
/// purple), then for a collected type its purposes, whether it's linked
/// and used for tracking, the assistant's reason, and a conflict to settle.
struct PrivacyDataTypeRow: View {
    @Bindable var viewModel: AppPrivacyViewModel
    let type: PrivacyDataType
    var isMismatched = false

    var body: some View {
        let entry = viewModel.worksheet[type]
        let answer = entry?.answer ?? .notCollected
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text(type.name)
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                collectedPicker(answer)
                if let entry {
                    sourceTag(entry)
                }
            }
            if let entry {
                PrivacyDataTypeReviewLine(viewModel: viewModel, type: type, entry: entry)
            }
            if answer.collected {
                PrivacyPurposeToggles(answer: answer) { viewModel.togglePurpose($0, for: type) }
                if answer.isMissingPurpose {
                    InlineMessage.warning(String(localized: "Pick at least one purpose."))
                        .font(.caption)
                        .accessibilityIdentifier("appInformation.appPrivacy.type.\(type.rawValue).noPurpose")
                }
                PrivacyLinkageLine(type: type, answer: answer, viewModel: viewModel)
            }
            if let entry, entry.status.isAssistants, let rationale = entry.suggestion?.rationale {
                Text(rationale)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let entry, let conflict = entry.conflict {
                PrivacyConflictBox(yours: entry.answer, theirs: conflict) {
                    viewModel.keepYours(type)
                } onUseTheirs: {
                    viewModel.useAssistants(type)
                }
                .accessibilityIdentifier("appInformation.appPrivacy.type.\(type.rawValue).conflict")
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small + 2)
        .background(background(entry))
        .overlay(alignment: .leading) {
            if isMismatched {
                Rectangle().fill(Palette.warningMark).frame(width: 3).accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(accessibilityLabel(entry, answer: answer)))
        .accessibilityIdentifier("appInformation.appPrivacy.type.\(type.rawValue)")
    }

    private func collectedPicker(_ answer: PrivacyAnswer) -> some View {
        Picker(type.name, selection: Binding(get: { answer.collected }, set: { viewModel.setCollected(type, $0) })) {
            Text("Not collected").tag(false)
            Text("Collected").tag(true)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .controlSize(.small)
        .accessibilityIdentifier("appInformation.appPrivacy.type.\(type.rawValue).collected")
    }

    /// The assistant's chip while the answer is its, or "You".
    @ViewBuilder
    private func sourceTag(_ entry: PrivacyTypeEntry) -> some View {
        if let client = entry.client {
            AssistantChip(name: client)
        } else {
            Text("You")
                .font(.caption)
                .foregroundStyle(Palette.label2)
        }
    }

    private func background(_ entry: PrivacyTypeEntry?) -> Color {
        if isMismatched { return Palette.warningTint }
        return entry?.status == .unreviewed ? Palette.machineTranslatedTint : Palette.raised
    }

    private func accessibilityLabel(_ entry: PrivacyTypeEntry?, answer: PrivacyAnswer) -> String {
        let state = answer.collected ? String(localized: "collected") : String(localized: "not collected")
        guard entry?.status == .unreviewed else { return "\(type.name): \(state)" }
        return String(localized: "\(type.name): \(state), suggestion not reviewed")
    }
}
