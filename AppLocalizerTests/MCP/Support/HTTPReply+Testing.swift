//
//  HTTPReply+Testing.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

extension HTTPReply {
    /// The plain response, or nil for an event stream.
    var response: HTTPResponse? {
        if case let .response(response) = self { return response }
        return nil
    }

    /// The event stream, or nil for a plain response.
    var eventStream: HTTPEventStream? {
        if case let .events(stream) = self { return stream }
        return nil
    }
}
