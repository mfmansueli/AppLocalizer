//
//  GuidedDoneStepView.swift
//  AppLocalizer
//

import SwiftUI

/// Done: the push to App Store Connect as it goes (the images, then the
/// header, search and App Preview), then "Sent to the App Store". What
/// couldn't be sent says so, with Try Again and Open Review & Push….
struct GuidedDoneStepView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    @Environment(PushController.self) private var push: PushController?
    @Environment(WorkspaceNavigator.self) private var navigator: WorkspaceNavigator?

    var body: some View {
        let images = imageRun
        let extras = extrasRun
        let outcome = GuidedPushOutcome.make(
            images: images.map { GuidedPushOutcome.Tally(total: $0.totalCount, done: $0.doneCount, isRunning: $0.isRunning) },
            extras: extras.map { GuidedPushOutcome.Tally(total: $0.items.count, done: $0.doneCount, isRunning: $0.isRunning) }
        )
        VStack(spacing: Spacing.medium) {
            Spacer(minLength: 0)
            if outcome == .sending {
                ProgressView().controlSize(.large)
                Text("Sending to the App Store")
                    .font(.title2.weight(.semibold))
                    .accessibilityIdentifier("autopilot.guided.done.title")
            } else {
                Image(systemName: outcome.symbol)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(outcome == .partly ? Palette.warningMark : Palette.accent, in: Circle())
                    .accessibilityHidden(true)
                Text(outcome.title)
                    .font(.title2.weight(.semibold))
                    .accessibilityIdentifier("autopilot.guided.done.title")
                Text(outcome.detail ?? sentText)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("autopilot.guided.done.text")
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                if let images {
                    progress(title: images.title, subtitle: images.subtitle, value: images.progress, identifier: "images")
                }
                if let extras {
                    progress(
                        title: extras.title, subtitle: extras.failures.first?.reason ?? "", value: extras.progress, identifier: "extras"
                    )
                }
            }
            .frame(maxWidth: 520)
            if outcome == .partly || outcome == .unknown {
                HStack(spacing: Spacing.small) {
                    Button("Open Review & Push…") { studio.openReviewPush(navigator) }
                        .accessibilityIdentifier("autopilot.guided.done.openReview")
                    if outcome == .partly {
                        Button("Try Again") {
                            push?.screenshots.run?.retryUnsent()
                            push?.screenshots.extras.run?.retryUnsent()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("autopilot.guided.done.retry")
                    }
                }
                .buttonBorderShape(.capsule)
            }
            Spacer(minLength: 0)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.done")
    }

    /// This app's image push, if it's the one going (or last gone).
    private var imageRun: ScreenshotPushRun? {
        guard let run = push?.screenshots.run, run.appIDs.contains(studio.app.id) else { return nil }
        return run
    }

    private var extrasRun: ExtrasPushRun? {
        guard let run = push?.screenshots.extras.run, run.items.contains(where: { $0.appID == studio.app.id }) else { return nil }
        return run
    }

    /// "12 screenshots, 2 App Previews and a header and search image in
    /// 15 languages are on App Store Connect. Template v5 is saved;
    /// everything is in the set’s history."
    private var sentText: String {
        let what = GuidedMakeSummary.pushed(run.plan) ?? String(localized: "The new files")
        var text = String(localized: "\(what) are on App Store Connect.")
        if let version = run.templateVersion, run.plan.makesScreenshots {
            text += " " + String(localized: "Template v\(version) is saved; everything is in the set’s history.")
        }
        return text + " " + String(localized: "Apple is processing them; the live page changes within minutes.")
    }

    private func progress(title: String, subtitle: String, value: Double, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(title).font(.callout.weight(.semibold))
            ProgressView(value: value)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("autopilot.guided.done.\(identifier)")
    }
}
