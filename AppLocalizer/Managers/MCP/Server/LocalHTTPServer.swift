//
//  LocalHTTPServer.swift
//  AppLocalizer
//

import Foundation
import Network

/// The MCP server's socket: a Network framework listener bound to
/// 127.0.0.1 only, so nothing outside this Mac can reach it. Each accepted
/// connection is an `HTTPConnection`. All state lives on `queue`.
final class LocalHTTPServer: LocalHTTPServing, @unchecked Sendable {
    private let queue = DispatchQueue(label: "AppLocalizer.LocalHTTPServer")
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: HTTPConnection] = [:]

    func start(port: UInt16, handler: @escaping Handler, onEvent: @escaping EventHandler) {
        queue.async { [self] in
            stopListening()
            do {
                try listen(on: port, handler: handler, onEvent: onEvent)
            } catch {
                onEvent(.failed(message: Self.message(for: error, port: port)))
            }
        }
    }

    func stop() {
        queue.async { [self] in stopListening() }
    }

    private func listen(on port: UInt16, handler: @escaping Handler, onEvent: @escaping EventHandler) throws {
        let parameters = NWParameters.tcp
        parameters.acceptLocalOnly = true
        parameters.allowLocalEndpointReuse = true
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: NWEndpoint.Port(rawValue: port) ?? .any)
        let listener = try NWListener(using: parameters)
        listener.stateUpdateHandler = { [weak self, weak listener] state in
            switch state {
            case .ready:
                onEvent(.ready(port: listener?.port?.rawValue ?? port))
            // The port is taken: waiting would only retry the same port.
            case let .waiting(error), let .failed(error):
                onEvent(.failed(message: Self.message(for: error, port: port)))
                self?.stopListening()
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection, handler: handler)
        }
        listener.start(queue: queue)
        self.listener = listener
    }

    private func accept(_ nwConnection: NWConnection, handler: @escaping Handler) {
        let connection = HTTPConnection(connection: nwConnection, queue: queue, handler: handler)
        let id = ObjectIdentifier(connection)
        connections[id] = connection
        connection.onEnd = { [weak self] in self?.connections[id] = nil }
        connection.start()
    }

    private func stopListening() {
        listener?.stateUpdateHandler = nil
        listener?.newConnectionHandler = nil
        listener?.cancel()
        listener = nil
        for connection in connections.values {
            connection.close()
        }
        connections = [:]
    }

    private static func message(for error: any Error, port: UInt16) -> String {
        if case let NWError.posix(code) = error, code == .EADDRINUSE {
            return String(localized: "Port \(String(port)) is in use by another app.")
        }
        return error.localizedDescription
    }
}
