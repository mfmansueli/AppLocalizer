//
//  AutopilotConceptsBox.swift
//  AppLocalizer
//

import SwiftUI

/// Design's header concepts, as they arrive: each row fills in with its
/// name, where it came from, its metaphor and why it fits, and with Motion
/// loop its loop's beats, as soon as its idea is sent; its still follows as
/// soon as a page passes render_artwork, and, when each concept is
/// animated, its loop plays once it's in.
struct AutopilotConceptsBox: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun

    var body: some View {
        let concepts = run.conceptList
        let count = max(run.expectedConcepts, concepts.count)
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, Spacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.fill1)
                .accessibilityAddTraits(.isHeader)
            ForEach(0..<count, id: \.self) { index in
                if index > 0 { Divider() }
                row(concepts.indices.contains(index) ? concepts[index] : nil, index: index)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.design.concepts")
    }

    /// "Header concepts from Claude Design", "Header concepts, from your
    /// templates".
    private var title: String {
        run.plan.alsoMakes.artworkStyle == .free
            ? String(localized: "Header concepts from \(run.designKind.usesDesignAI ? run.designKind.title : DesignProjectKind.claudeDesign.title)")
            : String(localized: "Header concepts, from your templates")
    }

    private func row(_ concept: AutopilotArtworkConcept?, index: Int) -> some View {
        let kind = run.plan.artworkKinds.first ?? .header
        return HStack(alignment: .center, spacing: 12) {
            Button {
                if let concept { studio.openConcept(concept, at: 0) }
            } label: {
                AutopilotConceptThumbnail(
                    studio: studio, run: run, concept: concept, kind: kind, width: 150, plays: concept.map(run.playsLoop) ?? false
                )
            }
            .buttonStyle(.plain)
            .disabled(concept?.stillDesign == nil)
            .help(Text("Click to view larger"))
            .accessibilityLabel(Text(concept.map { "View \($0.name) larger" } ?? ""))
            VStack(alignment: .leading, spacing: 2) {
                if let concept {
                    Text("\(Text(concept.name).fontWeight(.semibold)) \(Text(concept.sourceTitle).font(.caption).foregroundStyle(Palette.label2))")
                        .font(.callout)
                    Text([concept.metaphor, concept.fitsBecause].filter { !$0.isEmpty }.joined(separator: " "))
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                    if run.plan.alsoMakes.makesMotion, let loop = concept.loopLine {
                        Text(loop).font(.caption).foregroundStyle(Palette.label2)
                    }
                    if run.conceptsToAnimate.contains(where: { $0.id == concept.id }) {
                        HStack(spacing: Spacing.xSmall) {
                            if studio.assistantIsWorking { ProgressView().controlSize(.mini) }
                            Text("\(run.designKind.title) is animating its \(AutopilotArtworkMotion.loopSeconds)-second loop…")
                        }
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("autopilot.design.concept.animating")
                    }
                } else {
                    HStack(spacing: Spacing.small) {
                        if studio.assistantIsWorking { ProgressView().controlSize(.small) }
                        Text(placeholder(index)).foregroundStyle(Palette.label2)
                    }
                    .font(.callout)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("autopilot.design.concept.\(index)")
    }

    /// "Concept 2 · from the Layered Landscape template".
    private func placeholder(_ index: Int) -> String {
        let extras = run.plan.alsoMakes
        if extras.artworkStyle == .templates, extras.headerTemplates.indices.contains(index) {
            return String(localized: "Concept \(index + 1) · from the \(extras.headerTemplates[index].name) template")
        }
        return String(localized: "Concept \(index + 1)")
    }
}
