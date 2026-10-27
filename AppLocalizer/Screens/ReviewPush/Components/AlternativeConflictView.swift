//
//  AlternativeConflictView.swift
//  AppLocalizer
//

import SwiftUI

/// Under a review row that the person and an assistant both edited: the two
/// versions side by side; clicking one keeps it.
struct AlternativeConflictView: View {
    let yours: String
    let alternative: ChangeAlternative
    let onPick: (_ keepAlternative: Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("\(Text("You and \(alternative.source.title) both changed this field.").bold()) \(Text("Pick the one to push.").foregroundStyle(Palette.label2))")
                .font(.callout)
            HStack(alignment: .top, spacing: Spacing.small) {
                version(title: String(localized: "Yours"), text: yours, identifier: "review.pickYours") { onPick(false) }
                version(title: alternative.source.title, text: alternative.newValue, identifier: "review.pickAssistant") { onPick(true) }
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func version(title: String, text: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                Text(text.isEmpty ? String(localized: "Empty") : text)
                    .font(.callout)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Push this version")
        .accessibilityLabel(Text("Keep \(title): \(text)"))
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    AlternativeConflictView(
        yours: "• Neu: Wochenrückblicke\n• Schnellere Suche\n• Fehlerbehebungen",
        alternative: ChangeAlternative(
            newValue: "• Wochenrückblicke: eine ruhige Zusammenfassung deiner Woche\n• Schnellere Suche",
            source: .assistant(client: "Claude Code"),
            requests: []
        ),
        onPick: { _ in }
    )
    .frame(width: 720)
    .padding()
}
