//
//  DebugReviewData.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Pending changes and push history for the Review & Push DEBUG scenes, as
/// the design shows them: Lumen Plus Annual's recommended prices, machine
/// translations, Claude Code's proposals and three past pushes.
enum DebugReviewData {
    typealias AppIDs = DebugFixtures.AppID

    static let annualGroup = String(localized: "Subscription Pricing · Lumen Plus Annual")
    static let annualID = "6450100002"
    static let scheduleNote = String(localized: "Prices change as soon as Apple processes them · existing subscribers keep their price")
    static let versionGroup = String(localized: "Store Page · version 1.4")

    /// One recommended price in the sample data.
    private struct PriceRow {
        var territory: String
        var alpha2: String
        var alpha3: String
        var old: String
        var new: String
        var delta: Int

        init(_ territory: String, _ alpha2: String, _ alpha3: String, _ old: String, _ new: String, _ delta: Int) {
            self.territory = territory
            self.alpha2 = alpha2
            self.alpha3 = alpha3
            self.old = old
            self.new = new
            self.delta = delta
        }
    }

    /// One Claude Code proposal in the sample data.
    private struct Proposal {
        var locale: String
        var region: String
        var field: String
        var text: String

        init(_ locale: String, _ region: String, _ field: String, _ text: String) {
            self.locale = locale
            self.region = region
            self.field = field
            self.text = text
        }
    }

    private static let annualPrices: [PriceRow] = [
        PriceRow("Canada", "CA", "CAN", "CA$ 55.99", "CA$ 47.49", -15),
        PriceRow("Mexico", "MX", "MEX", "MX$ 549.00", "MX$ 439.00", -20),
        PriceRow("Brazil", "BR", "BRA", "R$ 219,90", "R$ 109,90", -50),
        PriceRow("Argentina", "AR", "ARG", "$39.99", "$17.99", -55),
        PriceRow("Chile", "CL", "CHL", "CLP 37.900", "CLP 20.900", -45),
        PriceRow("Colombia", "CO", "COL", "COP 164.900", "COP 65.990", -60),
        PriceRow("Peru", "PE", "PER", "S/ 149.90", "S/ 71.90", -52),
        PriceRow("Ecuador", "EC", "ECU", "$39.99", "$19.99", -50),
        PriceRow("Bolivia", "BO", "BOL", "$39.99", "$13.99", -65),
        PriceRow("Paraguay", "PY", "PRY", "$39.99", "$14.99", -63),
        PriceRow("Uruguay", "UY", "URY", "$39.99", "$27.99", -30),
        PriceRow("Venezuela", "VE", "VEN", "$39.99", "$17.99", -55),
        PriceRow("Costa Rica", "CR", "CRI", "$39.99", "$24.99", -38),
        PriceRow("Panama", "PA", "PAN", "$39.99", "$19.99", -50),
        PriceRow("Guatemala", "GT", "GTM", "$39.99", "$18.99", -53),
        PriceRow("Honduras", "HN", "HND", "$39.99", "$17.99", -55),
        PriceRow("El Salvador", "SV", "SLV", "$39.99", "$18.99", -53),
        PriceRow("Nicaragua", "NI", "NIC", "$39.99", "$16.99", -58),
        PriceRow("Dominican Republic", "DO", "DOM", "$39.99", "$19.99", -50),
        PriceRow("India", "IN", "IND", "₹2,499", "₹999", -60),
        PriceRow("Indonesia", "ID", "IDN", "Rp 639.000", "Rp 199.000", -69),
        PriceRow("Philippines", "PH", "PHL", "₱2,290.00", "₱869.00", -62),
        PriceRow("Türkiye", "TR", "TUR", "₺1.299,99", "₺499,99", -62),
        PriceRow("Egypt", "EG", "EGY", "E£1,999.99", "E£749.99", -63),
        PriceRow("Pakistan", "PK", "PAK", "Rs 11,900", "Rs 3,900", -67),
        PriceRow("Vietnam", "VN", "VNM", "1.090.000 ₫", "399.000 ₫", -63),
    ]

