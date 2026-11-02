//
//  PipeLineSplitter.swift
//  AppLocalizer
//

import Foundation
import Synchronization

/// Splits a pipe's bytes into lines as they arrive (`PipeLineReader`): at
/// "\n", "\r\n" or "\r", keeping the unfinished line for the next chunk.
/// A chunk can end inside a character; lines are decoded whole.
final class PipeLineSplitter: Sendable {
    private struct State {
        var pending: [UInt8] = []
        /// The last chunk ended with "\r": a "\n" next belongs to it.
        var afterCarriageReturn = false
    }

    private let state = Mutex(State())

    /// The lines `data` finishes.
    func append(_ data: Data) -> [String] {
        state.withLock { state in
            var lines: [String] = []
            for byte in data {
                defer { state.afterCarriageReturn = byte == Self.carriageReturn }
                switch byte {
                case Self.lineFeed where state.afterCarriageReturn:
                    continue
                case Self.lineFeed, Self.carriageReturn:
                    lines.append(Self.text(of: state.pending))
                    state.pending.removeAll(keepingCapacity: true)
                default:
                    state.pending.append(byte)
                }
            }
            return lines
        }
    }

    /// The last line, when it had no line break.
    func finish() -> String? {
        state.withLock { state in
            defer { state.pending.removeAll() }
            return state.pending.isEmpty ? nil : Self.text(of: state.pending)
        }
    }

    /// UTF-8, as Claude Code and the tools write; Latin-1 for anything else
    /// rather than losing the line.
    private static func text(of bytes: [UInt8]) -> String {
        String(bytes: bytes, encoding: .utf8) ?? String(bytes: bytes, encoding: .isoLatin1) ?? ""
    }

    private static let lineFeed = UInt8(ascii: "\n")
    private static let carriageReturn = UInt8(ascii: "\r")
}
