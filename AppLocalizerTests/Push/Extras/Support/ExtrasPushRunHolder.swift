//
//  ExtrasPushRunHolder.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Lets a fake asset library reach the run it serves, e.g. to cancel it
/// while an item is in flight.
@MainActor
final class ExtrasPushRunHolder {
    var run: ExtrasPushRun?

    func cancel() {
        run?.cancelRemaining()
    }
}
