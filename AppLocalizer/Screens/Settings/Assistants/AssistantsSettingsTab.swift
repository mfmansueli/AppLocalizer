//
//  AssistantsSettingsTab.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → AI Assistants: the local MCP server's switch and status, what
/// a paired assistant can and can't do, the paired assistants with Revoke
/// and "Pair Assistant…", what they may propose, the prompts they offer,
/// and the activity log with the reason for every refused call; Claude
/// Code started by AppLocalizer (its helper and project folders); then the
/// API key, which can be set up as well as an assistant.
struct AssistantsSettingsTab: View {
    @Environment(MCPServerController.self) private var server
    @State private var isPairing = false
    /// DEBUG scenes open on the pairing sheet or the log.
    private let opensPairing: Bool
    private let scrollsToLog: Bool

    init(opensPairing: Bool = false, scrollsToLog: Bool = false) {
        self.opensPairing = opensPairing
        self.scrollsToLog = scrollsToLog
    }

    var body: some View {
        ScrollViewReader { proxy in
            Form {
                serverSection
                Section {
                    AssistantCapabilitiesRow()
                } header: {
                    Text("What a paired assistant can do")
                } footer: {
                    if !server.isEnabled {
                        Text("Turn the server on to pair Claude Code, Claude Desktop, Cursor, Codex or any other MCP client.")
                            .font(.callout)
                            .foregroundStyle(Palette.label2)
                    }
                }
                if server.isEnabled {
                    pairedSection
                    permissionsSection
                    promptsSection
                }
                ClaudeCodeLauncherSection()
                    .id(Self.launcherID)
                KeyAssistantSettingsSection()
                if server.isEnabled {
                    logSection
                }
            }
            .formStyle(.grouped)
            .task {
                if scrollsToLog { proxy.scrollTo(Self.logID, anchor: .top) }
                #if DEBUG
                if Self.debugScrollsToLauncher { proxy.scrollTo(Self.launcherID, anchor: .top) }
                #endif
            }
        }
        .sheet(isPresented: $isPairing, onDismiss: server.cancelPairing) {
            PairAssistantSheet()
        }
        .task {
            // A DEBUG scene may have started the pairing already.
            guard opensPairing, server.isEnabled else { return }
            if server.pendingPairing == nil { server.beginPairing() }
            isPairing = true
        }
    }

    private static let logID = "settings.ai.log"
    private static let launcherID = "settings.ai.launcher"

    #if DEBUG
    /// `cc-settings` opens on Claude Code's helper and folders.
    static var debugScrollsToLauncher = false
    #endif

    private var serverSection: some View {
        Section {
            Toggle(isOn: Binding(get: { server.isEnabled }, set: server.setEnabled)) {
                SettingsRowLabel(title: "Local MCP server", caption: server.statusText)
            }
            .toggleStyle(.switch)
            .accessibilityIdentifier("settings.ai.server")
            Text("Off by default. Runs on this Mac only, at \(server.address), and only while AppLocalizer is open.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
        }
    }

    private var pairedSection: some View {
        Section {
            if server.pairedClients.isEmpty {
                Text("Nothing paired yet. Pairing gives one assistant its own token, so you can revoke it without touching the others.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("settings.ai.noClients")
            }
            ForEach(server.pairedClients) { client in
                PairedClientRow(client: client, status: server.status(of: client)) {
                    server.revoke(client.id)
                }
            }
        } header: {
            HStack {
                Text("Paired assistants")
                Spacer()
                Button("Pair Assistant…", systemImage: "plus", action: pair)
                    .controlSize(.small)
                    .disabled(!server.isRunning)
                    .accessibilityIdentifier("settings.ai.pair")
            }
        }
    }

    private var permissionsSection: some View {
        Section("What assistants may propose") {
            Toggle(isOn: .constant(true)) {
                SettingsRowLabel(
                    title: "Read captures, captions, templates, listings and prices",
                    caption: String(localized: "Always on while the server runs.")
                )
            }
            .disabled(true)
            ForEach(MCPProposalKind.allCases) { kind in
                HStack {
                    Toggle(isOn: Binding(get: { server.allows(kind) }, set: { server.setAllowed(kind, $0) })) {
                        SettingsRowLabel(title: LocalizedStringKey(kind.title), caption: kind.caption)
                    }
                    .accessibilityIdentifier("settings.ai.allow.\(kind.rawValue)")
                    if kind == .screenshots {
                        Spacer()
                        Pill(text: String(localized: "Screenshots"))
                    }
                }
            }
        }
        .toggleStyle(.checkbox)
    }

    @ViewBuilder
    private var promptsSection: some View {
        if !server.availablePrompts.isEmpty {
            Section("Prompts in Claude Code") {
                ForEach(server.availablePrompts) { prompt in
                    LabeledContent {
                        Text(prompt.summary)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                    } label: {
                        Text(prompt.slashCommand)
                            .font(.callout.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    private var logSection: some View {
        Section {
            if server.log.isEmpty {
                Text("Every call an assistant makes shows here: what it read, proposed, or was refused, and why.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
            ForEach(server.log) { entry in
                AssistantLogRow(entry: entry)
            }
        } header: {
            HStack {
                Text("Activity log")
                Spacer()
                if !server.log.isEmpty {
                    Button("Clear", action: server.clearLog)
                        .controlSize(.small)
                }
            }
        }
        .id(Self.logID)
    }

    private func pair() {
        server.beginPairing()
        isPairing = true
    }
}
