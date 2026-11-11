//
//  WorkspaceSectionModels.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The window's section models, per app, so switching sections (⌘1–⌘5) or
/// going back to an app opened a moment ago doesn't read everything from
/// App Store Connect again. Only the most recently opened apps are kept.
/// Refresh (⌘R) and a push make every kept model read again the next time
/// its section shows, and so does age.
@MainActor
@Observable
final class WorkspaceSectionModels {
    /// How long a section shows what it read before reading again when it
    /// is opened, so what changed in App Store Connect meanwhile (a version
    /// approved, a price taking effect) still turns up.
    static let maximumAge: TimeInterval = 15 * 60
    /// The apps whose models are kept.
    static let appLimit = 4

    @ObservationIgnored private var apps: [StoreApp.ID: AppSectionModels] = [:]
    /// The kept apps, least recently opened first.
    @ObservationIgnored private var order: [StoreApp.ID] = []
    @ObservationIgnored private let appLimit: Int
    @ObservationIgnored private let maximumAge: TimeInterval
    @ObservationIgnored private let now: () -> Date

    init(appLimit: Int = WorkspaceSectionModels.appLimit, maximumAge: TimeInterval = WorkspaceSectionModels.maximumAge, now: @escaping () -> Date = { .now }) {
        self.appLimit = max(1, appLimit)
        self.maximumAge = maximumAge
        self.now = now
    }

    /// The app's models, made empty the first time. Asking counts as
    /// opening the app; the app opened longest ago is dropped past the
    /// limit.
    func models(for appID: StoreApp.ID) -> AppSectionModels {
        order.removeAll { $0 == appID }
        order.append(appID)
        if let kept = apps[appID] { return kept }
        let models = AppSectionModels(maximumAge: maximumAge, now: now)
        apps[appID] = models
        while order.count > appLimit {
            apps[order.removeFirst()] = nil
        }
        return models
    }

    /// The apps whose models are kept, least recently opened first.
    var keptAppIDs: [StoreApp.ID] { order }
}
