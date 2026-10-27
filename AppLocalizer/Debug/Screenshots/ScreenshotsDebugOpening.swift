//
//  ScreenshotsDebugOpening.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Runs a scene's setup once, on the first Screenshots view model that
/// loads: a display type, a thumbnail size, an open sheet.
@MainActor
final class ScreenshotsDebugOpening {
    private var setUp: (@MainActor (ScreenshotsViewModel) async -> Void)?

    init(_ setUp: @escaping @MainActor (ScreenshotsViewModel) async -> Void) {
        self.setUp = setUp
    }

    func run(on viewModel: ScreenshotsViewModel) async {
        guard let setUp else { return }
        self.setUp = nil
        await setUp(viewModel)
    }
}
#endif
