//
//  AutopilotConnectionsList.swift
//  AppLocalizer
//

import SwiftUI

/// Under the stages: the assistant (with its Xcode and simulators), the
/// design source and AppLocalizer.
struct AutopilotConnectionsList: View {
    let run: AutopilotRun
    let assistant: String?
    let designProject: DesignProject?

    /// Pinned under the stages, which scroll: the list stays short.
    private static let detailLineLimit = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            row(
                title: run.client ?? assistant ?? String(localized: "No assistant"),
                detail: run.environment?.summary ?? assistantDetail,
                isOn: assistant != nil || run.client != nil
            )
            if let designProject {
                row(title: designProject.kind.title, detail: designProject.displayName, isOn: true)
            } else {
                row(title: String(localized: "No design project"), detail: String(localized: "Starters, colored from the app icon"), isOn: false)
            }
            row(title: "AppLocalizer", detail: String(localized: "Renders, checks and keeps every version"), isOn: true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.connections")
    }

    private func row(title: String, detail: String, isOn: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
            Circle()
                .fill(isOn ? Palette.positive : Palette.label3)
                .frame(width: 7, height: 7)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(Self.detailLineLimit)
                    .truncationMode(.middle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var assistantDetail: String {
        assistant == nil ? String(localized: "Connect Claude Code, Codex or Cursor to capture") : String(localized: "Connected")
    }
}
