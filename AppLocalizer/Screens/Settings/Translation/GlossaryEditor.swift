//
//  GlossaryEditor.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → Translation → Glossary: the terms that are never translated
/// (brand and product names), as removable tokens, plus Add Term.
struct GlossaryEditor: View {
    @Binding var glossary: TranslationGlossary
    @State private var isAdding = false
    @State private var draft = ""
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        FlowLayout(spacing: Spacing.xSmall) {
            ForEach(glossary.terms, id: \.self) { term in
                token(term)
            }
            if isAdding {
                TextField("New term", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                    .focused($isFieldFocused)
                    .onSubmit(add)
                    .onExitCommand { isAdding = false }
                    .accessibilityIdentifier("settings.glossaryField")
            } else {
                Button {
                    draft = ""
                    isAdding = true
                    isFieldFocused = true
                } label: {
                    Label("Add Term", systemImage: "plus")
                        .font(.callout)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, 3)
                        .background(Palette.fill1, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.addTerm")
            }
        }
        .onChange(of: isFieldFocused) { _, focused in
            if !focused, isAdding { add() }
        }
    }

    private func token(_ term: String) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Text(term)
                .font(.callout)
            Button {
                glossary.remove(term)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.label2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Remove \(term)"))
        }
        .padding(.horizontal, Spacing.small + 2)
        .padding(.vertical, 3)
        .background(Palette.fill2, in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings.term.\(term)")
    }

    private func add() {
        glossary.add(draft)
        draft = ""
        isAdding = false
    }
}
