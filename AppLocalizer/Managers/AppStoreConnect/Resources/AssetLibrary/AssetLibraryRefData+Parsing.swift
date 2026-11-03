//
//  AssetLibraryRefData+Parsing.swift
//  AppLocalizer
//

import Foundation

extension AssetLibraryRefData {
    /// Parses `GET /v1/appAssetLibraryRefData`'s body. Apple adds fields
    /// and values over time, so it's read leniently: unknown keys are
    /// ignored, an entry that doesn't decode is skipped, a few spellings of
    /// each ID key are accepted (`placementTypeId` or `placementType`), and
    /// `data` may be a list or one resource. Throws
    /// `AppStoreConnectError.unexpectedPayload` only when there's no `data`.
    init(json data: Data) throws {
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { throw AppStoreConnectError.unexpectedPayload }
        self.init(specs: payload.specs, mappings: payload.mappings, groupLimits: payload.groupLimits)
    }

    private struct Payload: Decodable {
        var specs: [AssetLibrarySpec] = []
        var mappings: [AssetLibrarySpecMapping] = []
        var groupLimits: [AssetLibraryGroupLimit] = []

        init(from decoder: any Decoder) throws {
            let fields = try Fields(decoder)
            guard fields.container.contains(AnyKey("data")) else { throw Fields.missing }
            for attributes in fields.list(Datum.self, "data").compactMap(\.attributes) {
                specs += attributes.imageSpecs.map { $0.spec(media: .image) } + attributes.videoSpecs.map { $0.spec(media: .video) }
                mappings += attributes.placementTypes.flatMap(\.mappings)
                groupLimits += attributes.features.flatMap(\.limits)
            }
        }
    }

    private struct Datum: Decodable {
        var attributes: Attributes?

        init(from decoder: any Decoder) throws {
            attributes = try Fields(decoder).object(Attributes.self, "attributes")
        }
    }

    private struct Attributes: Decodable {
        var features: [Feature]
        var imageSpecs: [Spec]
        var videoSpecs: [Spec]
        var placementTypes: [PlacementType]

        init(from decoder: any Decoder) throws {
            let fields = try Fields(decoder)
            features = fields.list(Feature.self, "features")
            imageSpecs = fields.list(Spec.self, "imageSpecs")
            videoSpecs = fields.list(Spec.self, "videoSpecs")
            placementTypes = fields.list(PlacementType.self, "placementTypes")
        }
    }

    /// `features[]`: a feature (`APP_STORE_VERSIONS`, …) and its placement
    /// policies' group limits.
    private struct Feature: Decodable {
        var limits: [AssetLibraryGroupLimit]

        init(from decoder: any Decoder) throws {
            let fields = try Fields(decoder)
            let feature = fields.string("featureId", "id")
            limits = fields.list(Policy.self, "placementPolicies").flatMap { policy in
                policy.limits.map { limit in
                    AssetLibraryGroupLimit(feature: feature, placementType: policy.placementType, groupIDs: limit.groupIDs, maxCount: limit.maxCount)
                }
            }
        }
    }

    private struct Policy: Decodable {
        var placementType: String?
        var limits: [Limit]

        init(from decoder: any Decoder) throws {
            let fields = try Fields(decoder)
            placementType = fields.string("placementType", "placementTypeId")
            limits = fields.list(Limit.self, "groupLimits")
        }
    }

    private struct Limit: Decodable {
        var groupIDs: [String]
        var maxCount: Int

        init(from decoder: any Decoder) throws {
            let fields = try Fields(decoder)
            guard let maxCount = fields.int("maxCount") else { throw Fields.missing }
            self.maxCount = maxCount
            groupIDs = fields.strings("groupIds", "groupId", "placementGroupIds")
        }
    }

    /// `imageSpecs[]` and `videoSpecs[]`.
    private struct Spec: Decodable {
        var id: String
        var shortName: String?
        var dimensions: Dimensions?
        var aspectRatio: Double?
        var compatiblePlacementTypes: [String]
        var maxFileSize: Int?
        var isUniversal: Bool

        init(from decoder: any Decoder) throws {
            let fields = try Fields(decoder)
            guard let id = fields.string("specId", "id") else { throw Fields.missing }
            self.id = id
            shortName = fields.string("shortName")
            dimensions = fields.object(Dimensions.self, "dimensions")
            aspectRatio = AssetLibrarySpec.ratio(fields.string("aspectRatio"))
            compatiblePlacementTypes = fields.strings("compatiblePlacementTypes")
            maxFileSize = fields.int("maxFileSize")
            isUniversal = fields.bool("universalAsset") ?? false
        }

