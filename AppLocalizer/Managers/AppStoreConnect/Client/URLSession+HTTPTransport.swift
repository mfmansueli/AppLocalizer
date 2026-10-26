//
//  URLSession+HTTPTransport.swift
//  AppLocalizer
//

import Foundation

extension URLSession: HTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}
