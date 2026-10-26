//
//  AccessibilityFeatureRow.swift
//  AppLocalizer
//

import SwiftUI

/// One feature in the editor: a checkbox with the name and its meaning,
/// Live / Adds / Removes against what's published, an assistant's
/// suggestion, and Criteria ↗.
struct AccessibilityFeatureRow: View {
    let feature: AccessibilityFeature
    let isChecked: Bool
    let status: AccessibilityRowStatus?
    let suggestion: AccessibilitySuggestion?
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small + 2) {
            Toggle(feature.name, isOn: Binding(get: { isChecked }, set: { _ in onToggle() }))
                .toggleStyle(.checkbox)
                .labelsHidden()
                .accessibilityLabel(Text(feature.name))
                .accessibilityHint(Text(feature.meaning))
                .accessibilityIdentifier("appInformation.accessibility.editor.\(feature.rawValue)")
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.small) {
                    Text(feature.name)
                        .fontWeight(.semibold)
                    if let suggestion {
                        AssistantProposedTag(client: suggestion.client, text: String(localized: "Suggested"))
                        confidence(suggestion.confidence)
                    }
                    if let status {
                        Pill(text: status.title, style: statusStyle(status))
                            .accessibilityIdentifier("appInformation.accessibility.editor.\(feature.rawValue).status")
                    }
                }
                Text(feature.meaning)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                if let suggestion {
                    Text("\(suggestion.client): \(suggestion.rationale) Code alone can’t prove support; check it with the feature on.")
                        .font(.caption2)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: Spacing.small)
            ExternalLinkButton(title: String(localized: "Criteria"), url: feature.criteriaURL, isLink: true)
                .font(.caption)
                .accessibilityLabel(Text("\(feature.name) criteria"))
        }
        .padding(.horizontal, Spacing.medium + 2)
        .padding(.vertical, Spacing.small + 1)
        .contentShape(Rectangle())
    }

    private func confidence(_ confidence: SuggestionConfidence) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "cellularbars", variableValue: confidence == .medium ? 0.66 : 0.33)
                .imageScale(.small)
            Text(confidence.title)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(Palette.label2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(confidence.title) confidence"))
    }

    private func statusStyle(_ status: AccessibilityRowStatus) -> PillStyle {
        switch status {
        case .live: .neutral
        case .adds: .accent
        case .removes: .danger
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        AccessibilityFeatureRow(feature: .voiceOver, isChecked: true, status: .live, suggestion: nil) {}
        Divider()
        AccessibilityFeatureRow(
            feature: .darkInterface,
            isChecked: false,
            status: nil,
            suggestion: AccessibilitySuggestion(
                feature: .darkInterface,
                supports: true,
                confidence: .medium,
                rationale: "Every color comes from the asset catalog with a dark variant.",
                client: "Claude Code"
            )
        ) {}
    }
    .frame(width: 600)
    .padding()
}
