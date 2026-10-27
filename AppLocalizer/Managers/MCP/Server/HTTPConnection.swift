//
//  HTTPConnection.swift
//  AppLocalizer
//

import Foundation
import Network

/// One client connection to the MCP server. It reads requests one at a time
/// (keep-alive), answers each through the handler, and turns into a
/// server-sent events stream when the handler opens one. All state lives on
/// the server's queue.
final class HTTPConnection: @unchecked Sendable {
    /// Called on the queue once the connection is closed.
    var onEnd: (() -> Void)?

    private let connection: NWConnection
    private let queue: DispatchQueue
    private let handler: LocalHTTPServing.Handler
    private var parser = HTTPRequestParser()
    private var isHandlingRequest = false
    private var isStreaming = false
    private var isClosed = false
    private var streamTask: Task<Void, Never>?
    private var onStreamClose: (@Sendable () -> Void)?

    init(connection: NWConnection, queue: DispatchQueue, handler: @escaping LocalHTTPServing.Handler) {
        self.connection = connection
        self.queue = queue
        self.handler = handler
    }

    func start() {
        connection.stateUpdateHandler = { [self] state in
            switch state {
            case .failed, .cancelled: close()
            default: break
            }
        }
        connection.start(queue: queue)
        receive()
    }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        streamTask?.cancel()
        streamTask = nil
        onStreamClose?()
        onStreamClose = nil
        connection.stateUpdateHandler = nil
        connection.cancel()
        onEnd?()
        onEnd = nil
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [self] data, _, isComplete, error in
            guard !isClosed else { return }
            // A stream's client sends nothing more; only its going away matters.
            if let data, !data.isEmpty, !isStreaming {
                parser.append(data)
                handleNextRequest()
            }
            if isComplete || error != nil {
                close()
            } else {
                receive()
            }
        }
    }

    private func handleNextRequest() {
        guard !isHandlingRequest, !isStreaming, !isClosed else { return }
        let request: HTTPRequest
        do {
            guard let next = try parser.nextRequest() else { return }
            request = next
        } catch {
            send(.text(error.statusCode), keepAlive: false)
            return
        }
        isHandlingRequest = true
        let handler = handler
        Task { [self] in
            let reply = await handler(request)
            queue.async { [self] in answer(request, with: reply) }
        }
    }

    private func answer(_ request: HTTPRequest, with reply: HTTPReply) {
        guard !isClosed else { return }
        switch reply {
        case let .response(response):
            send(response, keepAlive: request.keepsAlive)
        case let .events(stream):
            openStream(stream)
        }
    }

    private func send(_ response: HTTPResponse, keepAlive: Bool) {
        connection.send(content: response.serialized(keepAlive: keepAlive), completion: .contentProcessed { [self] error in
            isHandlingRequest = false
            if error != nil || !keepAlive {
                close()
            } else {
                handleNextRequest()
            }
        })
    }

    private func openStream(_ stream: HTTPEventStream) {
        isStreaming = true
        isHandlingRequest = false
        onStreamClose = stream.onClose
        var headers = stream.headers
        headers["Content-Type"] = "text/event-stream"
        headers["Cache-Control"] = "no-cache"
        headers["Connection"] = "keep-alive"
        connection.send(content: HTTPResponse.head(status: 200, headers: headers), completion: .idempotent)
        streamTask = Task { [self] in
            for await chunk in stream.events {
                queue.async { [self] in
                    guard !isClosed else { return }
                    connection.send(content: Data(chunk.utf8), completion: .idempotent)
                }
            }
            queue.async { [self] in close() }
        }
    }
}
