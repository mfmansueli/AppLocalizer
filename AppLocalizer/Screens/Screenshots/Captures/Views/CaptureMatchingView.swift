//
//  CaptureMatchingView.swift
//  AppLocalizer
//

import SwiftUI

/// The matching step (design `capt-match`): what was found and where,
/// with a choice on each row that needs you. Nothing is uploaded here.
struct CaptureMatchingView: View {
    @Bindable var captures: CapturesViewModel
    let session: CaptureImportSession

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(captures.visibleRows) { row in
                            CaptureMatchRowView(row: row) { choice in
                                captures.choose(choice, forRow: row.id)
                            }
                            Divider()
                        }
                        if let more = captures.moreMatchedText {
                            Button(more) { captures.showsAllMatched = true }
                                .buttonStyle(.link)
                                .font(.caption)
                                .foregroundStyle(Palette.label2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Spacing.medium)
                                .padding(.vertical, Spacing.small)
                                .accessibilityIdentifier("captures.moreMatched")
                        }
                    } header: {
                        CaptureMatchColumns()
                    }
                }
            }
            Divider()
            footer
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("captures.matching")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(session.title)
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier("captures.matching.title")
            Text(session.location)
                .font(.caption.monospaced())
                .foregroundStyle(Palette.label2)
                .textSelection(.enabled)
            HStack(spacing: Spacing.xSmall) {
                Pill(text: session.matchedText)
                if session.needsYouCount > 0 {
                    Pill(text: session.needsYouText, style: .warning)
                        .accessibilityIdentifier("captures.matching.needsYou")
                }
                Pill(text: session.spreadText, style: .outline)
            }
            .padding(.top, Spacing.xxSmall)
            if let warning = session.warning {
                InlineWarning(text: warning)
                    .padding(.top, Spacing.xxSmall)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
    }

    private var footer: some View {
        HStack(spacing: Spacing.small) {
            Text("Nothing is uploaded at this step. Captures stay on this Mac until you push renders.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
            Spacer(minLength: Spacing.large)
            Button("Cancel") { captures.cancel() }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("captures.cancel")
            Button(session.importTitle) {
                Task { await captures.importCaptures() }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(session.items.isEmpty || captures.isImporting)
            .accessibilityIdentifier("captures.import")
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
    }

    /// App Store Connect's warning that its screenshots may have captions.
    private struct InlineWarning: View {
        let text: String

        var body: some View {
            Label(text, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(Palette.warning)
                .accessibilityIdentifier("captures.matching.warning")
        }
    }
}
