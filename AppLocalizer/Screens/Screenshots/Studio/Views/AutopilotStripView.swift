//
//  AutopilotStripView.swift
//  AppLocalizer
//

import SwiftUI

/// The Autopilot strip above the preview: what it does or is doing, its
/// progress, a purple "Your turn" at a checkpoint, a red pill for a
/// problem, and the assistant and design project it uses.
struct AutopilotStripView: View {
    let content: AutopilotStripContent
    /// "Claude Code", when one that can run Xcode is connected.
    let assistant: String?
    let designProject: DesignProject?
    let perform: (AutopilotStripAction) -> Void
    let onConnectDesign: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: Spacing.medium) {
                icon
                texts
                Spacer(minLength: Spacing.small)
                if content.showsConnections { connections(vertical: true) }
                buttons
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(alignment: .top, spacing: Spacing.medium) {
                    icon
                    texts
                }
                HStack(spacing: Spacing.small) {
                    if content.showsConnections { connections(vertical: false) }
                    Spacer(minLength: Spacing.small)
                    buttons
                }
            }
        }
        .padding(Spacing.medium)
        .background(
            content.kind == .yourTurn ? Palette.machineTranslatedTint : Palette.raised,
            in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("studio.autopilot")
    }

    private var icon: some View {
        Image(systemName: "camera")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Palette.machineTranslated)
            .frame(width: 34, height: 34)
            .background(Palette.machineTranslatedTint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
            .accessibilityHidden(true)
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            HStack(spacing: Spacing.small) {
                Text(content.title)
                    .font(.headline)
                    .accessibilityIdentifier("studio.autopilot.title")
                if let pill = content.pill {
                    Pill(text: pill, style: content.pillStyle)
                        .accessibilityIdentifier("studio.autopilot.pill")
                }
            }
            Text(content.text)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("studio.autopilot.text")
            if let progress = content.progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 420)
                    .accessibilityLabel(Text("Autopilot progress"))
                    .accessibilityIdentifier("studio.autopilot.progress")
            }
        }
        .frame(minWidth: 260, alignment: .leading)
    }

    @ViewBuilder
    private func connections(vertical: Bool) -> some View {
        let layout = vertical ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xxSmall)) : AnyLayout(HStackLayout(spacing: Spacing.xSmall))
        layout {
            AutopilotConnectionPill(
                title: assistant ?? String(localized: "Assistant"),
                status: assistant == nil ? String(localized: "Not connected") : String(localized: "Connected"),
                isConnected: assistant != nil,
                help: String(localized: "Captures in Simulator"),
                action: { perform(.setUpAssistant) }
            )
            .accessibilityIdentifier("studio.autopilot.assistant")
            AutopilotConnectionPill(
                title: designProject?.displayName ?? String(localized: "Design project"),
                status: designProject?.kind.title ?? String(localized: "Connect…"),
                isConnected: designProject != nil,
                help: String(localized: "Designs the template"),
                action: onConnectDesign
            )
            .accessibilityIdentifier("studio.autopilot.designProject")
        }
    }

    private var buttons: some View {
        HStack(spacing: Spacing.small) {
            if let secondary = content.secondary {
                Button(secondary.secondaryTitle) { perform(secondary) }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier(secondary.identifier)
            }
            Button(content.primary.title) { perform(content.primary) }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier(content.primary.identifier)
        }
        .fixedSize()
    }
}
