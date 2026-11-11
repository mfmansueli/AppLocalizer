//
//  ScreenshotPushPlanner.swift
//  AppLocalizer
//

import Foundation

/// Derives what a screenshot push would send: every localized render whose
/// key differs from what's live (unless it was discarded at that key), the
/// renders that fail a check, and restores queued for pinned locales. Pure
/// and thread-safe; the controller runs it off the main actor.
struct ScreenshotPushPlanner {
    func plan(_ input: ScreenshotPlanInput) -> ScreenshotPushPlan {
        let snapshot = input.snapshot
        let matrix = ScreenshotMatrixBuilder().build(snapshot)
        var plan = ScreenshotPushPlan.empty(
            appID: input.appID, appName: input.appName, version: input.context.version, primaryLocaleName: input.context.primaryLocale.name
        )
        // Blocked only when no device's screenshots can go: Mac's follow the
        // macOS version.
        let displays = Set(matrix.localizedCells.map(\.key.displayType))
        if !input.context.version.isEditable, displays.allSatisfy({ input.context.editBlock(for: $0) != nil }) {
            let version = input.context.version.versionString
            plan.blockedReason = String(localized: "Version \(version) is live. Screenshots can only change with a version that’s being prepared.")
        }
        var groups: [String: ScreenshotPlanGroup] = [:]
        for cell in matrix.localizedCells {
            guard let locale = snapshot.locale(code: cell.key.locale) else { continue }
            if case let .failed(reason) = cell.state {
                plan.excluded.append(ScreenshotPlanExclusion(appID: input.appID, cell: cell.key, localeName: locale.name, failedCheck: reason))
                continue
            }
            guard cell.state == .notPushed, let job = cell.image.renderJob else { continue }
            let item = ScreenshotPlanItem(
                appID: input.appID, cell: cell.key, slotName: input.document.slotName(cell.key.slot, on: cell.key.displayType),
                content: .render(job), old: cell.live,
                oldOrigin: origin(of: cell.live, cell: cell.key, document: input.document), source: source(of: cell.caption)
            )
            if input.state.kept[cell.key] == job.key {
                plan.kept.append(item)
            } else if input.context.localizationID(for: locale, displayType: cell.key.displayType) == nil {
                plan.excluded.append(ScreenshotPlanExclusion(appID: input.appID, cell: cell.key, localeName: locale.name, failedCheck: nil))
            } else {
                add(item, locale: locale, to: &groups, input: input)
            }
        }
        for request in input.state.restores where input.document.scope.isPinned(request.locale) {
            guard let locale = snapshot.locale(code: request.locale) else { continue }
            addRestore(request, locale: locale, to: &groups, kept: &plan.kept, input: input)
        }
        if plan.blockedReason == nil { exclude(fromBlockedVersions: &groups, plan: &plan, input: input) }
        plan.groups = groups.values.sorted { order($0, primary: input.context.primaryLocale.code) < order($1, primary: input.context.primaryLocale.code) }
        return plan
    }

    /// A device whose version can't change while another's can: its images
    /// wait, saying why, and the rest go.
    private func exclude(fromBlockedVersions groups: inout [String: ScreenshotPlanGroup], plan: inout ScreenshotPushPlan, input: ScreenshotPlanInput) {
        for (id, group) in groups {
            guard let reason = input.context.editBlock(for: group.displayType) else { continue }
            plan.excluded += group.items.map {
                ScreenshotPlanExclusion(appID: input.appID, cell: $0.cell, localeName: group.locale.name, failedCheck: reason)
            }
            groups[id] = nil
        }
    }

    private func add(_ item: ScreenshotPlanItem, locale: StoreLocale, to groups: inout [String: ScreenshotPlanGroup], input: ScreenshotPlanInput) {
        let display = item.cell.displayType
        let id = "\(input.appID)|\(locale.code)|\(display.rawValue)"
        groups[id, default: ScreenshotPlanGroup(
            appID: input.appID, locale: locale, displayType: display, localizationID: input.context.localizationID(for: locale, displayType: display),
            liveSet: input.live.set(locale: locale.code, displayType: display),
            emptySetID: input.live.emptySet(locale: locale.code, displayType: display)?.id, items: [],
            previews: input.live.previews(locale: locale.code, displayType: display)
        )].items.append(item)
    }

    /// A restore's images, slot by slot, unless the slot already shows the
    /// kept file; screenshots past the kept set's end are removed.
    private func addRestore(
        _ request: ScreenshotRestoreRequest,
        locale: StoreLocale,
        to groups: inout [String: ScreenshotPlanGroup],
        kept: inout [ScreenshotPlanItem],
        input: ScreenshotPlanInput
    ) {
        for display in ScreenshotDisplayType.studio {
            let images = request.images.filter { $0.displayType == display }.sorted { $0.position < $1.position }
            guard !images.isEmpty, let localizationID = input.context.localizationID(for: locale, displayType: display) else { continue }
            let liveSet = input.live.set(locale: locale.code, displayType: display)
            var items: [ScreenshotPlanItem] = []
            for image in images {
                let old = liveSet?.screenshot(slot: image.position)
                if let checksum = image.checksum, old?.checksum == checksum { continue }
                let item = ScreenshotPlanItem(
                    appID: input.appID, cell: image.cell, slotName: input.document.slotName(image.position, on: display),
                    content: .restore(image), old: old,
                    oldOrigin: origin(of: old, cell: image.cell, document: input.document), source: .restore
                )
                if input.state.keptRestores.contains(image.id) {
                    kept.append(item)
                } else {
                    items.append(item)
                }
            }
            let extra = items.isEmpty ? [] : Array((liveSet?.screenshots ?? []).dropFirst(images.count))
            guard !items.isEmpty else { continue }
            let group = ScreenshotPlanGroup(
                appID: input.appID, locale: locale, displayType: display, localizationID: localizationID,
                liveSet: liveSet, emptySetID: input.live.emptySet(locale: locale.code, displayType: display)?.id,
                items: items, extraLive: extra, restoredFrom: request.backupDate,
                previews: input.live.previews(locale: locale.code, displayType: display)
            )
            groups[group.id] = group
        }
    }

    /// Who made the image's change: an assistant whose caption proposal was
    /// accepted, machine translation, or you.
    private func source(of caption: ScreenshotCaption?) -> ChangeSource {
        guard let caption else { return .you }
        if let assistant = caption.provenance.assistant { return assistant }
        return caption.provenance.isMachineTranslated ? .machineTranslation : .you
    }

    /// A live screenshot AppLocalizer pushed is "from the template".
    private func origin(of live: LiveScreenshot?, cell: ScreenshotCellKey, document: ScreenshotsDocument) -> ScreenshotBackupOrigin {
        guard let live, let pushed = document.pushedRender(for: cell), pushed.checksum == live.checksum else { return .uploadedByHand }
        return .template
    }

    /// iPhone, iPad, Apple Watch, then Apple Vision Pro; the primary locale
    /// first, then by name.
    private func order(_ group: ScreenshotPlanGroup, primary: String) -> String {
        let display = ScreenshotDisplayType.studio.firstIndex(of: group.displayType) ?? 9
        return "\(display)|\(group.locale.code == primary ? 0 : 1)|\(group.locale.name)"
    }
}
