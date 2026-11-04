//
//  AssetLibraryKindFilter.swift
//  AppLocalizer
//

import Foundation

/// The library sheet's All | Images | Videos.
enum AssetLibraryKindFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case images
    case videos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .images: String(localized: "Images")
        case .videos: String(localized: "Videos")
        }
    }

    func includes(_ file: AssetLibraryFile) -> Bool {
        switch self {
        case .all: true
        case .images: file.media == .image
        case .videos: file.media == .video
        }
    }
}
