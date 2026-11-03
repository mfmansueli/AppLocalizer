//
//  AutopilotCenter+Extras.swift
//  AppLocalizer
//

import Foundation

/// Localize and check's extras: once every caption fits, the header and
/// search artwork are rendered in each language and the App Previews cut
/// from the recordings, each checked, then saved with the set for Review &
/// Push. A failure is said in the log and the row; the screenshots are
/// ready either way.
extension AutopilotCenter {
    /// What was saved with the set; nil when the run makes no extras or
    /// they couldn't be saved.
    @discardableResult
    func makeExtras(_ appID: StoreApp.ID, context: AutopilotContext) async -> ScreenshotExtras? {
        guard let run = runs[appID], !run.plan.alsoMakes.isEmpty, let direction = run.chosenDirection else { return nil }
        let plan = run.plan
        var progress = AutopilotExtrasProgress()
        progress.artworkTotal = plan.artworkKinds.isEmpty ? 0 : plan.localeCodes.count
        progress.previewsTotal = plan.previewDisplays.count * plan.previewLocales.count
        update(appID) { $0.extrasProgress = progress }
        let services = context.services
        guard var document = try? await services.loadDocument(for: context.app, primaryLocale: context.primaryLocale) else { return nil }
        var extras = ScreenshotExtras(
            directionName: direction.name, madeAt: now(), artworkSize: plan.artworkKinds.isEmpty ? nil : plan.alsoMakes.artworkSize,
            artworkTemplate: plan.artworkKinds.isEmpty ? nil : direction.artworkLook, searchSlot: plan.searchSlot,
            previewLanguages: plan.previewDisplays.isEmpty ? nil : plan.alsoMakes.previewLanguages,
            previewTemplate: plan.previewDisplays.isEmpty ? nil : direction.previewLook,
            pushedChecksums: document.extras?.pushedChecksums
        )
        // What was discarded stays out while it's the same file.
        extras.discardedChecksums = document.extras?.discardedChecksums
        if !plan.artworkKinds.isEmpty {
            extras.artworkShows = plan.alsoMakes.artworkShows
            extras.artworkMotion = plan.alsoMakes.makesMotion ? .loop : .still
        }
        if !plan.artworkKinds.isEmpty {
            do {
                extras.artwork = try await AutopilotArtworkMaker(context: context).make(
                    for: run, look: direction.artworkLook, texts: document.artworkTexts ?? ArtworkTextBook()
                ) { done in
                    update(appID) { $0.extrasProgress?.artworkDone = done }
                }
                let tooLong = extras.tooLongLocales
                let checks = Self.checks(of: extras.artwork)
                update(appID) { run in
                    run.extrasProgress?.artworkTooLong = tooLong
                    run.extrasProgress?.artworkChecks = checks
                    run.appendLog(Self.artworkLogLine(plan: plan, tooLong: tooLong), kind: .event, at: now())
                    if let line = Self.checksLogLine(checks) { run.appendLog(line, kind: checks.contains(where: \.isError) ? .problem : .event, at: now()) }
                }
            } catch {
                update(appID) { run in
                    let total = run.extrasProgress?.artworkTotal ?? 0
                    run.extrasProgress?.artworkDone = total
                    run.appendLog(String(localized: "Couldn’t make the header and search artwork: \(error.localizedDescription)"), kind: .problem, at: now())
                }
            }
        } else if let made = document.extras {
            // The artwork made before and not in this run stays.
            extras.artwork = made.artwork
            extras.artworkSize = made.artworkSize
            extras.artworkTemplate = made.artworkTemplate
            extras.artworkShows = made.artworkShows
            extras.artworkMotion = made.artworkMotion
        }
        if !plan.previewDisplays.isEmpty {
            extras.previews = await makePreviews(appID, run: run, direction: direction, captions: document.captions, context: context)
            extras.previewMusic = plan.alsoMakes.previewMusic
        } else if let made = document.extras {
            // The App Previews made before and not in this run stay.
            extras.previews = made.previews
            extras.previewLanguages = made.previewLanguages
            extras.previewTemplate = made.previewTemplate
            extras.previewMusic = made.previewMusic
        }
        document.extras = extras
        var saved: ScreenshotExtras? = extras
        do {
            try await services.saveDocument(document, for: context.app)
        } catch {
            saved = nil
            update(appID) { $0.appendLog(String(localized: "Couldn’t save the extras: \(error.localizedDescription)"), kind: .problem, at: now()) }
        }
        update(appID) { $0.extrasProgress?.isFinished = true }
        return saved
    }

    /// Every file's findings, errors first.
    static func checks(of files: [ExtrasArtworkFile]) -> [ArtworkCheck] {
        let all = files.flatMap { $0.checks ?? [] }
        return all.filter(\.isError) + all.filter { !$0.isError }
    }

    /// "Artwork checks: 1 error keeps it out of the push (German header:
    /// ‘−50%’ — …) · 2 warnings", or nil when nothing was found.
    static func checksLogLine(_ checks: [ArtworkCheck]) -> String? {
        guard !checks.isEmpty else { return nil }
        let errors = checks.filter(\.isError)
        let warnings = checks.count - errors.count
        let warningText = warnings == 1 ? String(localized: "1 warning") : String(localized: "\(warnings) warnings")
        guard let first = errors.first else { return String(localized: "Artwork checks: \(warningText), nothing that blocks the push") }
        let errorText = errors.count == 1
            ? String(localized: "1 error keeps that image out of the push")
            : String(localized: "\(errors.count) errors keep those images out of the push")
        let parts = ["\(errorText) (\(first.text))"] + (warnings > 0 ? [warningText] : [])
        return String(localized: "Artwork checks: \(parts.joined(separator: " · "))")
    }

    /// "Header and search rendered in 15 languages · headline fits in all".
    static func artworkLogLine(plan: AutopilotPlan, tooLong: [String]) -> String {
        let what = plan.alsoMakes.artworkSize == .wide ? String(localized: "Header and search image") : String(localized: "Header and search artwork")
        let count = plan.localeCodes.count
        guard !tooLong.isEmpty else {
            return String(localized: "\(what) rendered in \(count) languages · headline fits in all")
        }
        return String(localized: "\(what) rendered in \(count) languages · headline too long in \(tooLong.formatted(.list(type: .and)))")
    }
}
