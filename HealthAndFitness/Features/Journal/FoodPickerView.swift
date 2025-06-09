//
//  FoodPickerView.swift
//  HealthAndFitness
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

struct FoodPickerView: View {
    static var energyFormatter: EnergyFormatter = {
        let formatter = EnergyFormatter()
        formatter.unitStyle = .long
        formatter.isForFoodEnergyUse = true
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter
    }()

    @Environment(\.dismiss) var dismiss

    let onFoodItemSelected: (FoodItem) -> Void

    private let foodItems = FoodItem.foodItems.sorted { $0.name < $1.name }

    var body: some View {
        NavigationStack {
            List(foodItems) { item in
                Button {
                    onFoodItemSelected(item)
                    dismiss()
                } label: {
                    HStack {
                        Text(item.name)

                        Spacer()

                        Text(Self.energyFormatter.string(fromJoules: item.joules))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Pick Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FoodPickerView { foodItem in
        print("Selected: \(foodItem.name)")
    }
}

#Preview("Dark Mode") {
    FoodPickerView { foodItem in
        print("Selected: \(foodItem.name)")
    }
    .preferredColorScheme(.dark)
}
