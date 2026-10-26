//
//  StorePageDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// The Store Page section's DEBUG scenes (`-AppLocalizerDebugScene <id>`).
/// `DebugSceneView` asks here for any id it doesn't know itself.
enum StorePageDebugScenes {
    static let ids: [String] = []

    @MainActor
    static func view(for _: String) -> AnyView? {
        nil
    }
}
#endif
