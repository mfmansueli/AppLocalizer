//
//  DebugPricingCallLog.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Counts the price sheets a DEBUG scene asked for, so a scene can answer
/// the first at once and hold the refresh that follows (the skeleton).
@MainActor
final class DebugPricingCallLog {
    private(set) var sheetRequests = 0

    func recordSheetRequest() -> Int {
        sheetRequests += 1
        return sheetRequests
    }
}
#endif
