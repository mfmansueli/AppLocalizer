//
//  PrivacyExportSheet.swift
//  AppLocalizer
//

import SwiftUI

/// "Export answers": fastlane JSON, or a summary as Markdown or PDF, with
/// a preview of the file. Reviewed answers only, and the worksheet, not
/// what's in App Store Connect.
struct PrivacyExportSheet: View {
    @Bindable var viewModel: AppPrivacyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Export answers")
                    .font(.title2.weight(.semibold))
                Text("For fastlane, or for your team and legal. Exports describe the worksheet, not what’s in App Store Connect.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                Picker(String(localized: "Format"), selection: $viewModel.exportFormat) {
                    ForEach(PrivacyExportFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("appInformation.appPrivacy.exportSheet.format")
                Text(viewModel.exportFormat == .fastlane ? "fastlane/\(viewModel.exportFileName)" : viewModel.exportFileName)
                    .font(.caption.monospaced())
                    .foregroundStyle(Palette.label2)
                    .help(viewModel.exportFormat.detail)
                ScrollView {
                    Text(viewModel.exportPreview)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.small + 2)
                }
                .frame(height: 330)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
                .accessibilityIdentifier("appInformation.appPrivacy.exportSheet.preview")
            }
            .padding(Spacing.xLarge)
            Divider()
            HStack {
                Spacer()
                Button(String(localized: "Cancel"), role: .cancel) { viewModel.isExportSheetPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button(String(localized: "Save…"), action: viewModel.saveExport)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("appInformation.appPrivacy.exportSheet.save")
            }
            .padding(Spacing.large)
        }
        .frame(width: 640)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.exportSheet")
    }
}
