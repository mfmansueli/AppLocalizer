//
//  FilePrivacyWorksheetStore.swift
//  AppLocalizer
//

import Foundation
import Observation
import OSLog

/// Keeps each app's worksheet as JSON in Application Support
/// (`AppPrivacy/<app ID>.json`), read once and cached. App Store Connect has
/// no API for the questionnaire, so this file is the only copy. It holds no
/// secrets.
@MainActor
@Observable
final class FilePrivacyWorksheetStore: PrivacyWorksheetStore {
    static let shared = FilePrivacyWorksheetStore()

    @ObservationIgnored private let directory: URL
    private var cache: [StoreApp.ID: PrivacyWorksheet] = [:]
    @ObservationIgnored private let logger = Logger(subsystem: "com.lima.applocalizer", category: "AppPrivacy")

    init(directory: URL = .applicationSupportDirectory.appending(path: "AppPrivacy", directoryHint: .isDirectory)) {
        self.directory = directory
    }

    func worksheet(for appID: StoreApp.ID) -> PrivacyWorksheet {
        if let cached = cache[appID] { return cached }
        let worksheet = load(appID) ?? PrivacyWorksheet()
        cache[appID] = worksheet
        return worksheet
    }

    func setWorksheet(_ worksheet: PrivacyWorksheet, for appID: StoreApp.ID) {
        cache[appID] = worksheet
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.sortedKeys]
            try encoder.encode(worksheet).write(to: fileURL(appID), options: .atomic)
        } catch {
            logger.error("Couldn’t save the App Privacy worksheet: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func load(_ appID: StoreApp.ID) -> PrivacyWorksheet? {
        guard let data = try? Data(contentsOf: fileURL(appID)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(PrivacyWorksheet.self, from: data)
    }

    private func fileURL(_ appID: StoreApp.ID) -> URL {
        let safe = appID.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        return directory.appending(path: "\(safe).json")
    }
}
