//
//  BikeDetectionService.swift
//  bikecheck
//
//  Created by Claude on 2026-02-12.
//

import Foundation
import Yams

class BikeDetectionService {
    static let shared = BikeDetectionService()

    private(set) var presetConfig: BikePresetConfig?
    private(set) var bikeDatabase: BikeDatabase?

    private init() {
        loadPresetConfig()
        loadBikeDatabase()
    }

    // MARK: - Data Loading

    func loadPresetConfig() {
        guard let url = Bundle.main.url(forResource: "BikePresets", withExtension: "yaml") else {
            print("Error: BikePresets.yaml not found in bundle")
            return
        }

        do {
            let yamlString = try String(contentsOf: url, encoding: .utf8)
            let decoder = YAMLDecoder()
            presetConfig = try decoder.decode(BikePresetConfig.self, from: yamlString)
            print("Loaded \(presetConfig?.manufacturers.count ?? 0) manufacturers from BikePresets.yaml")
        } catch {
            print("Error loading bike presets: \(error)")
        }
    }

    func loadBikeDatabase() {
        guard let url = Bundle.main.url(forResource: "BikeDatabase", withExtension: "json") else {
            print("Warning: BikeDatabase.json not found in bundle (optional fallback)")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            bikeDatabase = try decoder.decode(BikeDatabase.self, from: data)
            print("Loaded \(bikeDatabase?.bikeDefinitions.count ?? 0) bikes from BikeDatabase.json")
        } catch {
            print("Error loading bike database: \(error)")
        }
    }

    // MARK: - Main Detection Method

    func detectBike(name: String) -> BikeDetectionResult {
        let normalized = normalizeName(name)

        // Stage 1: Check BikePresets.yaml for exact manufacturer + model
        if let preset = matchBikePreset(normalized: normalized) {
            return BikeDetectionResult(
                manufacturer: preset.manufacturer,
                model: preset.model,
                type: preset.type,
                confidence: .high,
                suggestedIntervals: preset.intervals
            )
        }

        // Stage 2: Model-only match (bike name has no manufacturer prefix)
        if let preset = matchModelOnly(normalized: normalized) {
            return BikeDetectionResult(
                manufacturer: preset.manufacturer,
                model: preset.model,
                type: preset.type,
                confidence: .high,
                suggestedIntervals: preset.intervals
            )
        }

        // Stage 3: Check BikeDatabase.json (220+ bikes)
        if let dbMatch = matchBikeDatabase(normalized: normalized) {
            let intervals = getDefaultIntervalsForType(dbMatch.type)
            return BikeDetectionResult(
                manufacturer: dbMatch.manufacturer,
                model: dbMatch.model,
                type: BikeType(rawValue: dbMatch.type) ?? .unknown,
                confidence: .medium,
                suggestedIntervals: intervals
            )
        }

        // Stage 3: Generic fallback - show type picker
        return BikeDetectionResult(
            manufacturer: nil,
            model: nil,
            type: .unknown,
            confidence: .fallback,
            suggestedIntervals: []
        )
    }

    // MARK: - Name Parsing

    private func normalizeName(_ name: String) -> String {
        return name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ") // Collapse multiple spaces
    }

    private func parseManufacturer(from normalized: String) -> String? {
        guard let config = presetConfig else { return nil }

        // Sort manufacturers by name length (descending) to match longest first
        // This prevents "Giant" from matching "Specialized Giant"
        let sortedManufacturers = config.manufacturers.sorted { $0.name.count > $1.name.count }

        for manufacturer in sortedManufacturers {
            // Check manufacturer name
            if normalized.contains(manufacturer.name.lowercased()) {
                return manufacturer.name
            }

            // Check aliases
            for alias in manufacturer.aliases {
                if normalized.contains(alias.lowercased()) {
                    return manufacturer.name
                }
            }
        }

        return nil
    }

