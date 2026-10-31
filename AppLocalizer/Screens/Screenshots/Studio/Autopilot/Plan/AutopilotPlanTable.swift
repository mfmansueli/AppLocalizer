//
//  AutopilotPlanTable.swift
//  AppLocalizer
//

import SwiftUI

/// The plan's screens: name, how the assistant gets there, and the
/// caption it goes with, grouped by device when Apple Watch or Apple
/// Vision Pro has its own. Every field can be edited until the run starts.
struct AutopilotPlanTable: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    let client: String
    let isEditable: Bool

    /// How many lines a long name, steps or caption wraps to before it
    /// scrolls.
    private static let wrappedLineLimit = 3

    var body: some View {
        VStack(spacing: 0) {
            header
            ForEach(sections, id: \.self) { display in
                section(display)
            }
        }
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.screens")
    }

    /// The set's screens (iPhone and iPad), then each planned device with
    /// its own.
    private var sections: [ScreenshotDisplayType] {
        [.iPhone] + plan.displayTypes.filter(\.hasOwnScreens)
    }

    /// Sections are headed only when a device has its own screens.
    private var isGrouped: Bool { sections.count > 1 }

    @ViewBuilder
    private func section(_ display: ScreenshotDisplayType) -> some View {
        let screens = plan.screens(on: display)
        if isGrouped {
            Divider()
            Text(sectionTitle(display))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.label2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.xSmall)
                .background(Palette.fill1.opacity(0.5))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("autopilot.plan.section.\(display.mcpValue)")
        }
        ForEach(Array(screens.enumerated()), id: \.element.id) { index, screen in
            Divider()
            row(index: index, screen: screen, display: display)
        }
        if screens.isEmpty {
            Divider()
            Text(emptyText(display))
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.medium)
        }
        if isEditable, screens.count < ScreenshotTemplate.maximumSlots {
            Divider()
            Button {
                studio.updatePlan { plan in
                    let count = plan.screens(on: display).count
                    plan.appendScreen(AutopilotScreen(id: newID(display, plan: plan), name: String(localized: "Screen \(count + 1)")), on: display)
                }
            } label: {
                Label("Add Screen", systemImage: "plus")
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .accessibilityIdentifier(display.hasOwnScreens ? "autopilot.plan.addScreen.\(display.mcpValue)" : "autopilot.plan.addScreen")
        }
    }

    /// "iPhone and iPad"; "Apple Watch · paired with the iPhone simulator;
    /// no captions on the watch"; "Apple Vision Pro".
    private func sectionTitle(_ display: ScreenshotDisplayType) -> String {
        switch display {
        case .watch:
            String(localized: "Apple Watch · paired with the iPhone simulator; no captions on the watch")
        case .visionPro:
            ScreenshotDisplayType.visionPro.title
        default:
            plan.displayTypes.filter { !$0.hasOwnScreens }.map(\.shortTitle).formatted(.list(type: .and))
        }
    }

    private func emptyText(_ display: ScreenshotDisplayType) -> String {
        display == .watch
            ? String(localized: "No watch screens yet. Add them here, or \(client) adds the ones it finds in your watch app’s UI tests.")
            : String(localized: "No screens yet. Add them here, or \(client) adds the ones it finds in your UI tests.")
    }

    /// A screen id no device uses yet: `watch-screen-3`.
    private func newID(_ display: ScreenshotDisplayType, plan: AutopilotPlan) -> String {
        let prefix = display.hasOwnScreens ? "\(display.mcpValue)-screen" : "screen"
        var number = plan.screens(on: display).count + 1
        while plan.screen(id: "\(prefix)-\(number)") != nil { number += 1 }
        return "\(prefix)-\(number)"
    }

    private var header: some View {
        HStack(spacing: Spacing.medium) {
            Text("").frame(width: 18)
            Text("Screen").frame(width: 130, alignment: .leading)
            Text("How \(client) gets there").frame(maxWidth: .infinity, alignment: .leading)
            Text("Caption").frame(width: 190, alignment: .leading)
            if isEditable { Text("").frame(width: 18) }
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(Palette.label2)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.fill1)
    }

    private func row(index: Int, screen: AutopilotScreen, display: ScreenshotDisplayType) -> some View {
        let tag = display.hasOwnScreens ? "\(display.mcpValue).\(index)" : "\(index)"
        // Long names and steps wrap instead of being cut at the column's edge.
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
            Text("\(index + 1)")
                .foregroundStyle(Palette.label2)
                .frame(width: 18, alignment: .leading)
            TextField(String(localized: "Name"), text: binding(screen.id, \.name), axis: .vertical)
                .fontWeight(.semibold)
                .lineLimit(1...Self.wrappedLineLimit)
                .frame(width: 130, alignment: .leading)
                .accessibilityIdentifier("autopilot.plan.name.\(tag)")
            TextField(String(localized: "Steps, e.g. tab “Week” → scroll to top"), text: binding(screen.id, \.steps), axis: .vertical)
                .font(.system(.callout, design: .monospaced))
                .lineLimit(1...Self.wrappedLineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("autopilot.plan.steps.\(tag)")
            caption(screen: screen, display: display, tag: tag)
                .frame(width: 190, alignment: .leading)
            if isEditable {
                Button {
                    studio.updatePlan { $0.removeScreen(id: screen.id) }
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
                .frame(width: 18)
                .help(Text("Remove this screen"))
                .accessibilityLabel(Text("Remove \(screen.name)"))
            }
        }
        .textFieldStyle(.plain)
        .disabled(!isEditable)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }

    /// The caption field; Apple Watch has none, and an Apple Vision Pro
    /// window shows its iPhone screen's.
    @ViewBuilder
    private func caption(screen: AutopilotScreen, display: ScreenshotDisplayType, tag: String) -> some View {
        if !display.hasCaptions {
            Text(verbatim: "—")
                .foregroundStyle(Palette.label3)
                .accessibilityLabel(Text("No caption"))
        } else if screen.sourceScreenID != nil {
            Text(plan.caption(of: screen))
                .foregroundStyle(Palette.label2)
                .lineLimit(1)
                .help(Text("The caption of the iPhone screen this window shows"))
                .accessibilityIdentifier("autopilot.plan.caption.\(tag)")
        } else {
            TextField(String(localized: "Caption"), text: binding(screen.id, \.caption), axis: .vertical)
                .lineLimit(1...Self.wrappedLineLimit)
                .accessibilityIdentifier("autopilot.plan.caption.\(tag)")
        }
    }

    private func binding(_ id: String, _ keyPath: WritableKeyPath<AutopilotScreen, String>) -> Binding<String> {
        Binding {
            plan.screen(id: id)?[keyPath: keyPath] ?? ""
        } set: { value in
            studio.updatePlan { $0.updateScreen(id: id) { $0[keyPath: keyPath] = value } }
        }
    }
}
