//
//  SuggestionProvenanceLine.swift
//  AppLocalizer
//

import SwiftUI

/// Under a field whose value came from a suggestion, while it's not pushed:
/// "Accepted Claude Code’s suggestion." with Undo, or "Edited from Claude
/// Code’s suggestion." once the text changed.
struct SuggestionProvenanceLine: View {
    let provenance: SuggestionProvenance
    let currentValue: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(Palette.accentText)
                .accessibilityHidden(true)
            SuggestionSourceTag(source: provenance.source)
            Text(provenance.line(currentValue: currentValue))
                .foregroundStyle(Palette.label2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("suggestion.provenanceText")
            Button("Undo", action: onUndo)
                .buttonStyle(.link)
                .accessibilityIdentifier("suggestion.undo")
        }
        .font(.caption)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("suggestion.provenance")
    }
}

#Preview {
    SuggestionProvenanceLine(
        provenance: SuggestionProvenance(
            suggestionID: "sg_1",
            source: .assistant(client: "Claude Code"),
            value: "• Weekly reflections",
            previousValue: "• Bug fixes",
            isForEditing: false
        ),
        currentValue: "• Weekly reflections"
    ) {}
        .padding()
        .frame(width: 520)
}
