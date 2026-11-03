//
//  AutopilotSheet.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// The Screenshot Autopilot sheet: the eight stages on the left, the one
/// shown on the right, and its buttons underneath, with the full-size
/// viewer over it. Closing it doesn't stop anything.
struct AutopilotSheet: View {
    @Bindable var studio: ScreenshotStudioModel
    /// The connected assistant that can run Xcode.
    let assistant: String?
    @Environment(WorkspaceNavigator.self) private var navigator: WorkspaceNavigator?
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?

    var body: some View {
        VStack(spacing: 0) {
            if let run = studio.run {
                AutopilotSheetHeader(
                    appName: studio.app.name, run: run,
                    hides: run.stage.isRunning
                ) {
                    studio.isAutopilotPresented = false
                }
                Divider()
                HStack(spacing: 0) {
                    AutopilotStageList(studio: studio, run: run, assistant: assistant)
                        .frame(width: 220)
                    Divider()
                    stage(run)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                Divider()
                AutopilotSheetFooter(studio: studio, run: run) {
                    studio.isAutopilotPresented = false
                    navigator?.isReviewPresented = true
                }
            } else {
                ContentUnavailableView("No Autopilot run", systemImage: "camera", description: Text("Run Autopilot… plans one."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Button("Close") { studio.isAutopilotPresented = false }
                    .padding()
            }
        }
        .frame(minWidth: 960, idealWidth: 1100, minHeight: 640, idealHeight: 760)
        .overlay {
            if let viewer = studio.viewer { FullSizeViewer(studio: studio, viewer: viewer) }
        }
        .fileImporter(isPresented: isUploading, allowedContentTypes: [.png]) { result in
            guard let problem = studio.uploadingProblem, case let .success(url) = result else { return }
            studio.uploadingProblem = nil
            Task { await studio.upload(url, for: problem) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.sheet")
        .onAppear { studio.launcher = launcher }
        .onDisappear { studio.closeViewer() }
    }

    @ViewBuilder
    private func stage(_ run: AutopilotRun) -> some View {
        switch studio.shownStep {
        case .plan, .waiting:
            AutopilotPlanStageView(studio: studio, run: run, assistant: assistant, isEditable: run.stage == .plan)
        case .capture:
            if run.stage == .waiting {
                AutopilotWaitStageView(studio: studio, client: assistant)
            } else {
                AutopilotCaptureStageView(studio: studio, run: run)
            }
        case .pick:
            AutopilotPickStageView(studio: studio, run: run, isEditable: run.stage == .pick)
        case .design:
            AutopilotDesignStageView(studio: studio, run: run)
        case .choose:
            AutopilotChooseStageView(studio: studio, run: run, isEditable: run.stage == .choose)
        case .localize:
            AutopilotLocalizeStageView(studio: studio, run: run)
        case .watchPreview:
            AutopilotWatchStageView(studio: studio, run: run, isEditable: run.stage == .watchPreview)
        case .ready:
            AutopilotReadyStageView(studio: studio, run: run)
        }
    }

    private var isUploading: Binding<Bool> {
        Binding {
            studio.uploadingProblem != nil
        } set: { isPresented in
            if !isPresented { studio.uploadingProblem = nil }
        }
    }
}
