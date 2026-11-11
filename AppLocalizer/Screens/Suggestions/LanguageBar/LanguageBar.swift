//
//  LanguageBar.swift
//  AppLocalizer
//

import SwiftUI

/// Over the Store Page's fields and the screenshots: the language in view
/// and how many suggestions it has, Accept All Languages beside it with the
/// total, arrows to the previous or next language with suggestions, how many
/// wait elsewhere, and Accept n in this language. When Accept All doesn't
/// ask first, the line under it says so and offers Ask First.
struct LanguageBar<Trailing: View>: View {
    let model: LanguageBarModel
    /// Accept All Languages is part of Pro and the person is on Free.
    var showsProChip = false
    let onSelect: (StoreLocale) -> Void
    let onAcceptAll: () -> Void
    let onAcceptHere: () -> Void
    let onAskFirst: () -> Void
    /// More controls at the end of the bar.
    @ViewBuilder var trailing: () -> Trailing

    @State private var showsMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            FlowLayout(spacing: Spacing.small) {
                picker
                acceptAll
                arrows
                if !model.restText.isEmpty {
                    Text(model.restText)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                        .accessibilityIdentifier("languageBar.rest")
                }
                if model.hereCount > 0 {
                    Button(model.acceptHereTitle, action: onAcceptHere)
                        .accessibilityIdentifier("languageBar.acceptHere")
                }
                trailing()
            }
            if model.acceptsRightAway, model.totalCount > 0 {
                acceptsRightAwayLine
            }
        }
        .padding(.leading, Spacing.xSmall)
        .padding(.trailing, 10)
        .padding(.vertical, Spacing.xSmall)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("languageBar")
    }

    private var picker: some View {
        Button {
            showsMenu.toggle()
        } label: {
            HStack(spacing: 9) {
                FlagTile(regionCode: model.current.regionCode)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: Spacing.tiny) {
                    Text(model.current.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(model.hereText)
                        .font(.caption2)
                        .fontWeight(model.hereCount > 0 ? .semibold : .regular)
                        .foregroundStyle(model.hereCount > 0 ? Palette.machineTranslated : Palette.label2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                    .accessibilityHidden(true)
            }
            .padding(.leading, Spacing.small)
            .padding(.trailing, 10)
            .frame(width: 220, height: 40)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(model.pickerAccessibilityText))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("languageBar.picker")
        .popover(isPresented: $showsMenu, arrowEdge: .bottom) {
            LanguageMenu(model: model) { locale in
                showsMenu = false
                onSelect(locale)
            } onAcceptAll: {
                showsMenu = false
                onAcceptAll()
            }
        }
    }

    /// Prominent while there's something to accept; once every language is
    /// reviewed it's a plain ✓ that says so, not a blue button that does
    /// nothing.
    @ViewBuilder
    private var acceptAll: some View {
        if model.totalCount > 0 {
            acceptAllButton.buttonStyle(.borderedProminent)
        } else {
            acceptAllButton.buttonStyle(.bordered)
        }
    }

    private var acceptAllButton: some View {
        Button(action: onAcceptAll) {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: model.totalCount > 0 ? "sparkles" : "checkmark")
                    .imageScale(.small)
                Text(model.acceptAllTitle)
                if model.totalCount > 0 {
                    Text(SuggestionBadge.text(for: model.totalCount))
                        .font(.system(size: 10.5, weight: .bold))
                        .monospacedDigit()
                        .padding(.horizontal, 5)
                        .frame(minWidth: 17, minHeight: 17)
                        .background(.white.opacity(0.26), in: Capsule())
                }
                if showsProChip { ProChip() }
            }
        }
        .disabled(model.totalCount == 0)
        .accessibilityLabel(Text(model.acceptAllAccessibilityText))
        .accessibilityIdentifier("languageBar.acceptAll")
    }

    private var arrows: some View {
        ControlGroup {
            Button {
                if let previous = model.previous { onSelect(previous) }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(model.previous == nil || model.previous == model.current)
            .help(arrowHelp(model.previous, String(localized: "Previous language with suggestions")))
            .accessibilityLabel(Text(arrowHelp(model.previous, String(localized: "Previous language with suggestions"))))
            .accessibilityIdentifier("languageBar.previous")
            Button {
                if let next = model.next { onSelect(next) }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(model.next == nil || model.next == model.current)
            .help(arrowHelp(model.next, String(localized: "Next language with suggestions")))
            .accessibilityLabel(Text(arrowHelp(model.next, String(localized: "Next language with suggestions"))))
            .accessibilityIdentifier("languageBar.next")
        }
        .fixedSize()
    }

    private func arrowHelp(_ locale: StoreLocale?, _ title: String) -> String {
        locale.map { "\(title): \($0.name)" } ?? title
    }

    private var acceptsRightAwayLine: some View {
        HStack(spacing: Spacing.small) {
            Pill(text: String(localized: "Accepts right away"), style: .accent)
                .fixedSize()
            Text("Accept All Languages doesn’t show the suggestions first. You can undo each time.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
            Button("Ask First", action: onAskFirst)
                .buttonStyle(.link)
                .font(.caption)
                .accessibilityIdentifier("languageBar.askFirst")
        }
        .padding(.leading, Spacing.xxSmall)
    }
}
