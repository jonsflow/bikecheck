//
//  PartTemplateService.swift
//  bikecheck
//
//  Created on 1/5/26.
//

import Foundation
import Yams

class PartTemplateService {
    static let shared = PartTemplateService()

    private(set) var config: PartTemplateConfig?

    private init() {
        loadTemplates()
    }

    func loadTemplates() {
        guard let url = Bundle.main.url(forResource: "PartTemplates", withExtension: "yaml") else {
            print("Error: PartTemplates.yaml not found in bundle")
            return
        }

        do {
            let yamlString = try String(contentsOf: url, encoding: .utf8)
            let decoder = YAMLDecoder()
            config = try decoder.decode(PartTemplateConfig.self, from: yamlString)
            print("Loaded \(config?.partTemplates.count ?? 0) part templates")
        } catch {
            print("Error loading part templates: \(error)")
        }
    }

    func getTemplate(id: String) -> PartTemplate? {
        return config?.partTemplates.first { $0.id == id }
    }

    func getAllTemplates() -> [PartTemplate] {
        return config?.partTemplates ?? []
    }

    func getTemplatesByCategory(_ categoryId: String) -> [PartTemplate] {
        return config?.partTemplates.filter { $0.category == categoryId } ?? []
    }

    func getAllCategories() -> [PartCategory] {
        return config?.categories ?? []
    }

    func getCategory(id: String) -> PartCategory? {
        return config?.categories.first { $0.id == id }
    }
}
