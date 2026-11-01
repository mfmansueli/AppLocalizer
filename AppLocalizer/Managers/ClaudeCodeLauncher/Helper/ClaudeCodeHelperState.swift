//
//  ClaudeCodeHelperState.swift
//  AppLocalizer
//

import Foundation

/// Whether AppLocalizer can start Claude Code: the helper saved in the
/// app's scripts folder, and the Claude Code it finds.
enum ClaudeCodeHelperState: Hashable, Sendable {
    /// Not looked at yet.
    case unknown
    case notInstalled
    case checking
    /// Saved, and it found Claude Code.
    case ready(ClaudeCodeInstallation)
    /// Saved by an older AppLocalizer; it needs saving again.
    case outdated(installedVersion: Int)
    /// Saved, but there's no `claude` on this Mac.
    case claudeMissing
    /// The helper couldn't run, e.g. it isn't executable.
    case failed(String)

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    var installation: ClaudeCodeInstallation? {
        if case let .ready(installation) = self { return installation }
        return nil
    }

    /// The file is in the scripts folder, whatever it found.
    var isInstalled: Bool {
        switch self {
        case .unknown, .notInstalled: false
        case .checking, .ready, .outdated, .claudeMissing, .failed: true
        }
    }

    /// "Helper installed", "Helper not installed", "Checking…".
    var title: String {
        switch self {
        case .unknown, .checking: String(localized: "Checking the helper…")
        case .notInstalled: String(localized: "Helper not installed")
        case .ready: String(localized: "Helper installed")
        case .outdated: String(localized: "Helper needs updating")
        case .claudeMissing: String(localized: "Claude Code not found")
        case .failed: String(localized: "The helper couldn’t run")
        }
    }

    /// The line under the title.
    var detail: String {
        switch self {
        case .unknown, .checking:
            ""
        case .notInstalled:
            String(localized: "Save it once and AppLocalizer starts Claude Code for you: no Terminal, nothing to paste.")
        case let .ready(installation):
            "\(installation.title) · \(installation.displayPath())"
        case .outdated:
            String(localized: "This AppLocalizer needs a newer helper. Save it again over the old one.")
        case .claudeMissing:
            String(localized: "The helper is installed, but it found no claude command. Install Claude Code, then check again.")
        case let .failed(message):
            message
        }
    }

    /// "Install Helper…", "Update Helper…", or nil when it's fine.
    var installTitle: String? {
        switch self {
        case .notInstalled, .unknown: String(localized: "Install Helper…")
        case .outdated, .failed: String(localized: "Save the Helper Again…")
        case .checking, .ready, .claudeMissing: nil
        }
    }
}
