//
//  AssistantEvidencePopover.swift
//  AppLocalizer
//

import SwiftUI

/// Why an assistant answered as it did: the answer, the reason, the
/// evidence it found (selectable, monospaced) and what it couldn't see,
/// with Reject and Confirm.
struct AssistantEvidencePopover: View {
    let title: String
    let evidence: AssistantEvidence
    let onReject: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small + 2) {
            SourceTag(source: .assistant(client: evidence.client))
            Text(title)
                .font(.headline)
            Text(evidence.summary)
                .font(.callout)
                .foregroundStyle(Palette.label2)
            Text(evidence.why)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            if !evidence.evidence.isEmpty {
                evidenceList
            }
            if let couldNotSee = evidence.couldNotSee {
                couldNotSeeBox(couldNotSee)
            }
            HStack {
                Spacer()
                Button("Reject", action: onReject)
                    .accessibilityIdentifier("appInformation.evidence.reject")
                Button("Confirm", action: onConfirm)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("appInformation.evidence.confirm")
            }
        }
        .padding(Spacing.large)
        .frame(width: 360)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.evidence")
    }

    private var evidenceList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EVIDENCE")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Palette.label2)
                .padding(.bottom, Spacing.xxSmall)
            ForEach(evidence.evidence, id: \.self) { line in
                Divider()
                Text(line)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, Spacing.xSmall)
            }
        }
    }

    private func couldNotSeeBox(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.warningMark)
                .accessibilityHidden(true)
            Text("**Couldn’t see:** \(text)")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.small + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.warningTint, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
    }
}

#Preview {
    AssistantEvidencePopover(
        title: "Export compliance",
        evidence: AssistantEvidence(
            client: "Claude Code",
            summary: "Uses encryption: Yes · exempt: Yes",
            why: "Lumen only uses encryption built into Apple’s operating systems.",
            evidence: ["Vault/EntryVault.swift:8 — import CryptoKit"],
            couldNotSee: "Server-side encryption isn’t part of this question."
        ),
        onReject: {},
        onConfirm: {}
    )
}