    /// Apple's refusals in the partial-failure scene: Chile and Venezuela.
    static let partialFailures: [String: AppStoreConnectError] = [
        "CHL": .rejected(statusCode: 409, code: "ENTITY_ERROR.RELATIONSHIP.INVALID", detail: "The price point is not available for this territory."),
        "VEN": .rejected(statusCode: 409, code: "ENTITY_ERROR.ATTRIBUTE.INVALID", detail: "An attribute value is not acceptable for the current resource."),
    ]

    // MARK: - Pending changes

    /// Lumen's 26 recommended annual prices.
    static var annualPriceChanges: [PendingChange] {
        annualPrices.map { priceChange(app: AppIDs.lumen, row: $0) }
    }

    /// The review scene: Lumen's prices and two machine translations, plus
    /// Habitat's store-page edits under All apps.
    static var reviewChanges: [PendingChange] {
        annualPriceChanges + [
            listingChange(
                locale: "German",
                region: "DE",
                field: "Subtitle",
                old: "Dein ruhiges Tagebuch",
                new: "Ruhiges Tagebuch, täglich",
                source: .machineTranslation
            ),
            listingChange(
                locale: "Japanese",
                region: "JP",
                field: "Promotional Text",
                old: "",
                new: "週ごとの振り返りで、1週間を穏やかにまとめます。",
                source: .machineTranslation
            ),
        ] + DebugWorkspace.pendingChanges
    }

    /// The conflict scene: Brazil changed in App Store Connect since the
    /// last fetch; three more prices wait.
    static var conflictChanges: [PendingChange] {
        let territories: Set = ["Brazil", "Indonesia", "Philippines", "India"]
        return annualPriceChanges
            .filter { territories.contains($0.title) }
            .map { change in
                var change = change
                if change.title == "Brazil" {
                    change.remoteConflict = RemoteConflict(remoteRawValue: "199.9", remoteDisplayValue: "R$ 199,90")
                }
                return change
            } + DebugWorkspace.pendingChanges
    }

    /// Claude Code's store-page proposals for version 1.4, and German What's
    /// New that both the person and Claude Code changed.
    static var assistantChanges: [PendingChange] {
        let claude = ChangeSource.assistant(client: "Claude Code")
        let proposals: [Proposal] = [
            Proposal("English (U.K.)", "GB", "What’s New", "• Weekly reflections: a calm summary of your week • Faster search • Fixes"),
            Proposal("French", "FR", "What’s New", "• Bilans hebdomadaires : un résumé apaisé de votre semaine • Recherche plus rapide"),
            Proposal("Spanish (Spain)", "ES", "What’s New", "• Resúmenes semanales: un repaso tranquilo de tu semana • Búsqueda más rápida"),
            Proposal("Spanish (Mexico)", "MX", "Description", "Lumen es un lugar tranquilo para escribir cada día. Responde una pregunta."),
            Proposal("Portuguese (Brazil)", "BR", "What’s New", "• Reflexões semanais: um resumo tranquilo da sua semana • Busca mais rápida"),
            Proposal("Italian", "IT", "Promotional Text", "Novità: le riflessioni settimanali raccolgono i tuoi momenti migliori."),
            Proposal("Italian", "IT", "What’s New", "• Riflessioni settimanali: un riepilogo sereno della tua settimana"),
            Proposal("Japanese", "JP", "What’s New", "• 週ごとの振り返り：1週間を穏やかにまとめます • 何年分の記録もすばやく検索"),
            Proposal("Korean", "KR", "Name", "Lumen: 매일 일기"),
            Proposal("Korean", "KR", "Subtitle", "나만의 기록, 다정한 질문"),
        ]
        var changes = proposals.map { proposal in
            listingChange(locale: proposal.locale, region: proposal.region, field: proposal.field, old: "", new: proposal.text, source: claude)
        }
        var german = listingChange(
            locale: "German",
            region: "DE",
            field: "What’s New",
            old: "",
            new: "• Neu: Wochenrückblicke\n• Schnellere Suche\n• Fehlerbehebungen",
            source: .you
        )
        german.alternative = ChangeAlternative(
            newValue: "• Wochenrückblicke: eine ruhige Zusammenfassung deiner Woche\n• Schnellere Suche über Jahre an Einträgen",
            source: claude,
            requests: german.requests
        )
        changes.insert(german, at: 1)
        return changes
    }

    // MARK: - History

