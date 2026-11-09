//
//  DebugScreenshotUploadTransport.swift
//  AppLocalizer
//

#if DEBUG
import Foundation
import Synchronization

/// Simulates App Store Connect's screenshot endpoints for DEBUG scenes: sets
/// are created, screenshots reserved in three parts, committed, checked,
/// deleted and reordered in a `DebugScreenshotLedger`, so what a push did
/// shows up as live afterwards. `script` slows it down, holds images at a
/// step and fails some once. Never contacts App Store Connect.
final class DebugScreenshotUploadTransport: ScreenshotUploadTransport {
    private struct State {
        var ledger: DebugScreenshotLedger
        var used: Int
        /// Scripted failures already spent.
        var spent: Set<String> = []
    }

    private let script: DebugScreenshotUploadScript
    private let state: Mutex<State>

    init(live: LiveScreenshots, script: DebugScreenshotUploadScript = DebugScreenshotUploadScript()) {
        self.script = script
        state = Mutex(State(ledger: DebugScreenshotLedger(live: live), used: script.usedThisHour))
    }

    /// What's live now, after the pushes so far.
    func live(previews: [LiveAppPreviewSet]) -> LiveScreenshots {
        state.withLock { $0.ledger.live(previews: previews) }
    }

    /// A screenshot's uploaded file, for its thumbnail.
    func data(forScreenshot id: String) -> Data? {
        state.withLock { $0.ledger.shots[id]?.data }.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// Which locale each localization ID stands for.
    func register(localizations: [StoreLocale: String]) {
        state.withLock { state in
            for (locale, id) in localizations {
                state.ledger.localizations[id] = locale.code
            }
        }
    }

    func send(_ request: PushRequest) async throws -> AppStoreConnectResponse {
        try await Task.sleep(for: script.delay)
        let body = request.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        let data = body?["data"] as? [String: Any]
        let path = request.path
        switch request.method {
        case .post where path == "/v1/appScreenshotSets":
            return response(id: createSet(data))
        case .post where path == "/v1/appScreenshots":
            return try await reserve(data)
        case .patch where path.hasSuffix("/relationships/appScreenshots"):
            reorder(setID: path.components(separatedBy: "/")[3], ids: (body?["data"] as? [[String: Any]])?.compactMap { $0["id"] as? String } ?? [])
            return response(id: nil)
        case .patch:
            return try await commit(id: path.components(separatedBy: "/").last ?? "", data: data)
        case .delete:
            delete(id: path.components(separatedBy: "/").last ?? "")
            return response(id: nil)
        default:
            throw AppStoreConnectError.notFound(detail: path)
        }
    }

    func fetch(_ path: String) async throws -> AppStoreConnectResponse {
        try await Task.sleep(for: script.delay)
        let id = path.components(separatedBy: "/").last?.components(separatedBy: "?").first ?? ""
        let fileName = state.withLock { $0.ledger.shots[id]?.fileName } ?? ""
        let failure = DebugScreenshotUploadScript.matching(fileName, in: script.processingFailures).flatMap { spend("process|\($0)") ? $0 : nil }
        let delivery: [String: Any] = failure == nil
            ? ["state": "COMPLETE"]
            : ["state": "FAILED", "errors": [["code": "IMAGE_TOOL_FAILURE", "description": "The image couldn’t be processed."]]]
        return response(id: id, attributes: ["assetDeliveryState": delivery])
    }

    /// Each part goes out in quarters, so the percentage moves as it does
    /// with App Store Connect.
    func upload(_ operation: ScreenshotUploadOperation, data: Data, progress: @escaping @Sendable (Int64) -> Void) async throws {
        let parts = operation.url.components(separatedBy: "/")
        let id = parts.dropLast().last ?? ""
        let part = Int(parts.last ?? "") ?? 1
        let fileName = state.withLock { $0.ledger.shots[id]?.fileName } ?? ""
        if case let .upload(afterParts)? = DebugScreenshotUploadScript.matching(fileName, in: script.holds.keys).flatMap({ script.holds[$0] }),
           part > afterParts
        {
            try await Task.sleep(for: .seconds(3600))
        }
        if part == 2, let name = DebugScreenshotUploadScript.matching(fileName, in: script.timeouts), spend("timeout|\(name)") {
            try await Task.sleep(for: script.delay)
            throw URLError(.timedOut)
        }
        for quarter in 1...4 {
            try await Task.sleep(for: script.delay / 4)
            progress(Int64(operation.length * quarter / 4))
        }
        state.withLock { $0.ledger.shots[id]?.data.append(operation.slice(of: data)) }
    }

    // MARK: - Steps

    private func createSet(_ data: [String: Any]?) -> String {
        let display = ((data?["attributes"] as? [String: Any])?["screenshotDisplayType"] as? String).flatMap(ScreenshotDisplayType.init(apiValue:))
        let relationships = data?["relationships"] as? [String: Any]
        let localization = ((relationships?["appStoreVersionLocalization"] as? [String: Any])?["data"] as? [String: Any])?["id"] as? String ?? ""
        return state.withLock { state in
            let id = state.ledger.makeID("set")
            let locale = state.ledger.localizations[localization] ?? localization.replacingOccurrences(of: "debug-loc-", with: "")
            state.ledger.sets[id] = DebugScreenshotLedger.LedgerSet(locale: locale, displayType: display ?? .iPhone, order: [])
            return id
        }
    }

    private func reserve(_ data: [String: Any]?) async throws -> AppStoreConnectResponse {
        let attributes = data?["attributes"] as? [String: Any]
        let fileName = attributes?["fileName"] as? String ?? ""
        let size = attributes?["fileSize"] as? Int ?? 0
        if case .reserve? = DebugScreenshotUploadScript.matching(fileName, in: script.holds.keys).flatMap({ script.holds[$0] }) {
            try await Task.sleep(for: .seconds(3600))
        }
        let relationships = data?["relationships"] as? [String: Any]
        let setID = ((relationships?["appScreenshotSet"] as? [String: Any])?["data"] as? [String: Any])?["id"] as? String ?? ""
        let id = state.withLock { state in
            let id = state.ledger.makeID("shot")
            state.ledger.shots[id] = DebugScreenshotLedger.LedgerShot(fileName: fileName, checksum: nil, isCommitted: false)
            state.ledger.sets[setID]?.order.append(id)
            return id
        }
        // Three parts, split at 36 % and 64 %.
        let cuts = [0, size * 36 / 100, size * 64 / 100, size]
        let operations = (0..<3).map { index in
            ["method": "PUT", "url": "debug://upload/\(id)/\(index + 1)", "offset": cuts[index], "length": cuts[index + 1] - cuts[index],
             "requestHeaders": [["name": "Content-Type", "value": "image/png"]]] as [String: Any]
        }
        return response(id: id, attributes: ["fileName": fileName, "uploadOperations": operations])
    }

    private func commit(id: String, data: [String: Any]?) async throws -> AppStoreConnectResponse {
        let fileName = state.withLock { $0.ledger.shots[id]?.fileName } ?? ""
        if case .commit? = DebugScreenshotUploadScript.matching(fileName, in: script.holds.keys).flatMap({ script.holds[$0] }) {
            try await Task.sleep(for: .seconds(3600))
        }
        let checksum = (data?["attributes"] as? [String: Any])?["sourceFileChecksum"] as? String
        state.withLock { state in
            state.ledger.shots[id]?.checksum = checksum
            state.ledger.shots[id]?.isCommitted = true
        }
        return response(id: id)
    }

    private func delete(id: String) {
        state.withLock { state in
            state.ledger.shots[id] = nil
            for key in state.ledger.sets.keys {
                state.ledger.sets[key]?.order.removeAll { $0 == id }
            }
        }
    }

    private func reorder(setID: String, ids: [String]) {
        state.withLock { $0.ledger.sets[setID]?.order = ids }
    }

    /// Uses up a one-time failure; false once it's been used.
    private func spend(_ key: String) -> Bool {
        state.withLock { $0.spent.insert(key).inserted }
    }

    private func response(id: String?, attributes: [String: Any] = [:]) -> AppStoreConnectResponse {
        let used = state.withLock { state in
            state.used += 1
            return state.used
        }
        let limit = AppStoreConnectRateLimit.defaultHourlyLimit
        let object: [String: Any] = id.map { ["data": ["type": "appScreenshots", "id": $0, "attributes": attributes]] } ?? [:]
        let data = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        return AppStoreConnectResponse(data: data, rateLimit: AppStoreConnectRateLimit(limit: limit, remaining: max(0, limit - used)))
    }
}
#endif
