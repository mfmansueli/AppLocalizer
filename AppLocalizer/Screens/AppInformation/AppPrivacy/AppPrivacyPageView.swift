//
//  AppPrivacyPageView.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// App Privacy: a worksheet an assistant helps fill from the code, a
/// checklist for entering it in App Store Connect (which has no API for
/// the questionnaire, so it's never pushed), and the privacy URLs, which
/// do go through Review & Push. Fills the page area itself: the worksheet
/// keeps the label preview in a column beside it.
struct AppPrivacyPageView: View {
    @Bindable var viewModel: AppPrivacyViewModel

    var body: some View {
        VStack(spacing: 0) {
            AppPrivacyHeader(viewModel: viewModel)
            Divider()
            switch viewModel.tab {
            case .worksheet: PrivacyWorksheetTab(viewModel: viewModel)
            case .checklist: PrivacyChecklistTab(viewModel: viewModel)
            case .urls: PrivacyURLsTab(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $viewModel.isExportSheetPresented) {
            PrivacyExportSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isImportSheetPresented) {
            PrivacyImportSheet(viewModel: viewModel)
        }
        .sheet(item: $viewModel.explainingType) { type in
            PrivacyExplainSheet(viewModel: viewModel, type: type)
        }
        .fileImporter(isPresented: $viewModel.isImporterPresented, allowedContentTypes: [.json]) { result in
            switch result {
            case let .success(url): viewModel.importFile(at: url)
            case let .failure(error): viewModel.say(error.localizedDescription)
            }
        }
        .fileExporter(
            isPresented: $viewModel.isExporterPresented,
            document: viewModel.isExporterPresented ? viewModel.exportDocument : nil,
            contentType: viewModel.exportFormat.contentType,
            defaultFilename: viewModel.exportFileName
        ) { result in
            viewModel.exportDidFinish(result)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy")
    }
}
