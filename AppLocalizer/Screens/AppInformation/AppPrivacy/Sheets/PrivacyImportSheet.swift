//
//  PrivacyImportSheet.swift
//  AppLocalizer
//

import SwiftUI

/// "Import app_privacy_details.json": the data types the file declares,
/// to import as the person's answers, or why the file can't be read.
struct PrivacyImportSheet: View {
    let viewModel: AppPrivacyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text("Import \(viewModel.importFileName ?? "app_privacy_details.json")")
                        .font(.title2.weight(.semibold))
                    if let path = viewModel.importFilePath {
                        Text(path)
                            .font(.caption.monospaced())
                            .foregroundStyle(Palette.label2)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                if let error = viewModel.importError {
                    InlineMessage.error(error)
                        .accessibilityIdentifier("appInformation.appPrivacy.importSheet.error")
                } else if let preview = viewModel.importPreview {
                    rows(preview)
                    Text("Imported answers are tagged as yours. Run a scan afterwards to check them against the code.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Spacing.xLarge)
            Divider()
            HStack {
                Spacer()
                Button(String(localized: "Cancel"), role: .cancel, action: viewModel.cancelImport)
                    .keyboardShortcut(.cancelAction)
                if let preview = viewModel.importPreview {
                    Button(importTitle(preview), action: viewModel.confirmImport)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .accessibilityIdentifier("appInformation.appPrivacy.importSheet.import")
                }
            }
            .padding(Spacing.large)
        }
        .frame(width: 540)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.importSheet")
    }

    private func rows(_ preview: PrivacyFastlaneImport) -> some View {
        VStack(spacing: 0) {
            if preview.types.isEmpty {
                row(String(localized: "Data Not Collected"), detail: String(localized: "The file says the app collects no data."))
            }
            ForEach(preview.types) { type in
                if let answer = preview.answers[type] {
                    if type != preview.types.first { Divider() }
                    row(type.name, detail: detail(answer))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.importSheet.rows")
    }

    private func row(_ title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(.callout)
            Spacer(minLength: Spacing.small)
            Text(detail)
                .font(.caption)
                .foregroundStyle(Palette.label2)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.raised)
        .accessibilityElement(children: .combine)
    }

    /// "App Functionality · linked", or "… · used for tracking".
    private func detail(_ answer: PrivacyAnswer) -> String {
        let purposes = answer.sortedPurposes.map(\.title).joined(separator: ", ")
        let linkage = answer.tracking ? String(localized: "used for tracking")
            : answer.linked ? String(localized: "linked") : String(localized: "not linked")
        return "\(purposes) · \(linkage)"
    }

    private func importTitle(_ preview: PrivacyFastlaneImport) -> String {
        preview.types.isEmpty ? String(localized: "Import") : String(localized: "Import \(preview.types.count) Data Types")
    }
}
