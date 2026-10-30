//
//  AssistantSetupViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// "Set Up Your AI Assistant": first how, an assistant over MCP or an API
/// key. With an assistant: pick the client, turn on the local server and
/// choose what assistants may do, copy the snippet with a token made for
/// that client, and test it with a first call. It drives the same pairing
/// as Settings → AI Assistants (`MCPServerController+Pairing`). "Finish
/// Without Testing" keeps the token, and the Assistant button waits for
/// the first call; "Finish Setup…" comes back to the test. With a key, the
/// steps are `KeyAssistantSetupViewModel`'s.
@MainActor
@Observable
final class AssistantSetupViewModel {
    let assistants: MCPServerController
    let key: KeyAssistantSetupViewModel
    private(set) var step: AssistantSetupStep
    private(set) var method: AssistantSetupMethod
    private(set) var kind: MCPClientKind
    /// "Suggest and edit drafts" instead of "Suggest only".
    var editsDrafts: Bool
    private(set) var hasCopiedSnippet = false
    /// A client paired without testing, whose first call the test waits for.
    private(set) var waitingClientID: MCPPairedClient.ID?
    /// Why the key couldn't be saved, in the footer.
    private(set) var saveError: String?

    /// The prompt step 4 asks to send.
    static let testPrompt = "List my apps in AppLocalizer"

    init(
        assistants: MCPServerController,
        keyAssistant: KeyAssistantController,
        appName: String,
        method: AssistantSetupMethod? = nil,
        step: AssistantSetupStep? = nil
    ) {
        self.assistants = assistants
        key = KeyAssistantSetupViewModel(controller: keyAssistant, appName: appName)
        editsDrafts = assistants.editsDrafts
        self.method = method ?? .assistant
        if method == .apiKey {
            kind = .claudeCode
            self.step = step ?? .assistant
        } else if let pairing = assistants.pendingPairing {
            kind = pairing.kind
            self.step = step ?? (pairing.isWaiting || pairing.isConnected ? .test : .snippet)
        } else if assistants.isEnabled, let client = assistants.leadingClient, client.lastSeenAt == nil {
            kind = client.kind
            waitingClientID = client.id
            self.step = step ?? .test
        } else {
            kind = .claudeCode
            self.step = step ?? .assistant
        }
    }

    // MARK: - Reading

    var isServerOn: Bool { assistants.isEnabled }

    /// The command or configuration for the chosen client, with its token.
    var snippet: String? { assistants.pairingSnippet }

    /// The client once it called AppLocalizer.
    var connectedClient: MCPPairedClient? {
        if let client = assistants.pendingPairing?.connectedClient { return client }
        guard let id = waitingClientID, let client = assistants.pairedClients.first(where: { $0.id == id }), client.lastSeenAt != nil else { return nil }
        return client
    }

    var isConnected: Bool { connectedClient != nil }

    /// e.g. "Claude Code".
    var clientName: String { connectedClient?.name ?? kind.title }

    /// "Claude Code called list_apps. It can read and suggest; it can’t push."
    var connectedText: String {
        let tool = assistants.recentCalls(of: clientName, limit: 1).first?.tool
        let reach = editsDrafts
            ? String(localized: "It can read, suggest and edit drafts; it can’t push.")
            : String(localized: "It can read and suggest; it can’t push.")
        guard let tool else { return String(localized: "\(clientName) called AppLocalizer. \(reach)") }
        return String(localized: "\(clientName) called \(tool). \(reach)")
    }

    var usesKey: Bool { method == .apiKey }

    var canGoBack: Bool { step.previous != nil && (usesKey || !isConnected) }

    var canContinue: Bool {
        switch (method, step) {
        case (.assistant, .server): isServerOn
        case (.apiKey, .server): key.keyState.isWorking
        case (.apiKey, .test): key.testState != .sending
        default: true
        }
    }

    /// "Continue", then "Done" once connected or tested, else "Finish
    /// Without Testing".
    var continueTitle: String {
        guard step == .test else { return String(localized: "Continue") }
        let isDone = usesKey ? key.testState.isWorking : isConnected
        return isDone ? String(localized: "Done") : String(localized: "Finish Without Testing")
    }

