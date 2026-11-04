//
//  DebugExtrasScript.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// How a DEBUG scene's simulated App Store Connect answers the extras push
/// and Product Page Optimization, and what the scene opens on.
struct DebugExtrasScript: Sendable {
    /// Each call waits this long, so the push shows its progress.
    var delay: Duration = .milliseconds(150)
    /// State checks that say Apple is still processing before a file is
    /// ready.
    var processingChecks = 0
    /// Pushes the extras once the plans are in (`shots-extras-pushing`).
    var pushesExtras = false
    /// A treatment won't take header or search artwork, so the test falls
    /// back to the export.
    var refusesTreatmentArtwork = false
    /// Opens “Test with Product Page Optimization…” for this placement once
    /// the plans are in.
    var opensTest: ProductPageTestPlacement?
    /// And presses Create Test.
    var createsTest = false
    /// And asks for the variant, which the pretend Claude Code reads and
    /// works on (`shots-ppo-asking`).
    var asksVariant = false
}
#endif
