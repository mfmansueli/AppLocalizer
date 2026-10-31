//
//  ConnectDesignProjectSheet.swift
//  AppLocalizer
//

import SwiftUI
import UniformTypeIdentifiers

/// Connect a Design Project: Claude Design (recommended), a Figma file, a
/// brand folder, or AppLocalizer's starters; the system or project, what
/// was found, and how it connects.
struct ConnectDesignProjectSheet: View {
    @Bindable var studio: ScreenshotStudioModel
    @State private var kind: DesignProjectKind = .claudeDesign
    @State private var link = ""
    @State private var createsInClaudeDesign = true
    @State private var summary: DesignSourceSummary?
    @State private var findMessage: String?
    @State private var isPickingFolder = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text("Connect a Design Project").font(.title2.weight(.semibold)).accessibilityAddTraits(.isHeader)
                        Text("The design AI makes \(studio.app.name)’s screenshot template in your brand. The result is an AppLocalizer template, so you can still edit it here.")
                            .font(.callout)
                            .foregroundStyle(Palette.label2)
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.small), GridItem(.flexible())], spacing: Spacing.small) {
                        ForEach(DesignProjectKind.allCases) { option in
                            DesignKindCard(kind: option, isSelected: kind == option) {
                                select(option)
                            }
                        }
                    }
                    if kind != .none { source }
                    if kind == .claudeDesign {
                        Toggle("Also create the directions in Claude Design, so I can refine them there", isOn: $createsInClaudeDesign)
                            .toggleStyle(.checkbox)
                            .accessibilityIdentifier("designProject.createInClaudeDesign")
                    }
                    Label {
                        Text(howItConnects).fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "info.circle")
                    }
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .padding(Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                    .accessibilityIdentifier("designProject.howItConnects")
                }
                .padding(Spacing.xLarge)
            }
            Divider()
            HStack {
                Button("Cancel") { studio.isDesignProjectPresented = false }
                    .buttonBorderShape(.capsule)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(kind == .none ? String(localized: "Use Starters") : String(localized: "Connect")) { connect() }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .keyboardShortcut(.defaultAction)
                    .disabled(kind != .none && link.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("designProject.connect")
            }
            .padding(Spacing.large)
        }
        .frame(width: 700, height: 640)
        .onAppear(perform: restore)
        .fileImporter(isPresented: $isPickingFolder, allowedContentTypes: [.folder]) { result in
            guard case let .success(url) = result else { return }
            read(folder: url)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("designProject.sheet")
    }

    private var source: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(sourceTitle).font(.headline)
            HStack(spacing: Spacing.small) {
                TextField(sourcePrompt, text: $link)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("designProject.link")
                Button(kind == .folder ? String(localized: "Choose…") : String(localized: "Find")) { find() }
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("designProject.find")
            }
            if let summary {
                DesignSourceSummaryView(summary: summary)
            } else if let findMessage {
                Text(findMessage)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("designProject.findMessage")
            }
        }
    }

    private var sourceTitle: String {
        switch kind {
        case .claudeDesign: String(localized: "Design system or project")
        case .figma: String(localized: "Figma file")
        case .folder: String(localized: "Folder")
        case .none: ""
        }
    }

    private var sourcePrompt: String {
        switch kind {
        case .claudeDesign: String(localized: "Name or link, e.g. Northpier Brand")
        case .figma: "https://www.figma.com/design/…"
        case .folder: String(localized: "A folder with tokens.json, fonts and an SVG logo")
        case .none: ""
        }
    }

    private var howItConnects: String {
        switch kind {
        case .claudeDesign, .figma:
            String(localized: "How it connects: AppLocalizer gives Claude the brief over MCP (captures, captions, canvas sizes, safe areas, the longest caption in each language). Claude designs with your \(kind == .figma ? String(localized: "Figma file") : String(localized: "design system")) and sends back templates in AppLocalizer’s format. Nothing is uploaded to App Store Connect from here.")
        case .folder:
            String(localized: """
            How it connects: AppLocalizer reads the folder and hands its colors, fonts and logo to the assistant with \
            the brief. The directions come back as AppLocalizer templates.
            """)
        case .none:
            String(localized: "AppLocalizer makes three directions from its starters, colored from the app icon. You can connect a design project any time.")
        }
    }

    private func select(_ option: DesignProjectKind) {
        guard option != kind else { return }
        kind = option
        link = ""
        summary = nil
        findMessage = nil
        if let project = studio.designProject, project.kind == option {
            link = project.link
            summary = project.summary
        }
    }

    private func restore() {
        guard let project = studio.designProject else { return }
        kind = project.kind
        link = project.link
        createsInClaudeDesign = project.createsInClaudeDesign
        summary = project.summary
    }

    private func find() {
        if kind == .folder {
            isPickingFolder = true
            return
        }
        summary = studio.designProject?.link == link ? studio.designProject?.summary : nil
        if summary == nil {
            findMessage = String(localized: "AppLocalizer can’t open \(kind.title) itself: Claude reads “\(link)” when Autopilot designs, and what it finds shows here.")
        }
    }

    private func read(folder: URL) {
        let didAccess = folder.startAccessingSecurityScopedResource()
        defer { if didAccess { folder.stopAccessingSecurityScopedResource() } }
        link = folder.path(percentEncoded: false)
        do {
            summary = try BrandFolderReader.summary(of: folder)
            findMessage = nil
        } catch {
            summary = nil
            findMessage = error.localizedDescription
        }
    }

    private func connect() {
        let project = kind == .none ? nil : DesignProject(
            kind: kind, link: link.trimmingCharacters(in: .whitespaces), createsInClaudeDesign: kind == .claudeDesign && createsInClaudeDesign,
            summary: summary
        )
        studio.autopilot?.setDesignProject(project, for: studio.app.id)
        studio.isDesignProjectPresented = false
    }
}
