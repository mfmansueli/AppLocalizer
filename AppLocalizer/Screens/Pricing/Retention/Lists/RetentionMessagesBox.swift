//
//  RetentionMessagesBox.swift
//  AppLocalizer
//

import SwiftUI

/// Messages, "1 of 10": each one's name, state, subscriptions and how many
/// languages it has. Click one to edit it.
struct RetentionMessagesBox: View {
    let model: RetentionModel

    var body: some View {
        RetentionBox(title: String(localized: "Messages")) {
            Text("\(model.messages.count) of \(RetentionLimits.messagesPerApp)")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .monospacedDigit()
        } content: {
            ForEach(Array(model.messages.enumerated()), id: \.element.id) { index, message in
                if index > 0 { Divider() }
                row(message)
            }
        }
        .accessibilityIdentifier("retention.messages")
    }

    private func row(_ message: RetentionMessage) -> some View {
        let isSelected = message.id == model.selectedMessageID
        let status = model.status(of: message)
        let name = RetentionText.trimmed(message.referenceName).isEmpty ? String(localized: "Untitled message") : message.referenceName
        return Button {
            model.select(message)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(name)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    Spacer(minLength: Spacing.xSmall)
                    Pill(text: status.title, style: status.pillStyle)
                }
                Text(model.listDetail(of: message))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(2)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Palette.accentTint : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(status.help)
        .contextMenu {
            if message.isNew {
                Button("Delete Draft") { model.discardDraft(message) }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("retention.message.\(message.id)")
    }
}
