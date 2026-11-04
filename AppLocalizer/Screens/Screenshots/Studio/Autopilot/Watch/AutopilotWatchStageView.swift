//
//  AutopilotWatchStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Watch the App Preview, after Localize and check: the App Preview
/// playing (a language and a device to switch to when there are more), what
/// it is and its music, and Ask for changes, which goes to the design
/// source; with a header loop from the chosen concept, the loop under it
/// (or alone: Watch the header loop). Looked at later, it plays but doesn't
/// change.
struct AutopilotWatchStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let isEditable: Bool

    /// The height the stage has, to fit the player and its controls.
    @State private var height: CGFloat = 640
    /// The width inside the margins, for the header loop.
    @State private var width: CGFloat = 800

    /// The languages shown as segments; the rest are in a menu.
    private static let segmentLanguages = 4
    /// The title, the switches, the player's controls and the margins.
    private static let aroundPlayer: CGFloat = 250

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text(run.watchTitle).font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("autopilot.watch.title")
                    Spacer()
                    if run.watchesAppPreview {
                        Text(subtitle)
                            .font(.callout)
                            .foregroundStyle(Palette.label2)
                            .accessibilityIdentifier("autopilot.watch.subtitle")
                    }
                }
                if run.watchesAppPreview {
                    appPreview
                }
                if run.loopReview != nil, run.usesConcepts {
                    AutopilotLoopReviewBox(studio: studio, run: run, isEditable: isEditable, width: width)
                }
            }
            .padding(Spacing.xLarge)
        }
        .onGeometryChange(for: CGSize.self, of: { $0.size }, action: { height = $0.height; width = $0.width - Spacing.xLarge * 2 })
        // A new version or music is saved with the set: read it back.
        .task(id: ReloadKey(
            version: review?.version, music: run.plan.alsoMakes.previewMusic, isRemaking: review?.remake != nil,
            loop: run.loopReview?.version, isRemakingLoop: run.loopReview?.isRemaking == true
        )) {
            await studio.screenshots.reloadDocument()
        }
        .alert(String(localized: "This music can’t be used"), isPresented: musicError) {
            Button("OK") {}
        } message: {
            Text(studio.musicError ?? "")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.watch")
    }

    /// The App Preview playing, its switches, what it is and Ask.
    @ViewBuilder private var appPreview: some View {
        if let file = studio.watchedPreview {
            HStack(alignment: .top, spacing: Spacing.large) {
                VStack(spacing: Spacing.small) {
                    pickers
                    StudioAppPreviewPlayer(studio: studio, file: file, width: playerWidth(file))
                }
                .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: Spacing.small) {
                    AutopilotWatchInfoBox(studio: studio, file: file, isEditable: isEditable && review?.isBusy != true)
                    AutopilotWatchAskBox(studio: studio, run: run, isEditable: isEditable)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            HStack(spacing: Spacing.small) {
                ProgressView().controlSize(.small)
                Text("Opening the App Preview…").foregroundStyle(Palette.label2)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        }
    }

    private var review: AutopilotPreviewReview? { run.previewReview }

    /// iPhone's 206 pt and iPad's 260 pt, smaller when the controls
    /// wouldn't fit under it.
    private func playerWidth(_ file: ExtrasPreviewFile) -> CGFloat {
        let aspect = CGFloat(file.pixelSize.height) / CGFloat(max(file.pixelSize.width, 1))
        let fits = ((height - Self.aroundPlayer) / aspect).rounded(.down)
        return min(file.displayType == .iPad ? 260 : 206, max(140, fits))
    }

    /// "English (U.S.) · other languages show it · iPhone · v1",
    /// "15 languages · iPhone and iPad · v2".
    private var subtitle: String {
        let languages = run.plan.alsoMakes.previewLanguages == .all
            ? String(localized: "\(run.plan.previewLocales.count) languages")
            : String(localized: "\(StoreLocaleCatalog.locale(code: run.plan.primaryLocale)?.name ?? run.plan.primaryLocale) · other languages show it")
        let devices = run.plan.previewDisplays.map(\.shortTitle).formatted(.list(type: .and))
        return [languages, devices, "v\(review?.version ?? 1)"].joined(separator: " · ")
    }

    @ViewBuilder
    private var pickers: some View {
        let locales = studio.watchLocales
        if locales.count > 1 {
            HStack(spacing: Spacing.xSmall) {
                StudioSegmentedControl(
                    label: String(localized: "Language"),
                    options: locales.prefix(Self.segmentLanguages).map { .init(value: $0, title: languageName($0), key: $0) },
                    selection: Binding { watchedLocale } set: { watch(locale: $0) },
                    identifier: "autopilot.watch.language"
                )
                if locales.count > Self.segmentLanguages {
                    let more = Array(locales.dropFirst(Self.segmentLanguages))
                    Menu(more.contains(watchedLocale) ? languageName(watchedLocale) : String(localized: "\(more.count) more")) {
                        ForEach(more, id: \.self) { code in
                            Button(StoreLocaleCatalog.locale(code: code)?.name ?? code) { watch(locale: code) }
                        }
                    }
                    .menuStyle(.button)
                    .controlSize(.small)
                    .fixedSize()
                    .accessibilityIdentifier("autopilot.watch.moreLanguages")
                }
            }
        }
        let devices = studio.watchDevices
        if devices.count > 1 {
            StudioSegmentedControl(
                label: String(localized: "Device"),
                options: devices.map { .init(value: $0, title: $0.shortTitle, key: $0.mcpValue) },
                selection: Binding { studio.watchedPreview?.displayType ?? devices[0] } set: { device in
                    studio.previewPlayer.pause()
                    studio.watchedDevice = device
                },
                identifier: "autopilot.watch.device"
            )
        }
    }

    private var watchedLocale: String {
        studio.watchedPreview?.locale ?? run.plan.primaryLocale
    }

    private func watch(locale: String) {
        studio.previewPlayer.pause()
        studio.watchedLocale = locale
    }

    /// "German": short, for the segments.
    private func languageName(_ code: String) -> String {
        StoreLocaleCatalog.locale(code: code)?.shortName ?? code
    }

    private var musicError: Binding<Bool> {
        Binding { studio.musicError != nil } set: { if !$0 { studio.musicError = nil } }
    }

    private struct ReloadKey: Hashable {
        var version: Int?
        var music: AutopilotPreviewMusic
        var isRemaking: Bool
        var loop: Int?
        var isRemakingLoop: Bool
    }
}
