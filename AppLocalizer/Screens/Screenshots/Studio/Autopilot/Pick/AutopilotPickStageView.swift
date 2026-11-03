//
//  AutopilotPickStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Pick captures: on Screenshots, each screen's pick with the attempts it
/// was ranked against, per device (iPhone and iPad, iPhone Duo, Apple
/// Watch); on App Preview recording, the raw take and the moments that go
/// in. A click opens the viewer, where another attempt can be used.
struct AutopilotPickStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let isEditable: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                header
                switch studio.currentPickTab(run) {
                case .screenshots: screenshots
                case .recording: AutopilotRecordingTab(studio: studio, run: run, isEditable: isEditable)
                }
            }
            .padding(Spacing.xLarge)
        }
        .accessibilityIdentifier("autopilot.pick")
    }

    private var header: some View {
        HStack(spacing: Spacing.medium) {
            Text("Pick the best captures")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
            let tabs = studio.pickTabs(run)
            if tabs.count > 1 {
                FittingSegmentedPicker(
                    label: String(localized: "Captures"), options: tabs.map { ($0, $0.title) },
                    selection: Binding(get: { studio.currentPickTab(run) }, set: { studio.pickTab = $0 })
                )
                .fixedSize()
                .accessibilityIdentifier("autopilot.pick.tabs")
            }
        }
    }

    @ViewBuilder
    private var screenshots: some View {
        let device = studio.currentPickDevice(run)
        let devices = studio.pickDevices(run)
        HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
            if devices.count > 1 {
                FittingSegmentedPicker(
                    label: String(localized: "Device"), options: devices.map { ($0, $0.title) },
                    selection: Binding(get: { studio.currentPickDevice(run) }, set: { studio.pickDevice = $0 })
                )
                .fixedSize()
                .accessibilityIdentifier("autopilot.pick.device")
            }
            Text(studio.pickNote(run, device: device))
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("autopilot.pick.note")
        }
        AutopilotCapturesToCheck(run: run)
        switch device {
        case .phones:
            LazyVGrid(columns: Self.columns(5), alignment: .leading, spacing: Spacing.medium) {
                ForEach(Array(studio.pickPhoneScreens(run).enumerated()), id: \.element.id) { index, screen in
                    AutopilotPickCard(studio: studio, run: run, screen: screen, index: index)
                }
            }
        case .duo:
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 250), spacing: Spacing.medium, alignment: .topLeading)],
                alignment: .leading, spacing: Spacing.medium
            ) {
                ForEach(Array(run.plan.screens.enumerated()), id: \.element.id) { index, screen in
                    AutopilotDuoPickCard(studio: studio, run: run, screen: screen, index: index)
                }
            }
        case .watch:
            HStack(alignment: .top, spacing: 18) {
                ForEach(Array(run.plan.screens(on: .watch).enumerated()), id: \.element.id) { index, screen in
                    AutopilotWatchPickCard(studio: studio, run: run, screen: screen, index: index)
                }
            }
        }
    }

    private static func columns(_ count: Int) -> [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 60), spacing: Spacing.medium, alignment: .topLeading), count: count)
    }
}
