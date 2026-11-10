//
//  ExportCompliancePageView.swift
//  AppLocalizer
//

import SwiftUI

/// Export Compliance: the encryption questions, an assistant's answers
/// with their evidence, and the Info.plist key that skips the question.
struct ExportCompliancePageView: View {
    @Bindable var viewModel: AppInformationViewModel

    var body: some View {
        if let answers = viewModel.exportAnswers {
            VStack(alignment: .leading, spacing: Spacing.large) {
                AppInformationPageHeader(
                    title: AppInformationPage.exportCompliance.title,
                    subtitle: AppInformationPage.exportCompliance.summary(appName: viewModel.app.name, version: nil)
                ) {
                    Pill(text: answers.status)
                        .accessibilityIdentifier("appInformation.export.status")
                }
                AppInformationPageBar(viewModel: viewModel, page: .exportCompliance)
                if let evidence = viewModel.notes.exportEvidence {
                    assistantBanner(evidence)
                }
                if let notice = viewModel.exportNotice {
                    InlineMessage.warning(notice)
                        .accessibilityIdentifier("appInformation.export.notice")
                }
                AppInformationFormSection(title: String(localized: "Encryption")) {
                    ForEach(Array(answers.visibleQuestions.enumerated()), id: \.element) { index, question in
                        if index > 0 { Divider() }
                        AppInformationFormRow(label: question.title, detail: question.subtitle) {
                            YesNoPicker(title: question.title, value: answers[question]) {
                                viewModel.setExportAnswer($0, for: question)
                            }
                            .accessibilityIdentifier("appInformation.export.\(question.rawValue)")
                        }
                    }
                }
                if let build = viewModel.content?.export.buildNumber {
                    Text("Sent to build \(build) as “uses non-exempt encryption”. The answers themselves are kept on this Mac.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                InfoPlistKeyCard()
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("appInformation.exportCompliance")
        }
    }

    private func assistantBanner(_ evidence: AssistantEvidence) -> some View {
        AssistantAnswersBanner(client: evidence.client, text: String(localized: "answered from the app’s use of cryptography")) {
            Button(String(localized: "Evidence")) { viewModel.showsExportEvidence = true }
                .buttonStyle(.link)
                .accessibilityIdentifier("appInformation.export.evidence")
                .popover(isPresented: $viewModel.showsExportEvidence, arrowEdge: .bottom) {
                    AssistantEvidencePopover(
                        title: String(localized: "Export compliance"),
                        evidence: evidence,
                        onReject: { viewModel.rejectExportEvidence() },
                        onConfirm: { viewModel.confirmExportEvidence() }
                    )
                }
        }
    }
}
