//
//  ReviewCreationRows.swift
//  AppLocalizer
//

import SwiftUI

/// What a push creates, e.g. "Create the Polish page" with "A new App Store
/// language for Lumen Journal, with the text below", then each field it's
/// created with: "Name", "Empty → Lumen — Dziennik", who wrote it. The
/// fields' checkboxes follow the page's: they can't be pushed without it.
struct ReviewCreationRows: View {
    let creation: ReviewCreation
    let isSelected: Bool
    let onToggle: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ForEach(creation.fields) { field in
                Divider()
                fieldRow(field)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Toggle(isOn: Binding(get: { isSelected }, set: { _ in onToggle() })) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .labelsHidden()
                .disabled(creation.isBlocked)
                .accessibilityLabel(Text("Select \(creation.title)"))
                .accessibilityIdentifier("review.creation.\(creation.id).toggle")
                VStack(alignment: .leading, spacing: 2) {
                    Text(creation.title)
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("review.creation.\(creation.id).title")
                    Text(creation.detail)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("review.creation.\(creation.id).detail")
                }
                Spacer(minLength: Spacing.small)
                SourceTag(source: creation.source)
                Button(action: onDiscard) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .help("Don’t create it, or push its fields")
                .accessibilityLabel(Text("Discard \(creation.title)"))
                .accessibilityIdentifier("review.creation.\(creation.id).discard")
            }
            if let message = creation.blockingMessage {
                Label(message, systemImage: "exclamationmark.octagon.fill")
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
                    .padding(.leading, 26)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.creation.\(creation.id)")
    }

    private func fieldRow(_ field: PendingChangePart) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            // Mirrors the page's checkbox; it can't be changed on its own.
            Toggle(isOn: .constant(isSelected)) {
                EmptyView()
            }
            .toggleStyle(.checkbox)
            .labelsHidden()
            .disabled(true)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(field.title)
                HStack(spacing: Spacing.xSmall) {
                    // "Empty" always shows whole; a long old value gives way.
                    Text(field.oldValue.isEmpty ? String(localized: "Empty") : field.oldValue)
                        .layoutPriority(field.oldValue.isEmpty ? 1 : -1)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .accessibilityLabel(Text("to"))
                    Text(field.newValue.isEmpty ? String(localized: "Empty") : field.newValue)
                }
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(Palette.label2)
            }
            Spacer(minLength: Spacing.small)
            SourceTag(source: field.source)
                // Lines up with the page's tag, past its discard button.
                .padding(.trailing, 22)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("review.creation.\(creation.id).\(field.id)")
    }
}

#Preview {
    let creation = PendingCreation(
        id: "storePage.1.pl",
        title: "Create the Polish page",
        detail: "A new App Store language for Lumen Journal, with the text below",
        source: .builtInSuggestion,
        fields: [
            PendingChangePart(id: "subtitle", title: "Subtitle", oldValue: "", newValue: "Dziennik nastroju", source: .assistant(client: "Claude Code")),
            PendingChangePart(id: "keywords", title: "Keywords", oldValue: "", newValue: "dziennik,nastrój", source: .assistant(client: "Claude Code")),
        ]
    )
    var change = PendingChange(
        id: "storePage.1.version.v1.pl.new",
        appID: "1",
        section: .storePage,
        group: "Store Page · Polish (new)",
        title: "Polish · New locale · 2 fields",
        oldValue: "",
        newValue: "",
        source: .builtInSuggestion,
        requests: []
    )
    change.creation = creation
    return ReviewCreationRows(
        creation: ReviewCreation.group([change])[0],
        isSelected: true,
        onToggle: {},
        onDiscard: {}
    )
    .frame(width: 760)
}
