//
//  UploadProgressDelegate.swift
//  AppLocalizer
//

import Foundation

/// Tells one upload's sender how many bytes of the body have gone out, as
/// URLSession sends them.
final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    private let progress: @Sendable (Int64) -> Void

    init(progress: @escaping @Sendable (Int64) -> Void) {
        self.progress = progress
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didSendBodyData _: Int64, totalBytesSent: Int64, totalBytesExpectedToSend _: Int64) {
        progress(totalBytesSent)
    }
}