    private func parseModel(from normalized: String, manufacturer: ManufacturerPreset) -> BikeModelPreset? {
        // Sort models by name length (descending) for longest match first
        let sortedModels = manufacturer.models.sorted { $0.name.count > $1.name.count }

        for model in sortedModels {
            // Check model name
            if normalized.contains(model.name.lowercased()) {
                return model
            }

            // Check aliases
            if let aliases = model.aliases {
                for alias in aliases {
                    if normalized.contains(alias.lowercased()) {
                        return model
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Matching Logic

    private func matchBikePreset(normalized: String) -> (manufacturer: String, model: String, type: BikeType, intervals: [String])? {
        guard let config = presetConfig else { return nil }

        // Sort manufacturers by name length (descending)
        let sortedManufacturers = config.manufacturers.sorted { $0.name.count > $1.name.count }

        for manufacturer in sortedManufacturers {
            // Check if manufacturer name or alias is in the bike name
            var manufacturerMatched = false

            if normalized.contains(manufacturer.name.lowercased()) {
                manufacturerMatched = true
            } else {
                for alias in manufacturer.aliases {
                    if normalized.contains(alias.lowercased()) {
                        manufacturerMatched = true
                        break
                    }
                }
            }

            if !manufacturerMatched {
                continue
            }

            // Try to match a model
            if let matchedModel = parseModel(from: normalized, manufacturer: manufacturer) {
                let intervals = matchedModel.intervals ?? getDefaultIntervalsForType(matchedModel.type.rawValue)
                return (
                    manufacturer: manufacturer.name,
                    model: matchedModel.name,
                    type: matchedModel.type,
                    intervals: intervals
                )
            }
        }

        return nil
    }

    private func matchModelOnly(normalized: String) -> (manufacturer: String, model: String, type: BikeType, intervals: [String])? {
        guard let config = presetConfig else { return nil }

        // Collect all models across all manufacturers, sorted by name length descending
        // to prefer longer/more specific matches (e.g. "Turbo Kenevo" over "Kenevo")
        var candidates: [(manufacturer: ManufacturerPreset, model: BikeModelPreset)] = []
        for manufacturer in config.manufacturers {
            for model in manufacturer.models {
                candidates.append((manufacturer, model))
            }
        }
        candidates.sort { ($0.model.name + ($0.model.aliases?.joined() ?? "")).count > ($1.model.name + ($1.model.aliases?.joined() ?? "")).count }

        for candidate in candidates {
            let model = candidate.model
            if normalized.contains(model.name.lowercased()) {
                let intervals = model.intervals ?? getDefaultIntervalsForType(model.type.rawValue)
                return (manufacturer: candidate.manufacturer.name, model: model.name, type: model.type, intervals: intervals)
            }
            if let aliases = model.aliases {
                for alias in aliases {
                    if normalized.contains(alias.lowercased()) {
                        let intervals = model.intervals ?? getDefaultIntervalsForType(model.type.rawValue)
                        return (manufacturer: candidate.manufacturer.name, model: model.name, type: model.type, intervals: intervals)
                    }
                }
            }
        }

        return nil
    }

    private func matchBikeDatabase(normalized: String) -> BikeDefinition? {
        guard let database = bikeDatabase else { return nil }

        // Sort by manufacturer + model length (descending) for longest match first
        let sortedDefinitions = database.bikeDefinitions.sorted {
            ($0.manufacturer + $0.model).count > ($1.manufacturer + $1.model).count
        }

        for definition in sortedDefinitions {
            let manufacturerNorm = definition.manufacturer.lowercased()
            let modelNorm = definition.model.lowercased()

            // Check if both manufacturer and model are present
            if normalized.contains(manufacturerNorm) && normalized.contains(modelNorm) {
                return definition
            }
        }

        return nil
    }

    // MARK: - Helper Methods

    func getDefaultIntervalsForType(_ typeString: String) -> [String] {
        guard let config = presetConfig else {
            return ["chain", "fork_lowers", "rear_shock"]
        }

        // Find matching bike type definition
        for bikeType in config.bikeTypes {
            if bikeType.type.rawValue == typeString {
                return bikeType.defaultIntervals
            }
        }

        // Fallback based on type string
        if typeString.contains("full") {
            return ["chain", "fork_lowers", "rear_shock", "dropper_post", "brake_pads"]
        } else if typeString.contains("hard") {
            return ["chain", "fork_lowers", "brake_pads"]
        } else {
            return ["chain", "cassette", "brake_pads", "grips_tape"]
        }
    }

    func getDefaultIntervalsForType(_ type: BikeType) -> [String] {
        return getDefaultIntervalsForType(type.rawValue)
    }
}
