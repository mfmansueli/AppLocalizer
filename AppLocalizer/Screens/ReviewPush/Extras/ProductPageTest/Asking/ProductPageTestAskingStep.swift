//
//  ProductPageTestAskingStep.swift
//  AppLocalizer
//

import Foundation

/// One step of asking for the variant, as the sheet lists them while it
/// waits: AppLocalizer asked, the assistant read what to change, designed
/// the image and sent it, then AppLocalizer renders and checks it in every
/// language. Each is done, the one going on, or still to come.
struct ProductPageTestAskingStep: Hashable, Identifiable {
    enum State: String, Hashable {
        case done
        case current
        case upcoming
    }

    /// `asked`, `read`, `design`, `render`.
    var id: String
    var title: String
    var detail: String?
    var state: State

    /// The steps for `request`. `assistant` is "Claude Code", `placement`
    /// "search results", `direction` the chosen direction's name, and
    /// `languageCount` how many languages it's rendered in.
    static func steps(
        for request: ArtworkVariantRequest, assistant: String, placement: String, direction: String?, languageCount: Int
    ) -> [ProductPageTestAskingStep] {
        let idea = request.variantIdea
        let asked = ProductPageTestAskingStep(
            id: "asked", title: String(localized: "Asked \(assistant) for the \(idea) \(placement) image"),
            detail: String(localized: "One idea changed: \(request.controlIdea) → \(idea); the rest stays · \(time(request.askedAt))"),
            state: .done
        )
        let read = if let readAt = request.readAt {
            ProductPageTestAskingStep(id: "read", title: String(localized: "\(assistant) read what to change"), detail: time(readAt), state: .done)
        } else {
            ProductPageTestAskingStep(
                id: "read", title: String(localized: "Waiting for \(assistant) to read what to change"),
                detail: String(localized: "It gets the request from next_step, as design_variant."), state: .current
            )
        }
        let keeps = direction.map { String(localized: "Keeps \($0)’s colours, type and captures; shows \(ArtworkVariantRequest.meaning(of: idea)).") }
            ?? String(localized: "Keeps the colours, type and captures; shows \(ArtworkVariantRequest.meaning(of: idea)).")
        let design = if let receivedAt = request.receivedAt {
            ProductPageTestAskingStep(id: "design", title: String(localized: "\(assistant) sent the \(idea) image"), detail: time(receivedAt), state: .done)
        } else {
            ProductPageTestAskingStep(
                id: "design",
                title: request.readAt == nil ? String(localized: "\(assistant) designs it") : String(localized: "\(assistant) is designing it"),
                detail: keeps, state: request.readAt == nil ? .upcoming : .current
            )
        }
        let count = request.languageCount ?? languageCount
        let render = if request.receivedAt != nil {
            ProductPageTestAskingStep(
                id: "render", title: String(localized: "Rendering and checking it in \(count) languages"),
                detail: String(localized: "\(min(request.renderedCount ?? 0, count)) of \(count) done · Apple’s rules, safe area and contrast"),
                state: .current
            )
        } else {
            ProductPageTestAskingStep(
                id: "render", title: String(localized: "AppLocalizer renders it in \(count) languages and checks it"),
                detail: String(localized: "Apple’s rules, safe area and contrast, like the current image"), state: .upcoming
            )
        }
        return [asked, read, design, render]
    }

    /// "21:53".
    private static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
