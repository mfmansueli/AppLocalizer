//
//  AutopilotDirectionRow.swift
//  AppLocalizer
//

import SwiftUI

/// One direction: five screenshots (and, when the run makes them, its
/// header, search artwork and App Preview poster), name with its source
/// badge, the rationale, language checks and its buttons.
struct AutopilotDirectionRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let direction: AutopilotDirection
    let isChosen: Bool
    let isEditable: Bool
    var stacksDevices = false

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                AutopilotDirectionThumbnails(studio: studio, direction: direction, stacksDevices: stacksDevices) { index in
                    studio.openDirection(direction, at: index)
                }
                if let run = studio.run, !run.plan.alsoMakes.isEmpty {
                    AutopilotDirectionExtras(studio: studio, run: run, direction: direction)
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack(spacing: Spacing.small) {
                    Text(direction.name).font(.headline)
                    Pill(text: "\(direction.source.monogram) \(direction.sourceTitle)", style: .outline)
                    if direction.isRevised {
                        Pill(text: String(localized: "Revised"), style: .machineTranslated)
                            .accessibilityIdentifier("autopilot.direction.revised")
                    }
                }
                Text(direction.rationale)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                if !direction.checks.isEmpty {
                    FlowLayout(spacing: Spacing.xSmall) {
                        ForEach(direction.checks, id: \.self) { check in
                            Pill(text: check.title, style: check.style)
                        }
                    }
                }
                HStack(spacing: Spacing.small) {
                    if let link = direction.link, let url = URL(string: link) {
                        Link(destination: url) {
                            Text("Open in \(direction.sourceTitle) ↗")
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("autopilot.direction.open")
                    }
                    Button(isChosen ? String(localized: "Using This Direction") : String(localized: "Use This Direction")) {
                        studio.useDirection(direction)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isEditable)
                    .accessibilityIdentifier("autopilot.direction.use")
                }
                .buttonBorderShape(.capsule)
                .controlSize(.small)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.medium)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                .strokeBorder(isChosen ? Color.accentColor : Palette.separator, lineWidth: isChosen ? 1.5 : 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.direction.\(direction.id)")
    }

    /// The room the name, rationale, checks and buttons need beside the
    /// thumbnails.
    static let textWidth: CGFloat = 320
}
