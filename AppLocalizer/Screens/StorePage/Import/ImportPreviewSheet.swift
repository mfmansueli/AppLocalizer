//
//  ImportPreviewSheet.swift
//  AppLocalizer
//

import SwiftUI

/// "Import translations": what a translator's file would change, a
/// checkbox per change, and the problems found (unknown locale codes,
/// values over the limit), before anything is applied.
struct ImportPreviewSheet: View {
    let viewModel: StorePageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Import translations")
                    .font(.title2.weight(.semibold))
                if let preview = viewModel.importPreview {
                    Text(preview.summary)
                        .font(.caption.monospaced())
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("storePage.import.summary")
                }
            }
            .padding([.horizontal, .top], Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    if let preview = viewModel.importPreview {
                        changes(preview)
                        ForEach(Array(preview.problems.enumerated()), id: \.offset) { _, problem in
                            ImportProblemRow(problem: problem)
                        }
                    } else if let error = viewModel.importError {
                        InlineMessage.error(error)
                            .accessibilityIdentifier("storePage.import.error")
                    }
                }
                .padding(.horizontal, Spacing.xLarge)
                .padding(.bottom, Spacing.medium)
            }
            Divider()
            HStack(spacing: Spacing.small) {
                Button("Choose Another File…") {
                    viewModel.dismissImport(choosingAnother: true)
                }
                .buttonStyle(.link)
                Spacer()
                Button("Cancel", role: .cancel) {
                    viewModel.dismissImport()
                }
                .keyboardShortcut(.cancelAction)
                Button(viewModel.importPreview?.applyTitle ?? String(localized: "Apply")) {
                    viewModel.applyImport()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.importPreview?.selectedChanges.isEmpty ?? true)
                .accessibilityIdentifier("storePage.import.apply")
            }
            .padding(Spacing.large)
        }
        .frame(width: 720, height: 600)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.importSheet")
    }

    @ViewBuilder
    private func changes(_ preview: ListingImportPreview) -> some View {
        if preview.changes.isEmpty {
            Text("Nothing in this file differs from the store page.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
        } else {
            VStack(spacing: 0) {
                ForEach(preview.changes) { change in
                    ImportChangeRow(change: change) {
                        viewModel.toggleImportChange(change.id)
                    }
                    if change.id != preview.changes.last?.id {
                        Divider()
                    }
                }
            }
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        }
    }
}