    /// Three pushes, newest first: Lumen's store page, Habitat's prices with
    /// two failures, and Lumen's prices in three territories.
    static var activityRecords: [PushRecord] {
        let storePage = (1...24).map { index in
            let locales = ["German", "French", "Japanese", "Korean", "Italian", "Spanish (Spain)", "Dutch", "Swedish"]
            let fields = ["Subtitle", "Promotional Text", "What’s New"]
            return listingChange(
                locale: locales[(index - 1) % locales.count],
                region: "DE",
                field: fields[(index - 1) / locales.count],
                old: "Before \(index)",
                new: "After \(index)",
                source: .you
            )
        }
        let habitat = annualPriceChanges.prefix(14).map { change in
            var change = change
            change.appID = AppIDs.habitat
            change.group = String(localized: "Subscription Pricing · Habitat Pro Annual")
            return change
        }
        let habitatFailures = Dictionary(uniqueKeysWithValues: habitat.suffix(2).map {
            ($0.id, "ENTITY_ERROR.RELATIONSHIP.INVALID — The price point is not available for this territory.")
        })
        let lumenPrices = annualPriceChanges.filter { ["Mexico", "Türkiye", "India"].contains($0.title) }
        return [
            PushRecord(
                date: date(month: 10, day: 12, hour: 14, minute: 32),
                appID: AppIDs.lumen,
                appName: "Lumen Journal",
                title: String(localized: "Store Page · 24 texts in 8 locales"),
                pushed: storePage
            ),
            PushRecord(
                date: date(month: 9, day: 30, hour: 9, minute: 10),
                appID: AppIDs.habitat,
                appName: "Habitat — Plant Care",
                title: String(localized: "Subscription Pricing · 14 territories"),
                pushed: Array(habitat.prefix(12)),
                failures: habitatFailures,
                failedChanges: Array(habitat.suffix(2))
            ),
            PushRecord(
                date: date(month: 7, day: 14, hour: 17, minute: 5),
                appID: AppIDs.lumen,
                appName: "Lumen Journal",
                title: String(localized: "Subscription Pricing · Mexico, Türkiye, India"),
                pushed: lumenPrices
            ),
        ]
    }

    // MARK: - Builders

    private static func priceChange(app: StoreApp.ID, row: PriceRow) -> PendingChange {
        PendingChange(
            id: "price.\(annualID).\(row.alpha3)",
            appID: app,
            section: .subscriptionPricing,
            group: annualGroup,
            groupID: annualID,
            groupNote: scheduleNote,
            title: row.territory,
            flagRegion: row.alpha2,
            oldValue: row.old,
            newValue: row.new,
            deltaPercent: row.delta,
            source: .suggestion,
            requests: [priceRequest(alpha3: row.alpha3, pricePoint: "new")],
            restoreRequests: [priceRequest(alpha3: row.alpha3, pricePoint: "old")]
        )
    }

    private static func priceRequest(alpha3: String, pricePoint: String) -> PushRequest {
        let body = """
        {"data":{"type":"subscriptionPrices","attributes":{"preserveCurrentPrice":true},"relationships":{\
        "subscription":{"data":{"type":"subscriptions","id":"\(annualID)"}},\
        "territory":{"data":{"type":"territories","id":"\(alpha3)"}},\
        "subscriptionPricePoint":{"data":{"type":"subscriptionPricePoints","id":"\(alpha3)-\(pricePoint)"}}}}}
        """
        return PushRequest(method: .post, path: "/v1/subscriptionPrices", body: Data(body.utf8))
    }

    private static func listingChange(locale: String, region: String, field: String, old: String, new: String, source: ChangeSource) -> PendingChange {
        let path = "/v1/appStoreVersionLocalizations/debug-lumen-\(region)"
        return PendingChange(
            id: "listing.debug-lumen-14.\(locale).\(field)",
            appID: AppIDs.lumen,
            section: .storePage,
            group: versionGroup,
            title: "\(locale) · \(field)",
            flagRegion: region,
            oldValue: old,
            newValue: new,
            source: source,
            requests: [PushRequest(method: .patch, path: path, body: Data("{\"field\":\"\(field)\"}".utf8))],
            restoreRequests: [PushRequest(method: .patch, path: path, body: Data("{\"field\":\"\(field)\",\"restore\":true}".utf8))]
        )
    }

    private static func date(month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = .current
        components.year = 2026
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date ?? .now
    }
}
#endif
