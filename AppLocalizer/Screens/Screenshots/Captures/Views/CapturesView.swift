//
//  CapturesView.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// The Captures tab: the drop zone before any import, the matching step
/// while one is open, the coverage after.
struct CapturesView: View {
    @Bindable var viewModel: ScreenshotsViewModel

    private var captures: CapturesViewModel { viewModel.captures }

    var body: some View {
        @Bindable var captures = captures
        VStack(spacing: 0) {
            if let message = captures.errorMessage {
                Banner(kind: .warning, title: message) {
                    Button {
                        captures.errorMessage = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Text("Dismiss"))
                }
                .accessibilityIdentifier("captures.error")
            }
            content
        }
        .fileImporter(
            isPresented: $captures.isImporterPresented, allowedContentTypes: [.folder, .png, .package], allowsMultipleSelection: true
        ) { result in
            guard case let .success(urls) = result else { return }
            Task { await captures.scan(urls, securityScoped: true) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("captures.root")
    }

    @ViewBuilder
    private var content: some View {
        if let session = captures.session {
            CaptureMatchingView(captures: captures, session: session)
        } else if let coverage = captures.coverage {
            CaptureCoverageView(viewModel: viewModel, coverage: coverage)
        } else {
            CaptureDropZoneView(captures: captures)
        }
    }
}
