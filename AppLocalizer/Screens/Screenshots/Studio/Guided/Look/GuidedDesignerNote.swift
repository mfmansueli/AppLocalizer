//
//  GuidedDesignerNote.swift
//  AppLocalizer
//

import SwiftUI

/// Anything to tell the designer? Optional words, quick additions, and
/// images or videos the person likes. Sent with the brief for the
/// screenshots' looks and the header alike.
struct GuidedDesignerNote: View {
    @Bindable var studio: ScreenshotStudioModel
    let direction: AutopilotArtworkDirection
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("\(Text("Anything to tell the designer?").fontWeight(.semibold)) \(Text("Optional").foregroundStyle(Palette.label2))")
                .font(.callout)
            TextField(
                String(localized: "Notes for the designer"), text: $text,
                prompt: Text("e.g. clean and premium, in the icon’s colors; show the main screen first"),
                axis: .vertical
            )
            .lineLimit(2...5)
            .textFieldStyle(.roundedBorder)
            .labelsHidden()
            .accessibilityLabel(Text("Notes for the designer"))
            .accessibilityIdentifier("autopilot.guided.look.note")
            .onChange(of: text) { _, new in
                if new != direction.text { studio.setArtworkText(new) }
            }
            HStack(alignment: .center, spacing: Spacing.xSmall) {
                FlowLayout(spacing: Spacing.xSmall) {
                    ForEach(Array(AutopilotArtworkDirection.additions.enumerated()), id: \.offset) { index, addition in
                        Button {
                            studio.addArtworkAddition(addition)
                        } label: {
                            Pill(text: "+ " + addition, style: .outline)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Add “\(addition)”"))
                        .accessibilityIdentifier("autopilot.guided.look.note.add.\(index)")
                    }
                    ForEach(direction.references) { reference in
                        HStack(spacing: Spacing.xxSmall) {
                            Text(reference.name).lineLimit(1)
                            Button("✕") { studio.removeArtworkReference(reference) }
                                .buttonStyle(.plain)
                                .opacity(0.7)
                                .accessibilityLabel(Text("Remove \(reference.name)"))
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Palette.accentText)
                        .padding(.horizontal, Spacing.xSmall)
                        .padding(.vertical, 1)
                        .background(Palette.accentTint, in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button("Add Image or Video…") { studio.chooseArtworkReferences() }
                    .controlSize(.small)
                    .help(Text("\(studio.headerDesignerName) takes the feel from them, not the content."))
                    .accessibilityIdentifier("autopilot.guided.look.note.addReference")
            }
            if let error = studio.referenceError {
                Text(error).font(.caption).foregroundStyle(Palette.danger)
            }
        }
        .modifier(GuidedSelectableCard())
        .onAppear { text = direction.text }
        .onChange(of: direction.text) { _, new in
            if new != text { text = new }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.look.noteCard")
    }
}
