//
//  MCPDirectionTemplate.swift
//  AppLocalizer
//

import Foundation

/// A direction's template from a tool's arguments: `template` (the JSON
/// get_template returns, whole or in part) and/or `ops`, laid on a base —
/// a starter, or the direction being revised — and checked field by field
/// like an edit in the template editor.
@MainActor
enum MCPDirectionTemplate {
    static func template(_ arguments: MCPToolArguments, base: ScreenshotTemplate, fonts: ScreenshotFontCatalog) throws -> ScreenshotTemplate {
        var operations: [TemplateOperation] = []
        if let object = try arguments.optionalObject("template") {
            operations += self.operations(from: .object(object), over: base)
        }
        if let ops = try arguments.optionalArray("ops") {
            operations += try TemplateOperation.mcpOperations(from: .array(ops), argument: "ops")
        }
        guard !operations.isEmpty || arguments.values["base"] != nil else {
            throw MCPToolError.invalidArgument(name: "template", expected: String(localized: "a template (as get_template returns it), ops, or a base starter"))
        }
        switch TemplateOperationApplier(fonts: fonts).applying(operations, to: base) {
        case let .success(template): return template
        case let .failure(refusals): throw MCPToolError.invalidArgument(name: "template", expected: refusals.summary)
        }
    }

    /// Replace operations for every field the JSON sets differently from
    /// `base`, in the schema's fields only.
    static func operations(from json: JSONValue, over base: ScreenshotTemplate) -> [TemplateOperation] {
        TemplateSchema.rules.keys.sorted().compactMap { path in
            let components = path.split(separator: ".").map(String.init)
            guard let value = json.value(at: components), !value.isNull else { return nil }
            if let current = base.value(at: path), current.isEquivalent(to: value) { return nil }
            return .replace(path, with: value)
        }
    }

    /// The starter named `base`, sized for the run, or Above.
    static func starter(_ arguments: MCPToolArguments, app: StoreApp, slotCount: Int) throws -> ScreenshotTemplate {
        let name = try arguments.optionalString("base") ?? TemplateStarter.above.rawValue
        guard let starter = TemplateStarter(rawValue: name.lowercased()) else {
            let names = TemplateStarter.allCases.map(\.rawValue).formatted(.list(type: .or))
            throw MCPToolError.invalidArgument(name: "base", expected: names)
        }
        return ScreenshotTemplate.starter(starter, id: app.id, title: app.name, slotCount: slotCount)
    }
}
