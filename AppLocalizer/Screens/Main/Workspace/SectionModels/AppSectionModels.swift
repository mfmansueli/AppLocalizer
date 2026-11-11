//
//  AppSectionModels.swift
//  AppLocalizer
//

import Foundation

/// One app's section models, kept while the person moves between the
/// sections, so coming back to one shows what it had instead of reading
/// App Store Connect again. Each section stamps its model when a read
/// finishes and reads again only once the stamp is stale.
@MainActor
final class AppSectionModels {
    var storePage: StorePageViewModel?
    var appInformation: AppInformationViewModel?
    var pricing: PricingViewModel?
    var retention: RetentionModel?
    var screenshots: ScreenshotsSectionModel?
    /// The page Overview's App Store preview draws.
    var overviewContent: StorePageContent?

    private var stamps: [AppWorkspaceSection: SectionLoadStamp] = [:]
    private let maximumAge: TimeInterval
    private let now: () -> Date

    init(maximumAge: TimeInterval, now: @escaping () -> Date) {
        self.maximumAge = maximumAge
        self.now = now
    }

    /// True when `section` has to read App Store Connect: it never
    /// finished a read, Refresh was asked since, or what it has is old.
    func needsLoad(_ section: AppWorkspaceSection, refreshCount: Int) -> Bool {
        guard let stamp = stamps[section] else { return true }
        return !stamp.isFresh(refreshCount: refreshCount, now: now(), maximumAge: maximumAge)
    }

    /// `section` finished a read that was started under `refreshCount`.
    func didLoad(_ section: AppWorkspaceSection, refreshCount: Int) {
        stamps[section] = SectionLoadStamp(refreshCount: refreshCount, date: now())
    }
}
