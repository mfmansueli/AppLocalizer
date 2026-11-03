//
//  AutopilotRunChoiceCard.swift
//  AppLocalizer
//

import SwiftUI

/// "What this run makes", at the top of the plan: presets, then a row each
/// for screenshots, the App Preview and the header and search artwork with
/// a cell per device, the languages, whether to capture again or reuse
/// the last captures, the App Preview's music, and what the run makes in
/// one sentence. A run can be
/// as small as one thing; what it leaves out stays live as it is.
struct AutopilotRunChoiceCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    let client: String

    static let deviceWidth: CGFloat = 66
    static let languagesWidth: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text("What this run makes").font(.headline).accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.small)
                StudioSegmentedControl(
                    label: String(localized: "Presets"),
                    options: AutopilotRunPreset.allCases.map { .init(value: $0, title: $0.title, isEnabled: $0 != .custom, key: $0.rawValue) },
                    selection: Binding { studio.runPreset(plan) } set: { studio.applyPreset($0) },
                    identifier: "autopilot.plan.preset"
                )
            }
            rows
            ForEach(studio.planDeviceNotes(plan), id: \.self) { note in
                Text(note)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            languages
            captures
            if plan.makesScreenshots, plan.plansDuo {
                AutopilotDuoChoiceRow(studio: studio, plan: plan)
            }
            if plan.alsoMakes.makesArtwork {
                AutopilotArtworkChoiceRow(studio: studio, plan: plan)
            }
            if plan.alsoMakes.makesAppPreview, !plan.previewDisplays.isEmpty {
                music
            }
            Text(studio.runSummaryText(plan))
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(plan.makesNothing ? Palette.warningTint : Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                .accessibilityIdentifier("autopilot.plan.runSummary")
        }
        .padding(Spacing.medium)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.runChoice")
    }

    private var devices: [ScreenshotDisplayType] { studio.planDevices(plan) }

    // MARK: - Rows

    private var rows: some View {
        Grid(alignment: .leading, horizontalSpacing: Spacing.small, verticalSpacing: 0) {
            GridRow {
                Text("Make").frame(maxWidth: .infinity, alignment: .leading)
                ForEach(devices, id: \.self) { display in
                    Text(display.shortTitle)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: Self.deviceWidth)
                }
                Text("Languages").frame(width: Self.languagesWidth, alignment: .leading)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Palette.label2)
            .padding(.bottom, Spacing.xxSmall)
            Divider()
            screenshotsRow
            Divider()
            appPreviewRow
            Divider()
            artworkRow
        }
    }

    private var screenshotsRow: some View {
        AutopilotRunChoiceRow(
            title: String(localized: "Screenshots"), detail: studio.screenshotsRowDetail(plan),
            isOn: Binding { plan.makesScreenshots } set: { studio.setMakesScreenshots($0) },
            identifier: "autopilot.plan.screenshots"
        ) {
            ForEach(devices, id: \.self) { display in
                let detail = studio.planDeviceDetail(display, plan: plan)
                cell(
                    isOn: plan.makesScreenshots && plan.displayTypes.contains(display),
                    // iPhone stays while the run makes screenshots: picks and the design start from it.
                    isEnabled: plan.makesScreenshots && display != .iPhone,
                    label: String(localized: "Screenshots on \(display.title)") + ", " + detail,
                    identifier: "autopilot.plan.\(display == .iPad ? "iPad" : display.mcpValue)"
                ) { studio.setPlans(display, $0) }
                    .help(Text(detail))
            }
        } languages: {
            Text(plan.makesScreenshots ? studio.runLanguagesTitle(plan) : "—").font(.callout)
        }
    }

    private var appPreviewRow: some View {
        AutopilotRunChoiceRow(
            title: String(localized: "App Preview video"), detail: studio.appPreviewRowDetail(plan),
            isOn: extrasBinding(\.makesAppPreview), identifier: "autopilot.plan.appPreview"
        ) {
            ForEach(devices, id: \.self) { display in
                if AutopilotExtras.previewDisplays.contains(display) {
                    cell(
                        isOn: plan.previewDisplays.contains(display), isEnabled: plan.alsoMakes.makesAppPreview,
                        label: String(localized: "App Preview on \(display.title)"),
                        identifier: "autopilot.plan.appPreview.\(display == .iPad ? "iPad" : display.mcpValue)"
                    ) { studio.setPreviews(display, $0) }
                } else {
                    Text(verbatim: "—")
                        .foregroundStyle(Palette.label3)
                        .frame(width: Self.deviceWidth)
                        .help(Text("AppLocalizer makes App Previews for iPhone and iPad"))
                        .accessibilityLabel(Text("No App Preview on \(display.title)"))
                }
            }
        } languages: {
            Picker(String(localized: "App Preview languages"), selection: extrasBinding(\.previewLanguages)) {
                ForEach(AutopilotPreviewLanguages.allCases, id: \.self) { languages in
                    Text(previewLanguagesTitle(languages)).tag(languages)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .disabled(!plan.alsoMakes.makesAppPreview)
            .accessibilityIdentifier("autopilot.plan.previewLanguages")
        }
    }

    private var artworkRow: some View {
        AutopilotRunChoiceRow(
            title: String(localized: "Header and search results"), detail: studio.artworkRowDetail(plan),
            isOn: extrasBinding(\.makesArtwork), identifier: "autopilot.plan.artwork"
        ) {
            Picker(String(localized: "Artwork size"), selection: Binding { plan.alsoMakes.artworkSize } set: { studio.setArtworkSize($0) }) {
                ForEach(AutopilotArtworkSize.allCases, id: \.self) { size in
                    Text(size.title).tag(size)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .fixedSize()
            .disabled(!plan.alsoMakes.makesArtwork)
            .help(Text(ScreenshotStudioModel.artworkSizeNote))
            .accessibilityIdentifier("autopilot.plan.artworkSize")
            .gridCellColumns(devices.count)
        } languages: {
            Text(plan.alsoMakes.makesArtwork ? studio.runLanguagesTitle(plan) : "—").font(.callout)
        }
    }

    private func cell(
        isOn: Bool, isEnabled: Bool, label: String, identifier: String, set: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(label, isOn: Binding { isOn } set: { set($0) })
            .labelsHidden()
            .toggleStyle(.checkbox)
            .disabled(!isEnabled)
            .frame(width: Self.deviceWidth)
            .accessibilityLabel(Text(label))
            .accessibilityIdentifier(identifier)
    }

    /// "English (U.S.) only", "Run languages (15)".
    private func previewLanguagesTitle(_ languages: AutopilotPreviewLanguages) -> String {
        switch languages {
        case .primary:
            let name = StoreLocaleCatalog.locale(code: plan.primaryLocale)?.name ?? plan.primaryLocale
            return String(localized: "\(name) only")
        case .all:
            return String(localized: "Run languages (\(plan.localeCodes.count))")
        }
    }

    // MARK: - Languages and captures

    private var languages: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(spacing: Spacing.small) {
                Text("Languages").font(.callout.weight(.medium)).frame(width: 76, alignment: .leading)
                StudioSegmentedControl(
                    label: String(localized: "Languages in this run"),
                    options: AutopilotLanguageMode.allCases.map { .init(value: $0, title: studio.languageModeTitle($0, plan: plan), key: $0.rawValue) },
                    selection: Binding { plan.runChoice.languages } set: { studio.setLanguageMode($0) },
                    identifier: "autopilot.plan.languages"
                )
                if plan.runChoice.languages == .all, let include = studio.includeNewLanguagesTitle(plan) {
                    Toggle(include, isOn: Binding { plan.includesNewLanguages } set: { studio.setIncludesNewLanguages($0) })
                        .toggleStyle(.checkbox)
                        .font(.callout)
                        .help(Text(studio.newLanguagesDetail))
                        .accessibilityIdentifier("autopilot.plan.newLanguages")
                }
            }
            if plan.runChoice.languages == .chosen {
                AutopilotLanguageChips(studio: studio, plan: plan)
                    .padding(.leading, 76 + Spacing.small)
            }
        }
    }

    private var captures: some View {
        let matters = studio.capturesMatter(plan)
        let canReuse = studio.reuseTitle != nil && studio.run?.startedAt == nil
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text("Captures").font(.callout.weight(.medium)).frame(width: 76, alignment: .leading)
            StudioSegmentedControl(
                label: String(localized: "Captures"),
                options: [
                    .init(value: false, title: String(localized: "Capture in Simulator"), key: "simulator"),
                    .init(value: true, title: studio.reuseTitle ?? String(localized: "Reuse earlier captures"), isEnabled: canReuse, key: "reuse"),
                ],
                selection: Binding { plan.reusesCaptures && canReuse } set: { studio.setReusesCaptures($0) },
                identifier: "autopilot.plan.captureSource"
            )
            .fixedSize()
            .disabled(!matters || studio.run?.startedAt != nil)
            .opacity(matters ? 1 : 0.5)
            Text(studio.capturesNote(plan, client: client))
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("autopilot.plan.captureNote")
        }
    }

    /// Every App Preview has music: a library track or the person's own
    /// file (Your File… chooses one, again when it's already chosen).
    private var music: some View {
        let current = plan.alsoMakes.previewMusic
        let options: [StudioSegmentedControl<AppPreviewTrack>.Option] = AppPreviewTrack.allCases.map { track in
            let title = track == .ownFile
                ? (current.track == .ownFile ? current.title : String(localized: "Your File…"))
                : track.title
            return .init(value: track, title: title, key: track.rawValue)
        }
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text("Music").font(.callout.weight(.medium)).frame(width: 76, alignment: .leading)
            StudioSegmentedControl(
                label: String(localized: "App Preview music"), options: options,
                selection: Binding { current.track } set: { studio.pickMusic($0) },
                identifier: "autopilot.plan.music"
            )
            .fixedSize()
            .disabled(studio.run?.startedAt != nil)
            Text(Self.musicNote)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("autopilot.plan.musicNote")
        }
    }

    static var musicNote: AttributedString {
        var required = AttributedString(localized: "Required")
        required.font = .caption.weight(.semibold)
        let rest = AttributedString(localized: """
         for every App Preview. Tracks from AppLocalizer’s library are licensed for the App Store; with your own file, \
        you confirm you hold the rights. Mixed under the captions, faded out at the end.
        """)
        return required + rest
    }

    private func extrasBinding<Value>(_ keyPath: WritableKeyPath<AutopilotExtras, Value>) -> Binding<Value> {
        Binding {
            plan.alsoMakes[keyPath: keyPath]
        } set: { value in
            studio.updatePlan { $0.alsoMakes[keyPath: keyPath] = value }
        }
    }
}
