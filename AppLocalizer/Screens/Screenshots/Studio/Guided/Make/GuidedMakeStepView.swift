//
//  GuidedMakeStepView.swift
//  AppLocalizer
//

import SwiftUI

/// Step 1, What to make: any mix of screenshots, an App Preview and the
/// header and search artwork, then the languages.
struct GuidedMakeStepView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun

    var body: some View {
        let shots = studio.guidedLiveShots(count: 3)
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                GuidedStepTitle(
                    title: String(localized: "What should Autopilot make?"),
                    subtitle: studio.guidedMakeIntro
                )
                HStack(alignment: .top, spacing: 14) {
                    screenshotsCard(shots)
                    appPreviewCard(shots)
                    artworkCard
                }
                .fixedSize(horizontal: false, vertical: true)
                GuidedLanguagesRow(studio: studio, plan: plan)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .task { await studio.loadHeaderColors() }
    }

    private var plan: AutopilotPlan { run.plan }

    private func binding(_ part: GuidedReviewPart) -> Binding<Bool> {
        Binding { GuidedDefaults.makes(part, plan) } set: { studio.setGuidedMakes(part, $0) }
    }

    // MARK: - Cards

    private func screenshotsCard(_ shots: [StudioShot]) -> some View {
        GuidedMakeCard(
            title: String(localized: "Screenshots"),
            text: String(localized: "The images on your App Store page, captured from the real app."),
            isOn: binding(.screenshots), identifier: "autopilot.guided.make.screenshots"
        ) {
            HStack(spacing: Spacing.xSmall) {
                if shots.isEmpty {
                    ForEach(0..<3, id: \.self) { _ in placeholderPhone(width: 58) }
                } else {
                    ForEach(shots) { shot in
                        GuidedShotImage(studio: studio, shot: shot, width: 58)
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    }
                }
            }
        } options: {
            GuidedDeviceChips(studio: studio, plan: plan)
        }
    }

    private func appPreviewCard(_ shots: [StudioShot]) -> some View {
        GuidedMakeCard(
            title: String(localized: "App Preview video"),
            text: String(localized: "A short video of the app in use, recorded in Simulator, with captions and music."),
            isOn: binding(.appPreview), identifier: "autopilot.guided.make.appPreview"
        ) {
            ZStack {
                if let shot = shots.first {
                    GuidedShotImage(studio: studio, shot: shot, width: 62)
                } else {
                    placeholderPhone(width: 62)
                }
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 26))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.45))
            }
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        } options: {
            // One language: nothing to choose.
            if plan.localeCodes.count > 1 {
                previewLanguages
            }
        }
    }

    private var previewLanguages: some View {
        StudioSegmentedControl(
            label: String(localized: "App Preview languages"),
            options: [
                .init(value: AutopilotPreviewLanguages.primary, title: String(localized: "\(GuidedMakeSummary.primaryName(plan)) only"), key: "primary"),
                .init(value: AutopilotPreviewLanguages.all, title: String(localized: "Every language"), key: "all"),
            ],
            selection: Binding { plan.alsoMakes.previewLanguages } set: { languages in
                studio.updatePlan { $0.alsoMakes.previewLanguages = languages }
            },
            identifier: "autopilot.guided.make.previewLanguages"
        )
    }

    private var artworkCard: some View {
        let colors = studio.headerSketchColors
        let template = studio.headerTemplatePicks.first ?? studio.headerRecommendation.template
        return GuidedMakeCard(
            title: String(localized: "Header and search artwork"),
            text: String(localized: "The wide image at the top of your page, and the one shown in search results."),
            isOn: binding(.artwork), identifier: "autopilot.guided.make.artwork"
        ) {
            HeaderTemplateSketch(template: template, light: colors.light, dark: colors.dark, isMoving: plan.alsoMakes.makesMotion, width: 250)
        } options: {
            StudioSegmentedControl(
                label: String(localized: "Still or moving"),
                options: [
                    .init(value: AutopilotArtworkMotion.still, title: String(localized: "Still"), key: "still"),
                    .init(value: AutopilotArtworkMotion.loop, title: String(localized: "Moving"), key: "loop"),
                ],
                selection: Binding { plan.alsoMakes.artworkMotion } set: { studio.setArtworkMotion($0) },
                identifier: "autopilot.guided.make.motion"
            )
        }
    }

    private func placeholderPhone(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: width * 0.12, style: .continuous)
            .fill(Palette.fill2)
            .frame(width: width, height: (width * 2.17).rounded())
    }
}
