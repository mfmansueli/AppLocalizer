//
//  AutopilotReadyStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Ready for review: what was made, the five new screenshots, and what to
/// check — shortened captions, languages that are new, the template
/// version it saved.
struct AutopilotReadyStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    @State private var contentWidth: CGFloat = 900

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Ready for review").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                Text(summary)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("autopilot.ready.summary")
                if let direction = run.chosenDirection {
                    AutopilotDirectionThumbnails(studio: studio, direction: direction, width: 98, stacksDevices: stacksDevices)
                }
                VStack(spacing: 0) {
                    ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                        if index > 0 { Divider() }
                        note
                    }
                }
                .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
            }
            .padding(Spacing.xLarge)
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { contentWidth = $0 - Spacing.xLarge * 2 })
        .accessibilityIdentifier("autopilot.ready")
    }

    private var stacksDevices: Bool {
        AutopilotDirectionThumbnails.oneRowWidth(
            thumbnail: 98, screens: run.plan.screens.count,
            hasVision: run.plan.displayTypes.contains(.visionPro) && !run.plan.screens(on: .visionPro).isEmpty,
            hasWatch: run.plan.displayTypes.contains(.watch) && !run.plan.screens(on: .watch).isEmpty
        ) > contentWidth
    }

    private var summary: String {
        let languages = run.plan.localeCodes.count == 1 ? String(localized: "1 language") : String(localized: "\(run.plan.localeCodes.count) languages")
        let name = run.chosenDirection?.name ?? String(localized: "the new template")
        return String(localized: "\(run.totalScreenshots) screenshots for \(run.plan.devicesTitle) in \(languages), in \(name). They’re in Review & Push; nothing is uploaded yet.")
    }

    private var notes: [AutopilotReadyNote] {
        var notes: [AutopilotReadyNote] = []
        let toCheck = run.capturesToCheck
        if let first = toCheck.first {
            let more = toCheck.count - 1
            let firstNote = "\(AutopilotCapturesToCheck.place(of: first, in: run)): \(first.issues[0].message)"
            notes.append(AutopilotReadyNote(
                title: AutopilotCapturesToCheck.title(count: toCheck.count),
                detail: more == 0 ? firstNote : String(localized: "\(firstNote) And \(more) more."),
                button: String(localized: "Open Captures"),
                identifier: "autopilot.ready.toCheck"
            ) {
                studio.isAutopilotPresented = false
                studio.screenshots.tab = .captures
            })
        }
        notes += run.shortenings.map { item in
            let language = StoreLocaleCatalog.locale(code: item.locale)?.shortName ?? item.locale
            return AutopilotReadyNote(
                title: String(localized: "\(language) slot \(item.slot + 1) was shortened"),
                detail: String(localized: "“\(item.before)” → “\(item.after)”. \(item.client)’s change; check that it reads well."),
                button: String(localized: "Open Caption"),
                identifier: "autopilot.ready.caption.\(item.locale).\(item.slot)"
            ) {
                studio.isAutopilotPresented = false
                studio.screenshots.tab = .captions
            }
        }
        let live = studio.screenshots.live
        let primary = studio.primaryLocale
        let added = run.plan.addedLocaleCodes
        for code in run.plan.localeCodes where code != primary.code && !live.hasOwnSet(locale: code) && !added.contains(code) {
            let language = StoreLocaleCatalog.locale(code: code)?.shortName ?? code
            notes.append(AutopilotReadyNote(
                title: String(localized: "\(language) is new"),
                detail: String(localized: "Live today, \(language) falls back to \(primary.shortName). This set adds \(language) screenshots."),
                identifier: "autopilot.ready.new.\(code)"
            ))
        }
        if !added.isEmpty {
            let names = added.map { StoreLocaleCatalog.locale(code: $0)?.shortName ?? $0 }.formatted(.list(type: .and))
            notes.append(AutopilotReadyNote(
                title: added.count == 1
                    ? String(localized: "\(names) is new on the App Store")
                    : String(localized: "\(added.count) languages are new on the App Store"),
                detail: added.count == 1
                    ? String(localized: "Its App Store page is created when you push, and its screenshots go up with it.")
                    : String(localized: "\(names) get their App Store pages when you push; their screenshots go up with them."),
                identifier: "autopilot.ready.newLanguages"
            ))
        }
        if let version = run.templateVersion {
            notes.append(AutopilotReadyNote(
                title: String(localized: "Saved as template v\(version)"),
                detail: String(localized: "Edit it in the template editor and the set re-renders. Earlier versions stay in History."),
                button: String(localized: "Template Editor"),
                identifier: "autopilot.ready.template"
            ) {
                studio.isAutopilotPresented = false
                studio.screenshots.tab = .template
            })
        }
        return notes
    }
}
