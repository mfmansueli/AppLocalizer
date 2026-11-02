//
//  FakeScreenshotUploadTransport.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// Answers the screenshot endpoints like App Store Connect would and logs
/// each call in order (`reserve de-DE_iPhone_1_Today.png set-1`,
/// `upload shot-2 1`, `commit shot-2`, `status shot-2`, `delete live-0`,
/// `reorder set-1 shot-2,live-1`). Images named by the start of their file
/// name can fail once. Nothing reaches the network.
final class FakeScreenshotUploadTransport: ScreenshotUploadTransport {
    struct Script: Sendable {
        /// The part that times out, once.
        var timeouts: [String: Int] = [:]
        /// Apple reports `IMAGE_TOOL_FAILURE`, once.
        var processingFailures: Set<String> = []
        /// Reserving finds the Mac offline.
        var offline: Set<String> = []
        /// The first request gets a 429.
        var rateLimitedOnce = false
        /// What each response reports as left this hour, before counting.
        var remaining = 3000
        /// Sets App Store Connect has that the plan didn't know about, by
        /// "<display type> <localization ID>": their ID and screenshot
        /// count. Creating one of these is refused with `STATE_ERROR`.
        var existingSets: [String: (id: String, screenshots: Int)] = [:]
    }

    private struct State {
        var log: [String] = []
        var nextID = 1
        var fileNames: [String: String] = [:]
        var uploaded: [String: Data] = [:]
        var spent: Set<String> = []
        var remaining: Int
    }

    private let script: Script
    private let state: Mutex<State>

    init(_ script: Script = Script()) {
        self.script = script
        state = Mutex(State(remaining: script.remaining))
    }

    var log: [String] { state.withLock { $0.log } }

    /// The bytes uploaded for a screenshot, parts joined.
    func uploaded(_ id: String) -> Data? {
        state.withLock { $0.uploaded[id] }
    }

    func send(_ request: PushRequest) async throws -> AppStoreConnectResponse {
        if script.rateLimitedOnce, spend("429") { throw AppStoreConnectError.rateLimited }
        let body = request.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        let data = body?["data"] as? [String: Any]
        let attributes = data?["attributes"] as? [String: Any]
        let path = request.path
        switch (request.method, path) {
        case (.post, "/v1/appScreenshotSets"):
            let localization = Self.relatedID(data, "appStoreVersionLocalization") ?? ""
            let display = attributes?["screenshotDisplayType"] as? String ?? ""
            if script.existingSets["\(display) \(localization)"] != nil {
                log("create-set \(display) \(localization) refused")
                throw AppStoreConnectError.rejected(statusCode: 409, code: "STATE_ERROR", detail: "Screenshot Set Already Exists!")
            }
            let id = record("set", "create-set \(display) \(localization)")
            return response(id: id)
        case (.post, "/v1/appScreenshots"):
            return try reserve(fileName: attributes?["fileName"] as? String ?? "", size: attributes?["fileSize"] as? Int ?? 0, data: data)
        case (.patch, _) where path.hasSuffix("/relationships/appScreenshots"):
            let ids = (body?["data"] as? [[String: Any]])?.compactMap { $0["id"] as? String } ?? []
            log("reorder \(path.components(separatedBy: "/")[3]) \(ids.joined(separator: ","))")
            return response(id: nil)
        case (.patch, _):
            log("commit \(path.components(separatedBy: "/").last ?? "")")
            return response(id: nil)
        case (.delete, _):
            log("delete \(path.components(separatedBy: "/").last ?? "")")
            return response(id: nil)
        default:
            throw AppStoreConnectError.notFound(detail: path)
        }
    }

    func fetch(_ path: String) async throws -> AppStoreConnectResponse {
        if path.hasPrefix("/v1/appStoreVersionLocalizations/") { return sets(at: path) }
        let id = path.components(separatedBy: "/").last?.components(separatedBy: "?").first ?? ""
        log("status \(id)")
        let fileName = state.withLock { $0.fileNames[id] } ?? ""
        if let name = Self.matching(fileName, script.processingFailures), spend("process|\(name)") {
            let errors: [[String: Any]] = [["code": "IMAGE_TOOL_FAILURE", "description": "The image couldn’t be processed."]]
            return response(id: id, attributes: ["assetDeliveryState": ["state": "FAILED", "errors": errors]])
        }
        return response(id: id, attributes: ["assetDeliveryState": ["state": "UPLOAD_COMPLETE"]])
    }

