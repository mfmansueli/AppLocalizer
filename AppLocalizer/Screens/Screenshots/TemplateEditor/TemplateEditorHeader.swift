//
//  TemplateEditorHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The template's name and version, "Unsaved edits" with Save, the CC tag
/// for a version that came from a proposal, History and Starter
/// Templates….
struct TemplateEditorHeader: View {
    @Bindable var model: TemplateEditorViewModel

    var body: some View {
        HStack(spacing: Spacing.small) {
            Text(model.template?.name ?? "")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
                .accessibilityIdentifier("screenshots.template.name")
            Pill(text: model.versionTitle)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("Version \(model.versionTitle)"))
                .accessibilityValue(Text(model.versionTitle))
                .accessibilityIdentifier("screenshots.template.version")
            if model.hasUnsavedEdits {
                unsaved
            }
            if let note = model.assistantNote {
                HStack(spacing: Spacing.xxSmall) {
                    MonogramTag(client: note.client)
                    Text(note.text)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("screenshots.template.assistant")
            }
            Spacer(minLength: Spacing.small)
            Button("History", systemImage: "clock") {
                model.isHistoryPresented.toggle()
            }
            .popover(isPresented: $model.isHistoryPresented, arrowEdge: .bottom) {
                TemplateHistoryPopover(model: model)
            }
            .accessibilityIdentifier("screenshots.template.history")
            Button("Starter Templates…") {
                model.isStarterSheetPresented = true
            }
            .accessibilityIdentifier("screenshots.template.starters")
        }
        .controlSize(.small)
        .padding(.horizontal, Spacing.large)
        .padding(.top, Spacing.small)
        .padding(.bottom, Spacing.xSmall)
    }

    private var unsaved: some View {
        HStack(spacing: Spacing.xSmall) {
            Pill(text: String(localized: "Unsaved edits"), systemImage: "circle.fill", style: .accent)
                .help(model.draftSummary ?? "")
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("screenshots.template.unsaved")
            Button {
                model.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.borderless)
            .help(Text("Undo the last edit"))
            .accessibilityLabel(Text("Undo"))
            .accessibilityIdentifier("screenshots.template.undo")
            Button(model.saveTitle) {
                Task { await model.save() }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("s", modifiers: .command)
            .accessibilityIdentifier("screenshots.template.save")
        }
    }
}
