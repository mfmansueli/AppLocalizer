//
//  ProposalsSheetHeader.swift
//  AppLocalizer
//

import SwiftUI

/// "Proposals · Lumen Journal", what accepting means, whether the
/// assistant is connected, and a note once it has gone.
struct ProposalsSheetHeader: View {
    let viewModel: ScreenshotProposalsViewModel
    @Environment(MCPServerController.self) private var assistants

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text("Proposals · \(viewModel.app.name)")
                        .font(.title3.weight(.semibold))
                    Text("Nothing an assistant sends changes your screenshots until you accept it here. Accepted renders still go through Review & Push.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Spacing.large)
                if let client {
                    connectionPill(client)
                }
            }
            if let client, case let .disconnected(lastSeen) = status(of: client) {
                Text("\(client) disconnected at \(lastSeen.formatted(date: .omitted, time: .shortened)). Its proposals stay here until you accept or reject them.")
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                    .accessibilityIdentifier("proposals.disconnected")
            }
        }
        .padding(.horizontal, Spacing.xxLarge)
        .padding(.vertical, Spacing.large)
    }

    /// The assistant the proposals came from, newest first.
    private var client: String? {
        viewModel.selected?.client ?? viewModel.proposals.last?.client
    }

    private func status(of client: String) -> MCPPairedClientStatus? {
        assistants.pairedClients.first { $0.name == client }.map(assistants.status(of:))
    }

    private func connectionPill(_ client: String) -> some View {
        HStack(spacing: Spacing.xxSmall) {
            AssistantMonogram(letters: ChangeSource.assistant(client: client).monogram ?? "AI")
            Text(connectionText(client))
                .font(.caption)
        }
        .padding(.leading, 3)
        .padding(.trailing, Spacing.xSmall)
        .padding(.vertical, 2)
        .overlay(Capsule().strokeBorder(Palette.separator2, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("proposals.connection")
    }

    /// "Claude Code · connected", "Claude Code · disconnected 10:44".
    private func connectionText(_ client: String) -> String {
        switch status(of: client) {
        case .connected?: String(localized: "\(client) · connected")
        case let .disconnected(lastSeen)?: String(localized: "\(client) · disconnected \(lastSeen.formatted(date: .omitted, time: .shortened))")
        case .idle?: String(localized: "\(client) · not connected")
        case nil: String(localized: "\(client) · not paired")
        }
    }
}
