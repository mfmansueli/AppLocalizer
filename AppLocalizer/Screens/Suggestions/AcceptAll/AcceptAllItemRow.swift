//
//  AcceptAllItemRow.swift
//  AppLocalizer
//

import SwiftUI

/// One suggestion on the sheet's right side: its checkbox, the field, who
/// suggested it, Now and New, and why. Dimmed once unticked.
struct AcceptAllItemRow: View {
    let item: AcceptAllItem
    let isSelected: Bool
    let isRightToLeft: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AcceptAllCheckbox(state: isSelected ? .checked : .unchecked, label: String(localized: "Accept \(item.title)"), action: onToggle)
                .accessibilityIdentifier("acceptAll.item.\(item.id)")
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack(spacing: Spacing.xSmall) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    SuggestionSourceTag(source: item.source)
                }
                values
                    .opacity(isSelected ? 1 : 0.5)
                Text(item.reason)
                    .font(.caption2)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, 10)
        .background(isSelected ? AnyShapeStyle(Palette.machineTranslatedTint) : AnyShapeStyle(Palette.fill1), in: shape)
        .overlay(shape.strokeBorder(isSelected ? Palette.machineTranslatedMark.opacity(0.35) : Palette.separator, lineWidth: isSelected ? 1 : 0.5))
        .accessibilityElement(children: .contain)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
    }

    private var values: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 3) {
            GridRow {
                Text("NOW")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                    .gridColumnAlignment(.leading)
                value(item.current.isEmpty ? String(localized: "Empty") : item.current, isRightToLeft: isRightToLeft && !item.current.isEmpty)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(3)
            }
            GridRow {
                Text("NEW")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.machineTranslated)
                value(item.suggested, isRightToLeft: isRightToLeft)
                    .lineLimit(6)
            }
        }
    }

    private func value(_ text: String, isRightToLeft: Bool) -> some View {
        Text(text)
            .font(.caption)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
    }
}

#Preview {
    AcceptAllItemRow(
        item: AcceptAllItem(
            id: "1",
            title: "Subtitle",
            source: .assistant(client: "Claude Code"),
            current: "Mood journal & prompts",
            suggested: "Private diary, mood & prompts",
            reason: "“Private” is the word people praise most in your last 220 reviews."
        ),
        isSelected: true,
        isRightToLeft: false
    ) {}
        .padding()
        .frame(width: 520)
}
