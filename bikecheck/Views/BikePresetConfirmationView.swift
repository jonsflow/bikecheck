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

    init(detectionResult: BikeDetectionResult, bike: Bike, viewModel: BikeDetailViewModel) {
        self.detectionResult = detectionResult
        self.bike = bike
        self.viewModel = viewModel
        _selectedIntervals = State(initialValue: Set(detectionResult.suggestedIntervals))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Detection Result Header
                detectionHeaderSection

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Date Picker Section
                        datePickerSection

                        Divider()

                        // Intervals Section
                        intervalsSection
                    }
                    .padding()
                }

                // Bottom Actions
                bottomActionButtons
            }
            .navigationTitle("Service Intervals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
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

    // MARK: - Header Section

    private var detectionHeaderSection: some View {
        VStack(spacing: 12) {
            // Bike icon
            let iconType = manuallySelectedType ?? detectionResult.type
            Image(systemName: iconType.iconName)
                .font(.system(size: 50))
                .foregroundColor(.blue)

            // Detection title
            if detectionResult.confidence != .fallback {
                Text("We detected:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(detectionResult.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(detectionResult.displaySubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Confidence badge
                confidenceBadge
            } else if let selected = manuallySelectedType {
                Text(bike.name ?? "")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(selected.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: {
                    showingTypeSelection = true
                }) {
                    HStack {
                        Image(systemName: "bicycle.circle.fill")
                        Text("Select Bike Type")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            } else {
                Text("Unable to detect bike type")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Please select your bike type to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)

                Button(action: {
                    showingTypeSelection = true
                }) {
                    HStack {
                        Image(systemName: "bicycle.circle.fill")
                        Text("Select Bike Type")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(confidenceColor.opacity(0.2))
        .foregroundColor(confidenceColor)
        .cornerRadius(12)
    }

    private var confidenceIcon: String {
        switch detectionResult.confidence {
        case .high:
            return "checkmark.circle.fill"
        case .medium:
            return "checkmark.circle"
        case .low:
            return "exclamationmark.circle"
        case .fallback:
            return "questionmark.circle"
        }
    }

    private var confidenceColor: Color {
        switch detectionResult.confidence {
        case .high:
            return .green
        case .medium:
            return .blue
        case .low:
            return .orange
        case .fallback:
            return .gray
        }
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Service Date")
                .font(.headline)

            Text("When were these components last serviced?")
                .font(.caption)
                .foregroundColor(.secondary)

            DatePicker(
                "Last Service Date",
                selection: $lastServiceDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
        }
    }

    // MARK: - Intervals Section

    private var intervalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Service Intervals")
                    .font(.headline)

                Spacer()

                if detectionResult.confidence == .fallback {
                    Button("Choose Type") {
                        showingTypeSelection = true
                    }
                    .font(.subheadline)
                }
            }

            if selectedIntervals.isEmpty {
                emptyStateView
            } else {
                intervalsList
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No intervals selected")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Choose Bike Type") {
                showingTypeSelection = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private var intervalsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(selectedIntervals).sorted(), id: \.self) { intervalId in
                intervalRow(for: intervalId)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }

    private func intervalRow(for intervalId: String) -> some View {
        HStack {
            Button(action: {
                if selectedIntervals.contains(intervalId) {
                    selectedIntervals.remove(intervalId)
                } else {
                    selectedIntervals.insert(intervalId)
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: selectedIntervals.contains(intervalId) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(selectedIntervals.contains(intervalId) ? .blue : .gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(intervalDisplayName(intervalId))
                            .font(.body)
                            .foregroundColor(.primary)

                        if let template = PartTemplateService.shared.getTemplate(id: intervalId) {
                            Text("\(Int(template.defaultIntervalHours)) hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(Color(.systemBackground))
        .accessibilityIdentifier("interval_\(intervalId)")
    }

    private func intervalDisplayName(_ id: String) -> String {
        if let template = PartTemplateService.shared.getTemplate(id: id) {
            return template.name
        }
        return id.replacingOccurrences(of: "_", with: " ").capitalized
    }

    // MARK: - Bottom Actions

    private var bottomActionButtons: some View {
        VStack(spacing: 12) {
            Divider()

            if detectionResult.confidence != .fallback {
                // Normal flow - show both Customize and Apply buttons
                HStack(spacing: 12) {
                    Button(action: {
                        showingTypeSelection = true
                    }) {
                        Text("Customize")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("customize_button")

                    Button(action: applyIntervals) {
                        Text("Apply")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedIntervals.isEmpty)
                    .accessibilityIdentifier("apply_button")
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            } else {
                // Fallback mode - only show Apply button (user must select type first)
                Button(action: applyIntervals) {
                    Text("Apply")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedIntervals.isEmpty)
                .accessibilityIdentifier("apply_button")
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Actions

    private func applyIntervals() {
        let templateIds = Array(selectedIntervals)
        viewModel.createIntervals(templateIds: templateIds, lastServiceDate: lastServiceDate)
        dismiss()
    }
}

