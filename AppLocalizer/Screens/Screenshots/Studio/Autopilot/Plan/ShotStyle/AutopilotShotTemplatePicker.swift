//
//  AutopilotShotTemplatePicker.swift
//  AppLocalizer
//

import SwiftUI

/// Choose Templates…, over the Autopilot sheet: the twelve gallery
/// templates previewed with the app's own captions and captures, filtered
/// by style. Pick picks up to three, numbered in order (a fourth replaces
/// the last); Remove takes one out. The template in use says so.
struct AutopilotShotTemplatePicker: View {
    @Bindable var studio: ScreenshotStudioModel
    @Environment(\.dismiss) private var dismiss
    @State private var style: TemplateStarter.Style?

    private let columns = [GridItem(.adaptive(minimum: 248), spacing: 14, alignment: .top)]

    private var screenshots: ScreenshotsViewModel { studio.screenshots }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Screenshot Templates")
                    .font(.title2.weight(.semibold))
                Text(studio.shotTemplatePickerNote)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("autopilot.shotTemplatePicker.note")
            }
            .padding([.horizontal, .top], Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            HStack(spacing: Spacing.small) {
                TemplateStyleFilter(style: $style)
                Spacer(minLength: Spacing.small)
                Text(screenshots.galleryCount(in: style))
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
                    .accessibilityIdentifier("autopilot.shotTemplatePicker.count")
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            ScrollView {
                grid
                    .padding(.horizontal, Spacing.xLarge)
                    .padding(.bottom, Spacing.large)
            }
            Divider()
            HStack(spacing: Spacing.small) {
                Text(studio.shotTemplatesPickedText)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .layoutPriority(1)
                    .accessibilityIdentifier("autopilot.shotTemplatePicker.picked")
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("autopilot.shotTemplatePicker.done")
            }
            .padding(Spacing.large)
        }
        // Three cards to a row, inside the Autopilot sheet (at least 960 pt).
        .frame(width: 880)
        .frame(minHeight: 440, idealHeight: 600, maxHeight: 700)
        .task { await screenshots.renderStarterPreviews() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.shotTemplatePicker")
    }

    private var grid: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
            ForEach(TemplateStarter.starters(in: style)) { starter in
                let number = studio.shotTemplateNumber(starter)
                TemplateGalleryCard(
                    starter: starter,
                    images: screenshots.starterImages(starter),
                    fontNote: screenshots.starterFontNote(starter),
                    isInUse: screenshots.document?.template?.starter == starter,
                    buttonTitle: number == nil ? String(localized: "Pick") : String(localized: "Remove"),
                    isProminent: number == nil,
                    pickNumber: number
                ) {
                    studio.toggleShotTemplate(starter)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.shotTemplatePicker.grid")
    }
}
