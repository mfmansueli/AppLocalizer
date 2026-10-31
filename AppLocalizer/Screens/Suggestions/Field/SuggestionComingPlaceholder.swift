//
//  SuggestionComingPlaceholder.swift
//  AppLocalizer
//

import SwiftUI

/// Under a field, question or feature Suggest Everything still owes a
/// suggestion: a striped strip saying the assistant is writing it. The
/// suggestion card takes its place when it arrives.
struct SuggestionComingPlaceholder: View {
    enum Kind {
        case field
        case question
        case feature
    }

    /// e.g. "Claude Code".
    let client: String
    var kind: Kind = .field

    var body: some View {
        HStack(spacing: Spacing.small) {
            ProgressView()
                .controlSize(.mini)
            Text(text)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Canvas { context, size in
                var path = Path()
                for x in stride(from: -size.height, to: size.width, by: 14) {
                    path.move(to: CGPoint(x: x, y: size.height))
                    path.addLine(to: CGPoint(x: x + size.height, y: 0))
                }
                context.stroke(path, with: .color(Palette.machineTranslatedTint), lineWidth: 5)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                .strokeBorder(Palette.machineTranslatedMark.opacity(0.35), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("suggestions.coming")
    }

    /// "Claude Code is writing a suggestion for this field…".
    private var text: String {
        switch kind {
        case .field: String(localized: "\(client) is writing a suggestion for this field…")
        case .question: String(localized: "\(client) is writing a suggestion for this question…")
        case .feature: String(localized: "\(client) is writing a suggestion for this feature…")
        }
    }
}

#Preview {
    VStack {
        SuggestionComingPlaceholder(client: "Claude Code")
        SuggestionComingPlaceholder(client: "Claude Code", kind: .question)
    }
    .padding()
    .frame(width: 600)
}
