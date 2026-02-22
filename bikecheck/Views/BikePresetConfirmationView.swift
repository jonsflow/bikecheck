//
//  BikePresetConfirmationView.swift
//  bikecheck
//
//  Created by Claude on 2026-02-12.
//

import SwiftUI

struct BikePresetConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BikeDetailViewModel

    let detectionResult: BikeDetectionResult
    let bike: Bike

    @State private var selectedIntervals: Set<String>
    @State private var lastServiceDate: Date = Date()
    @State private var showingTypeSelection = false
    @State private var manuallySelectedType: BikeType? = nil
    @State private var step = 1  // 1 = parts selection, 2 = date picker

    init(detectionResult: BikeDetectionResult, bike: Bike, viewModel: BikeDetailViewModel) {
        self.detectionResult = detectionResult
        self.bike = bike
        self.viewModel = viewModel
        _selectedIntervals = State(initialValue: Set(detectionResult.suggestedIntervals))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if step == 1 {
                    detectionHeaderSection
                    Divider()
                    partsList
                } else {
                    dateStepContent
                }

                bottomActionButtons
            }
            .navigationTitle(step == 1 ? "Choose Parts" : "Last Service Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if step == 1 {
                        Button("Cancel") { dismiss() }
                    } else {
                        Button("Back") { step = 1 }
                    }
                }
            }
            .sheet(isPresented: $showingTypeSelection) {
                BikeTypeSelectionView { selectedType in
                    let intervals = BikeDetectionService.shared.getDefaultIntervalsForType(selectedType)
                    selectedIntervals = Set(intervals)
                    manuallySelectedType = selectedType
                    showingTypeSelection = false
                }
            }
        }
    }

    // MARK: - Step 1: Parts List

    private var partsList: some View {
        List {
            ForEach(PartTemplateService.shared.getAllCategories()) { category in
                let parts = PartTemplateService.shared.getTemplatesByCategory(category.id)
                if !parts.isEmpty {
                    Section(header: Label(category.name, systemImage: category.icon)) {
                        ForEach(parts) { part in
                            partRow(for: part)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func partRow(for part: PartTemplate) -> some View {
        Button(action: {
            if selectedIntervals.contains(part.id) {
                selectedIntervals.remove(part.id)
            } else {
                selectedIntervals.insert(part.id)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: part.icon)
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(part.name)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text("Every \(Int(part.defaultIntervalHours)) hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if selectedIntervals.contains(part.id) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("interval_\(part.id)")
    }

    // MARK: - Step 2: Date Picker

    private var dateStepContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When were these components last serviced?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    let count = selectedIntervals.count
                    Text("\(count) part\(count == 1 ? "" : "s") selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)

                DatePicker(
                    "Last Service Date",
                    selection: $lastServiceDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }
            .padding()
        }
    }

    // MARK: - Detection Header

    private var detectionHeaderSection: some View {
        VStack(spacing: 8) {
            let iconType = manuallySelectedType ?? detectionResult.type
            HStack(spacing: 12) {
                Image(systemName: iconType.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    if detectionResult.confidence != .fallback {
                        Text(detectionResult.displayTitle)
                            .font(.headline)
                        Text(detectionResult.displaySubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let selected = manuallySelectedType {
                        Text(bike.name ?? "")
                            .font(.headline)
                        Text(selected.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Select a bike type to get recommendations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if detectionResult.confidence != .fallback {
                    confidenceBadge
                } else {
                    Button("Select Type") {
                        showingTypeSelection = true
                    }
                    .font(.subheadline)
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
                .font(.caption)
            Text(detectionResult.confidence.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(confidenceColor.opacity(0.2))
        .foregroundColor(confidenceColor)
        .cornerRadius(10)
    }

    private var confidenceIcon: String {
        switch detectionResult.confidence {
        case .high: return "checkmark.circle.fill"
        case .medium: return "checkmark.circle"
        case .low: return "exclamationmark.circle"
        case .fallback: return "questionmark.circle"
        }
    }

    private var confidenceColor: Color {
        switch detectionResult.confidence {
        case .high: return .green
        case .medium: return .blue
        case .low: return .orange
        case .fallback: return .gray
        }
    }

    // MARK: - Bottom Actions

    private var bottomActionButtons: some View {
        VStack(spacing: 0) {
            Divider()
            if step == 1 {
                Button(action: { step = 2 }) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedIntervals.isEmpty)
                .accessibilityIdentifier("next_button")
                .padding(.horizontal)
                .padding(.vertical, 12)
            } else {
                Button(action: applyIntervals) {
                    Text("Apply")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("apply_button")
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Actions

    private func applyIntervals() {
        viewModel.createIntervals(templateIds: Array(selectedIntervals), lastServiceDate: lastServiceDate)
        dismiss()
    }
}