    func upload(_ operation: ScreenshotUploadOperation, data: Data, progress: @escaping @Sendable (Int64) -> Void) async throws {
        let parts = operation.url.components(separatedBy: "/")
        let id = parts.dropLast().last ?? ""
        let part = Int(parts.last ?? "") ?? 1
        log("upload \(id) \(part)")
        let fileName = state.withLock { $0.fileNames[id] } ?? ""
        if let name = Self.matching(fileName, Set(script.timeouts.keys)), script.timeouts[name] == part, spend("timeout|\(name)") {
            throw URLError(.timedOut)
        }
        state.withLock { $0.uploaded[id, default: Data()].append(operation.slice(of: data)) }
        progress(Int64(operation.length))
    }

    // MARK: - Helpers

    /// A localization's sets of one display type, as the lookup after a
    /// refused create reads them.
    private func sets(at path: String) -> AppStoreConnectResponse {
        let localization = path.components(separatedBy: "/")[3]
        let display = path.components(separatedBy: "%5D=").dropFirst().first?.components(separatedBy: "&").first ?? ""
        log("find-set \(display) \(localization)")
        let existing = script.existingSets["\(display) \(localization)"]
        let data: [[String: Any]] = existing.map { set in
            let shots = (0..<set.screenshots).map { ["type": "appScreenshots", "id": "\(set.id)-shot-\($0)"] }
            return [[
                "type": "appScreenshotSets", "id": set.id, "attributes": ["screenshotDisplayType": display],
                "relationships": ["appScreenshots": ["data": shots]],
            ]]
        } ?? []
        let body = (try? JSONSerialization.data(withJSONObject: ["data": data])) ?? Data()
        return AppStoreConnectResponse(data: body, rateLimit: AppStoreConnectRateLimit(limit: 3600, remaining: 3000))
    }

    /// Two parts, split in the middle.
    private func reserve(fileName: String, size: Int, data: [String: Any]?) throws -> AppStoreConnectResponse {
        if Self.matching(fileName, script.offline) != nil { throw URLError(.notConnectedToInternet) }
        let id = record("shot", "reserve \(fileName) \(Self.relatedID(data, "appScreenshotSet") ?? "")")
        state.withLock { $0.fileNames[id] = fileName }
        let half = size / 2
        let operations: [[String: Any]] = [
            ["method": "PUT", "url": "test://upload/\(id)/1", "offset": 0, "length": half],
            ["method": "PUT", "url": "test://upload/\(id)/2", "offset": half, "length": size - half],
        ]
        return response(id: id, attributes: ["fileName": fileName, "uploadOperations": operations])
    }

    private func record(_ prefix: String, _ entry: String) -> String {
        state.withLock { state in
            let id = "\(prefix)-\(state.nextID)"
            state.nextID += 1
            state.log.append(entry)
            return id
        }
    }

    private func log(_ entry: String) {
        state.withLock { $0.log.append(entry) }
    }

    private func spend(_ key: String) -> Bool {
        state.withLock { $0.spent.insert(key).inserted }
    }

    private func response(id: String?, attributes: [String: Any] = [:]) -> AppStoreConnectResponse {
        let remaining = state.withLock { state in
            state.remaining -= 1
            return state.remaining
        }
        let object: [String: Any] = id.map { ["data": ["type": "appScreenshots", "id": $0, "attributes": attributes]] } ?? [:]
        let data = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        return AppStoreConnectResponse(data: data, rateLimit: AppStoreConnectRateLimit(limit: 3600, remaining: max(0, remaining)))
    }

    private static func relatedID(_ data: [String: Any]?, _ name: String) -> String? {
        let relationships = data?["relationships"] as? [String: Any]
        return ((relationships?[name] as? [String: Any])?["data"] as? [String: Any])?["id"] as? String
    }

    private static func matching(_ fileName: String, _ names: Set<String>) -> String? {
        names.first { fileName.hasPrefix($0) }
    }
}
