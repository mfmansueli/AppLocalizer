//
//  AgeRatingQuestionRow.swift
//  AppLocalizer
//

import SwiftUI

/// One question: its answers as a segmented picker. An assistant's answer
/// also shows "Proposed", its reason, Evidence (a popover) and Confirmed.
struct AgeRatingQuestionRow: View {
    let question: AgeRatingQuestion
    let answer: AgeRatingAnswer
    @Bindable var viewModel: AppInformationViewModel

    var body: some View {
        Group {
            if let assistant = viewModel.assistantAnswers[question] {
                assistantRow(client: assistant.client, confirmed: assistant.confirmed)
            } else {
                AppInformationFormRow(label: question.title) { picker }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.age.\(question.rawValue)")
    }

    private var picker: some View {
        Picker(question.title, selection: Binding(get: { answer }, set: { viewModel.setAnswer($0, for: question) })) {
            ForEach(question.answers) { answer in
                Text(answer.title).tag(answer)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .accessibilityLabel(Text(question.title))
    }

    private func assistantRow(client: String, confirmed: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(question.title)
                    if let why = viewModel.evidence(for: question)?.why {
                        Text(why)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: Spacing.small)
                AssistantProposedTag(client: client)
                evidenceButton
                Toggle(String(localized: "Confirmed"), isOn: Binding(get: { confirmed }, set: { viewModel.confirmAnswer(question, $0) }))
                    .toggleStyle(.checkbox)
                    .accessibilityIdentifier("appInformation.age.\(question.rawValue).confirmed")
            }
            picker
        }
        .padding(.horizontal, Spacing.medium + 2)
        .padding(.vertical, Spacing.small + 1)
    }

    @ViewBuilder
    private var evidenceButton: some View {
        if let evidence = viewModel.evidence(for: question) {
            Button(String(localized: "Evidence")) { viewModel.evidenceQuestion = question }
                .buttonStyle(.link)
                .accessibilityIdentifier("appInformation.age.\(question.rawValue).evidence")
                .popover(isPresented: Binding(
                    get: { viewModel.evidenceQuestion == question },
                    set: { if !$0 { viewModel.evidenceQuestion = nil } }
                )) {
                    AssistantEvidencePopover(
                        title: "\(question.title) → \(answer.title)",
                        evidence: evidence,
                        onReject: { viewModel.rejectAnswer(question) },
                        onConfirm: {
                            viewModel.confirmAnswer(question, true)
                            viewModel.evidenceQuestion = nil
                        }
                    )
                }
        }
    }
}
