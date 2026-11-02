//
//  ScreenshotPushRun+Sets.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotPushRun {
    /// Runs every set with queued images, `concurrentSets` at a time.
    func sendQueuedSets() async {
        let groupIDs = groupOrder.filter { id in items.contains { $0.groupID == id && $0.status == .queued } }
        await withTaskGroup(of: Void.self) { group in
            var pending = groupIDs.makeIterator()
            for _ in 0..<max(1, environment.concurrentSets) {
                guard let id = pending.next() else { break }
                group.addTask { await self.sendSet(id) }
            }
            while await group.next() != nil {
                if let id = pending.next() { group.addTask { await self.sendSet(id) } }
            }
        }
    }

    /// One set: create it if needed, send its images one by one, then
    /// delete what they replaced and put it in order.
    func sendSet(_ groupID: String) async {
        let indices = items.indices.filter { items[$0].groupID == groupID && items[$0].status == .queued }
        guard !indices.isEmpty else { return }
        if sets[groupID]?.setID == nil {
            if let halt = haltStatus {
                for index in indices { items[index].status = halt }
                return
            }
            do {
                try await createSet(groupID)
            } catch {
                for index in indices { items[index].status = status(for: error, replaces: showsLive(index)) }
                return
            }
        }
        for index in indices {
            if let halt = haltStatus {
                items[index].status = halt
                continue
            }
            await sendImage(index)
        }
        await finishSet(groupID)
    }

    private func createSet(_ groupID: String) async throws {
        guard let group = sets[groupID]?.group else { return }
        guard let localizationID = group.localizationID else {
            throw ScreenshotPushFailure.request(detail: String(localized: "\(group.locale.name) isn’t on this version in App Store Connect yet."))
        }
        do {
            let response = try await send(ScreenshotUploadRequests.createSet(displayType: group.displayType, localizationID: localizationID))
            sets[groupID]?.setID = try ScreenshotUploadRequests.createdID(in: response.data)
        } catch let error as AppStoreConnectError where error.isStateError {
            try await useExistingSet(groupID, group: group, localizationID: localizationID, refusal: error)
        }
    }

    /// App Store Connect refused a new set because the locale has one
    /// already, made since the push was planned or left empty by an
    /// upload that never finished: an empty one is filled; one with
    /// screenshots the push hasn't seen is left alone.
    private func useExistingSet(_ groupID: String, group: ScreenshotPlanGroup, localizationID: String, refusal: AppStoreConnectError) async throws {
        let response = try await fetch(ScreenshotUploadRequests.setsPath(localizationID: localizationID, displayType: group.displayType))
        guard let existing = try ScreenshotUploadRequests.existingSet(in: response.data, displayType: group.displayType) else { throw refusal }
        guard existing.screenshotCount == 0 else {
            throw ScreenshotPushFailure.request(detail: String(localized: """
            App Store Connect already has \(group.displayType.title) screenshots for \(group.locale.name) that this push hasn’t seen. \
            Refresh, review them and push again.
            """))
        }
        sets[groupID]?.setID = existing.id
    }

    /// After a set's images: delete the screenshots the committed ones
    /// replace (and, for a restore, any past its end), then reorder.
    func finishSet(_ groupID: String) async {
        let committed = items.indices.filter { items[$0].groupID == groupID && items[$0].isCommitted }
        guard !committed.isEmpty, let group = sets[groupID]?.group else { return }
        for index in committed where !items[index].isOldDeleted {
            guard let old = items[index].plan.old, sets[groupID]?.order.contains(old.id) == true else { continue }
            do {
                _ = try await send(ScreenshotUploadRequests.delete(screenshotID: old.id))
                sets[groupID]?.order.removeAll { $0 == old.id }
                items[index].isOldDeleted = true
            } catch {
                items[index].note = String(localized: "The old screenshot couldn’t be deleted, so the set shows both for now.")
            }
        }
        for extra in group.extraLive where sets[groupID]?.order.contains(extra.id) == true {
            do {
                try await keepExtra(extra, position: group.liveSet?.screenshots.firstIndex(of: extra) ?? 0, groupID: groupID)
                _ = try await send(ScreenshotUploadRequests.delete(screenshotID: extra.id))
                sets[groupID]?.order.removeAll { $0 == extra.id }
            } catch {
                sets[groupID]?.note = String(localized: "A screenshot past the end of the restored set couldn’t be removed.")
            }
        }
        await reorder(groupID)
    }

    /// Puts the set in slot order, when it isn't already.
    private func reorder(_ groupID: String) async {
        guard let progress = sets[groupID], let setID = progress.setID else { return }
        var committed: [Int: String] = [:]
        for item in items where item.groupID == groupID && item.isCommitted {
            if let id = item.screenshotID { committed[item.plan.cell.slot] = id }
        }
        let desired = progress.desiredOrder(committed: committed)
        guard desired != progress.order else { return }
        do {
            _ = try await send(ScreenshotUploadRequests.reorder(setID: setID, screenshotIDs: desired))
            sets[groupID]?.order = desired
        } catch {
            sets[groupID]?.note = String(localized: "The set couldn’t be put in order: \(Self.describe(error))")
        }
    }

    /// Keeps a screenshot a restore removes past the end of its set; one
    /// with no image in App Store Connect has nothing to keep.
    private func keepExtra(_ screenshot: LiveScreenshot, position: Int, groupID: String) async throws {
        guard let group = sets[groupID]?.group else { return }
        let data: Data
        do {
            data = try await environment.liveData(screenshot)
        } catch LiveScreenshotImageError.noImage {
            return
        }
        let image = ScreenshotBackupImage(
            backupID: backupID, locale: group.locale.code, displayType: group.displayType, position: position, liveID: screenshot.id,
            fileName: screenshot.fileName, checksum: screenshot.checksum, pixelSize: screenshot.pixelSize, origin: .uploadedByHand
        )
        try environment.backups.keep(data, as: image, appID: group.appID, date: date)
    }
}
