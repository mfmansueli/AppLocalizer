//
//  RetentionDebugLaunch.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Where a Retention DEBUG scene starts: the page, the messages App Store
/// Connect has and the ones only on this Mac, the selected message's
/// kind, image and language, what's open, and whether it's queued.
struct RetentionDebugLaunch {
    enum Sheet {
        case offer
        case image(pickedImageID: String)
    }

    /// App Store Connect's messages.
    var remoteMessages: [RetentionMessage] = [RetentionSampleData.liveMessage]
    /// Messages only on this Mac, not queued.
    var drafts: [RetentionMessage] = []
    var selectedMessageID: String?
    var kind: RetentionMessageKind?
    var image: RetentionImage?
    var locale = StoreLocale.englishUS.code
    var showsAllLanguages = false
    var isAdvancedExpanded = false
    var isDark = false
    var suggestion: RetentionSuggestion?
    /// Adds the selected message to Review & Push.
    var queues = false
    var sheet: Sheet?
}
#endif
