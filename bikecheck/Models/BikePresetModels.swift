//
//  BikePresetModels.swift
//  bikecheck
//
//  Created by Claude on 2026-02-12.
//

import Foundation

// MARK: - Bike Type

enum BikeType: String, Codable, CaseIterable {
    case fullSuspension = "full_suspension"
    case hardtail = "hardtail"
    case rigid = "rigid"
    case gravel = "gravel"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .fullSuspension:
            return "Full Suspension MTB"
        case .hardtail:
            return "Hardtail MTB"
        case .rigid:
            return "Road Bike"
        case .gravel:
            return "Gravel Bike"
        case .unknown:
            return "Unknown Bike Type"
        }
    }

    var description: String {
        switch self {
        case .fullSuspension:
            return "Mountain bike with front and rear suspension"
        case .hardtail:
            return "Mountain bike with front suspension only"
        case .rigid:
            return "Road bike with no suspension"
        case .gravel:
            return "Gravel bike for mixed terrain"
        case .unknown:
            return "Unable to detect bike type"
        }
    }

    var iconName: String {
        switch self {
        case .fullSuspension:
            return "figure.outdoor.cycle"
        case .hardtail:
            return "figure.mountain.biking"
        case .rigid:
            return "bicycle"
        case .gravel:
            return "figure.rolling"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

// MARK: - Confidence Level

enum DetectionConfidence: String {
    case high       // Exact manufacturer + model match in BikePresets.yaml
    case medium     // Fallback to BikeDatabase.json
    case low        // Generic bike type match
    case fallback   // No match found, manual selection required

    var displayName: String {
        switch self {
        case .high:
            return "High Confidence"
        case .medium:
            return "Medium Confidence"
        case .low:
            return "Low Confidence"
        case .fallback:
            return "Manual Selection"
        }
    }

    var color: String {
        switch self {
        case .high:
            return "green"
        case .medium:
            return "blue"
        case .low:
            return "orange"
        case .fallback:
            return "gray"
        }
    }
}

// MARK: - Detection Result

struct BikeDetectionResult {
    let manufacturer: String?
    let model: String?
    let type: BikeType
    let confidence: DetectionConfidence
    let suggestedIntervals: [String]

    var displayTitle: String {
        if let manufacturer = manufacturer, let model = model {
            return "\(manufacturer) \(model)"
        } else if let manufacturer = manufacturer {
            return manufacturer
        } else {
            return "Bike"
        }
    }

    var displaySubtitle: String {
        return type.displayName
    }
}

// MARK: - Bike Preset Configuration

struct BikePresetConfig: Codable {
    let version: String
    let bikeTypes: [BikeTypeDefinition]
    let manufacturers: [ManufacturerPreset]

    enum CodingKeys: String, CodingKey {
        case version
        case bikeTypes = "bike_types"
        case manufacturers
    }
}

struct BikeTypeDefinition: Codable {
    let type: BikeType
    let name: String
    let defaultIntervals: [String]

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case defaultIntervals = "default_intervals"
    }
}

struct ManufacturerPreset: Codable {
    let id: String
    let name: String
    let aliases: [String]
    let models: [BikeModelPreset]
}

struct BikeModelPreset: Codable {
    let id: String
    let name: String
    let aliases: [String]?
    let type: BikeType
    let intervals: [String]?
}

// MARK: - Bike Database (Fallback)

struct BikeDatabase: Codable {
    let bikeDefinitions: [BikeDefinition]

    enum CodingKeys: String, CodingKey {
        case bikeDefinitions = "bike_definitions"
    }
}

struct BikeDefinition: Codable {
    let manufacturer: String
    let model: String
    let type: String
}
