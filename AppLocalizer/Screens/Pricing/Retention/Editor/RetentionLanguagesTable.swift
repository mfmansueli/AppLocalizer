//
//  RetentionLanguagesTable.swift
//  AppLocalizer
//

import SwiftUI

/// Every language at a glance: its header, how long its message is, and
/// whether it's written, translated, too long or missing. Click a row to
/// edit that language.
struct RetentionLanguagesTable: View {
    let model: RetentionModel
    let message: RetentionMessage

    private static let languageWidth: CGFloat = 116
    private static let countWidth: CGFloat = 64
    private static let statusWidth: CGFloat = 88

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.small) {
                Text("Language").frame(width: Self.languageWidth, alignment: .leading)
                Text("Header").frame(maxWidth: .infinity, alignment: .leading)
                Text("Message").frame(width: Self.countWidth, alignment: .leading)
                Text("Status").frame(width: Self.statusWidth, alignment: .leading)
            }
            .font(.caption)
            .foregroundStyle(Palette.label2)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(Palette.fill1)
            ForEach(builderLanguages) { locale in
                Divider()
                row(locale)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                .strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("retention.languagesTable")
    }

    private var builderLanguages: [StoreLocale] {
        model.builder.languages(of: message)
    }

    private func row(_ locale: StoreLocale) -> some View {
        let text = message.text(for: locale.code)
        let status = model.status(of: locale, in: message)
        let isSelected = locale.code == model.selectedLocale
        return Button {
            model.selectedLocale = locale.code
        } label: {
            HStack(spacing: Spacing.small) {
                Text(locale.name)
                    .font(.callout.weight(.medium))
                    .frame(width: Self.languageWidth, alignment: .leading)
                Text(text.header.isEmpty ? String(localized: "Missing") : text.header)
                    .font(.callout)
                    .foregroundStyle(text.header.isEmpty ? Palette.label3 : Palette.label)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .environment(\.layoutDirection, RetentionCancelStrings.isRightToLeft(locale.code) ? .rightToLeft : .leftToRight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(text.body.isEmpty ? "—" : "\(text.bodyCount) / \(RetentionLimits.bodyLength)")
                    .font(.caption.weight(text.isBodyTooLong ? .semibold : .regular))
                    .foregroundStyle(text.isBodyTooLong ? Palette.danger : Palette.label2)
                    .monospacedDigit()
                    .frame(width: Self.countWidth, alignment: .leading)
                Pill(text: status.title, style: status.pillStyle)
                    .frame(width: Self.statusWidth, alignment: .leading)
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(isSelected ? Palette.accentTint : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("retention.languageRow.\(locale.code)")
    }
}
