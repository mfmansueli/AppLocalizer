//
//  DisplayRecording.swift
//  AppLocalizer
//

import Foundation

/// A display's recording as the helper's `record-display` prints it:
/// `folder <path>`, then `frame <start> <end> <file>` for each new frame,
/// `same <end>` when a capture matched the frame before, and `dropped
/// <file>` when the oldest goes. Frames are oldest first.
struct DisplayRecording: Hashable, Sendable {
    private(set) var folder: String?
    private(set) var frames: [RecordedFrame] = []

    /// Reads one line; anything else is ignored.
    mutating func read(_ line: String) {
        let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        switch parts.first {
        case "folder" where parts.count >= 2:
            folder = String(line.dropFirst("folder ".count))
        case "frame" where parts.count == 4:
            guard let start = Double(parts[1]), let end = Double(parts[2]) else { return }
            frames.append(RecordedFrame(file: parts[3], start: start, end: end, lastSeen: end))
        case "same" where parts.count == 2:
            guard let end = Double(parts[1]), !frames.isEmpty else { return }
            frames[frames.count - 1].lastSeen = end
        case "dropped" where parts.count == 2:
            frames.removeAll { $0.file == parts[1] }
        default:
            break
        }
    }

    /// A frame's file, for the helper's `recorded-frame`.
    func path(of frame: RecordedFrame) -> String? {
        folder.map { $0 + "/" + frame.file }
    }
}
