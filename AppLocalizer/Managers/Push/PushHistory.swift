//
//  PushHistory.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Every finished push, newest first, for Activity, the overview's "Last
/// push" card and Results. Kept as JSON in Application Support when given a
/// file URL; in memory otherwise (tests, DEBUG scenes).
@MainActor
@Observable
final class PushHistory {
    private(set) var records: [PushRecord]

    private let fileURL: URL?

    init(fileURL: URL? = nil, records: [PushRecord] = []) {
        self.fileURL = fileURL
        self.records = records
        if let fileURL, records.isEmpty, let data = try? Data(contentsOf: fileURL) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.records = (try? decoder.decode([PushRecord].self, from: data)) ?? []
        }
    }

    static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "PushHistory.json")
    }

    func records(for appID: StoreApp.ID) -> [PushRecord] {
        records.filter { $0.appID == appID }
    }

    func lastRecord(for appID: StoreApp.ID) -> PushRecord? {
        records.first { $0.appID == appID }
    }

    func add(_ record: PushRecord) {
        records.insert(record, at: 0)
        records.sort { $0.date > $1.date }
        save()
    }

    private func save() {
        guard let fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? encoder.encode(records).write(to: fileURL, options: .atomic)
    }
}
