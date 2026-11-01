//
//  ScreenshotPushRun+Images.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotPushRun {
    /// One image: keep a copy of the live one, make the PNG, reserve,
    /// upload the parts, commit and check. A failure deletes the
    /// reservation and leaves the live screenshot alone.
    func sendImage(_ index: Int) async {
        let groupID = items[index].groupID
        let replaces = showsLive(index)
        do {
            try await keepCopy(index)
            let data: Data
            do {
                data = try await environment.imageData(items[index].plan)
            } catch {
                throw ScreenshotPushFailure.image
            }
            try await makeRoom(index)
            items[index].status = .reserving
            let setID = sets[groupID]?.setID ?? ""
            let reserved = try await send(ScreenshotUploadRequests.reserve(fileName: items[index].plan.fileName, fileSize: data.count, setID: setID))
            let (id, operations) = try ScreenshotUploadRequests.reservation(in: reserved.data)
            items[index].screenshotID = id
            sets[groupID]?.order.append(id)
            try await uploadParts(index, operations: operations, data: data)
            items[index].status = .committing
            let checksum = ScreenshotPNG.checksum(data)
            _ = try await send(ScreenshotUploadRequests.commit(screenshotID: id, checksum: checksum))
            let state = try await fetch(ScreenshotUploadRequests.statusPath(screenshotID: id))
            if let delivery = ScreenshotUploadRequests.deliveryState(in: state.data), delivery.isFailed {
                throw ScreenshotPushFailure.processing(code: delivery.errorCode ?? delivery.state)
            }
            items[index].checksum = checksum
            items[index].isCommitted = true
            items[index].status = .done
        } catch {
            await dropReservation(index)
            items[index].status = status(for: error, replaces: replaces)
        }
    }

    /// Whether something live shows in the image's place while it fails:
    /// the screenshot it replaces, or for a new set the primary locale's.
    func showsLive(_ index: Int) -> Bool {
        items[index].plan.old != nil || sets[items[index].groupID]?.group.liveSet == nil
    }

    /// Downloads the live screenshot this image replaces and keeps it in
    /// the push's backup, once. One with no image in App Store Connect has
    /// nothing to keep, so it's replaced without a copy; one still
    /// processing isn't replaced yet.
    private func keepCopy(_ index: Int) async throws {
        let item = items[index]
        guard let old = item.plan.old, item.backup == nil, let group = sets[item.groupID]?.group else { return }
        items[index].status = .keepingCopy
        let data: Data
        do {
            data = try await environment.liveData(old)
        } catch LiveScreenshotImageError.noImage {
            items[index].note = String(
                localized: """
                The live screenshot had no image in App Store Connect (its upload never finished or Apple couldn’t \
                process it), so there was nothing to keep.
                """
            )
            return
        } catch LiveScreenshotImageError.stillProcessing {
            throw ScreenshotPushFailure.liveStillProcessing
        } catch {
            throw ScreenshotPushFailure.keepingCopy(detail: Self.describe(error))
        }
        let image = ScreenshotBackupImage(
            backupID: backupID, locale: group.locale.code, displayType: group.displayType, position: item.plan.cell.slot,
            liveID: old.id, fileName: old.fileName, checksum: old.checksum, pixelSize: old.pixelSize, origin: item.plan.oldOrigin
        )
        do {
            try environment.backups.keep(data, as: image, appID: item.appID, date: date)
        } catch {
            throw ScreenshotPushFailure.keepingCopy(detail: Self.describe(error))
        }
        items[index].backup = image
    }

    /// A full set takes no new screenshot: this image's old one goes first
    /// (it's kept already), or the image fails.
    private func makeRoom(_ index: Int) async throws {
        let groupID = items[index].groupID
        guard let order = sets[groupID]?.order, order.count >= Self.setCapacity else { return }
        guard let old = items[index].plan.old, order.contains(old.id) else { throw ScreenshotPushFailure.setFull }
        _ = try await send(ScreenshotUploadRequests.delete(screenshotID: old.id))
        sets[groupID]?.order.removeAll { $0 == old.id }
        items[index].isOldDeleted = true
    }

    private func uploadParts(_ index: Int, operations: [ScreenshotUploadOperation], data: Data) async throws {
        items[index].status = .uploading(0)
        for (offset, operation) in operations.enumerated() {
            do {
                try await environment.transport.upload(operation, data: data)
            } catch {
                let timedOut = (error as? URLError)?.code == .timedOut
                throw ScreenshotPushFailure.part(offset + 1, count: operations.count, timedOut: timedOut, detail: Self.describe(error))
            }
            let sent = operation.offset + operation.length
            items[index].status = .uploading(data.isEmpty ? Double(offset + 1) / Double(operations.count) : min(1, Double(sent) / Double(data.count)))
        }
    }

    /// Deletes a reservation that won't be committed, so the set doesn't
    /// keep an empty screenshot.
    private func dropReservation(_ index: Int) async {
        guard let id = items[index].screenshotID, !items[index].isCommitted else { return }
        let groupID = items[index].groupID
        if await (try? send(ScreenshotUploadRequests.delete(screenshotID: id))) != nil {
            sets[groupID]?.order.removeAll { $0 == id }
        }
        items[index].screenshotID = nil
    }
}
