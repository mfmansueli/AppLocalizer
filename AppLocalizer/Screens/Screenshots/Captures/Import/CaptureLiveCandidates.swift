//
//  CaptureLiveCandidates.swift
//  AppLocalizer
//

import Foundation

/// The screenshots live in App Store Connect as an import: every iPhone
/// 6.9″ and iPad 13″ set, each screenshot in its set's slot. They're
/// finished marketing images and may already have captions, which the
/// import warns about.
enum CaptureLiveCandidates {
    static func scan(_ live: LiveScreenshots) -> CaptureScan {
        let candidates = live.screenshotSets.filter(\.displayType.isRendered).flatMap { set in
            set.screenshots.enumerated().map { index, shot in
                CaptureCandidate(
                    path: "\(set.locale)/\(set.displayType.title) · \(index + 1)",
                    origin: .live(shot), source: .appStoreConnect, pixelSize: shot.pixelSize, localeCode: set.locale,
                    deviceName: nil, slotNumber: index + 1, slotName: nil, displayType: set.displayType
                )
            }
        }
        return CaptureScan(source: .appStoreConnect, location: String(localized: "App Store Connect"), candidates: candidates)
    }
}
