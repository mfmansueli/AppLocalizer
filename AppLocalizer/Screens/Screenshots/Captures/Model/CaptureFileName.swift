//
//  CaptureFileName.swift
//  AppLocalizer
//

import Foundation

/// What a screenshot's file name says: fastlane snapshot's
/// `iPhone 17 Pro Max-03_Search.png` (device, slot 3, "Search"), an Xcode
/// test attachment's `01_Today_0_9F2C….png` (slot 1, "Today"), or a plain
/// `02-Week.png`.
struct CaptureFileName: Hashable, Sendable {
    var deviceName: String?
    /// 1-based.
    var slotNumber: Int?
    var slotName: String?

    init(_ fileName: String) {
        let base = (fileName as NSString).deletingPathExtension
        if let match = base.firstMatch(of: /^(.+?)-(\d{1,2})_(.+)$/) {
            deviceName = String(match.1).trimmingCharacters(in: .whitespaces)
            slotNumber = Int(match.2)
            slotName = Self.name(String(match.3))
        } else if let match = base.firstMatch(of: /^(\d{1,2})[_\- ](.+)$/) {
            slotNumber = Int(match.1)
            slotName = Self.name(String(match.2))
        } else if let match = base.firstMatch(of: /^(\d{1,2})$/) {
            slotNumber = Int(match.1)
        }
    }

    /// "Today_0_9F2C…" → "Today": an attachment's repetition and ID go,
    /// and other underscores read as spaces.
    private static func name(_ text: String) -> String? {
        let trimmed = text.replacing(/_\d+_[0-9A-Fa-f\-]{6,}$/, with: "")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}