        func spec(media: AssetLibraryMedia) -> AssetLibrarySpec {
            AssetLibrarySpec(
                id: id, shortName: shortName, media: media,
                minWidth: dimensions?.minWidth, maxWidth: dimensions?.maxWidth, minHeight: dimensions?.minHeight, maxHeight: dimensions?.maxHeight,
                aspectRatio: aspectRatio, compatiblePlacementTypes: compatiblePlacementTypes, maxFileSize: maxFileSize, isUniversal: isUniversal
            )
        }
    }

    private struct Dimensions: Decodable {
        var minWidth: Int?
        var maxWidth: Int?
        var minHeight: Int?
        var maxHeight: Int?

        init(from decoder: any Decoder) throws {
            let fields = try Fields(decoder)
            minWidth = fields.int("minWidth", "width")
            maxWidth = fields.int("maxWidth", "width")
            minHeight = fields.int("minHeight", "height")
            maxHeight = fields.int("maxHeight", "height")
        }
    }

    /// `placementTypes[]`: a placement type and the specs each of its
    /// groups takes.
    private struct PlacementType: Decodable {
        var mappings: [AssetLibrarySpecMapping]

        init(from decoder: any Decoder) throws {
            let fields = try Fields(decoder)
            guard let placementType = fields.string("placementTypeId", "placementType", "id") else { throw Fields.missing }
            mappings = fields.list(Mapping.self, "specMappings").map {
                AssetLibrarySpecMapping(placementType: placementType, placementGroup: $0.group, specIDs: $0.specIDs)
            }
        }
    }

    private struct Mapping: Decodable {
        var group: String
        var specIDs: [String]

        init(from decoder: any Decoder) throws {
            let fields = try Fields(decoder)
            guard let group = fields.string("placementGroupId", "placementGroup", "groupId", "placementProfileGroupId") else { throw Fields.missing }
            self.group = group
            specIDs = fields.list(SpecReference.self, "specs", "specIds").map(\.id)
        }
    }

    /// A spec mapping's entry: the spec ID itself, or an object with it.
    private struct SpecReference: Decodable {
        var id: String

        init(from decoder: any Decoder) throws {
            if let id = try? decoder.singleValueContainer().decode(String.self) {
                self.id = id
            } else if let id = try Fields(decoder).string("specId", "id") {
                self.id = id
            } else {
                throw Fields.missing
            }
        }
    }

    private struct AnyKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }

        init(_ string: String) { stringValue = string }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue _: Int) { nil }
    }

    /// A list that skips the entries that don't decode.
    private struct Lossy<Element: Decodable>: Decodable {
        var elements: [Element] = []

        init(from decoder: any Decoder) throws {
            var container = try decoder.unkeyedContainer()
            while !container.isAtEnd {
                if let element = try? container.decode(Element.self) {
                    elements.append(element)
                } else if (try? container.decode(Skip.self)) == nil {
                    break
                }
            }
        }
    }

    /// Steps over one entry of a list.
    private struct Skip: Decodable {
        init(from _: any Decoder) throws {}
    }

    /// An object's fields, each read without failing the object: the first
    /// of `keys` that decodes wins.
    private struct Fields {
        static var missing: DecodingError {
            DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "A required field is missing."))
        }

        let container: KeyedDecodingContainer<AnyKey>

        init(_ decoder: any Decoder) throws {
            container = try decoder.container(keyedBy: AnyKey.self)
        }

        func string(_ keys: String...) -> String? {
            keys.lazy.compactMap { try? container.decodeIfPresent(String.self, forKey: AnyKey($0)) }.first
        }

        func int(_ keys: String...) -> Int? {
            keys.lazy.compactMap { key in
                (try? container.decodeIfPresent(Int.self, forKey: AnyKey(key)))
                    ?? (try? container.decodeIfPresent(String.self, forKey: AnyKey(key))).flatMap { Int($0) }
            }.first
        }

        func bool(_ key: String) -> Bool? {
            try? container.decodeIfPresent(Bool.self, forKey: AnyKey(key))
        }

        /// A list of strings, or one string as a list of one.
        func strings(_ keys: String...) -> [String] {
            for key in keys {
                if let list = try? container.decodeIfPresent([String].self, forKey: AnyKey(key)) { return list }
                if let one = try? container.decodeIfPresent(String.self, forKey: AnyKey(key)) { return [one] }
            }
            return []
        }

        func object<T: Decodable>(_: T.Type, _ key: String) -> T? {
            try? container.decodeIfPresent(T.self, forKey: AnyKey(key))
        }

        /// A list, skipping entries that don't decode, or one object as a
        /// list of one.
        func list<T: Decodable>(_: T.Type, _ keys: String...) -> [T] {
            for key in keys {
                if let list = try? container.decodeIfPresent(Lossy<T>.self, forKey: AnyKey(key)) { return list.elements }
                if let one = try? container.decodeIfPresent(T.self, forKey: AnyKey(key)) { return [one] }
            }
            return []
        }
    }
}
