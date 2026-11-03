//
//  AutopilotArtworkDirectionBox.swift
//  AppLocalizer
//

import SwiftUI

/// Expected result: what the person expects of the header and search
/// artwork, in words (with quick additions) and in images or videos they
/// like. Sent to Claude Design with the brief.
struct AutopilotArtworkDirectionBox: View {
    @Bindable var studio: ScreenshotStudioModel
    let direction: AutopilotArtworkDirection
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text("\(Text("Expected result").fontWeight(.semibold)) \(Text(direction.summary).foregroundStyle(Palette.label2))")
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("autopilot.plan.artworkDirection.summary")
                Button(studio.showsArtworkDirection ? "Hide" : "Describe the Result…") {
                    studio.showsArtworkDirection.toggle()
                }
                .controlSize(.small)
                .accessibilityValue(Text(studio.showsArtworkDirection ? "Expanded" : "Collapsed"))
                .accessibilityIdentifier("autopilot.plan.artworkDirection.toggle")
            }
            if studio.showsArtworkDirection {
                TextField(
                    String(localized: "Describe the expected header and search artwork"), text: $text,
                    prompt: Text("e.g. a calm night sky over hills, the moon rising behind the name; for search, a hand holding the phone on the Today screen"),
                    axis: .vertical
                )
                .lineLimit(2...5)
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .accessibilityLabel(Text("Describe the expected header and search artwork"))
                .accessibilityIdentifier("autopilot.plan.artworkDirection.text")
                .onChange(of: text) { _, new in
                    if new != direction.text { studio.setArtworkText(new) }
                }
                FlowLayout(spacing: 6) {
                    Text("Add:").font(.caption).foregroundStyle(Palette.label2)
                    ForEach(Array(AutopilotArtworkDirection.additions.enumerated()), id: \.offset) { index, addition in
                        Button {
                            studio.addArtworkAddition(addition)
                        } label: {
                            Pill(text: addition, style: .outline)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("autopilot.plan.artworkDirection.add.\(index)")
                    }
                }
                FlowLayout(spacing: 6) {
                    Text("References:").font(.caption).foregroundStyle(Palette.label2)
                    ForEach(direction.references) { reference in
                        HStack(spacing: 4) {
                            Text(reference.name).lineLimit(1)
                            Button("✕") { studio.removeArtworkReference(reference) }
                                .buttonStyle(.plain)
                                .opacity(0.7)
                                .accessibilityLabel(Text("Remove \(reference.name)"))
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Palette.accentText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Palette.accentTint, in: Capsule())
                    }
                    Button("Add Image or Video…") { studio.chooseArtworkReferences() }
                        .controlSize(.small)
                        .accessibilityIdentifier("autopilot.plan.artworkDirection.addReference")
                }
                Text("""
                Claude Design takes the feel from them, not the content. Sent with the brief; you can change it later \
                with “Ask for changes” on each direction.
                """)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                if let error = studio.referenceError {
                    Text(error).font(.caption).foregroundStyle(Palette.danger)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, Spacing.small)
        .background(Palette.content, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .onAppear { text = direction.text }
        .onChange(of: direction.text) { _, new in
            if new != text { text = new }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.artworkDirection")
    }
}
