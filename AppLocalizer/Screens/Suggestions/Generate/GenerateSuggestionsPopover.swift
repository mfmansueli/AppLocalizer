//
//  GenerateSuggestionsPopover.swift
//  AppLocalizer
//

import SwiftUI

/// Before Generate Suggestions… sends anything with an API key: each part
/// of what goes to the vendor with about how many tokens, the total it
/// bills, and Generate. It waits for the answer here, with Cancel.
struct GenerateSuggestionsPopover: View {
    let model: GenerateSuggestionsModel
    let onGenerate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.title)
                .font(.headline)
            Text(model.intro)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            if let plan = model.plan {
                sends(plan)
                ForEach(plan.notes, id: \.self) { note in
                    Label(note, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let totalText = model.totalText {
                Text(totalText)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("generate.total")
            }
            footer
        }
        .padding(Spacing.large)
        .frame(width: 420)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("generate.popover")
    }

    private func sends(_ plan: KeyAssistantPlan) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(plan.items) { item in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Palette.label2)
                        .accessibilityHidden(true)
                    Text(item.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(KeyAssistantTokens.formatted(item.tokens))
                        .monospacedDigit()
                        .foregroundStyle(Palette.label2)
                }
                .font(.caption)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("\(item.title), about \(KeyAssistantTokens.formatted(item.tokens)) tokens"))
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("generate.sends")
    }

    @ViewBuilder
    private var footer: some View {
        switch model.phase {
        case .preparing:
            progress(String(localized: "Reading what to send…"))
        case .generating:
            progress(String(localized: "Waiting for \(model.client)…"))
        case .ready, .failed:
            if case let .failed(reason) = model.phase {
                Label(reason, systemImage: "exclamationmark.octagon")
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("generate.error")
            }
            HStack(spacing: Spacing.xSmall) {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("generate.cancel")
                Button(model.phase == .ready ? String(localized: "Generate") : String(localized: "Try Again"), action: onGenerate)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.canGenerate)
                    .accessibilityIdentifier("generate.go")
            }
            .controlSize(.small)
        }
    }

    private func progress(_ text: String) -> some View {
        HStack(spacing: Spacing.small) {
            ProgressView()
                .controlSize(.small)
            Text(text)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Cancel", action: onCancel)
                .controlSize(.small)
                .accessibilityIdentifier("generate.cancel")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, Spacing.small)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("generate.progress")
    }
}
