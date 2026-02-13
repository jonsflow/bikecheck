//
//  BikeTypeSelectionView.swift
//  bikecheck
//
//  Created by Claude on 2026-02-12.
//

import SwiftUI

struct BikeTypeSelectionView: View {
    @Environment(\.dismiss) var dismiss

    let onTypeSelected: (BikeType) -> Void

    // Filter out unknown type from selection
    private var selectableTypes: [BikeType] {
        BikeType.allCases.filter { $0 != .unknown }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(selectableTypes, id: \.self) { bikeType in
                        bikeTypeRow(for: bikeType)
                    }
                } header: {
                    Text("Select Your Bike Type")
                } footer: {
                    Text("Choose the type that best matches your bike. This will determine which service intervals are suggested.")
                }
            }
            .navigationTitle("Bike Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func bikeTypeRow(for type: BikeType) -> some View {
        Button(action: {
            onTypeSelected(type)
            dismiss()
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: type.iconName)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("bike_type_\(type.rawValue)")
    }
}

