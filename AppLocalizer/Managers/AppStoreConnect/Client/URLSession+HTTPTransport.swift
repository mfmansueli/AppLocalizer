//
//  URLSession+HTTPTransport.swift
//  AppLocalizer
//

import Foundation

extension URLSession: HTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }

    func upload(_ request: URLRequest, body: Data, progress: @escaping @Sendable (Int64) -> Void) async throws -> (Data, URLResponse) {
        try await upload(for: request, from: body, delegate: UploadProgressDelegate(progress: progress))
    }
}
