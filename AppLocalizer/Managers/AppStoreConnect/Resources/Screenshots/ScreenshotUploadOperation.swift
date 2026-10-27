//
//  ScreenshotUploadOperation.swift
//  AppLocalizer
//

import Foundation

/// One part of a reserved screenshot's upload: send `length` bytes of the
/// file from `offset` to `url` with `method` and these headers.
struct ScreenshotUploadOperation: Codable, Hashable, Sendable {
    var method: String
    var url: String
    var offset: Int
    var length: Int
    var requestHeaders: [ScreenshotUploadHeader]?

    /// This part's bytes of `data`.
    func slice(of data: Data) -> Data {
        let start = data.startIndex + min(max(0, offset), data.count)
        let end = min(start + max(0, length), data.endIndex)
        return data.subdata(in: start..<end)
    }
}
