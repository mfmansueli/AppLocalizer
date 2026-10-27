//
//  AssistantDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// The `ai-*` DEBUG scenes: Lumen with Claude Code paired and connected.
/// - `ai-translate`: Translate Missing with "Your AI assistant" chosen, the
///   prompt copied and the sheet waiting.
/// - `ai-streaming`: the coverage grid while proposals stream in (Chinese
///   and Dutch just added, still empty), and the toolbar indicator spinning.
/// - `ai-review`: Review & Push filtered to Claude Code's proposals.
/// - `ai-conflict`: Review & Push with German What's New changed by both
///   the person and Claude Code.
/// - `overview-ai`: the Overview while Claude Code works.
enum AssistantDebugScenes {
    static let ids = ["ai-translate", "ai-streaming", "ai-review", "ai-conflict", "overview-ai"]

    static let client = StorePageSampleData.assistantClient

    @MainActor
    static func view(for id: String) -> AnyView? {
        switch id {
        case "ai-translate":
            connected(StorePageDebugScenes.scene { model in
                for locale in StorePageSampleData.addedLocales {
                    model.addLocale(locale)
                }
                model.mode = .coverage
                model.translation.glossary = StorePageSampleData.glossary
                model.presentTranslate()
                model.translation.provider = .assistant
                model.translation.isAssistantPromptCopied = true
            })
        case "ai-streaming":
            connected(StorePageDebugScenes.scene(pending: streamedProposals) { model in
                model.addLocale(.chineseSimplified)
                model.addLocale(.dutch)
                model.mode = .coverage
            }, working: true)
        case "ai-review":
            connected(DebugMainScene(section: .storePage, pendingChanges: DebugReviewData.assistantChanges, presentedSheet: .proposals(client: client)))
        case "ai-conflict":
            connected(DebugMainScene(section: .storePage, pendingChanges: DebugReviewData.assistantChanges, presentedSheet: .review))
        case "overview-ai":
            connected(DebugMainScene(section: .overview, pendingChanges: DebugWorkspace.pendingChanges + streamedProposals), working: true)
        default:
            nil
        }
    }

    /// Claude Code's proposals so far: What's New in nine locales, the
    /// Italian promotional text, the Mexican Spanish description, and
    /// Korean's name, subtitle and privacy policy URL.
    static var streamedProposals: [PendingChange] {
        var listing = StorePageSampleData.fetchedListing
        listing.addLocale(.korean)
        let whatsNew: [(StoreLocale, String)] = [
            (.englishUK, "• Weekly reflections: a calm summary of your week • Faster search • Fixes"),
            (.arabic, "• ملخص أسبوعي هادئ لأسبوعك • بحث أسرع • إصلاحات"),
            (.french, "• Bilans hebdomadaires : un résumé apaisé de votre semaine • Recherche plus rapide"),
            (.german, "• Wochenrückblicke: eine ruhige Zusammenfassung deiner Woche • Schnellere Suche"),
            (.italian, "• Riflessioni settimanali: un riepilogo sereno della tua settimana"),
            (.japanese, "• 週ごとの振り返り：1週間を穏やかにまとめます • 検索がより速く"),
            (.portugueseBrazil, "• Reflexões semanais: um resumo tranquilo da sua semana • Busca mais rápida"),
            (.spanishMexico, "• Resúmenes semanales: un repaso tranquilo de tu semana • Búsqueda más rápida"),
            (.spanishSpain, "• Resúmenes semanales: un repaso tranquilo de tu semana • Búsqueda más rápida"),
        ]
        for (locale, text) in whatsNew {
            _ = listing.propose(text, for: .whatsNew, in: locale, by: client)
        }
        _ = listing.propose("Novità: le riflessioni settimanali raccolgono i tuoi momenti migliori.", for: .promotionalText, in: .italian, by: client)
        _ = listing.propose("Lumen es un lugar tranquilo para escribir cada día. Responde una pregunta.", for: .description, in: .spanishMexico, by: client)
        _ = listing.propose("Lumen: 매일 일기", for: .name, in: .korean, by: client)
        _ = listing.propose("나만의 기록, 다정한 질문", for: .subtitle, in: .korean, by: client)
        _ = listing.propose("https://lumen.example/ko/privacy", for: .privacyPolicyURL, in: .korean, by: client)
        return DebugStorePageContent.pendingChanges(for: listing)
    }

    /// `content` with Claude Code connected, and working when `working`.
    @MainActor
    private static func connected(_ content: some View, working: Bool = false) -> AnyView {
        AnyView(content.modifier(Connected(isWorking: working)))
    }

    /// Puts the MCP server in the paired state once the scene appears.
    private struct Connected: ViewModifier {
        let isWorking: Bool
        @Environment(MCPServerController.self) private var assistants

        func body(content: Content) -> some View {
            content.task {
                AssistantsDebugState.paired.apply(to: assistants)
                if isWorking { assistants.noteWorking(client: AssistantDebugScenes.client, for: .seconds(24 * 60 * 60)) }
            }
        }
    }
}
#endif
