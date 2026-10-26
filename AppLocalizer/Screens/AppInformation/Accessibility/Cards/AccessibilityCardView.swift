//
//  AccessibilityCardView.swift
//  AppLocalizer
//

import SwiftUI

/// One device family's card: its state, the answer, what changes when it
/// publishes, a note, and Edit… / Declare…, Copy from iPhone and Delete
/// Draft.
struct AccessibilityCardView: View {
    let card: AccessibilityCard
    let viewModel: AppInformationViewModel

    var body: some View {
        Card {
            header
            answer
            if let note = card.note {
                Label(note, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(prefix).note")
            }
            Spacer(minLength: 0)
            actions
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityIdentifier(prefix)
    }

    private var prefix: String { "appInformation.accessibility.\(card.family.rawValue)" }

    private var header: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: card.family.systemImage)
                .foregroundStyle(Palette.label2)
                .frame(width: 16)
                .accessibilityHidden(true)
            Text(card.family.name)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.small)
            if card.hasPendingChange {
                Pill(text: String(localized: "Not pushed"), systemImage: "circle.fill", style: .accent)
                    .accessibilityIdentifier("\(prefix).notPushed")
            }
            AccessibilityStateBadge(state: card.state)
                .accessibilityIdentifier("\(prefix).state")
        }
    }

    @ViewBuilder
    private var answer: some View {
        if let shown = card.shown, card.state != .notDeclared {
            Text(shown.supportsAny ? "Supports accessibility features: Yes" : "Supports accessibility features: No")
                .font(.callout)
            if shown.supportsAny {
                AccessibilityFeaturePills(features: shown.orderedFeatures, unpublished: card.unpublishedFeatures)
            }
            if let changes = card.changesAfterPublishing {
                AccessibilityChangesBox(added: changes.added, removed: changes.removed)
            }
        } else {
            Text("Not declared for \(card.family.name).")
                .font(.callout)
        }
    }

    private var actions: some View {
        HStack(spacing: Spacing.small) {
            if card.state == .notDeclared {
                Button(String(localized: "Declare…")) { viewModel.openEditor(card.family) }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("\(prefix).declare")
            } else {
                Button(String(localized: "Edit…")) { viewModel.openEditor(card.family) }
                    .accessibilityIdentifier("\(prefix).edit")
            }
            if viewModel.canCopyFromIPhone(to: card.family) {
                Button(String(localized: "Copy from iPhone")) { viewModel.copyFromIPhone(to: card.family) }
                    .accessibilityIdentifier("\(prefix).copy")
            }
            if card.canDeleteDraft {
                Button(String(localized: "Delete Draft"), role: .destructive) { viewModel.deleteDraft(card.family) }
                    .foregroundStyle(Palette.danger)
                    .accessibilityIdentifier("\(prefix).deleteDraft")
            }
        }
        .controlSize(.small)
        .padding(.top, Spacing.xxSmall)
    }
}
