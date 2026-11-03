//
//  AutopilotArtworkReference.swift
//  AppLocalizer
//

import Foundation

/// An image or video the person attached to the expected result: the
/// design source takes the feel from it, not the content. Kept with the
/// app's extras, named by `fileID`.
struct AutopilotArtworkReference: Codable, Hashable, Sendable, Identifiable {
    /// The file's checksum and extension, its name in the References
    /// folder.
    var fileID: String
    /// "video-search-results-dark.mp4", as it was named.
    var name: String

    var id: String { fileID }

    /// Images and videos the plan takes.
    static let allowedExtensions = ["png", "jpg", "jpeg", "heic", "gif", "mov", "mp4", "m4v"]

    var isVideo: Bool { ["mov", "mp4", "m4v"].contains((name as NSString).pathExtension.lowercased()) }
}
