//
//  GuidedAutopilotSheet.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// The guided Screenshot Autopilot: three setup steps (What to make, Look,
/// Plan), Making it while it runs on its own, then the person's two
/// stops, Choose and Review & push, and Done. Closing it doesn't stop
/// anything; the same run and engine as the classic sheet.
struct GuidedAutopilotSheet: View {
    @Bindable var studio: ScreenshotStudioModel
    /// The connected assistant that can run Xcode.
    let assistant: String?
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?

    var body: some View {
        VStack(spacing: 0) {
            if let run = studio.run {
                let step = studio.guidedStep
                GuidedSheetHeader(studio: studio, run: run, step: step)
                GuidedStepperView(position: studio.guidedPosition, isWorking: GuidedLiveTimeline.isWorking(run))
                    .padding(.horizontal, Spacing.xLarge)
                    .padding(.bottom, Spacing.medium)
                Divider()
                content(run, step: step)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                if step != .done {
                    Divider()
                    GuidedSheetFooter(studio: studio, run: run, step: step)
                }
            } else {
                ContentUnavailableView("No Autopilot run", systemImage: "sparkles", description: Text("Start… sets one up."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Button("Close") { studio.isAutopilotPresented = false }
                    .padding()
            }
        }
        .frame(minWidth: 960, idealWidth: 1040, minHeight: 640, idealHeight: 760)
        .background(Palette.window)
        .overlay {
            if let viewer = studio.viewer { FullSizeViewer(studio: studio, viewer: viewer) }
        }
        .fileImporter(isPresented: isUploading, allowedContentTypes: [.png]) { result in
            guard let problem = studio.uploadingProblem, case let .success(url) = result else { return }
            studio.uploadingProblem = nil
            Task { await studio.upload(url, for: problem) }
        }
        .alert(Text("Couldn’t push"), isPresented: hasPushError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(studio.guided.pushError ?? "")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.sheet")
        .onAppear { studio.launcher = launcher }
        .onDisappear { studio.closeViewer() }
    }

    @ViewBuilder
    private func content(_ run: AutopilotRun, step: GuidedStep) -> some View {
        switch step {
        case .make:
            GuidedMakeStepView(studio: studio, run: run)
        case .look:
            GuidedLookStepView(studio: studio, run: run)
        case .plan:
            GuidedPlanStepView(studio: studio, run: run, assistant: assistant)
        case .making:
            GuidedMakingStepView(studio: studio, run: run, assistant: assistant)
        case .choose:
            GuidedChooseStepView(studio: studio, run: run)
        case .review:
            GuidedReviewStepView(studio: studio, run: run)
        case .done:
            GuidedDoneStepView(studio: studio, run: run)
        }
    }

    private var isUploading: Binding<Bool> {
        Binding {
            studio.uploadingProblem != nil
        } set: { isPresented in
            if !isPresented { studio.uploadingProblem = nil }
        }
    }

    private var hasPushError: Binding<Bool> {
        Binding {
            studio.guided.pushError != nil
        } set: { isPresented in
            if !isPresented { studio.guided.pushError = nil }
        }
    }
}