    /// The step bars' labels.
    var stepTitles: [String] { method.stepTitles }

    /// The footer's note for the step.
    var footnote: String {
        if usesKey {
            return switch step {
            case .assistant: String(localized: "You can add the other way later in Settings → AI Assistants.")
            case .server: String(localized: "The key only ever goes to \(key.vendor.title).")
            case .snippet: String(localized: "You can change this for each request.")
            case .test: saveError ?? ""
            }
        }
        return switch step {
        case .assistant: String(localized: "You can change this later in Settings → AI Assistants.")
        case .server: String(localized: "Nothing is shared until an assistant connects with its token.")
        case .snippet: hasCopiedSnippet ? String(localized: "Copied. Paste it, then continue.") : ""
        case .test: isConnected ? "" : String(localized: "Keep this open while you ask.")
        }
    }

    /// What VoiceOver hears, and the Assistant button then shows, after Done.
    var finishedAnnouncement: String {
        if usesKey { return String(localized: "\(key.vendor.apiName) is ready. Use Generate Suggestions on Store Page.") }
        return isConnected
            ? String(localized: "\(clientName) is connected. Ask it from the Assistant button or from any suggestion bar.")
            : String(localized: "Saved. The Assistant button turns green when \(clientName) first calls AppLocalizer.")
    }

    // MARK: - Changing

    func choose(_ method: AssistantSetupMethod) {
        guard step == .assistant else { return }
        self.method = method
    }

    func choose(_ kind: MCPClientKind) {
        guard !isConnected else { return }
        self.kind = kind
        hasCopiedSnippet = false
        if assistants.pendingPairing != nil { assistants.choosePairingKind(kind) }
    }

    func setServerOn(_ isOn: Bool) {
        assistants.setEnabled(isOn)
    }

    func goBack() {
        guard canGoBack, let previous = step.previous else { return }
        step = previous
    }

    /// Continue, Done or Finish Without Testing. Returns whether the sheet
    /// should close.
    func advance() -> Bool {
        guard canContinue else { return false }
        if usesKey { return advanceWithKey() }
        switch step {
        case .assistant:
            step = .server
        case .server:
            assistants.editsDrafts = editsDrafts
            // Suggestions need both, whichever permission was chosen.
            assistants.setAllowed(.storeText, true)
            assistants.setAllowed(.appInformation, true)
            if assistants.pendingPairing == nil {
                assistants.beginPairing(kind: kind)
                waitingClientID = nil
            } else {
                assistants.choosePairingKind(kind)
            }
            step = .snippet
        case .snippet:
            step = .test
        case .test:
            finish()
            return true
        }
        return false
    }

    /// Copy Command or Copy Configuration: returns the snippet to copy.
    func copySnippet() -> String? {
        guard let snippet else { return nil }
        assistants.markPairingCopied()
        hasCopiedSnippet = true
        return snippet
    }

    /// Cancel: a client that never connected isn't paired; a key isn't
    /// saved.
    func cancel() {
        guard !usesKey else { return }
        if assistants.pendingPairing?.isConnected == true {
            assistants.finishPairing()
        } else {
            assistants.cancelPairing()
        }
    }

    /// What it sees, then the test request as step 4 opens.
    private func advanceWithKey() -> Bool {
        switch step {
        case .assistant: step = .server
        case .server: step = .snippet
        case .snippet:
            step = .test
            Task { await key.runTest() }
        case .test:
            do {
                try key.save()
                saveError = nil
            } catch {
                saveError = String(localized: "Couldn’t save the key: \(error.localizedDescription)")
                return false
            }
            return true
        }
        return false
    }

    private func finish() {
        guard let pairing = assistants.pendingPairing else { return }
        if pairing.isConnected {
            assistants.finishPairing()
        } else {
            let id = pairing.clientID
            assistants.finishPairingWithoutTesting()
            waitingClientID = id
        }
    }
}
