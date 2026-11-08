//
//  RetentionAskPrompts.swift
//  AppLocalizer
//

import Foundation

/// What Retention asks Claude Code (or the connected assistant) to do. The
/// answers come back through AppLocalizer's MCP tools and wait in Review &
/// Push; the server setup runs in the person's own terminal, step by step.
enum RetentionAskPrompts {
    /// The runs' purpose, so each button finds its own run.
    static var purpose: ClaudeCodeRunPurpose { .ask(area: String(localized: "Retention")) }

    /// Draft a message (and, when it fits, an offer).
    static func draft(app: String) -> String {
        String(localized: """
        Draft a retention message for \(app) in AppLocalizer: what subscribers see on Apple's Confirm Cancellation \
        screen after they tap Cancel Subscription. Read the app's project, its paywall and its App Store listing \
        (get_listing) for what the subscription gives people, and get_retention for the subscriptions, the messages \
        and offers there already, and the limits. Write it in the app's voice: a header of at most 66 characters and \
        a message of at most 144, honest, no pressure, saying what people keep and what ends. Propose it with \
        propose_retention_message in the source language for the subscriptions it fits; AppLocalizer translates it. \
        If a discount would keep people, propose one retention offer with propose_retention_offer. Pass evidence as \
        "file:line — finding".
        """)
    }

    /// A shorter wording for one language that runs over Apple's limits.
    static func shorten(app: String, message: String, language: String, locale: String, header: String, body: String) -> String {
        String(localized: """
        In AppLocalizer, \(app)'s retention message "\(message)" runs over Apple's limits in \(language) (\(locale)): \
        the header can have 66 characters and the message 144. Now: header "\(header)" (\(header.count)), message \
        "\(body)" (\(body.count)). Write a shorter \(language) version that says the same and reads naturally, and \
        offer it with propose_retention_message for locale \(locale) with suggestion true (get_retention has the \
        message's id); the person takes it with Use Shorter Version.
        """)
    }

    /// An image for the message, made with Claude Design.
    static func image(app: String, message: String, folder: String) -> String {
        String(localized: """
        Make an image for \(app)'s retention message "\(message)" in AppLocalizer with Claude Design, in the app's \
        design language: a PNG 3840 pixels wide and 1000 tall (160 to 2160 is allowed), no transparency, that reads \
        on Apple's Confirm Cancellation screen in light and in dark mode, with no text in it. Save it in \(folder), \
        then call propose_retention_message for that message with kind "image" and the PNG as imageBase64 \
        (AppLocalizer is sandboxed and may not read the file at imagePath).
        """)
    }

    /// Real-time messages from the developer's server.
    static func server(app: String) -> String {
        String(localized: """
        Set up Apple's Retention Messaging API for \(app), step by step, asking me before each change. 1. Find the \
        app's server code. 2. Add the Get Retention Message endpoint Apple calls when someone taps Cancel: it must \
        answer within 700 ms with the message to show (by its ID in App Store Connect), an alternate product to \
        suggest, or a promotional offer signed with the app's In-App Purchase key; when it can't, Apple shows the \
        messages set up in App Store Connect. 3. Verify Apple's signed requests. 4. Register the sandbox URL with the \
        Retention Messaging API and run Apple's performance test. 5. Tell me what's left for production. Don't put \
        any key in the code, and don't call App Store Connect's write APIs.
        """)
    }
}
