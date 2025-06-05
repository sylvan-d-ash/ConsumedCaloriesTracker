//
//  EnergyView-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 05/06/2025.
//

import Foundation

/*
 Resting
 Consumed - dieetaryEnergyConsumed
 Burned - activeEnergyBurned
 Net Energy
 */

extension EnergyView {
    @MainActor
    final class ViewModel: ObservableObject {
        private var energyFormatter: EnergyFormatter = {
            let formatter = EnergyFormatter()
            formatter.unitStyle = .long
            formatter.isForFoodEnergyUse = true // This makes it default to kCal display
            formatter.numberFormatter.maximumFractionDigits = 0 // Usually calories are whole numbers
            return formatter
        }()

        private let healthKitManager: HealthKitManager

        init(healthKitManager: HealthKitManager) {
            self.healthKitManager = healthKitManager
        }
    }
}
