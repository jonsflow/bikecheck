//
//  PartTemplateModels.swift
//  bikecheck
//
//  Created on 1/5/26.
//

import Foundation

struct PartTemplateConfig: Codable {
    let version: String
    let categories: [PartCategory]
    let partTemplates: [PartTemplate]

    enum CodingKeys: String, CodingKey {
        case version
        case categories
        case partTemplates = "part_templates"
    }
}

struct PartCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
}

struct PartTemplate: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let defaultIntervalHours: Double
    let icon: String
    let description: String
    let notifyDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case defaultIntervalHours = "default_interval_hours"
        case icon
        case description
        case notifyDefault = "notify_default"
    }
}
